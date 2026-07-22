# Herdr 플러그인 사용 가이드 (Herdr Plugins Guide)

이 문서는 Herdr에 설치된 5가지 플러그인의 상세 사용법, 활성화/비활성화 방법, 그리고 삭제(삭제/언링크) 방법을 다룹니다.

현재 설치 및 활성화된 플러그인 목록은 `herdr plugin list` 명령어로 확인할 수 있습니다.

---

## 1. 📂 herdr-file-viewer (`herdr-file-viewer`)
*Git과 연동되는 터미널 TUI 파일 뷰어 및 탐색기*

### 사용 방법
* **실행**:
  ```bash
  herdr plugin action invoke open-file-viewer --plugin herdr-file-viewer
  ```
  현재 활성화된 Pane 옆에 TUI 파일 탐색기 분할 창(Split pane)이 열립니다.
* **조작**:
  * 키보드 방향키 또는 마우스를 사용해 파일 트리를 탐색하고 선택할 수 있습니다.
  * Markdown 파일의 스타일 렌더링 및 소스 코드의 구문 강조(Syntax highlighting), Git 변경 사항(Diff)을 실시간으로 확인합니다.
* **단축키 바인딩 (선택 사항)**: `~/.config/herdr/config.toml` 내 `[keys]` 섹션에 아래 키바인딩을 추가하여 편리하게 열고 닫을 수 있습니다. `prefix+f`는 herdr 기본 액션과 충돌하지 않습니다.

  > **주의**: `ctrl+alt+f`처럼 Alt가 들어간 직접 단축키는 터미널 환경에 따라 동작하지 않을 수 있습니다.
  > 실제로 이 환경에서는 `herdr-client.log`에 `flushing lone escape after input timeout`
  > 경고가 반복적으로 남으며 인식이 안 됐습니다 — Alt chord(ESC + key)가 herdr의 입력 타임아웃 안에
  > 도착하지 못해 herdr가 이를 조합키가 아니라 단독 ESC로 처리했기 때문입니다. `prefix`(기본 `ctrl+b`)
  > 조합이 더 안정적입니다.

  ```toml
  [[keys.command]]
  key = "prefix+f"
  type = "plugin_action"
  command = "herdr-file-viewer.open-file-viewer"
  description = "TUI 파일 뷰어 열기"
  ```

### 켜기 / 끄기 (On/Off)
* **켜기**: 위 실행 명령이나 단축키를 통해 뷰어 Pane을 엽니다.
* **끄기**: 열려 있는 파일 뷰어 Pane에서 `q` 또는 `esc`를 누르거나, 해당 Pane을 닫습니다 (`prefix+x`).

### 삭제 방법
* 플러그인을 완전히 삭제하려면 아래 명령을 실행합니다:
  ```bash
  herdr plugin uninstall herdr-file-viewer
  ```

---

## 2. 🔍 reviewr (`persiyanov.reviewr`)
*AI 에이전트 코드 변경점(Diff) 리뷰 및 GitHub PR 연동 도구*

### 사용 방법
* **사이드바 열기 / 닫기**:
  * **열기**: `herdr plugin action invoke open --plugin persiyanov.reviewr`
  * **닫기**: `herdr plugin action invoke close --plugin persiyanov.reviewr`
  * **토글**: `herdr plugin action invoke toggle --plugin persiyanov.reviewr`
* **주요 기능**:
  * AI 에이전트가 코드를 수정하고 만든 Diff를 사이드바에서 시각적으로 확인합니다.
  * 변경 코드 라인에 직접 피드백 주석을 남기고 다시 에이전트에게 보내어 재수정을 요청할 수 있습니다.
  * GitHub PR의 상태, 체크 결과, 코멘트 등을 브라우저 없이 조회할 수 있습니다.

