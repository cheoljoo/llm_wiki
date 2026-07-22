# pvs_crawler — sage_llm_summary / sage-check-status 파이프라인 운영 노트

pvs_crawler의 LLM 기반 요약·검증 파이프라인(`sage_llm_summary.py`, `sage-check-status.py`,
`sage-check-llm-answer.py`)을 운영하며 정리한, 이 프로젝트 고유의 설계 결정과 노하우.

## Semaphore 기반 adaptive worker는 이미 포화 상태면 고정해야 한다

`_ExaoneKeySlot`는 API 키 1개당 `threading.Semaphore(MAX_WORKERS_EXAONE=5)`를 보유하고,
`_acquire_exaone_slot()`이 라운드로빈으로 빈 슬롯을 찾는다. EXAONE 전용 실행에서는
`_initial_workers`가 이미 `N_keys × 5`(EXAONE 총 슬롯 수)로 시작하는데, 정상 완료마다 worker를
`+1`(adaptive 증가) 하는 로직이 그대로 남아 있어 슬롯 총량을 초과하는 요청이 계속 쌓이고, 결국
슬롯 획득 420초 타임아웃이 반복 악화되는 문제가 있었다.

**교훈**: adaptive worker 증가는 "서버에 여유가 있을 때 처리량을 끌어올리는" 것이 목적이다.
`_initial` 값이 이미 실제 서버 한계(슬롯 총량)와 같다면 `_max > _initial`로 두면 역효과 —
정상 완료를 신호로 계속 worker를 늘려 오히려 슬롯을 고갈시킨다. `_only_exaone` 같은 플래그로
"이미 포화 상태로 시작하는 실행"을 구분해서, 그 경우엔 `_max_workers = _initial_workers`로
고정하는 것이 안전하다 (EXAONE+GPT 혼합 실행처럼 여유 슬롯이 있는 경우엔 기존 adaptive 증가를
유지하는 게 맞다 — GPT 슬롯을 놀리지 않으려면).

부수 조정:
- `_acquire_exaone_slot` 타임아웃: 300s → 420s (배치가 길어질수록 슬롯이 일시적으로 막히는 빈도가 늘어나는 점 반영)
- `MAX_RUN_HOURS`: 6 → 8 — 타임아웃을 늘리면 슬롯 대기 시간도 늘어 전체 실행 시간에 영향을 준다. **timeout을 상향할 때는 상위 실행시간 제한도 함께 검토할 것.**
- 키 소스를 `issue_exaone_key_list` → `commit_exaone_key_list`로 분리해 이슈 처리용/커밋 처리용 키 풀의 자원 경쟁을 줄임

## 호출자가 이미 조회한 row는 `preloaded_rows` dict로 내려서 중복 SQL 제거

`SageLLMSummary` 생성자에 `preloaded_rows_by_issue_id: Optional[dict]`를 추가해, `sage-check-llm-answer`가
확장된 `SQL_FETCH_BASE`로 이미 읽어온 row를 그대로 넘기면 `--issues` 지정 시 두 번째 DB 조회를 생략한다.
`preloaded_rows_by_issue_id`가 있어도 `issue_ids`가 함께 없으면 기존 SQL 조회 경로를 그대로 타므로
하위 호환이 유지된다. 일반화된 패턴은 [[python-patterns]] 참고.

부가로 `save_prompt: bool = False` 파라미터를 추가해 `True`일 때만 치환된 프롬프트를 `debug/`에
저장하도록 했다 — `--issues` CLI 디버그 전용이며 프로덕션 배치 경로에는 영향 없음.

## sage-check-status.py 타입 불일치 분석

같은 issue를 여러 모델로 처리했을 때 응답 필드 타입이 모델별로 갈리는 문제를 집계하는 로직.

### 변환 가능/불가 판정 (`_CONVERTIBLE_TYPE_PAIRS`)

- 변환 가능: `str ↔ bool/int/float`, `bool ↔ int`, `int ↔ float`, `dict → list`(`dict.keys()`로 항상 가능),
  `str → list/dict`(JSON 파싱 성공 시에만 — 조건부)
