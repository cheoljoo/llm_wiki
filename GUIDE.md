# llm_wiki 설정·사용 가이드

`README.md`가 구조/개념 설명이라면, 이 문서는 **처음 설정하는 사람이 순서대로 따라 하는 실전 가이드**입니다.

## 1. 저장소 설치

```bash
git clone <이 저장소 URL> ~/code/llm_wiki
cd ~/code/llm_wiki
make install
```

`make install`이 하는 일:
- `~/.config/llm_wiki/repo_path`에 이 clone의 절대경로 기록
- `tooling/commands/{wiki-log,wiki-recall,wiki-report,wiki-todo,wiki-project-done}.md`를
  `~/.claude/commands/`로 복사 (어느 프로젝트에서든 `/wiki-log`, `/wiki-recall`, `/wiki-report`,
  `/wiki-todo`, `/wiki-project-done`을 바로 쓸 수 있게 됨)

git으로 저장소를 업데이트한 뒤(`git pull`)에는 `make update`만 다시 실행하면 최신 커맨드로 갱신됩니다.

VS Code Copilot에서도 `/wiki-log`를 쓰고 싶다면 `make install-copilot`을 추가로 실행하세요 (자세한 내용은
`make help` 참고).

## 2. MCP (Jira/Confluence) 연동 — mcp-atlassian

`/wiki-log`가 Jira/Confluence의 최근 변경사항을 자동으로 로그에 반영하려면 `mcp-atlassian` MCP 서버가
필요합니다. **없어도 `/wiki-log`, `/wiki-recall`, `/wiki-report`, `/wiki-todo`는 모두 정상 동작**하고
(Jira/Confluence 관련 부분만 best-effort로 생략됨) 이 절은 순수 옵션입니다.

### 2.1 사전 준비

`mcp-atlassian`은 `uvx`(Python 패키지 실행기)로 띄웁니다. `uv`가 없다면 먼저 설치:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2.2 Jira/Confluence Personal Access Token 발급

LGE 사내 Jira(`jira.lge.com`)/Confluence(`collab.lge.com`) 기준:
- 우측 상단 프로필 아이콘 → **Profile** → **Personal Access Tokens**(또는 API tokens) 메뉴에서 토큰 생성
- Jira용, Confluence용 각각 발급 (같은 토큰을 재사용할 수 있는 인스턴스도 있지만, 분리 발급이 안전)

