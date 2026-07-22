---
start_time: 2026-07-17 09:56:58
end_time: 2026-07-17 10:46:35
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [llm-echo-detection, similarity-matching, deterministic-recovery, difflib, sage-llm-summary]
digested: true
---

# ECHO 오탐 근본원인(번역) 발견 → 유사도 기반 판정 + 결정적 prefix-strip 복구 도입

## 배경 및 트러블슈팅 과정

`sage-check-status.py`(수십만 건 규모 전체 스캔)의 ECHO(LLM이 prompt 지시문을 그대로
베껴 응답한 경우) 판정은 고정 문구 매커(`ECHO_MARKERS`) 매칭에만 의존했다. 이 마커 중
`"write in english"`가 **번역 개입 시 오탐**을 낸다는 걸 실제 프로덕션 DB를 직접 조회해
확인했다: 원본 COMMENTS가 한글로 "영문으로 작성해주세요"라고 요청하면, LLM이 이를 정상적으로
"Please write in English"로 **번역만** 해도 그 문구가 우연히 마커와 매칭되어 ECHO로
오판된다. 흥미로운 점은, 이 오탐은 "LLM에 실제 입력된(truncate 후) 텍스트에 마커 문구가
이미 있으면 제외"하는 기존 방어 로직(`given_text_lower` 대조)으로도 못 잡는다는 것 —
**원본 언어가 다르면(한글→영어 번역) 입력 텍스트 대조 자체가 무의미**해지기 때문이다.
truncation(입력 길이 제한으로 인한 누락)이 원인이라는 최초 가설은 틀렸고, 번역이 진짜
원인이었다.

**교훈**: "입력 데이터에 이미 있는 문구는 제외"라는 방어 로직은 입력=출력이 같은 언어일 때만
유효하다. LLM이 번역/의역을 수행하는 파이프라인에서는 이 가정이 깨진다.

## 설계 결정: 마커 vs 유사도, 역할을 명확히 분리

마커 기반 판정을 유사도(prompt 지시문 원문과 difflib 비교) 기반으로 통째로 대체하지 않고,
**두 신호를 독립적으로 유지하되 용도를 다르게** 가져갔다:

- **마커**: "LLM을 다시 부를지"를 결정하는 **유일한** 트리거. 오탐 가능성이 낮고 결정론적.
- **유사도**: 마커가 놓치는 "지시문을 살짝 바꿔 베낀" 케이스를 보완하는 **참고 신호**.
  오탐 가능성이 마커보다 높다고 판단해, 이것만으로는 LLM 재질의를 자동 트리거하지 않기로
  결정. 대신 사람이 CSV를 보고 검토하거나, 아래 결정적 복구 후보로만 쓴다.

임계값은 80% → 95% → 다시 80%로 왔다갔다 했다: 처음엔 오탐을 줄이려 95%로 올렸으나, 이후
"유사도는 자동 재질의를 트리거하지 않는 참고 신호일 뿐"이라는 결정이 확정되면서, 참고
자료는 다소 과다검출(false positive)되어도 사람이 걸러내면 되므로 놓치는 것(false
negative)보다 넓게 잡는 게 낫다고 판단해 80%로 되돌렸다. **설계 결정이 바뀌면 관련
파라미터(임계값)도 그 결정에 맞춰 재검토해야 한다**는 사례.

## 결정적 prefix-strip 복구 — LLM 재호출 없는 문자열 처리 복구

실제 유사도 사례 3건을 DB에서 직접 조회해 비교해보니, 그중 2건은 **"prompt 지시문을 거의
그대로 베끼고 문장 맨 끝의 지시어만 실제 답으로 바꿔치기"**한 명백한 패턴이었다:

```
instruction: "...or state 'Unverifiable' if it cannot be determined. write in english."
value:       "...or state 'Unverifiable' if it cannot be determined. pierre.de-mauduit-du-plessis@ampere.cars"
→ 공백 토큰 기준 91% 연속 일치
```

나머지 1건은 문장 중간 동사만 바뀐 경계 사례("한글로 분석해주세요" → "분석할 수 없습니다")로,
이 패턴에 맞지 않았다.

이 관찰에서 **"값이 지시문의 접두부와 토큰 단위로 80% 이상 연속 일치하면, 그 접두부를
잘라내고 남은 부분을 실제 답으로 채택"**하는 결정적(deterministic) 복구 함수
(`try_strip_echoed_instruction_prefix`)를 만들었다. LLM을 다시 부르지 않고 **문자열
처리만으로** 복구되므로 비용이 0에 가깝다.