- 변환 불가: `list → dict` (가장 문제적 케이스 — 역방향인 `dict → list`와 비대칭이라는 점에 주의)
- 빈 값(`[]`, `{}`, `''`)은 타입에 관계없이 상호 변환 가능으로 취급 (`_is_value_convertible()`에 early
  return 추가). 이걸 빼먹으면 실제로는 무해한 "빈 list vs 빈 dict" 불일치까지 변환불가로 잘못
  집계된다.

### `list_c`/`list_nc` 인코딩으로 오버카운트 수정

`ticket_compact` 저장 시 `list` 타입을 `list_c`(빈 list 또는 `list[0]`이 dict → 변환가능)와
`list_nc`(비어있지 않고 `list[0]`이 dict 아님 → 변환불가)로 나눠 저장한다. 이 구분이 없으면
`list→dict` 불일치가 전부 "조건부(?)" 취급되어 실제로는 변환 불가능한 케이스까지 복원 가능으로
오카운트되는 버그(`타입 복원 == 타입 불일치`로 항상 같은 값이 되는 증상)가 있었다.

### L1/L2 분리 집계

1st pass에서 dict 값 내부의 sub-key 타입도 `key1.key2` 경로로 함께 수집해, level-1(최상위 키)과
level-2(중첩 키) dominant type을 따로 계산하고 요약 테이블에 `타입 불일치(L1)/(L2)`,
`타입 복원(L1)/(L2)`로 분리 표시한다. 안 그러면 최상위 키만 봐서는 안 보이는 중첩 필드의
타입 불일치가 통계에서 통째로 누락된다.

### 변환불가 예시는 확정 버킷에서 직접 수집

`type_value_samples_conv`/`type_value_samples_nc` 두 버킷을 `(model, key, type)`(L1) 또는
`(model, "key1.key2", type)`(L2) 키로 따로 모아두면, 분포가 99.9% 변환가능이어도 변환불가 샘플
3건을 실제 issue_id + 값 스니펫과 함께 표시할 수 있다. `변환불가=0건`인데 예시가 표시되는 버그는
`not_conv == 0`일 때 `_nc_ex = []`로 가드해서 수정.

### CSV export (`--export-issues-csv`)

컬럼: `ISSUE_ID, prompt_file, model, type_mismatch, key_mismatch, echo_include`. unique key는
`(ISSUE_ID, prompt_file, model)` — 모델별 1행. `type_mismatch`는 `key=실제타입(expect:dominant타입)`
형식으로 해당 모델에서 dominant와 다른 key만 담고, `echo_include`는 `_find_echo_fields()`로 얻은
field_path 목록을 표시한다.

### DB 저장 관련 확인 사항

- `sage_llm_summary.py`는 ECHO 필드 체크를 하지 않으므로 ECHO가 있어도 DB에 저장된다.
- `PER_KEY_RETRY`: 부분 성공(≥1 key 채워짐)이면 DB 저장, 완전 실패(0 key)면 저장 안 하고 CSV에만 기록.
- 타입 불일치는 `sage-check-status.py`의 통계 전용 — 재생성을 트리거하지 않는다. ECHO/key 누락 감지 후
  재쿼리(`regenerate_candidates`)는 `sage-check-llm-answer.py`가 기존 DB 데이터를 읽어서 별도로 수행한다.
  `sage-check-status.py` 자체는 읽기 전용.

## `--count-only`로 루프 수 자동 계산 (셸 루프 스크립트 패턴)

배치를 `while` 루프로 반복 실행하는 셸 스크립트에서, 루프 시작 전 처리 대상 row 수를 조회해
`TOTAL_LOOPS = ceil(rows / CHUNK_SIZE)`를 계산하고 `while [ LOOP_COUNT -lt TOTAL_LOOPS ]`로
바꾸면, "소진 감지 후 break"보다 예측 가능하게 루프를 종료할 수 있다.

- `sage-check-llm-answer.py --count-only`: 고유 태그 `[COUNT_ONLY_RESULT] <숫자>`는 stdout, SQL은
  `[COUNT_ONLY_SQL]`로 stderr에 출력 — 셸에서 `grep '\[COUNT_ONLY_RESULT\]' | awk '{print $NF}'`로
  안전하게 파싱 가능 (COUNT SQL은 기존 `build_sql_fetch()` 결과에서 `\nLIMIT` 이후만 잘라 재사용).
- 파싱에 lookbehind regex(`grep -oP '(?<=TAG] )\d+'`)를 쓰면 에디터가 긴 라인을 자동 줄바꿈할 때
  깨지는 위험이 있다 — 관련 함정은 [[shell-cli-gotchas]] 참고.

