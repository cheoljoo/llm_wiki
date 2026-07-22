# CCR ↔ Gerrit 연결: 다대다 매핑은 매개 테이블로, 대표값은 명시적 규칙으로

CCR(고객 요청/이슈 티켓 시스템)과 Gerrit(코드리뷰) 사이를 연결하는 여러 이슈(`AGILEDEV-1051`,
`AGILEDEV-1056`, `AGILEDEV-1061`)에서 반복적으로 확인된 설계 패턴.

## 두 시스템 간 다대다 매핑은 직접 조인하지 말고 매개 테이블을 둔다

처음 설계는 "CCR → DL_CLOSED DB"로 역방향 조회를 시도했으나 방향이 잘못됐음을 깨닫고, "DL_CLOSED DB에
새로 추가되는 것 기준으로 CCR을 검색"하는 방향으로 재설계했다. 이를 위해 매개 테이블
`QCD_CCR_GERRIT`(Gerrit URL ↔ CCR ISSUE_ID 매핑, 27,794건)을 신설하고, 이후 `sage-commit-ccr.py`가 이
매개 테이블만 읽도록 일원화해 Gerrit REST API 재호출 로직을 완전히 제거했다 — 코드가 크게 단순해지고,
두 경로 간 `COMMIT_URL` 포맷 불일치로 인한 매칭 누락 문제도 함께 해소됐다.

**일반화된 패턴**: 두 시스템 간 다대다 매핑을 직접 조인/API 재호출로 매번 계산하지 말고, 사전 계산된
매개 테이블을 두는 것이 유지보수성과 일관성 면에서 유리하다.

## 대표값 선택 규칙: change_id + repo 기준, "merged 중 가장 이른 것"

CCR 티켓의 "Gerrit Link"와 DB에 저장된 `COMMIT_FINAL_URL`이 서로 다른 링크처럼 보이는 경우가 있었는데,
데이터 오류가 아니라 설계된 정규화 정책 때문이었다. Gerrit 링크는 c-type(패치셋까지 특정)과
q-type(change-id 기반) 두 종류가 있고, 하나의 change_id+repo 그룹 안에 merge된 patchset이 여러 개 있을
수 있다. 대표값 선택 규칙: **change_id + repo가 같으면 동일 커밋으로 취급하고, 그중 "merged 상태이며
created가 가장 이른 것"을 대표로 선택**한다(cherry-pick 이전의 최초 문제 해결 지점을 기준으로 삼기
위함).

**일반화된 패턴**: 여러 개의 관련 리비전/패치셋 중 대표값을 뽑아야 하는 상황에서, "가장 이른 것"처럼
명시적이고 재현 가능한 규칙을 정해두면 이후 재계산·검증이 쉬워진다.

## branch 필드는 실제 데이터 분포부터 확인하고 설계에 넣을 것

CCR readiness 분석 초기에는 Gerrit branch까지 고려하려 했으나, 실제 데이터를 까보니 CCR의 "Gerrit
Link"는 거의 100%가 c-type이라 branch는 사실상 항상 1개뿐이라 의미가 없었다. 분석/설계 전에 실제 데이터
분포를 먼저 표본 확인하면 불필요한 차원(복잡도)을 걷어낼 수 있다.

[[pvs-crawler-sage-llm-pipeline]]

[^hermes]

[^hermes]: `hermes` 프로젝트에서 `/wiki-log`로 Jira catch-up(`AGILEDEV-1051`, `AGILEDEV-1056`,
  `AGILEDEV-1061`)을 정리하며 확인한 내용. 실제 코드(`sage-commit-ccr.py`,
  `sage-ccr-connectwide.py`, `qcd_dl_issue_commit_llm_gerrit_info_check.py`)는 pvs_crawler/ticketsage
  쪽 스크립트로 보인다.
