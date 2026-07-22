---
start_time: 2026-07-17 15:48:26
end_time: 2026-07-18 10:33:02
who: cheoljoo.lee
project: hermes
source_repo: /data01/cheoljoo.lee/code/hermes
branch: main
tags: [jira-catchup, ccr, echo-detection, llm-validation, gerrit, troubleshooting]
digested: true
---

# Jira/Confluence catch-up (2026-07-10 ~ 2026-07-17 갱신분)

이번 세션은 `/wiki-log` 실행 자체였고 hermes 리포지토리에서 별도 코드 작업은 없었음. 대신 지난 `/wiki-log` 실행(2026-07-10) 이후 갱신된 Jira 이슈 12건과 Confluence 페이지 변경분을 정리.

## Jira 업데이트

### 재사용 가치가 있는 설계 결정 / 트러블슈팅

- **AGILEDEV-1061 (QCD_DL_ISSUE_COMMIT_LLM CCR ticket 불일치, Resolved)**
  겉보기엔 "CCR 티켓의 Gerrit Link"와 DB에 저장된 `COMMIT_FINAL_URL`이 서로 다른 링크처럼 보이지만, 실제로는 데이터 오류가 아니라 설계된 정규화 정책 때문이었음. Gerrit 링크는 c-type(패치셋까지 특정)과 q-type(change-id 기반) 두 종류가 있고, 하나의 change_id+repo 그룹 안에 merge된 patchset이 여러 개 있을 수 있음. 대표값 선택 규칙: **change_id + repo가 같으면 동일 커밋으로 취급하고, 그중 "merged 상태이며 created가 가장 이른 것"을 대표로 선택** (cherry-pick 이전의 최초 문제 해결 지점을 기준으로 삼기 위함). 여러 개의 관련 리비전/패치셋 중 대표값을 뽑아야 하는 상황에서 재사용 가능한 패턴.

- **AGILEDEV-1059 (getPmsExcel.py 크래시, Return code 3221225477, Windows)**
  torch(easyocr)와 numpy/opencv가 서로 다른 OpenMP 런타임을 로드하며 충돌하는 것으로 추정해 `KMP_DUPLICATE_LIB_OK=TRUE`를 설정했으나 재현이 계속됨. **실제 해결책은 코드가 아니라 Windows 재부팅**이었음 — 오래 켜둔 Windows 환경에서 누적된 메모리/리소스 문제가 원인. 재현이 잘 안 되는 access violation(0xC0000005)류 크래시는 코드보다 "장시간 미재부팅 환경"을 먼저 의심할 가치가 있음.

- **AGILEDEV-1056 (Connectwide commit/CCR 데이터 수집, Resolved)**
  CCR readiness 분석 초기에는 Gerrit branch까지 고려하려 했으나, 실제 데이터를 까보니 CCR의 "Gerrit Link"는 거의 100%가 c-type이라 branch는 사실상 항상 1개뿐이라 의미가 없었음. 분석 설계 전에 실제 데이터 분포를 먼저 표본 확인하면 불필요한 복잡도(불필요한 차원)를 걷어낼 수 있다는 교훈.

- **AGILEDEV-1051 ([ticketsage][VDA] gerrit에 CCR list 추가, Resolved)**
  처음엔 "CCR → DL_CLOSED DB"로 역방향 조회를 시도했으나 방향이 잘못됐음을 깨닫고, "DL_CLOSED DB에 새로 추가되는 것 기준으로 CCR을 검색"하는 방향으로 재설계. 이를 위해 매개 테이블 `QCD_CCR_GERRIT`(Gerrit URL ↔ CCR ISSUE_ID 매핑, 27,794건)를 신설하고, 이후 `sage-commit-ccr.py`가 이 매개 테이블만 읽도록 일원화하여 Gerrit REST API 재호출 로직을 완전히 제거함 — 코드가 크게 단순해지고 두 경로 간 COMMIT_URL 포맷 불일치로 인한 매칭 누락도 해소됨. **두 시스템 간 다대다 매핑은 직접 조인하지 말고 사전 계산된 매개 테이블을 두는 것이 유지보수성과 일관성 면에서 유리**하다는 재사용 가능한 설계 패턴.

- **AGILEDEV-1044 / 1043 (commit LLM 요약 품질 검증·복구, Resolved)**
  LLM 응답 검증(`sage-check-llm-answer.py` 계열)에서 발견한 두 가지 버그성 함정:
  1. "키가 없으면 빈 문자열로 채우는" fallback 로직이 있었는데, 이게 **진짜 누락(missing)을 "정상"으로 위장**시키고 있었음 → fallback 제거.
  2. ECHO(LLM이 프롬프트 지시문을 그대로 베껴 답한 경우) 감지 시 값을 통째로 교체하던 방식을, `error:ECHO` 접두어만 붙이는 방식으로 바꿔 원문을 보존하도록 개선 (디버깅 시 원문을 다시 볼 수 있게).

