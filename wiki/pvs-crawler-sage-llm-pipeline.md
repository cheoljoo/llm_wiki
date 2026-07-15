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

## 관련 문서

- bash `$()` 파싱 함정, printf 줄바꿈 함정, `uv`/`pipenv` venv 충돌: [[shell-cli-gotchas]]
- `preloaded_rows` 같은 "호출자가 이미 가진 데이터 재사용" 패턴 일반화: [[python-patterns]]
- VS Code Copilot에서 mcp-atlassian 연동(wiki-log용): [[mcp-atlassian]]

[^pvs_crawler]

[^pvs_crawler]: `pvs_crawler` 프로젝트(`/home/cheoljoo.lee/code/pvs_crawler`)의 `sage_llm_summary.py`,
  `sage-check-status.py`, `sage-check-llm-answer.py`, `sage_check_status.sh` 세션들에서 정리.