## Teams webhook ON/OFF 토글 (운영/디버그 전환)

`sage_check_status.sh`, `sage-update-prompt-from-newest-with-exaone-loop.sh` 등 셸 스크립트에
`TEAMS_ENABLED="ON"` 변수 하나를 두고 `send_teams_message()` 맨 앞에서
`[ "${TEAMS_ENABLED}" != "ON" ] && return 0`로 즉시 리턴하게 하면, 코드 변경 없이 한 줄만 바꿔서
Teams 전송을 껐다 켰다 할 수 있다. `sage_check_status.sh`는 `SLEEP_HOURS`(기본 10h) 간격으로
`sage-check-status.py`를 `MAX_LOOPS`(기본 10)번 반복 실행하며, 루프 시작(🚀)/종료(✅ + 로그 끝 50줄)/
비정상 종료(❌)/전체 완료(🏁) 시점에 Teams 알림을 보낸다. bash에서 알림 메시지에 실제 줄바꿈을 넣을 때
겪는 함정은 [[shell-cli-gotchas]] 참고.

## ECHO(프롬프트 지시문 베끼기) 탐지: 마커 + 유사도 이원화, 결정적 prefix-strip 복구

`sage-check-status.py`의 ECHO(LLM이 prompt 지시문을 그대로 베껴 응답한 경우) 판정은 원래 고정 문구
마커(`ECHO_MARKERS`) 매칭에만 의존했는데, 이 중 `"write in english"` 마커가 **번역 개입 시 오탐**을
낸다는 걸 실제 프로덕션 DB로 확인했다: 원본이 한글로 "영문으로 작성해주세요"라고 요청하면 LLM이 이를
정상적으로 "Please write in English"로 번역만 해도 마커와 우연히 매칭돼 ECHO로 오판된다. "LLM에 실제
입력된 텍스트에 마커 문구가 이미 있으면 제외"하는 기존 방어 로직(`given_text_lower` 대조)도 원본
언어가 다르면(한글→영어 번역) 입력 텍스트 대조 자체가 무의미해져 못 잡는다 — **"입력에 이미 있는 문구는
제외"라는 방어는 입력=출력이 같은 언어일 때만 유효**하다.

**설계 결정**: 마커를 유사도로 통째로 대체하지 않고 역할을 분리했다 — 마커는 "LLM을 다시 부를지"를
결정하는 유일한 트리거(오탐 낮음, 결정론적), difflib 기반 유사도(prompt 지시문 원문과 비교)는 마커가
놓치는 "지시문을 살짝 바꿔 베낀" 케이스를 보완하는 참고 신호(오탐 가능성 높다고 판단해 이것만으로는
자동 재질의를 트리거하지 않음)로 컬럼/실행 모드(`--solve-problems` vs `--solve-problems-all`)까지
분리해서 관리한다. 유사도 임계값은 80%→95%→80%로 되돌렸다 — "유사도는 참고 신호일 뿐 자동 트리거가
아니다"가 확정되면서, 참고 자료는 과다검출(FP)돼도 사람이 걸러내면 되니 놓치는 것(FN)보다 넓게 잡는
게 낫다고 판단했기 때문. **설계 결정이 바뀌면 관련 파라미터(임계값)도 재검토해야 한다**는 사례.

유사도로 잡힌 사례 중 상당수는 "지시문을 거의 그대로 베끼고 문장 끝의 지시어만 실제 답으로 바꿔치기"한
패턴이라, "값이 지시문의 접두부와 토큰 단위로 80% 이상 연속 일치하면 그 접두부를 잘라내고 남은 부분을
채택"하는 결정적(deterministic) 복구 함수 `try_strip_echoed_instruction_prefix()`를 만들어 LLM 재호출
없이 문자열 처리만으로 복구한다(비용 0에 가까움). 처음 구현했을 때 전부 실패했는데, 원인은
`build_field_instruction_map()`이 반환하는 지시문 텍스트가 prompt 파일의 JSON 문자열 리터럴을 그대로
슬라이스해 감싸는 따옴표가 안 벗겨진 반면 실제 LLM 응답값(DB 저장값)은 JSON 파싱을 거쳐 quote가 없는
순수 텍스트였기 때문 — 토큰 비교가 첫 토큰부터 어긋났다. **교훈**: 두 텍스트 소스(파일 파싱 결과 vs
DB에 저장된 JSON 파싱 결과)를 비교할 때는 각각의 "원문성"(quote/escape/공백 정규화 차이)을 먼저
명시적으로 맞춰야 한다 — `repr()` 출력만 보고 판단하지 말고 `len()`/슬라이싱으로 실제 바이트를 확인할 것.