### 함정: 프롬프트 파일 파싱 결과에 JSON 리터럴 quote가 그대로 남아있음

이 함수를 처음 구현하고 실제 DB 값으로 테스트했을 때 전부 실패했다. 원인은
`build_field_instruction_map()`(prompt 파일을 파싱해 `{field_path: 지시문 텍스트}`
매핑을 만드는 함수)이 반환하는 지시문 텍스트가 **prompt 파일 안의 JSON 문자열 리터럴
원문을 그대로 슬라이스**한 것이라, 감싸는 큰따옴표(`"..."`)가 벗겨지지 않은 채 포함돼
있었다는 것. 반면 실제 LLM 응답값(DB에 저장된 값)은 JSON 파싱을 거쳐 quote가 없는 순수
텍스트다. 그 결과 토큰 비교의 **첫 토큰부터 어긋나** 전혀 매칭되지 않았다.
`repr()`로 출력한 문자열을 보고 "따옴표가 있다/없다"를 눈으로 판단할 때, 그 따옴표가
**repr()의 delimiter인지 문자열 내용 자체인지**를 혼동해 한동안 삽질했다 — `len()`과
슬라이싱으로 실제 첫/마지막 문자를 직접 확인하고서야 정확한 원인을 잡았다.

**교훈**: 두 텍스트 소스(파일 파싱 결과 vs DB에 저장된 JSON 파싱 결과)를 비교할 때는 각각의
"원문성(raw-ness)" 차이(quote, escape, 공백 정규화 등)를 먼저 명시적으로 맞춘 뒤 비교해야
한다. `repr()` 출력만 보고 판단하지 말고 `len()`/슬라이싱으로 실제 바이트를 확인할 것.

### 적용 지점 확장 — 옵션 없이도 항상 즉시 복구

처음엔 새 CLI 옵션(`--solve-problems-all`)에서만 이 복구를 시도하도록 구현했으나, 사용자
피드백으로 "재질의를 유발하는 기존 스캔 로직(`process_chunk`, 모든 모드 공통)에도 같은
복구를 넣어도 되지 않겠냐"는 제안이 있어 확장했다. 이때 **"LLM 재질의 트리거 여부는 여전히
마커만 사용"**이라는 기존 역할 분담은 건드리지 않고, "재질의 없이 그 자리에서 프로그래밍적으로
고칠 수 있는 부분만" 유사도 기준으로 추가했다 — type mismatch 즉시 복원(대표 타입 기준 값
변환)과 정확히 같은 성격의 "즉시 고칠 수 있으면 고친다" 정책 계열에 자연스럽게 편입시켰다.
값을 직접 바꾸는 자동화 로직이므로, 무엇을 왜 바꿨는지(필드 경로, 유사도 %, 변경 전/후 값)를
`--verbose` 여부와 무관하게 항상 로그로 남기도록 했다 — 자동 수정 로직은 침묵하지 않아야
나중에 감사(audit)할 수 있다는 원칙.

## 검증 방법

새 로직을 구현할 때마다 실제 프로덕션 DB의 실제 사례(오탐 2건 확인용으로 이미 조회해둔
issue)를 직접 가져와 함수에 그대로 대입해 기대값과 비교하는 방식으로 검증했다. 유닛
테스트 프레임워크 없이도, "실제 데이터 3건 중 2건은 복구되고 1건은 복구 안 됨(그리고 그
이유가 설계 의도와 일치)"을 스크립트로 즉석 검증하는 것만으로 충분한 신뢰도를 얻을 수
있었다 — 특히 이 함수는 nested closure(`run_solve_problems` 내부의
`_try_deterministic_echo_strip`)라 외부에서 직접 import해 테스트할 수 없었는데, 이때는
같은 로직을 스크립트에 그대로 복제해 재현 테스트하는 방식으로 우회했다.

## 결과물 (참고용)

- `SWPMUtil/sage_llm_schema.py`: `build_field_instruction_map()`, `is_echo_by_similarity()`,
  `find_echo_similarity_hits()`, `try_strip_echoed_instruction_prefix()` 추가.
- `sage-check-status.py`: 유사도 판정을 요약 테이블/`--export-issues-csv`에 마커와 별도
  컬럼으로 노출.
- `sage-check-llm-answer.py`: `--solve-problems-all`(마커+유사도 모두 처리, 유사도 단독
  케이스는 prefix-strip 우선 시도) 신규 옵션, `process_chunk()`에도 동일 즉시 복구 적용.
- 3개 스크립트 + 공유 모듈 전체에 "전체 흐름" 개요 docstring 추가.
