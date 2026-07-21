# llm_wiki

팀이 여러 프로젝트에서 얻은 지식/경험을 계속 쌓아가는 개인·팀용 LLM Wiki입니다.
(Andrej Karpathy가 언급한 "LLM이 유지보수하는 위키" 개념을 참고)

## 구조

```
log/    원본 로그. 각 프로젝트 세션이 끝날 때 append-only로 쌓이는 raw 기록.
wiki/   정제된 지식. log/의 내용을 주제별로 통합·정리한 문서. 서로 [[링크]]로 연결.
```

- `log/`는 사람이 직접 편집하지 않습니다. `/wiki-log` 명령으로만 추가됩니다.
- `wiki/`는 `/wiki-digest` 명령이 `log/`를 읽어 자동으로 만들고 업데이트합니다.

## 사용 흐름

1. **어느 프로젝트에서 작업하든** 의미 있는 작업(버그 수정, 설계 결정, 트러블슈팅, 배운 점 등)이 끝나면
   그 프로젝트 세션에서 `/wiki-log` 를 실행합니다. → `log/`에 날짜별 원본 노트가 쌓입니다.
2. 주기적으로 (또는 로그가 어느 정도 쌓이면) 이 저장소에서 `/wiki-digest` 를 실행합니다.
   → 새 로그들을 읽어 `wiki/` 아래 주제별 문서로 정리·통합하고, 처리된 로그는 `digested: true`로 표시합니다.
3. `wiki/README.md`가 전체 주제의 목차 역할을 합니다.

자세한 규칙은 [CLAUDE.md](CLAUDE.md), [log/README.md](log/README.md), [wiki/README.md](wiki/README.md) 참고.
설치·MCP(Jira/Confluence) 연동·커맨드별 사용법을 처음부터 따라 하려면 [GUIDE.md](GUIDE.md) 참고.

## 쌓인 wiki 활용하기

`log/`는 쓰기 전용이고, 실제로 다시 꺼내 쓰는 것은 정제된 `wiki/`입니다.
핵심 원칙은 **"README.md를 통째로 읽히지 말고, 키워드 grep으로 필요한 주제만 골라 읽힌다"**입니다 —
주제가 100개로 늘어나도 조회 비용이 거의 늘지 않습니다.