적용 범위는 새 CLI 옵션(`--solve-problems-all`)뿐 아니라 재질의를 유발하는 기존 스캔 로직
(`process_chunk`, 모든 모드 공통)에도 확장했다 — "LLM 재질의 트리거는 여전히 마커만 사용"이라는 역할
분담은 그대로 두고, "재질의 없이 그 자리에서 프로그래밍적으로 고칠 수 있는 부분만" 유사도 기준으로
추가한 것. 값을 직접 바꾸는 자동화 로직이므로 무엇을 왜 바꿨는지(필드 경로, 유사도 %, 변경 전/후 값)를
`--verbose` 여부와 무관하게 항상 로그로 남긴다 — **자동 수정 로직은 침묵하지 않아야 나중에 감사할 수
있다.**

검증은 유닛 테스트 프레임워크 없이, 실제 프로덕션 DB에서 확인해둔 사례를 함수에 그대로 대입해 기대값과
대조하는 방식으로 충분한 신뢰도를 얻었다 — 특히 이 함수는 `run_solve_problems` 내부의 nested closure라
외부에서 직접 import할 수 없었는데, 같은 로직을 스크립트에 복제해 재현 테스트하는 방식으로 우회했다.

related: `AGILEDEV-1053`(이 작업으로 In Progress → Resolved 전환, prompt v1.002 기준 597,930건 처리
완료). `AGILEDEV-1044/1043`에서 발견된 인접 버그 2건도 같은 LLM 응답 검증 계열
(`sage-check-llm-answer.py`)이라 함께 기록: (1) "키가 없으면 빈 문자열로 채우는" fallback 로직이 진짜
누락(missing)을 "정상"으로 위장시키고 있어서 제거함, (2) ECHO 감지 시 값을 통째로 교체하던 방식을
`error:ECHO` 접두어만 붙이는 방식으로 바꿔 원문을 보존하도록 개선(디버깅 시 원문을 다시 볼 수 있게).

[^pvs_crawler2] [^hermes]

## `ensure_models`가 "존재하지만 오래된(stale)" 모델 결과는 재처리하지 못하던 사각지대

`make_llm_summary.sh`는 `[A.1]`(gpt-4o-mini 기본 처리) → `[B.2]`
(`sage-check-llm-answer.py --ensure-models exaone`, exaone 보정) 순서로 도는데, `[A.1]`이 어떤 티켓을
hash 변경으로 재처리(gpt-4o-mini만 갱신)해도 `_save_results()`의 병합 로직
(`{**existing_llm_base, **model_results}`)이 기존 모델 키를 보존하므로 exaone 값이 **유실되지는
않는다.** 하지만 여기서 진짜 문제가 드러남: exaone 값이 유실은 안 되지만 **갱신되지도 않는다.**
`[B.2]`의 `ensure_models` 판정이 "해당 모델이 LLM_SUMMARY에 아예 없는 경우(`missing_model`)"만 재생성
대상으로 잡고 있어서, "모델 키는 있지만 그 값이 티켓 내용이 바뀌기 전의 옛 snapdate 그대로인" 케이스는
영원히 재처리되지 않는 사각지대였다(`llm_snapdate={'exaone': '2026-07-08', 'gpt-4o-mini': '2026-07-22'}`
처럼 실제 로그에서 확인).

**해결**: `process_chunk()`의 `ensure_model not in row_models_present`만 보던 판정 블록에, `ensure_model`이
존재하더라도 같은 티켓의 다른 모델 snapdate보다 오래되면 `stale_model_snapdate`라는 새 reason으로
`regenerate_candidates`에 포함하는 분기를 추가했다. 이 새 reason은 `--dry-run` 출력 필터와 실제
재생성을 트리거하는 수집 로직 **두 곳 모두**에 `missing_model`과 동일하게 넣어야 한다 — 하나만 고치면
dry-run 목록에는 보이는데 실행은 안 되는 식으로 조용히 반쪽짜리가 된다.

