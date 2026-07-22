---
start_time: 2026-07-22 09:10:40
end_time: 2026-07-22 09:53:35
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [sage, llm_summary, exaone, ensure-models, jira-sync, mcp-atlassian]
digested: false
---

# sage-check-llm-answer.py: ensure_models에 "존재하지만 오래된(stale)" 모델도 재처리하도록 확장

## 배경 / 문제 발견 과정

`make_llm_summary.sh`의 `[A.1]`(gpt-4o-mini 기본 처리)과 `[B.2]`
(`sage-check-llm-answer.py --ensure-models exaone`, exaone 보정/보강) 두 단계로
구성된 파이프라인에서, 사용자가 실제 로그(`sage-llm.crawler.log`)를 보고
"[A.1]에서 hash변경으로 gpt-4o-mini만 재처리된 기존 레코드들 안에 있던 exaone
결과가 이후 [B.2]에서 누락 없이 잘 처리되는가?"를 질문한 것이 출발점.

먼저 코드(`sage_llm_summary.py`의 `_save_results()`)와 실제 로그를 대조해서
"기존 exaone 결과가 gpt-4o-mini UPDATE 때 유실/null화 되지는 않는다"는 것부터
확인함 — `"llm": {**existing_llm_base, **model_results}` 형태의 병합 로직이라
기존 모델 키는 보존된다. 실제 로그에서도
`llm_snapdate={'exaone': '2026-07-08', 'gpt-4o-mini': '2026-07-22'}` 처럼
exaone 값이 그대로 남아있는 사례를 확인.

그런데 여기서 진짜 문제가 드러남: exaone 값은 **유실되지 않지만, 갱신되지도
않는다**. `[B.2]`(`sage-check-llm-answer.py`)의 `--ensure-models` 로직은
"해당 모델이 LLM_SUMMARY에 아예 없는 경우(`missing_model`)"만 재생성 대상으로
잡고 있어서, "모델 키는 있지만 그 값이 티켓 내용이 바뀌기 전의 옛 snapdate
그대로인" 케이스는 영원히 재처리되지 않는 사각지대였다.

## 해결

`sage-check-llm-answer.py`의 `process_chunk()` 내 `ensure_models` 판정
블록(`ensure_model not in row_models_present`만 보던 곳)에 분기를 추가:

- `ensure_model`이 존재하더라도, 같은 티켓의 `llm_summary["snapdate"]` 안에서
  다른 모델의 snapdate보다 오래된 경우 `stale_model_snapdate`라는 새 reason으로
  `regenerate_candidates`에 포함.
- 비교할 다른 모델의 snapdate가 없거나(단일 모델만 존재), 이미 최신이면 skip.
- 이 새 reason을 `--dry-run` 출력 필터와, 실제 재생성을 트리거하는
  `ensure_model_issue_id_to_models` 수집 로직 두 곳에 모두 `missing_model`과
  동일하게 포함시켜야 실제로 `run_sage_llm_summary()` 재호출까지 이어짐(하나만
  고치면 dry-run 목록에는 보이는데 실행은 안 되는 식으로 조용히 반쪽짜리가 됨).

## 배운 점 / 재사용 포인트

1. **"모델 결과가 있다" ≠ "모델 결과가 최신이다"** — merge 기반으로 여러 모델
   결과를 누적 저장하는 구조에서는 "존재 여부"만으로 재처리 필요성을 판단하면
   부분 업데이트(A 모델만 갱신되고 B 모델은 방치)가 영구히 고착되는 사각지대가
   생긴다. per-model timestamp(snapdate)를 함께 저장해두면 이런 staleness를
   사후에 감지할 수 있다는 게 이번 케이스의 핵심 설계 포인트.
2. 이런 파이프라인 버그는 "코드만 읽어서는" 확신하기 어렵고, 실제 운영 로그의
   구체적 수치(`llm_snapdate={...}`)를 코드 흐름과 나란히 대조해야 확실히
   검증된다 — 코드상 "합리적으로 보이는" 병합 로직도 실제 데이터에서 어떤
   부작용을 남기는지 로그로 재확인하는 습관이 유효했다.
3. 파이프라인 하위 단계(`run-regenerate-llm`)로 실제 재처리를 강제하려면
   `issue_ids`를 명시적으로 넘겨야 hash/기존 모델 보유 여부와 무관하게 강제
   재처리된다는 것도 코드 추적으로 확인(`self.force_rerun or self.issue_ids`
   분기). 이 메커니즘 덕분에 sage-check-llm-answer.py 쪽 감지 로직만 고치면
   되고 sage_llm_summary.py의 skip 판단 로직은 건드릴 필요가 없었음 — 사각지대
   수정 시 "가장 좁은 지점"에서 고치는 게 안전하다는 사례.
4. 실제 프로덕션 옵션 그대로(`--run-regenerate-llm --ensure-models exaone`,
   실제 exaone API 호출 + DB 갱신 발생)를 돌리기 전에는 반드시 사용자에게
   "이건 실제 비용/DB 변경이 따른다"는 것을 명확히 알리고 확인받은 뒤 진행함
   (AskUserQuestion 사용) — dry-run이 있는 스크립트라도 `--help`의 문구
   ("DB 변경 없음")를 그대로 믿지 말고 실제 코드(`dry_run=` 인자 전달 여부)로
   확인해야 한다는 것도 이번에 재확인(이 스크립트의 `--run-regenerate-llm`
   help 문구는 실제 동작과 다르게 오래된 상태였음).

## Jira 업데이트

- **AGILEDEV-1053** — `[pvs_crawler][VDA][sage] LLM_SUMMARY 를 prompt version이
  v1.002 보다 적은 경우 최신 version으로 update하기 (한글 / 영어 문제) + ECHO 처리`
  (Resolved). 이번 세션에서 작성한 `stale_model_snapdate` 커밋 메시지 초안이 이
  이슈에 댓글로 추가됨(배경/변경사항/검증 내용 — 위 "해결" 절과 동일 내용).
  같은 이슈에 지난 `/wiki-log` 이후로 다음 댓글들도 추가되어 있었음(모두 과거
  작업의 진행 로그성 댓글):
  - 2026-07-14: `sage-check-status.py` 실행 결과 요약 테이블 2건(prompt 버전별
    처리 통계, exaone/gpt-4o-mini 타입 불일치 집계).
  - 2026-07-17: `709cfdd6` 커밋(ECHO 유사도 판정 추가) 커밋 메시지 전문 + 실행
    결과 스크린샷 2장.
  - 2026-07-20: `sage-check-status.py` 실행 결과 요약 테이블 1건(신규 불일치 없음
    확인).
- **AGILEDEV-1057** — `LLM Wiki` (In Progress). 본인이 하는 작업 기준으로 LLM
  wiki(이 llm_wiki 저장소)를 만드는 상위 이슈. 지난 확인 이후 갱신은 없었고
  단순 조회 시점 갱신(`updated` 필드만 최신화됨, 새 댓글 없음).

## Git 활동

- 감시 대상 저장소(`llm_wiki`, `hermes`, `pvs_crawler`, `misc`, `ccr`) 모두 지난
  확인 시각(2026-07-21 18:42:23) 이후 새 커밋 없음 — 이번 세션에서 만든
  `sage-check-llm-answer.py`/`mm.md` 변경은 아직 로컬 working tree에만 있고
  커밋되지 않은 상태.