아래 예제들 중 반복적으로 쓰는 것들은 `wiki-` 접두어를 공유하는 슬래시 커맨드로 만들어뒀습니다
(`/wiki-recall`, `/wiki-report`, `/wiki-todo`, `/wiki-project-done` — `wiki-log`/`wiki-digest`와 같은 계열).
직접 grep 프롬프트를 매번 타이핑할 필요 없이 그대로 호출하면 됩니다. 설치는 [설치](#설치-팀원별-1회) 절 참고,
각 커맨드의 호출 예시·상세 사용법은 [GUIDE.md의 "슬래시 커맨드 사용법"](GUIDE.md#4-슬래시-커맨드-사용법) 참고.

### 1. 새 작업 시작 전 관련 지식 조회 (`/wiki-recall`)

다른 프로젝트의 Claude Code 세션에서, 작업을 시작하기 전에 이렇게 호출합니다:

> `/wiki-recall docker`

`docker-compose-ops` 같은 관련 항목을 wiki 목차에서 찾아 그 파일만 읽고, 지금 상황과
관련된 부분만 요약해서 알려줍니다. 과거에 겪은 "같은 이미지를 쓰는 다중 서비스 운영 시
체크포인트" 같은 노하우를 세션 시작 시점에 미리 주입하는 효과입니다.

내부적으로는 `grep -i docker ~/code/llm_wiki/wiki/README.md`로 목차에서 관련 주제를 찾고,
일치하는 wiki 문서를 읽는 방식으로 동작합니다 — 커맨드 없이 이 프롬프트를 직접 줘도 동일하게 동작합니다.

### 2. 특정 프로젝트의 CLAUDE.md에 참조 지침 박아두기 (자동화)

반복적으로 참고할 주제가 정해져 있으면, 해당 프로젝트의 `CLAUDE.md`에 한 줄 넣어둡니다:

```markdown
# 예: pvs_crawler 프로젝트의 CLAUDE.md
- sage 파이프라인 관련 작업 전에는 반드시
  ~/code/llm_wiki/wiki/pvs-crawler-sage-llm-pipeline.md 를 읽고 시작할 것.
- Jira/Confluence MCP 도구를 쓸 때는 ~/code/llm_wiki/wiki/mcp-atlassian.md 의 함정 목록을 먼저 확인할 것.
```

이러면 매 세션 자동으로 읽고 시작하므로, 같은 함정에 다시 빠지거나 같은 설계 논의를 반복하지 않습니다.

### 3. 트러블슈팅 시 "예전에 이거 겪었나?" 조회 (`/wiki-recall`)

에러를 만났을 때도 같은 커맨드를 검색 창구로 씁니다:

> `/wiki-recall OpenMP timezone encoding`

목차(README.md) grep으로 안 잡히면 `/wiki-recall`이 자동으로 `wiki/*.md` 본문 전체까지
grep 범위를 넓힙니다 (파일 수가 많지 않아 본문 grep도 충분히 쌉니다). 걸리는 문서가 있으면
읽고 지금 에러와 관련 있는지까지 판단해서 알려줍니다.

### 4. 팀 온보딩 / 지식 공유

새 팀원에게 "이 저장소 clone하고 `wiki/README.md` 목차만 훑어보라"고 안내하면,
프로젝트별 축적된 결정 사항과 함정 목록이 그대로 온보딩 문서가 됩니다.
발표나 회고 자료가 필요할 때도 `wiki/<topic>.md`가 이미 정제돼 있어 거의 그대로 쓸 수 있습니다.

### 5. task / 일정 관리에 활용하기

`log/`의 frontmatter에는 `start_time`/`end_time`/`project`가, 본문에는 `## Jira 업데이트` /
`## Confluence 업데이트` 절이 쌓입니다. 이것 자체가 "내가 언제 어떤 프로젝트에서 무엇을 했는지"의
타임라인 데이터라서, 다음과 같이 활용할 수 있습니다.

**주간 업무 보고 초안 + 프로젝트별 시간 통계** (`/wiki-report`):

> `/wiki-report 이번 주`

`log/`에서 지정한 기간(생략하면 최근 7일)의 frontmatter(`start_time`/`project`)를 기준으로
대상 로그를 골라, 프로젝트별로 묶은 업무 보고 초안(Jira 이슈 키 포함)과 프로젝트별 세션 수·대략
소요 시간 표를 함께 만들어줍니다. 기간은 `/wiki-report 2026-07-01 ~ 2026-07-15`처럼 직접 지정할
수도 있습니다.

**진행 중인 일 / 놓친 일 점검 + Todo 이어받기** (`/wiki-todo`):

> `/wiki-todo`  (또는 `/wiki-todo pvs_crawler`로 특정 프로젝트만)

`/wiki-log`가 Jira 이슈 본문·댓글 요약까지 기록해두므로, log에 남은 `## Jira 업데이트` 절만
훑어서 "In Progress로 마지막 언급된 뒤 14일 넘게 아무 log에도 안 나온 이슈"를 정체 후보로 골라줍니다.
동시에 최근 로그의 "Todo / 남은 작업 / 후속 작업" 문장도 project별로 모아 보여줍니다.
Jira를 직접 다 뒤지지 않아도, log 스냅샷만으로 "요즘 손을 놓고 있는 일"을 찾을 수 있습니다
(정확한 현재 상태 확인이 필요하면 그때만 mcp-atlassian으로 해당 이슈를 재조회하면 됩니다).

주의할 점 하나: `log/`는 기록 시점의 스냅샷이라 일정·상태 정보는 시간이 지나면 낡습니다.
`/wiki-report`, `/wiki-todo` 모두 "탐색·초안용"으로 쓰고, 최종 확인은 Jira/캘린더 원본에서 하는 것이 안전합니다.

### 6. 프로젝트 종료/정리 시 요약 문서 만들기 (`/wiki-project-done`)

프로젝트가 끝나거나 한 단락 정리가 필요할 때, **그 프로젝트 자신의 저장소에서** 호출합니다:

> `/wiki-project-done`  (log의 `project` 값이 디렉토리명과 다르면 `/wiki-project-done <project명>`)

llm_wiki 쪽 `log/`·`wiki/`에서 이 프로젝트와 관련된 내용만 모아, **호출한 그 저장소 루트**에
`wiki-project.md`를 만들어줍니다 (llm_wiki 저장소 안이 아니라 대상 프로젝트 안에 생김). 작업
타임라인, 관련 Jira 이슈, wiki에 정제된 설계 결정·트러블슈팅 요약(원본 wiki 문서 경로 포함)이
담깁니다. llm_wiki 쪽은 읽기만 하고, 만든 파일의 git add/commit은 하지 않으므로 검토 후 직접
커밋하면 됩니다.

## 설치 (팀원별 1회)

`/wiki-log`, `/wiki-recall`, `/wiki-report`, `/wiki-todo`, `/wiki-project-done`은 어느 프로젝트에서든
호출해야 하므로 Claude Code의 **user-level 커맨드**로 설치합니다. 개인 clone 경로는 커맨드 파일에
직접 적지 않고, 개인 설정 파일 하나에 저장합니다 — 그래야 `tooling/commands/*.md`가 git으로
업데이트돼도 매번 경로를 다시 적어 넣을 필요가 없습니다.

1. 이 저장소를 원하는 위치에 clone
2. 클론한 디렉터리에서 `make install` 실행 — `~/.config/llm_wiki/repo_path`에 이 clone의 절대경로를
   기록하고, `tooling/commands/{wiki-log,wiki-recall,wiki-report,wiki-todo,wiki-project-done}.md`를
   `~/.claude/commands/`로 복사합니다.

수동으로 하고 싶다면:
   ```
   mkdir -p ~/.config/llm_wiki
   echo "<본인의 llm_wiki clone 절대경로>" > ~/.config/llm_wiki/repo_path
   cp tooling/commands/wiki-log.md tooling/commands/wiki-recall.md \
      tooling/commands/wiki-report.md tooling/commands/wiki-todo.md \
      tooling/commands/wiki-project-done.md \
      ~/.claude/commands/
   ```

이후 저장소를 `git pull`로 갱신해서 `tooling/commands/*.md`가 바뀌면,
`make update`(또는 위 `cp` 한 줄)만 다시 실행하면 됩니다.

`/wiki-digest`는 이 저장소 안에서만 쓰므로 이미 `.claude/commands/wiki-digest.md`에 있고 별도 설치가 필요 없습니다.

## scripts/

wiki 워크플로우와는 별개로, 여러 시스템에 반복 적용하는 개인 환경 설정 스크립트를 모아둡니다.
필요한 도구가 없으면 `WARNING:` 메시지만 남기고 계속 진행하거나(설치 후 재실행하면 됨) 안전하게
멈추므로, 실패 원인만 보고 다시 실행하면 됩니다.

- **`scripts/setup-herdr-vim-nav.sh`** — [herdr](https://herdr.dev)에 [vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation)
  플러그인을 설치하고, herdr pane 이동(`ctrl+up/down/left/right`), Vim split ↔ herdr pane 이동(`prefix+h/j/k/l`) 및 workspace/tab 전환
  (`ctrl+shift+up/down/left/right`) 키바인딩을 구성합니다. `herdr`, `jq`, `vim`이 없으면 `WARNING:`을
  남기고(herdr는 필수라 종료, 나머지는 경고만 하고 계속) 설치 후 재실행하면 이어서 진행됩니다.
  재실행해도 안전(idempotent)합니다 — 이미 적용된 설정은 marker 주석으로 감지해 건너뜁니다.
  기존 `~/.config/herdr/config.toml`이 있어도 자동으로 병합합니다 (TOML은 `[keys]` 테이블을 두 번
  선언할 수 없으므로, 기존 `[keys]` 테이블이 있으면 그 안에 이어붙이는 방식). 단, 이미 같은 키
  이름(`focus_pane_left` 등)이 할당돼 있어 충돌하는 경우에만 안전하게 자동 편집을 건너뛰고
  `config.toml.vim-herdr-navigation.snippet`으로 병합할 내용만 남깁니다.

  ```bash
  bash scripts/setup-herdr-vim-nav.sh
  ```
