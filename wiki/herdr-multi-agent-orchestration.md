# herdr로 다른 터미널의 CLI 에이전트를 원격 조작해 핑퐁 리뷰시키기

`herdr`(터미널 워크스페이스 매니저) 환경에서, 같은 워크스페이스의 다른 pane에서 실행 중인 CLI
에이전트(예: Gemini CLI "agy"/Antigravity CLI)를 원격으로 조작해 두 에이전트가 같은 문서를 번갈아
리뷰·수정하는 협업(핑퐁 리뷰)을 오케스트레이션한 사례.

## 핵심 커맨드

- `herdr agent list` — 워크스페이스의 모든 에이전트(pane_id, agent 이름, cwd, agent_status) 나열. 같은
  cwd에서 실행 중인 상대 에이전트를 이걸로 찾는다.
- `herdr agent read <pane_id> --lines N` — 해당 pane의 최근 터미널 출력을 읽는다. `--lines`가 작으면
  긴 응답이 잘려 보이므로 넉넉히(150~250) 주거나 필요시 재호출할 것.
- `herdr agent send <pane_id> "<text>"` — 대상 pane에 텍스트를 입력만 한다(Enter는 안 눌림).
- `herdr pane send-keys <pane_id> Enter` — 실제 제출은 `agent send` 뒤에 반드시 별도로 호출해야 한다.
- `herdr agent wait <pane_id> --status idle --timeout <ms>` — 상대가 응답을 끝낼 때까지 블로킹 대기.

## 함정: "idle인데 사실은 멈춰있음"

`agent wait --status idle`이 즉시 리턴되는데 실제로는 상대가 파일 쓰기 승인("Allow creation of this
file? [Yes/No]") 같은 확인 프롬프트 대기 중이거나 "Loading...", "Working..." 표시가 남아있는 경우가
있다. `agent_status`는 idle로 보고되지만 실제로는 사용자 입력을 기다리는 중이라, wait만으로는 완료를
보장하지 못한다.

**해결 패턴** (매 라운드 반복):
1. `wait` 리턴 후 반드시 `agent read`로 화면 꼬리를 읽어 확인 프롬프트 여부를 확인한다.
2. 있으면 `herdr pane send-keys <pane_id> Enter`로 기본 옵션(Yes)을 승인한다.
3. 다시 `agent wait --status idle`로 실제 작업 완료까지 대기한다.

## 협업 프로토콜: 모아서 보내고, 파일로 직접 검증한다

한 번에 여러 지적(3~4개)을 모아 보내고, 상대가 전부 수용/반영했다고 응답한 뒤에는 **채팅 요약만 믿지
말고** 실제 파일을 Read 툴로 직접 열어 반영 여부(신설 섹션 번호, 표현 수정 등)를 확인한 뒤 다음
라운드로 넘어가는 방식이 효율적이었다 — 상대 에이전트의 자기 보고와 실제 파일 diff가 다를 수 있다는
전제로 검증하는 게 중요하다.

[^ai_resource_management]

[^ai_resource_management]: `ai_resource_management` 프로젝트에서 Claude(Claude Code)와 Gemini CLI(agy)가
  같은 `resource_mgmt.md` 문서를 2라운드에 걸쳐 핑퐁 리뷰하도록 오케스트레이션한 세션에서 정리.