- **AGILEDEV-1053 (LLM_SUMMARY prompt version 최신화 + ECHO 처리, In Progress — 이번 갱신구간 중 가장 비중 큰 작업)**
  - exaone 여러 API key로 처리량을 최적화하는 중. 정기 크롤러(`--crawler` 옵션, 하루 중 특정 시간대에만 짧게 동작)와 상시 백필 작업이 같은 key pool을 나눠 쓰면서 발생하는 낭비를 어떻게 배분할지 논의 중.
  - **ECHO 판정을 "고정 마커 문자열 매칭"에서 "prompt 지시문과의 문자열 유사도(difflib, threshold 0.80)" 기반으로 확장.** 배경: 마커 매칭만으로는 지시문을 어순만 바꿔 베낀 경우를 못 잡았고, 반대로 마커 `"write in english"`는 정상적으로 번역만 한 응답과도 우연히 매칭되어 오탐이 발생함(실제 프로덕션 데이터로 확인) → 이 마커는 제거.
  - 유사도로 잡힌 사례들을 실제로 까보니 상당수가 "지시문을 거의 그대로 베끼고 끝부분만 실제 답으로 바꿔치기"한 패턴 → 이런 경우는 LLM을 다시 부르지 않고 **문자열 처리(prefix-strip)만으로 결정적으로 복구**하는 함수(`try_strip_echoed_instruction_prefix`)를 추가해 비용을 줄임.
  - 마커 기반 신호(정확도 높음, 재질의 트리거로 계속 사용)와 유사도 기반 신호(오탐 위험 있음, 참고용/결정적 복구 트리거로만 사용)를 **컬럼과 실행 모드(`--solve-problems` vs `--solve-problems-all`)를 분리**해서 섞이지 않게 관리. LLM 응답 검증에서 정확 매칭과 퍼지 매칭을 함께 쓸 때 재사용할 만한 설계.

### 그 외 갱신된 이슈 (요약)

- **AGILEDEV-1048** (worklog 분석 + backstage 설계도, Resolved): Backstage를 업무 허브로 삼아 전체를 추적하는 방식은 비추천(사람의 입력 행동에 의존, 실측 격차가 큼). Template 기반 작업만 시간 추적하고 나머지는 사후 집계하는 방식을 추천. worklog 관련 결론은 결국 `/wiki-log` (llm_wiki repo)로 흡수됨.
- **AGILEDEV-1060** (hermes 사용 해보기, In Progress): hermes docker 설치/실행 확인. Schedule 기능이 초기엔 timezone 문제였으나 정상 동작 확인됨. kanban UI: `http://localhost:9119/kanban`.
- **AGILEDEV-1057** (LLM Wiki, In Progress): collab 페이지 또는 git repo에 설명 문서 작성 예정(발표용).
- **AGILEDEV-1054** (LLM_SUMMARY 빈 값 채우기, Resolved): `--user-defined-sql` 옵션으로 `LLM_SUMMARY IS NULL` 조건 대상만 골라 처리.
- **AGILEDEV-1063** (다른 project의 prompt 참조, In Progress): 사내 타 프로젝트/에이전트(waydroid 디버그 세션 문서 포맷, alice, ada, DCV, Claude Code 관련 자료 등) 참조 링크 수집 중 — 디버깅 세션 기록 방식이나 prompt 구조를 벤치마킹하려는 목적으로 보임.

## Confluence 업데이트

- **[W29주차] 주간업무보고_2026.07.16** (space: SWDEVDIV, 최종 수정: 2026-07-15 17:38, 원저자: 이상재 sangjae0.lee, 사용자는 contributor로 편집 참여)
  조직 전체 주간보고 문서라 다수가 공동 편집. 사용자가 관여한 것으로 보이는 부분은 "Ticket sage LLM data를 VDA의 데이터에 추가" 섹션 — AGILEDEV-1053 작업 내용과 일치: exaone 7개 API key로 하루 5~6만 건 처리, 59만 건 중 57만 건 완료, 최대 10일 이내 완료 예정. 그 외 섹션(Defect AI Agent 알림 확대, HexaChat AI Chat 개발, VOC 정리 등)은 타 팀원 작업분. 댓글 없음.