### 켜기 / 끄기 (On/Off)
* **토글 단축키 예시**: `config.toml`에 바인딩하여 간편하게 제어할 수 있습니다. **주의**: `prefix+r`은 herdr
  기본 액션인 `resize_mode`(pane 크기 조절 모드)에 이미 할당되어 있어 그대로 쓰면 충돌합니다. `ctrl+alt+r`
  같은 Alt 조합은 터미널에 따라 인식이 안 될 수 있으므로(위 file-viewer 절의 주의사항 참고), 이 환경에서는
  겹치지 않는 다른 prefix 조합인 `prefix+d`로 실제 적용되어 있습니다.
  ```toml
  [[keys.command]]
  key = "prefix+d"
  type = "plugin_action"
  command = "persiyanov.reviewr.toggle"
  description = "코드 리뷰 사이드바 토글"
  ```

### 트러블슈팅: prebuilt 바이너리가 GLIBC 버전 불일치로 실행 안 됨

`herdr plugin action invoke`로 호출해도 반응이 없거나 실패하면, `herdr plugin log list --plugin
persiyanov.reviewr --limit 3`으로 실제 stderr를 확인해볼 것. 이 환경에서는 다음 에러로 매번 실패하고
있었다:

```
herdr-reviewr: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.32' not found
(GLIBC_2.33/2.34/2.38/2.39도 동일하게 없음)
```

원인: `herdr plugin install`이 받아오는 prebuilt 릴리스 바이너리는 더 최신 glibc(2.32~2.39)에서 빌드돼
있는데, 이 시스템의 glibc는 `2.31`(Ubuntu 20.04)이라 실행 자체가 안 됐다. `ldd --version`으로 시스템
glibc 버전을 먼저 확인할 것.

**해결**: 로컬 체크아웃에서 직접 빌드해 시스템 glibc에 맞는 바이너리로 교체한다 (Rust 1.97 툴체인이
필요하며 `rustup`이 있으면 `rust-toolchain.toml`을 보고 자동으로 받는다):

```bash
cd /home/cheoljoo.lee/.gemini/antigravity-cli/brain/d149040d-0e12-499c-94a0-08893c8b16c0/scratch/herdr-reviewr
cargo build --release   # 의존성이 많아 처음엔 10분 이상 걸릴 수 있음
cp target/release/herdr-reviewr bin/herdr-reviewr
```

빌드 후 `ldd target/release/herdr-reviewr | grep libc`로 시스템 libc(`/lib/x86_64-linux-gnu/libc.so.6`)에
링크됐는지 확인하고, `herdr plugin action invoke toggle --plugin persiyanov.reviewr` 후 다시
`herdr plugin log list`로 `status: succeeded`인지 검증할 것.

### 삭제 방법
* 로컬 링크 해제 및 삭제:
  ```bash
  herdr plugin uninstall persiyanov.reviewr
  ```
  *(주의: 로컬 빌드로 GLIBC 문제를 우회한 상태라면, 위 클론 디렉터리
  `/home/cheoljoo.lee/.gemini/antigravity-cli/brain/d149040d-0e12-499c-94a0-08893c8b16c0/scratch/herdr-reviewr`의
  `bin/herdr-reviewr`가 실제로 실행되는 바이너리다. 삭제하면 다시 GLIBC 에러가 나는 prebuilt 버전으로
  되돌아가거나 아예 실행 안 되니, 플러그인을 완전히 삭제할 게 아니라면 지우지 말 것.)*

---

## 3. 💾 herdr-resurrect (`ntindle.herdr-resurrect`)
*Herdr 워크스페이스 구조 및 작업 상태 스냅샷 저장/복구*

### 사용 방법
* **현재 상태 저장 (스냅샷 생성)**:
  ```bash
  herdr plugin action invoke save --plugin ntindle.herdr-resurrect
  ```
* **저장된 스냅샷 목록 조회**:
  ```bash
  herdr plugin action invoke snapshots --plugin ntindle.herdr-resurrect
  ```
* **마지막 스냅샷으로 복구**:
  ```bash
  herdr plugin action invoke restore --plugin ntindle.herdr-resurrect
  ```
