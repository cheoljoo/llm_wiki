---
start_time: 2026-07-21 16:10:49
end_time: 2026-07-21 16:23:33
who: charles.lee
project: ai_resource_management
source_repo: /home/cheoljoo.lee/code/ai_resource_management
branch: main
tags: [herdr, multi-agent, gemini, agy, code-review-pingpong, resource-management-doc]
digested: true
---

# herdr로 두 CLI 에이전트(Claude/Gemini)를 같은 문서에 대해 핑퐁 리뷰시키기

## 배경

`resource_mgmt.md`(AI 기반 인적 자원 관리 방안 문서)가 이미 같은 디렉터리에서 실행 중인 Gemini CLI("agy", Antigravity CLI)에 의해 작성되어 있었고, 사용자가 "서로 pingpong하며 문서를 개선하라"고 요청함. 즉 한 명의 에이전트가 리뷰하고 다른 에이전트가 반영하는 과정을 반복하는 협업을 오케스트레이션해야 했음.

## 핵심 방법: herdr CLI로 다른 터미널의 에이전트를 원격 조작

이 환경은 `herdr`(터미널 워크스페이스 매니저)를 사용 중이며, 같은 워크스페이스 안의 다른 pane에서 실행 중인 에이전트를 다음 커맨드들로 제어할 수 있었다:

- `herdr agent list` — 현재 워크스페이스의 모든 에이전트(pane_id, agent 이름, cwd, agent_status)를 나열. 같은 디렉터리(cwd)에서 실행 중인 `agy`(Gemini) 인스턴스를 이걸로 찾음.
- `herdr agent read <pane_id> --lines N` — 해당 pane의 최근 터미널 출력을 텍스트로 읽음. **주의**: `--lines`가 작으면 긴 응답이 중간에 잘려 보일 수 있어, 응답을 확인할 때는 넉넉히(150~250) 주거나 필요시 재호출해야 함.
- `herdr agent send <pane_id> "<text>"` — 대상 pane에 리터럴 텍스트를 입력(Enter는 안 눌림).
- `herdr pane send-keys <pane_id> Enter` — 실제로 제출(Enter)하려면 `agent send` 뒤에 반드시 별도로 호출해야 함. (agent send만으로는 입력창에 텍스트만 채워지고 전송되지 않음)
- `herdr agent wait <pane_id> --status idle --timeout <ms>` — 상대 에이전트가 응답을 끝낼 때까지 블로킹 대기. 그러나 **Gemini CLI가 파일 쓰기 권한을 요청하는 "Allow creation of this file? [Yes/No]" 프롬프트를 띄우면 `agent_status`가 idle로 보고되면서도 실제로는 사용자 입력을 기다리는 중**이라, wait만으로는 완료를 보장 못 함 — 매번 `agent read`로 실제 화면 내용(프롬프트 여부)을 확인해야 했음.

## 트러블슈팅: "idle인데 사실은 멈춰있음" 문제

`herdr agent wait ... --status idle`이 즉시 리턴되는데 실제로는 상대가 파일 쓰기 승인(Yes/No) 대기 중이거나 "Loading...", "Working..." 표시가 남아있는 경우가 있었다. 해결 패턴:
1. wait 리턴 후 반드시 `agent read`로 화면 꼬리를 읽어 "Allow creation of this file?" 같은 확인 프롬프트가 있는지 확인.
2. 있으면 `herdr pane send-keys <pane_id> Enter`로 기본 옵션(Yes)을 승인.
3. 다시 `agent wait --status idle`로 실제 작업 완료까지 대기.
이 3단계를 매 라운드 반복해야 안전했다.

## 협업 프로토콜 설계

한 번에 여러 지적을 모아(3~4개) 보내고, 상대가 전부 수용/반영한 결과를 실제 파일(Read 툴)로 직접 검증한 뒤 다음 라운드로 넘어가는 방식이 효율적이었다. 상대의 채팅 요약만 믿지 않고 매 라운드 `resource_mgmt.md` 파일을 직접 Read해서 실제 반영 여부(신설 섹션 번호, 표현 수정 등)를 확인함 — 채팅 로그의 자기 보고와 실제 파일 diff가 다를 수 있음을 전제로 검증하는 게 중요.

2라운드로 수렴: 1라운드(법적/컴플라이언스 섹션 부재, LLM 태깅 엔진 입출력 불명확, 소스코드 클라우드 유출 리스크) → 2라운드(낮은 confidence_score 처리/HITL 큐, 거버넌스·이의제기 절차, 데이터 보존기간 구체화, 오탈자) 순으로 지적하고 모두 반영 확인 후 종료.

## Jira 업데이트

- **AGILEDEV-1057 (LLM Wiki, In Progress)**: `07-20 14:21`에 코멘트 추가 — Guide 링크(`https://github.com/cheoljoo/llm_wiki/blob/main/README.md`) 공유.
- **AGILEDEV-1053 ([pvs_crawler][VDA][sage] LLM_SUMMARY prompt version 갱신, Resolved)**: `07-20 15:33`에 코멘트 추가 — sage_llm_summary.v1.002.prompt 처리 현황 요약 테이블(타입 불일치/ECHO 포함 모두 0건으로 안정화됨을 확인하는 정기 상태 로그). 직전 `07-17` 코멘트에서 ECHO 판정에 "마커 매칭" 외에 "prompt 지시문과의 문자열 유사도(difflib, 임계값 0.80)" 기반 판정을 추가하고, 유사도로만 걸린 경우 LLM 재질의 없이 결정적 prefix-strip으로 복구하는 `--solve-problems-all` 옵션을 신설한 이력이 있음 — ECHO 오탐(예: "write in english" 마커가 정상 번역과 우연히 매칭)을 줄이기 위한 설계였음.
- **AGILEDEV-1063 (다른 project의 prompt 참조, In Progress)**: 새 코멘트 없음(마지막 코멘트는 `07-15`), `updated`만 갱신됨.
- **AGILEDEV-1060 (hermes 사용 해보기, In Progress)**: `07-20 17:22`에 코멘트 추가 — Telegram 봇(`t.me/Hermes_charles_two_bot`)에 exaone/gemma4 free 모델을 붙여 무료로 사용 가능하게 만듦, pairing code 공유 후 관리자 승인 필요. 직전 `07-20 14:20` 코멘트에서 Guide(`https://github.com/cheoljoo/hermes/blob/main/guide.md`) 작성 완료.

## Confluence 업데이트

- 조회된 2개 페이지("Honda SVN(JIRA) ID 요청 건.", "6.2 Request an authority of vBee/vgit/vOpenGrok...")는 저자/코멘트 작성자가 모두 다른 사람들이고 cheoljoo.lee와의 연관성이 확인되지 않음 — 내용 없음으로 판단, 기록에서 제외. (CQL의 `contributor = currentUser()`가 예상과 다른 결과를 반환할 수 있다는 점 참고용으로 남김)
