---
start_time: 2026-07-16 15:28:49
end_time: 2026-07-16 15:28:49
who: charles.lee
project: llm_wiki
source_repo: /home/cheoljoo.lee/code/llm_wiki
branch: main
tags: [claude-code, vscode, session-persistence, jira, confluence]
digested: true
---

# VSCode Claude Code 확장 세션 재개 동작 + Jira/Confluence 동기화

## VSCode 확장에서 세션 창이 비어 보이는 문제

VSCode를 닫았다 다시 열면 Claude Code 확장의 대화 창이 빈 새 세션처럼 보이는 경우가 있음.
이는 세션 기록이 사라진 것이 아니라, 확장이 이전 세션을 자동으로 다시 로드하지 않아서 생기는 현상.

- 실제 트랜스크립트는 `~/.claude/projects/<프로젝트-경로 인코딩>/`에 JSONL로 그대로 남아있음.
- 화면과 컨텍스트에 이어붙이려면 명시적으로 이전 세션을 resume해야 함 (`claude --continue` / `claude --resume`,
  또는 확장 UI의 세션 히스토리/"Resume session" 메뉴).
- 반면 `~/.claude/projects/<...>/memory/` 아래의 memory 파일들(사용자 프로필, feedback, project 컨텍스트 등)은
  새 세션 시작 시 항상 다시 로드되므로, 대화 세부 내용은 안 이어져도 memory에 저장해둔 내용은 이어짐.

## Jira 업데이트

지난 확인 시점 기록이 없어(최초 실행) 3일 전(2026-07-13 15:28)부터 조회. `assignee = currentUser()` 기준
10건 갱신 확인 (프로젝트: `pvs_crawler`, `ticketsage` 등 - 이 저장소와 무관하지만 새 변경사항이라 기록):

- **AGILEDEV-1060** (hermes 사용 해보기, In Progress): hermes docker 설치 후 schedule 정상 동작 확인
  (최초엔 timezone issue였음). 설치/실행/telegram 사용법은 별도 페이지로 문서화 예정.
  kanban 대시보드: `http://localhost:9119/kanban`.
- **AGILEDEV-1053** ([pvs_crawler][sage] LLM_SUMMARY prompt version 최신화, In Progress):
  daily 파이프라인에 최신 prompt version 반영 완료. 남은 작업은 구버전 prompt로 남은 레코드를 exaone으로
  일괄 재처리. 최신 상태 체크 결과 v1.002 prompt 기준 57만건 이상 처리 완료, 타입 불일치(list→dict 변환
  가능/불가) 케이스들을 등급(L1/L2)으로 나눠 CSV로 추출하는 방식으로 진행 중. exaone API key 분배 최적화
  (crawler 옵션 유무로 program1/program2 구분해 우선순위 조정) 논의 중.
- **AGILEDEV-1057** (LLM Wiki, In Progress): collab 위키 또는 git에 설명 페이지(발표용) 작성 예정 — 지금
  이 `llm_wiki` 저장소 자체가 그 결과물.
- **AGILEDEV-1063** (다른 project의 prompt 참조, In Progress): alice/waydroid/ada 등 사내 다른 프로젝트의
  prompt·문서 참고 링크 모음 (디버깅 세션 문서, Claude Code 관련 Notion 페이지, GitHub Copilot 교육자료 등).
- **AGILEDEV-1059** (getPmsExcel.py 종료코드 3221225477, Resolved): 원인은 두 가지 —
  (1) torch(easyocr)와 numpy/opencv가 서로 다른 OpenMP 런타임을 로드해 충돌 → `KMP_DUPLICATE_LIB_OK=TRUE`
  설정으로 완화 시도했으나 재발, (2) 최종 해결은 Windows notebook을 오래 켜둬서 쌓인 메모리 문제로,
  **재부팅**이 실질적 해결책이었음.
- **AGILEDEV-1056** (Connectwide commit/CCR 데이터 수집, Resolved): `QCD_DL_ISSUE_COMMIT_LLM.GERRIT_INFO`
  (MEDIUMTEXT) 크기 문제 없음을 확인(최대 2.88MB, MEDIUMTEXT의 17%). Gerrit URL 정규화(파이프 접미/커밋
  해시/패치셋 접미 제거) 후 2단계 fetch로 CCR과 commit을 연결하는 `sage-ccr-connectwide.py`,
  `qcd_dl_issue_commit_llm_gerrit_info_check.py` 신규 스크립트로 해결. branch 정보는 CCR의 "Gerrit Link"가
  거의 100% c-type이라 사실상 무의미함을 확인.
- **AGILEDEV-1051** ([ticketsage][VDA] gerrit에 CCR list 추가, Resolved): 최초 설계(COMMIT_URL 기준으로
  CCR 쪽에서 역참조)가 틀려서, CCR이 항상 먼저 생성된다는 점에 착안해 중간 매개 테이블
  `QCD_CCR_GERRIT`을 두는 방식으로 재설계. `sage-commit-ccr.py`가 이 매핑 테이블을 그대로 읽어
  `QCD_DL_ISSUE_COMMIT_LLM.CCR_COUNT/CCR_LIST`를 갱신하도록 일원화, 기존 Gerrit REST API 직접 호출/캐시/
  정규식 추출 로직을 걷어내 코드 단순화.
- **AGILEDEV-1044, 1043, 1054** (pvs_crawler/sage LLM summary 관련 3건, 모두 Resolved): 동일 시각
  (2026-07-15 09:06:43)에 일괄 갱신됨 — 내용상 새 코멘트 없이 상태/필드 재계산성 업데이트로 보임(내용 없음).

## Confluence 업데이트

지난 확인 시점 기록 없어 최근 페이지 중 이 계정이 기여한 것 확인:

- **[W29주차] 주간업무보고_2026.07.16 (목)** (space: SWDEVDIV, 최종수정 2026-07-15 17:38, 코멘트 없음):
  팀 주간보고 성격의 대용량 문서라 세부 통계는 생략하고 재사용 가치 있는 부분만 요약.
  - Defect AI Agent 신규 이슈 알림: 하루 10명 제한 시범 → 국내/LGEDV/LGSI 전체 대상으로 확대,
    평균 80명/일 발송. 유사 이슈 + 개발자 댓글 기반 해결 과정 자동 요약 제공.
  - Defect Agent VSCode 확장 "Smart Log Scan": Jira 접속 없이 신규 My Issue 티켓 로그를 자동
    다운로드/분석. 압축 포맷·차량 로그 포맷(DLT) 파싱 지원, 상용 모델 + 사내 EXAONE 모델 이원화 예정
    (비용/보안 절충). 현재 등록 863명, 로그 분석 1회당 150KB context, 상용 모델 5회/일 제한.
  - Defect Agent 관련 VOC 정리에서 반복 지적된 이슈: 도메인 지식/소스코드 컨텍스트 부족으로 인한 분석
    정확도 저하, 대용량 로그의 context length 초과 실패, 암호화/특정 로그 파일 처리 시 무한 대기,
    분석 대상 로그 파일 선정 기준 불명확 — 이런 유형의 "로그 분석 AI 에이전트"를 만들 때 흔히 부딪히는
    문제들이라 참고할 만함.
  - PVS 프로젝트: ticket sage LLM data v1.002 prompt로 전체 갱신 중(59만건 중 57만건 완료, exaone API
    key 7개로 하루 5~6만건 처리, 최대 10일 내 완료 예상) — [[AGILEDEV-1053]]과 동일 작업.