> 참고: LGE 환경에서 Copilot CLI 기준의 상세 설정 절차는
> [linux-copilot-cli-setup-korean.md](https://github.com/cheoljoo/mcp_copilot/blob/main/docs/linux-copilot-cli-setup-korean.md)에도
> 정리돼 있습니다. 토큰 발급 방법과 `mcp-atlassian` 자체 동작은 동일하지만, **아래 절차는 Claude Code CLI 기준**이고
> 토큰을 설정 파일에 직접 박아 넣지 않고 별도 `.env` 파일로 분리하는 더 안전한 방식을 씁니다.

### 2.3 인증 정보를 `.env` 파일로 분리 저장

토큰을 Claude Code 설정 파일(`~/.claude.json`)이나 커맨드에 직접 적지 않고, 별도 파일에 저장하고 권한을 좁힙니다:

```bash
mkdir -p ~/.config/mcp-atlassian
cat > ~/.config/mcp-atlassian/.env <<'EOF'
JIRA_URL=http://jira.lge.com/issue
JIRA_USERNAME=<본인 아이디>@lge.com
JIRA_PERSONAL_TOKEN=<발급받은 Jira 토큰>

CONFLUENCE_URL=http://collab.lge.com/main
CONFLUENCE_USERNAME=<본인 아이디>@lge.com
CONFLUENCE_PERSONAL_TOKEN=<발급받은 Confluence 토큰>

JIRA_SSL_VERIFY=true
CONFLUENCE_SSL_VERIFY=true
MCP_VERBOSE=false
EOF
chmod 600 ~/.config/mcp-atlassian/.env
```

`chmod 600`으로 본인만 읽을 수 있게 제한하는 게 핵심입니다.

### 2.4 Claude Code에 user-scope로 등록

**user-scope**로 등록해야 어느 프로젝트 디렉터리에서 세션을 열든 이 MCP 서버가 보입니다
(project-scope로 등록하면 그 프로젝트에서만 보이고, 토큰이 `.mcp.json`에 들어가면 그 저장소를
git clone하는 모두에게 노출되므로 절대 project-scope에 토큰을 직접 넣지 마세요):

```bash
claude mcp add --transport stdio --scope user mcp-atlassian -- \
  uvx --python=3.13 mcp-atlassian --env-file ~/.config/mcp-atlassian/.env
```

- `--python=3.13`: `mcp-atlassian`이 Python 3.13에서 안정적으로 동작하기 때문에 명시.
- `--env-file`: 위에서 만든 `.env`를 그대로 읽게 함 — 토큰이 `claude mcp add` 명령 자체나
  `~/.claude.json`에 평문으로 직접 박히지 않음.

등록 확인:

```bash
claude mcp list
claude mcp get mcp-atlassian
```

삭제하려면:

```bash
claude mcp remove mcp-atlassian
```

### 2.5 반영을 위해 새 세션 시작

`~/.claude.json`에 MCP 서버를 추가해도 **이미 열려 있는 세션에는 반영되지 않습니다.** 완전히 새
Claude Code 세션(VS Code라면 창을 새로 열거나 확장을 재시작)을 시작해야 `mcp-atlassian` 도구들이 보입니다.

### 2.6 VS Code Copilot에서도 쓰려면 (선택)

Claude Code와 별개로 VS Code Copilot Chat에서도 `mcp-atlassian`을 쓰려면, VS Code **전역**
`settings.json`(`~/.config/Code/User/settings.json`)에 별도로 등록해야 합니다:

```json
{
  "mcp": {
    "servers": {
      "mcp-atlassian": {
        "type": "stdio",
        "command": "uvx",
        "args": ["--python=3.13", "mcp-atlassian", "--env-file", "/home/<user>/.config/mcp-atlassian/.env"]
      }
    }
  }
}
```

등록 후 `Developer: Reload Window`(또는 VS Code 재시작)로 반영합니다.

### 2.7 트러블슈팅

- **"MCP 서버 연결해줘" 요청이 거부됨**: Claude Code가 자기 자신의 설정(`~/.claude.json`)에 토큰이
  든 MCP 서버를 추가하는 건 auto-mode에서 자동 차단될 수 있습니다(`[Self-Modification]`). "MCP 서버
  연결을 먼저 하고 나서..."처럼 명시적으로 지시하면 통과됩니다.
- **새로 등록했는데 도구가 안 보임**: 2.5번 참고 — 새 세션이 필요합니다.
- **Jira 404 에러**: `JIRA_URL`에 `/issue` 같은 경로 접미사가 필요한 인스턴스가 있습니다. 위 예시의
  `http://jira.lge.com/issue`처럼 실제 브라우저로 접속하는 base URL을 그대로 쓰세요.
- **Confluence CQL의 날짜 필터(`lastModified > "..."`)가 안 먹히는 것 같음**: 실제로 발생한 적 있는
  현상입니다. 날짜 조건을 바꿔가며 결과가 실제로 달라지는지 먼저 확인하고, 안 달라지면 그 결과를
  신뢰하지 마세요.
- **`jira_get_all_projects`가 너무 큰 응답을 반환**: 프로젝트 수가 많은 인스턴스에서는 도구 호출
  응답 한도를 넘길 수 있습니다. `JIRA_PROJECTS_FILTER` 환경변수로 필터링하거나, 단순 연결 확인
  목적이면 좁은 JQL의 `jira_search`를 쓰세요.

더 자세한 함정 목록은 [wiki/mcp-atlassian.md](wiki/mcp-atlassian.md) 참고.

## 3. GitHub / mod.lge.com 저장소의 git 활동 자동 조회 (옵션)

`/wiki-log`가 Jira/Confluence 외에, 평소 작업하는 GitHub·사내 mod.lge.com/mod 저장소의 최근
커밋도 `## Git 활동` 절로 함께 기록하게 할 수 있습니다. **없어도 `/wiki-log`는 정상 동작**하고
(이 부분만 조용히 생략됨) 순수 옵션입니다.

### 3.1 감시할 저장소 목록 등록

```bash
mkdir -p ~/.config/llm_wiki
cat > ~/.config/llm_wiki/git_watch_repos <<'EOF'
# 한 줄에 하나씩 git remote URL. #으로 시작하는 줄과 빈 줄은 무시됩니다.
git@github.com:cheoljoo/llm_wiki.git
https://mod.lge.com/hub/<group>/<project>.git
EOF
```

- URL은 로컬에서 `git clone`/`git fetch` 가능해야 합니다 — GitHub는 보통 SSH 키, mod.lge.com은
  사내 계정 인증(SSH 키 또는 credential helper)이 미리 설정돼 있어야 합니다. 인증이 안 돼 있으면
  해당 저장소만 건너뛰고 나머지는 그대로 진행됩니다.
- 커밋 작성자 판별은 `git config user.name` / `user.email`을 씁니다. GitHub와 mod.lge.com에서
  서로 다른 이메일을 쓴다면, 두 저장소에서 커밋을 찾을 수 있도록 로컬(프로젝트별) git config에
  각각 맞는 `user.email`이 설정돼 있는지 확인하세요.

### 3.2 동작 방식

- 목록의 각 URL을 `~/.cache/llm_wiki/git-mirrors/`에 bare mirror로 클론해두고, 이후 실행부터는
  `git fetch`로 갱신만 합니다 (매번 전체를 새로 받지 않음).
- Jira/Confluence와 같은 방식으로 `~/.config/llm_wiki/git_last_checked`에 마지막 확인 시각을
  워터마크로 남겨, 다음 실행부터는 그 이후 커밋만 조회합니다.
- 저장소 접근(clone/fetch)이 실패해도 다른 저장소·나머지 `/wiki-log` 단계는 그대로 진행됩니다
  (best-effort).

### 3.3 트러블슈팅

- **특정 저장소만 계속 실패**: `git clone --bare --filter=blob:none <url> /tmp/test-mirror`를
  터미널에서 직접 실행해 인증/네트워크 문제인지 먼저 확인하세요.
- **mod.lge.com 커밋이 하나도 안 잡힘**: 해당 저장소의 로컬 `user.email`이 GitHub용과 다른 경우
  흔합니다 (3.1 참고). `git log --all --author=<이메일>`로 직접 필터링해 실제로 잡히는지 확인하세요.

## 4. 슬래시 커맨드 사용법

### `/wiki-log` — 지금 세션에서 배운 것 기록

```
/wiki-log
```

지금까지의 대화에서 재사용 가치 있는 것(버그 수정, 설계 결정, 트러블슈팅, 배운 점)을 정리해
`log/`에 새 파일로 남기고 커밋합니다. `mcp-atlassian`이 연결돼 있으면 마지막 확인 이후 새로 생긴
Jira/Confluence 변경사항도 함께 반영합니다. 특정 주제를 우선 반영하고 싶으면 인자로 힌트를 줍니다:

```
/wiki-log docker 관련 트러블슈팅 위주로
```

어느 프로젝트 디렉터리에서 실행하든 동작합니다 (해당 프로젝트 이름으로 로그가 남음).

### `/wiki-digest` — log를 wiki로 정제 (이 저장소 안에서만)

```
/wiki-digest
```

`log/*.md` 중 아직 정제 안 된(`digested: false`) 것들을 읽어 `wiki/<topic>.md`로 통합·갱신하고,
`wiki/README.md` 목차를 갱신합니다. 이 저장소(`llm_wiki`) 안에서만 실행합니다.

### `/wiki-recall <키워드>` — 관련 지식 조회

```
/wiki-recall docker
/wiki-recall OpenMP timezone
```

`wiki/README.md` 목차에서 키워드를 찾고, 못 찾으면 `wiki/*.md` 본문 전체로 검색 범위를 넓혀
관련 문서를 찾아 지금 상황과 관련된 부분만 요약해줍니다. 새 작업 시작 전이나 에러를 만났을 때
"예전에 이거 겪었나?"를 물어보는 용도.

### `/wiki-report [기간]` — 업무 보고 초안 + 시간 통계

```
/wiki-report
/wiki-report 이번 주
/wiki-report 2026-07-01 ~ 2026-07-15
```

`log/`의 frontmatter(`start_time`/`project`)를 기준으로 지정한 기간(생략하면 최근 7일)의 로그를
프로젝트별로 묶어 업무 보고 초안(관련 Jira 이슈 키 포함)과 프로젝트별 세션 수·대략 소요 시간 표를
만들어줍니다. 파일을 만들거나 커밋하지 않고 대화창에만 출력합니다.

### `/wiki-todo [프로젝트명]` — 미완료 작업·정체 이슈 점검

```
/wiki-todo
/wiki-todo pvs_crawler
```

최근 로그의 "Todo/남은 작업/후속 작업" 문장과, `## Jira 업데이트` 절에서 "In Progress"로 마지막
언급된 뒤 14일 넘게 어떤 로그에도 다시 안 나온 이슈("정체 후보")를 찾아줍니다. log에 남은 스냅샷
기반이므로 실제 최신 상태는 필요하면 Jira에서 재확인하세요.

### `/wiki-project-done [프로젝트명]` — 프로젝트 마무리 요약 문서 생성

```
/wiki-project-done
/wiki-project-done pvs_crawler
```

다른 커맨드들과 달리 **llm_wiki가 아니라 정리하려는 그 프로젝트 저장소 안에서 실행**합니다.
llm_wiki의 `log/`·`wiki/`에서 이 프로젝트와 관련된 내용만 모아, 호출한 저장소 루트에
`wiki-project.md`를 새로 만들어줍니다 — 작업 타임라인, 관련 Jira 이슈, wiki에 정제된 설계 결정·
트러블슈팅 요약(원본 wiki 문서 경로 포함)이 담깁니다. 인자를 생략하면 현재 디렉터리 이름을
프로젝트명으로 쓰고, log에 기록된 `project` 값이 디렉터리명과 다르면 인자로 명시적으로 넘깁니다.
llm_wiki 쪽은 읽기만 하고, 만든 파일의 git add/commit은 하지 않으므로 검토 후 프로젝트 저장소에서
직접 커밋하면 됩니다.

## 5. 활용 아이디어 더 보기

`/wiki-recall`, `/wiki-report`, `/wiki-todo`로 커버되는 것 외에, log/wiki가 쌓이면 할 수 있는 것들:

- **분기/반기 성과 정리 초안**: `/wiki-report`를 넓은 기간(예: `2026-01-01 ~ 2026-06-30`)으로 돌려
  반기 자기평가·인사 평가 자료의 "무엇을 했는지" 섹션 초안을 뽑습니다. 실적 숫자는 별도로 검증하되,
  "무엇을 왜 했는지" 서술은 log에 이미 정리돼 있어 초안 작성 시간을 크게 줄여줍니다.
- **신규 프로젝트 착수 시 유사 사례 탐색**: 새 프로젝트에서 아키텍처를 고민할 때
  `/wiki-recall <기술스택>`으로 과거 비슷한 결정과 그 이유(예: `agent-framework-error-handling`,
  `pairing-otp-security-pattern`)를 먼저 조회해서 같은 논의를 반복하지 않습니다.
- **팀 온보딩/교육 자료 생성**: `/wiki-recall`로 관련 주제 문서 몇 개를 모은 뒤 "이 내용들을 신규
  입사자용 튜토리얼로 재구성해줘"라고 요청하면, 이미 정제된 지식을 발표/교육 자료로 빠르게 변환할 수
  있습니다.
- **코드/설계 리뷰 전 체크리스트**: PR을 올리기 전 `/wiki-recall <관련 주제>`로 과거에 겪은 함정
  목록을 미리 불러와 리뷰 코멘트가 나올 만한 지점을 스스로 먼저 점검합니다.
- **주간 팀 공유용 요약**: `/wiki-report`의 출력을 그대로 슬랙/이메일에 붙여넣기 좋은 형태로
  다듬어 "이번 주 한 일 공유" 메시지 초안으로 씁니다.
- **정기 자동화와 결합**: `/loop` 스킬과 조합해 매주 특정 요일에 `/wiki-report 이번 주`를 자동
  실행하고 결과를 파일로 저장해두면, 주간 보고 작성 시점에 다시 뒤지지 않아도 됩니다.
- **프로젝트 종료 시 lessons-learned 문서화**: 프로젝트가 끝나면 그 프로젝트 저장소에서
  `/wiki-project-done`을 실행해 타임라인·설계 결정·트러블슈팅을 모은 `wiki-project.md`를 만들고,
  이를 회고 문서의 뼈대로 삼습니다.
- **Jira 티켓 생성 전 중복 작업 방지**: 새 이슈를 등록하기 전에 `/wiki-recall <증상 키워드>`로 과거에
  비슷한 문제를 이미 해결한 적 있는지 먼저 확인합니다.