* **복구 미리보기 (Dry Run)**:
  ```bash
  herdr plugin action invoke restore-preview --plugin ntindle.herdr-resurrect
  ```
* **단축키 바인딩 (선택 사항)**: `save` 액션은 `~/.config/herdr/config.toml`에서 `prefix+u`로 바인딩되어
  실제로 적용되어 있습니다 (`herdr plugin action invoke save --plugin ntindle.herdr-resurrect` 실행 후
  `herdr plugin log list --plugin ntindle.herdr-resurrect --limit 3`으로 exit_code 0, status
  "succeeded" 확인 완료).

  ```toml
  [[keys.command]]
  key = "prefix+u"
  type = "plugin_action"
  command = "ntindle.herdr-resurrect.save"
  description = "herdr-resurrect: 현재 상태 스냅샷 저장"
  ```

### 켜기 / 끄기 (On/Off)
* **백그라운드 자동 저장 기능**: 플러그인이 로드되면 백그라운드 Pane(`autosave`)이 실행되어 주기적으로 세션을 자동 백업합니다.
* **임시 비활성화**: 자동 백업을 원치 않을 경우, `autosave` Pane을 닫거나 플러그인 설정 폴더(`/home/cheoljoo.lee/.config/herdr/plugins/config/ntindle.herdr-resurrect`)에서 자동 백업 간격 등을 변경하여 동작을 멈출 수 있습니다.

### 삭제 방법
* 플러그인을 완전히 삭제하려면 아래 명령을 실행합니다:
  ```bash
  herdr plugin uninstall ntindle.herdr-resurrect
  ```

---

## 4. 🚀 Spreader (`herdr-spreader`)
*YAML 선언적 파일을 사용한 워크스페이스 레이아웃 자동 부트스트래퍼*

### 사용 방법
* **레이아웃 파일 위치**: `herdr plugin action invoke apply`는 파일 경로를 인자로 받지 않습니다.
  다음 순서로 자동 탐색합니다: `$HERDR_PLUGIN_CONFIG_DIR/`(플러그인으로 실행 시 자동 지정,
  `herdr plugin config-dir herdr-spreader`로 확인 가능 — 이 환경에서는
  `~/.config/herdr/plugins/config/herdr-spreader/`) → `$XDG_CONFIG_HOME/herdr-spreader/` →
  `$HOME/.config/herdr-spreader/`. 각 위치에서 `config.yaml`, 없으면 `config.yml`을 찾습니다.
  **default로 자동 생성되는 레이아웃은 없으므로 직접 만들어 넣어야 합니다.**
* **실행**:
  ```bash
  herdr plugin action invoke apply --plugin herdr-spreader
  ```
* **레이아웃 예시** (`~/.config/herdr/plugins/config/herdr-spreader/config.yaml`, 이 환경에 실제 적용된
  2-pane 레이아웃 — `llm_wiki` 워크스페이스에 좌우로 분할된 pane 2개를 만듦):
  ```yaml
  workspaces:
    - name: llm_wiki
      root: ~/code/llm_wiki
      focus: true
      tabs:
        - label: main
          panes:
            - focus: true
            - split: right
              ratio: 0.5
  ```
  더 복잡한 예시(여러 workspace, 탭, `command`/`wait_for` 사용)는 플러그인 소스의
  `examples/config.yaml` 참고.
* **단축키 바인딩 (선택 사항)**: 위 config.yaml을 기본 레이아웃으로 실행하는 단축키가
  `~/.config/herdr/config.toml`에 `prefix+a`로 실제 적용되어 있습니다 (`herdr plugin action invoke
  apply --plugin herdr-spreader` 실행 후 `herdr plugin log list --plugin herdr-spreader --limit 2`로
  exit_code 0, status "succeeded" 확인 완료).
  ```toml
  [[keys.command]]
  key = "prefix+a"
  type = "plugin_action"
  command = "herdr-spreader.apply"
  description = "herdr-spreader: ~/.config/herdr/plugins/config/herdr-spreader/config.yaml 레이아웃 적용"
  ```