**교훈**: 여러 모델 결과를 병합(merge) 기반으로 누적 저장하는 구조에서는 "존재 여부"만으로 재처리
필요성을 판단하면 부분 업데이트(A 모델만 갱신되고 B는 방치)가 영구히 고착되는 사각지대가 생긴다.
per-model timestamp(snapdate)를 함께 저장해두면 이런 staleness를 사후에 감지할 수 있다. 이런 버그는
코드만 읽어서는 확신하기 어렵고 실제 운영 로그의 구체적 수치를 코드 흐름과 나란히 대조해야 확실히
검증된다. 강제 재처리는 `sage_llm_summary.py`의 `self.force_rerun or self.issue_ids` 분기 덕분에
`issue_ids`만 명시적으로 넘기면 되므로, 감지 로직(`sage-check-llm-answer.py`)만 고치고 하위 skip 판단
로직은 건드릴 필요가 없었다 — **사각지대 수정은 가장 좁은 지점에서 하는 게 안전**하다는 사례. 실제
`--run-regenerate-llm`처럼 비용/DB 변경이 따르는 옵션을 돌리기 전에는 `--help` 문구("DB 변경 없음")를
그대로 믿지 말고 실제 코드(`dry_run=` 인자 전달 여부)로 재확인할 것 — 이 스크립트의 help 문구는 실제
동작과 다르게 오래된 상태였다.

[^pvs_crawler3]

## 기타 운영 팁

- **재현 안 되는 Windows 크래시는 코드보다 재부팅부터 의심**: `getPmsExcel.py`의 access violation류
  크래시(종료코드 3221225477)를 torch(easyocr)/numpy/opencv의 OpenMP 런타임 충돌로 추정해
  `KMP_DUPLICATE_LIB_OK=TRUE`로 완화를 시도했으나 재발했고, 실질적 해결책은 오래 켜둔 Windows
  환경을 **재부팅**하는 것이었다. 재현이 잘 안 되는 0xC0000005류 크래시는 코드보다 "장시간
  미재부팅 환경"을 먼저 의심할 가치가 있다.
- **분석 설계 전에 실제 데이터 분포부터 표본 확인**: CCR readiness 분석 초기에는 Gerrit branch까지
  고려하려 했으나, 실제 데이터를 까보니 CCR의 "Gerrit Link"는 거의 100%가 c-type이라 branch는
  사실상 항상 1개뿐이라 의미가 없었다. 분석/설계 전에 실제 데이터 분포를 먼저 표본 확인하면
  불필요한 차원(복잡도)을 걷어낼 수 있다.

[^hermes]

## 관련 문서

- bash `$()` 파싱 함정, printf 줄바꿈 함정, `uv`/`pipenv` venv 충돌: [[shell-cli-gotchas]]
- `preloaded_rows` 같은 "호출자가 이미 가진 데이터 재사용" 패턴 일반화: [[python-patterns]]
- VS Code Copilot에서 mcp-atlassian 연동(wiki-log용): [[mcp-atlassian]]
- CCR/Gerrit 매핑용 매개 테이블 설계 패턴: [[pvs-crawler-ccr-gerrit-mapping]]

[^pvs_crawler]

[^pvs_crawler]: `pvs_crawler` 프로젝트(`/home/cheoljoo.lee/code/pvs_crawler`)의 `sage_llm_summary.py`,
  `sage-check-status.py`, `sage-check-llm-answer.py`, `sage_check_status.sh` 세션들에서 정리.

[^pvs_crawler2]: `pvs_crawler` 프로젝트 세션에서 ECHO 유사도 판정 + 결정적 prefix-strip 복구
  (`709cfdd6` 커밋)를 설계·구현하며 정리.

[^pvs_crawler3]: `pvs_crawler` 프로젝트 세션에서 `sage-check-llm-answer.py`의 `ensure_models` stale
  snapdate 사각지대를 발견·수정하며 정리.

[^hermes]: `hermes` 프로젝트에서 `/wiki-log` 실행으로 Jira catch-up 하며 정리한, pvs_crawler/ticketsage
  쪽 이슈(`AGILEDEV-1059`, `AGILEDEV-1056`)에서 얻은 트러블슈팅·설계 노하우.
