---
start_time: 2026-07-13 10:16:27
end_time: 2026-07-13 15:25:20
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [teams-webhook, bash, uv, venv, pipenv, loop-count, count-only, sage, shell-script]
digested: true
---

# Teams Webhook 알림 + uv venv 분리 + 루프 수 자동 계산

## Teams Incoming Webhook 통합 (bash shell scripts)

- `send_teams_message()` 함수: `curl`로 MessageCard JSON을 POST
- **핵심 버그**: bash 큰따옴표 안의 `\n`은 실제 줄바꿈이 아니라 literal `\n` 두 글자 → Teams에 `\n`이 그대로 출력됨
- **해결**: `"$(printf 'line1\nline2')"` 로 실제 줄바꿈 생성
- TAIL_LOG(`tail -n 50 "${LOGFILE}"`)은 실제 줄바꿈이 포함되어 있어 별도 처리 불필요

## bash syntax error: 편집기 자동 줄바꿈으로 인한 `$()` 파싱 오류

- **현상**: `line 86: syntax error near unexpected token ')'`
- **원인**: 에디터가 긴 라인을 자동 줄바꿈 → `grep -oP '(?<=TAG] )\d+'` 의 `(?`가 두 줄로 분리됨
  - bash는 `$()` 내부에서 싱글쿼트 안의 `(` 도 괄호 깊이 카운팅 → 잘못된 위치의 `)` 로 오류
- **해결**: lookbehind regex 제거, `awk '{print $NF}'` 로 대체 (괄호 없음)
- **교훈**: `$()` 안에서 싱글쿼트 내 `(` `)`가 있는 패턴은 라인이 길어지면 위험; `awk`/`sed` 로 우회

## `--count-only` 플래그 추가 (sage-check-llm-answer.py)

- 루프 시작 전 처리 대상 row 수를 조회해 `TOTAL_LOOPS = ceil(rows / CHUNK_SIZE)` 계산
- 고유 태그 `[COUNT_ONLY_RESULT] <숫자>` stdout 출력 + `[COUNT_ONLY_SQL]` SQL은 stderr 출력
  - shell에서: `grep '\[COUNT_ONLY_RESULT\]' | awk '{print $NF}'` 로 안전하게 파싱
- `SELECT COUNT(*) FROM (...) AS _count_t` — 기존 `build_sql_fetch()` 결과에서 `\nLIMIT` 이후만 제거
- `while true` → `while [ LOOP_COUNT -lt TOTAL_LOOPS ]` 로 변경; "소진 감지" → 조기 `break`

## uv `.venv` 생성 방지 (pipenv 충돌 해결)

- **문제**: `uv run` 이 프로젝트 내 `.venv` 생성 → pipenv가 해당 경로로 매핑됨
- **해결**: `export UV_PROJECT_ENVIRONMENT="${HOME}/.local/share/uv/envs/pvs_crawler"`
  - 11개 `.sh` 파일 모두에 `export PATH` 다음 줄에 추가
- **주의**: 해당 경로에 venv가 없으면 `uv run python -c "import sys; print(sys.prefix)"` 가 base Python 반환
  - 최초 1회 `uv sync` 필요
- `uv venv --show-path` 는 존재하지 않는 옵션 → `uv run python -c "import sys; print(sys.prefix)"` 사용

## sage_check_status.sh 신규 생성

- `SLEEP_HOURS`(기본 10h) 간격으로 `sage-check-status.py` 반복 실행
- `MAX_LOOPS`(기본 10)번 수행 후 자동 종료
- Teams 알림: 루프 시작(`🚀`), 종료(`✅` + 로그 끝 50줄), 비정상 종료(`❌`), 전체 완료(`🏁`)