### 켜기 / 끄기 (On/Off)
* 이 플러그인은 백그라운드 상주형이 아닌 **단발성 실행(On-demand Action)** 도구입니다. 호출 시에만 작동하므로 켜고 끌 필요가 없습니다.

### 삭제 방법
* 플러그인을 완전히 삭제하려면 아래 명령을 실행합니다:
  ```bash
  herdr plugin uninstall herdr-spreader
  ```

---

## 5. 💸 llmtrim (`llmtrim.proxy`)
*AI 에이전트의 LLM API 토큰 및 요금 절감을 위한 프록시 연동*

> [!IMPORTANT]
> 이 플러그인을 사용하려면 시스템에 `llmtrim` 글로벌 CLI 패키지가 먼저 설치되어 있어야 합니다.
> 아래 명령어로 글로벌 설치 및 초기 설정을 마쳐주세요:
> ```bash
> npm install -g @llmtrim/cli@latest
> llmtrim setup
> ```

### 사용 방법
* **작동 방식**: 플러그인을 설치하면 새로운 워크스페이스나 에이전트 Pane이 생성될 때 자동으로 프록시 환경변수를 주입하고 백그라운드 프록시 서버를 경유하게 만듭니다.
* **참고**: `herdr-plugin.toml`에 `workspace.created` 이벤트 훅(`bin/bootstrap.sh`)이 등록돼 있어서,
  **새 workspace가 생성될 때마다** 라우팅을 세팅하고 최초 1회 "llmtrim - setup & disclosure"
  안내 pane을 자동으로 엽니다. `herdr-spreader`로 새 workspace를 만들 때처럼, 직접 부르지 않았는데도
  이 pane이 나타난다면 이 훅 때문이다 — 정상 동작이며 안내 pane은 `q`나 평소처럼 닫으면 된다.
* **실시간 대시보드 조회**:
  ```bash
  herdr plugin action invoke open-dashboard --plugin llmtrim.proxy
  ```
  절약된 토큰양과 비용이 표시되는 대시보드 화면이 분할 창에 로드됩니다.
  **단축키 바인딩 (선택 사항)**: `~/.config/herdr/config.toml`에 `prefix+m`으로 실제 적용되어 있습니다.
  ```toml
  [[keys.command]]
  key = "prefix+m"
  type = "plugin_action"
  command = "llmtrim.proxy.open-dashboard"
  description = "llmtrim: 실시간 절감 대시보드 열기"
  ```
* **절약 요약 리포트**:
  ```bash
  herdr plugin action invoke summary --plugin llmtrim.proxy
  ```
  **주의**: `open-dashboard`와 달리 pane을 열지 않습니다. `bin/summary.sh`가 herdr의
  `notification.show` RPC로 **일회성 토스트 알림**만 띄우는 구조라(`herdr notification show
  <title> --body ...`), 화면에 잠깐 떴다 사라질 뿐 터미널에 남는 출력이 없습니다. `herdr plugin log
  list --plugin llmtrim.proxy`로 `exit_code 0`/`status: succeeded`면 정상 실행된 것이니, 알림을
  못 봤다고 해서 실패한 게 아니다. `herdr notification`에는 이력 조회(`list`) 기능이 없어 사후 확인은
  불가능하다.

### 켜기 / 끄기 (On/Off)
* **프록시 서버 켜기 (Start)**: `llmtrim start`
* **프록시 서버 끄기 (Stop)**: `llmtrim stop`
* **특정 에이전트/터미널 Pane에서 우회(비활성화)하기**:
  특정 에이전트가 프록시 때문에 오작동을 하거나 무압축 상태로 API를 쏘고 싶을 경우, **해당 터미널 창**에서 환경 변수 설정을 일시적으로 해제합니다:
  ```bash
  unset HTTP_PROXY HTTPS_PROXY NODE_EXTRA_CA_CERTS
  ```

### 삭제 방법
* Herdr 플러그인 연동 해제:
  ```bash
  herdr plugin uninstall llmtrim.proxy
  ```
