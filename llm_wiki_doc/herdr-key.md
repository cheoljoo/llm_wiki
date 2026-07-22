# Herdr 단축키 정리 (Herdr Keybindings)

이 문서는 이 환경(`~/.config/herdr/config.toml`)에 실제로 설정된 herdr 단축키를 정리한다. 나중에
LLM에게 "이 문서를 보고 단축키를 이렇게 바꿔달라"고 요청할 때 참고 자료로 쓰기 위한 것.

## 기본 정보

- 설정 파일: `~/.config/herdr/config.toml`
- prefix 키: 기본값 `ctrl+b` (herdr 기본 설정, 이 환경에서 변경하지 않음)
- 수정 후 반영 절차:
  ```bash
  herdr config check              # 문법 검증
  herdr server reload-config      # 실행 중인 서버에 반영 (재시작 불필요)
  ```
- 이 환경은 `ctrl+alt+*` 같은 Alt 조합키(alt chord)가 herdr 입력 타임아웃 안에 도착하지 못해 인식되지
  않는다(`~/.config/herdr/herdr-client.log`에 `flushing lone escape after input timeout` 경고로 확인됨).
  **그래서 모든 커스텀 단축키를 `prefix+<letter>` 형태로만 구성했다.** 새 단축키를 추가할 때도 Alt
  조합은 피할 것.

## 커스텀 단축키 (herdr-plugins-guide 관련, 이 저장소에서 추가한 것)

`config.toml`의 `# >>> herdr-plugins-guide keybindings >>>` 마커 블록 안에 있다.

| 키 | 액션 | 설명 |
|---|---|---|
| `prefix+f` | `herdr-file-viewer.open-file-viewer` | TUI 파일 뷰어 열기 |
| `prefix+d` | `persiyanov.reviewr.toggle` | 코드 리뷰 사이드바(reviewr) 토글 |
| `prefix+u` | `ntindle.herdr-resurrect.save` | 현재 상태 스냅샷 저장 |
| `prefix+a` | `herdr-spreader.apply` | `~/.config/herdr/plugins/config/herdr-spreader/config.yaml` 레이아웃 적용 |
| `prefix+m` | `llmtrim.proxy.open-dashboard` | llmtrim 실시간 절감 대시보드 열기 |

## vim-herdr-navigation 단축키 (별도 스크립트로 관리, 건드리지 말 것)

`config.toml`의 `# >>> vim-herdr-navigation (managed by setup-herdr-vim-nav.sh) >>>` 마커 블록.
`scripts/setup-herdr-vim-nav.sh`가 관리하므로 이 문서의 herdr-plugins-guide 블록과는 별개로 취급한다.

| 키 | 액션 |
|---|---|
| `prefix+h` | `vim-herdr-navigation.left` |
| `prefix+j` | `vim-herdr-navigation.down` |
| `prefix+k` | `vim-herdr-navigation.up` |
| `prefix+l` | `vim-herdr-navigation.right` |
| `ctrl+left/down/up/right` | pane 포커스 이동 (`focus_pane_*`) |
| `ctrl+shift+up/down` | 이전/다음 workspace |
| `ctrl+shift+left/right` | 이전/다음 tab |

## herdr 기본(내장) `prefix+<letter>` 액션 — 새 단축키 추가 시 반드시 피할 것

`herdr --default-config`로 출력되는 기본 설정 주석 기준. 아래 letter들은 이미 herdr 자체 기능에
할당돼 있으므로 커스텀 바인딩에 재사용하면 충돌한다.

| 키 | 기본 액션 |
|---|---|
| `prefix+b` | `toggle_sidebar` |
| `prefix+c` | `new_tab` |
| `prefix+e` | `edit_scrollback` |
| `prefix+g` | `goto` |
| `prefix+h/j/k/l` | `focus_pane_left/down/up/right` (이 환경에서는 vim-herdr-navigation 플러그인 액션으로 재바인딩됨) |
| `prefix+n` | `next_tab` |
| `prefix+o` | `open_notification_target` |
| `prefix+p` | `previous_tab` |
| `prefix+q` | `detach` |
| `prefix+r` | `resize_mode` |
| `prefix+s` | `settings` |
| `prefix+v` | `split_vertical` |
| `prefix+w` | `workspace_picker` |
| `prefix+x` | `close_pane` |
| `prefix+z` | `zoom` |
| `prefix+tab` / `prefix+shift+tab` | `cycle_pane_next` / `cycle_pane_previous` |
| `prefix+shift+r` | `reload_config` |
| `prefix+shift+n` | `new_workspace` |
| `prefix+shift+g` | `new_worktree` |
| `prefix+shift+w` | `rename_workspace` |
| `prefix+shift+d` | `close_workspace` |
| `prefix+shift+t` | `rename_tab` |
| `prefix+shift+x` | `close_tab` |
| `prefix+shift+p` | `rename_pane` |

**사용 가능한(비어있는) `prefix+<letter>` 후보**: 위 기본 액션 목록(`b,c,e,g,h,j,k,l,n,o,p,q,r,s,v,w,x,z`)과
이미 쓴 `f,d,u,a,m`을 제외하면 `i`, `t`, `y`가 남아있다 (정확히 확인하려면 `herdr --default-config`로
최신 기본값을 다시 뽑아볼 것 — herdr 버전이 올라가며 기본 바인딩이 늘어날 수 있다).

## 참고: 관련 문서

- [herdr-plugins-guide.md](herdr-plugins-guide.md) — 각 플러그인 사용법과 위 단축키들이 왜 이 값으로
  정해졌는지(충돌 회피 과정)에 대한 상세 설명.
