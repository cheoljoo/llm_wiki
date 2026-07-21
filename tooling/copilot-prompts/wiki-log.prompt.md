---
mode: agent
description: 현재 프로젝트 세션에서 배운 것/한 일을 중앙 llm_wiki 저장소의 log/에 기록한다
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

이 대화에서 지금까지 한 작업 중 재사용 가치가 있는 것(버그 수정, 설계 결정과 이유, 트러블슈팅 과정, 배운 점, 막혔던 부분과 해결법 등)을
간결하게 정리하라. 단순 진행상황이 아니라 나중에 다른 프로젝트에서도 참고할 만한 내용 위주로 쓴다.
Jira/Confluence MCP 도구가 연결되어 있다면, 지난 wiki-log 실행 이후 새로 생긴 Jira/Confluence 변경사항도
함께 반영한다 (아래 3번 참고) — 이 세션·프로젝트와 관련 있는지 여부와 무관하게, "새로 생긴 변경사항" 자체가 기록 대상이다.
사용자가 채팅 메시지에 특정 주제/힌트를 줬다면 그것을 우선 반영한다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 아직 설치가 안 된 것이므로 다음과 같이 안내하고 **중단한다** (경로를 추측하지 않는다):
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `date +'%Y-%m-%d %H:%M:%S'`를 실행해서 `end_time`을 정확히 구한다 (추측하지 말고 반드시 실행해서 값을 얻는다). 이 값은 `YYYY-MM-DD HH:MM:SS` 형태로 **날짜를 포함해서** 그대로 `end_time`에 쓴다.
3. `mcp-atlassian` MCP 도구(Jira/Confluence 조회)가 이 세션에 연결되어 있는지 확인한다. **이 단계 전체는 best-effort다** —
   최종적으로 도구를 사용할 수 없어도 나머지 단계(git 기반 기록)는 그대로 진행한다.

   연결 여부는 다음 절차로 확인한다:

   a. **연결 확인**: 가벼운 MCP 도구 호출 한 번으로 `mcp-atlassian`이 현재 세션에 살아있는지 체크한다
      (예: `assignee = currentUser() AND updated > "<end_time 기준 1시간 전>"` JQL로 `jira_search` 호출).
   b. **미연결 시 기동 시도**: 도구 호출이 실패하거나 도구 자체가 보이지 않으면, 터미널에서
      `uvx mcp-atlassian --help 2>&1 | head -3` (또는 `npx -y mcp-atlassian --help 2>&1 | head -3`)을
      실행해 패키지 설치 여부를 확인한다.
      - 명령이 정상 실행되면(exit 0): "⚠️ mcp-atlassian 패키지는 설치돼 있으나 현재 세션에 MCP 서버로
        등록되어 있지 않습니다. VS Code / Claude Code를 재시작하거나 MCP 설정을 확인한 뒤 다시
        `/wiki-log`를 실행하면 Jira/Confluence 항목도 기록됩니다."라고 사용자에게 알린다.
      - 명령이 실패하면(명령 없음 또는 오류): "⚠️ mcp-atlassian을 찾을 수 없습니다(`uvx`/`npx` 모두
        실패). Jira/Confluence 항목은 이번 기록에서 제외됩니다."라고 알린다.
      어느 경우든 이후 단계(git 활동 조회 포함)는 그대로 진행한다.
   c. **연결되어 있으면** "지난 실행 이후 새로 생긴 변경사항"만 골라서 반영한다 (매번 전체를 다시
      훑지 않도록, 마지막으로 확인한 시각을 개인 설정 파일에 워터마크로 남겨 다음 실행 때 그 이후
      것만 조회한다).

   d. Jira: `cat ~/.config/llm_wiki/jira_last_checked`로 마지막 확인 시각(`YYYY-MM-DD HH:MM`)을 읽는다.
      파일이 없으면 최초 실행이므로 2번에서 구한 `end_time`에서 3일 전을 기준으로 삼는다.
      `assignee = currentUser() AND updated > "<마지막 확인 시각>" ORDER BY updated ASC` JQL로 그 이후 갱신된
      이슈를 조회한다. 결과가 있으면 **각 이슈에 대해 다음을 추가로 수행한다**:
      - `jira_get_issue`로 이슈 본문(description)을 읽는다.
      - `jira_get_comments`(또는 동등한 comments 조회 도구)로 댓글 목록을 읽는다.
      - 제목만 기록하지 않고, 본문 요약(핵심 문제·배경·조치사항)과 최근 댓글 요약을
        함께 기록한다. 단, 내용이 없거나 기록 가치가 없다고 판단되면 "(내용 없음)"으로 표기한다.
      로그 본문에 `## Jira 업데이트` 절로 남긴다 (현재 프로젝트와 무관해도 모두 반영).
      조회에 성공했다면(결과가 없어도) `~/.config/llm_wiki/jira_last_checked`를 2번에서 구한 `end_time`으로
      덮어써서 다음 실행의 기준점으로 삼는다.
   e. Confluence: `cat ~/.config/llm_wiki/confluence_last_checked`로 마지막 확인 시각을 읽는다 (없으면 d와 동일하게
      3일 전을 기준으로 삼는다). `contributor = currentUser() AND lastModified > "<마지막 확인 시각>"` CQL로 그
      이후 수정된 페이지를 조회한다. 결과가 있으면 **각 페이지에 대해 다음을 추가로 수행한다**:
      - `confluence_get_page`로 페이지 본문을 읽는다.
      - `confluence_get_comments`로 댓글 목록을 읽는다.
      - 제목만 기록하지 않고, 본문 요약(주요 변경 내용·결정사항)과 최근 댓글 요약을
        함께 기록한다. 내용이 없거나 기록 가치가 없다고 판단되면 "(내용 없음)"으로 표기한다.
      페이지 제목/스페이스/링크/수정 시각과 함께 `## Confluence 업데이트` 절로 남긴다.
      조회에 성공했다면 `~/.config/llm_wiki/confluence_last_checked`를 2번에서 구한 `end_time`으로 덮어쓴다.
4. GitHub와 사내 mod.lge.com/mod의 git 활동도 조회한다. **이 단계도 best-effort다** — 저장소 접근이
   실패해도 나머지 단계는 그대로 진행한다.

   a. `~/.config/llm_wiki/git_watch_repos` 파일이 있는지 확인한다 (한 줄에 git remote URL 하나,
      `#`으로 시작하는 줄과 빈 줄은 무시 — 예: `git@github.com:cheoljoo/foo.git`,
      `https://mod.lge.com/hub/group/project.git`). **이 파일의 존재 여부와 무관하게, 12번 최종
      보고에 다음 안내를 매번 눈에 띄게(예: 굵게 또는 별도 문단) 포함한다** — 이 설정 파일은
      한 번 만들고 나면 사람이 그 존재를 잊기 쉬우므로, 조용히 넘어가지 않고 매 실행마다 상기시킨다:
      - 파일이 없거나 내용이 비어있으면: "⚠️ GitHub/mod.lge.com git 활동 자동 기록이 꺼져 있습니다.
        켜려면 `~/.config/llm_wiki/git_watch_repos`에 감시할 저장소 git remote URL을 한 줄씩
        추가하세요." 라고 안내하고, 이 단계의 b~f는 건너뛴다.
      - 파일이 있으면: 등록된 저장소 목록을 그대로 나열하며 "📋 현재 git 활동 감시 중인 저장소:
        <목록>. 추가/삭제하려면 `~/.config/llm_wiki/git_watch_repos`를 수정하세요." 라고 안내한다
        (이번에 새 커밋을 못 찾았어도 이 안내는 남긴다).
   b. `cat ~/.config/llm_wiki/git_last_checked`로 마지막 확인 시각(`YYYY-MM-DD HH:MM:SS`)을 읽는다.
      없으면 2번에서 구한 `end_time` 기준 3일 전으로 삼는다.
   c. 커밋 작성자 판별용으로 `git config user.name`과 `git config user.email`을 읽는다 (전역 설정이
      없으면 7번에서 구할 `who` 값으로 대체).
   d. 목록의 각 URL에 대해:
      - URL의 `/`, `:` 등 특수문자를 `_`로 치환한 이름으로 미러 경로를 정한다:
        `~/.cache/llm_wiki/git-mirrors/<치환한 이름>.git`
      - 미러가 없으면 `git clone --bare --filter=blob:none <url> <미러경로>`를 시도한다. 실패하면
        "⚠️ <url> 접근 실패, 건너뜀"만 남기고 다음 URL로 넘어간다.
      - 미러가 있으면 `git --git-dir=<미러경로> fetch --all --prune`으로 갱신한다 (실패해도 이전에
        받아둔 상태로 계속 진행).
      - `git --git-dir=<미러경로> log --all --extended-regexp --since="<마지막 확인 시각>" --author="<c에서 구한 이름>|<c에서 구한 이메일>" --pretty=format:'%ad|%s|%h' --date=short`로
        이번 확인 시각 이후 본인 커밋을 조회한다.
      - 커밋이 있으면 저장소별로 날짜·요약·커밋 해시를 모아둔다.
   e. 하나 이상의 저장소에서 커밋을 찾았으면, 로그 본문에 `## Git 활동` 절로 저장소별 커밋 목록을
      남긴다 (형식: `- <저장소 이름> (<url>): <날짜> <커밋 메시지 요약> (<hash>)`). 커밋이 많으면
      전체 나열보다 핵심(무엇을 했는지)이 드러나도록 요약해도 된다.
   f. 이 단계를 (부분적으로라도) 시도했다면 `~/.config/llm_wiki/git_last_checked`를 2번에서 구한
      `end_time`으로 덮어써서 다음 실행의 기준점으로 삼는다.
5. `start_time`을 추정한다: 현재 작업 디렉토리가 git 저장소면
   `git status --porcelain --untracked-files=all | awk '{print $2}' | xargs -r stat -c '%y %n' | sort | head -1`
   로 이번 세션 중 변경된 파일들 중 가장 이른 수정시각을 구한다. 이 출력(`YYYY-MM-DD HH:MM:SS.nnnnnnnnn +ZZZZ`)에서 날짜와 시각(`YYYY-MM-DD HH:MM:SS`)까지만 잘라서 `start_time`으로 쓴다 — 세션이 자정을 넘겨 `end_time`과 날짜가 다를 수 있으므로 시각만 남기지 말 것.
   변경된 파일이 없거나(순수 대화/조사 세션) git 저장소가 아니면 `start_time`은 `end_time`과 동일하게 둔다.
6. 현재 작업 디렉토리 이름을 `<project>`로 사용한다 (git 저장소면 저장소 이름).
7. `who`를 구한다: `git config user.name`을 실행한다. 비어있으면 `git config user.email`, 그것도 비어있으면 `whoami`로 대체한다 (추측하지 말고 반드시 실행해서 값을 얻는다).
8. `branch`를 구한다: 현재 작업 디렉토리가 git 저장소면 `git rev-parse --abbrev-ref HEAD`를 실행한다. git 저장소가 아니면 `branch` 필드는 생략한다.
9. 2번에서 얻은 `end_time`의 날짜 부분(`YYYY-MM-DD`)과 내용을 요약한 kebab-case `<slug>`로 파일명을 만든다:
   `<WIKI_REPO_PATH>/log/YYYY-MM-DD-<project>-<slug>.md`
10. 아래 형식으로 파일을 작성한다 (별도의 `date` 필드는 두지 않는다 — 파일명과 `end_time`의 날짜로 충분하고, 세션이 자정을 넘기면 오히려 어느 날짜를 가리키는지 헷갈린다):

```markdown
---
start_time: YYYY-MM-DD HH:MM:SS
end_time: YYYY-MM-DD HH:MM:SS
who: <7번에서 구한 값>
project: <project>
source_repo: <현재 작업 디렉토리의 절대 경로>
branch: <8번에서 구한 값>
tags: [관련 키워드]
digested: false
---

# <제목>

(정리한 내용 — 3번에서 찾은 Jira/Confluence 업데이트, 4번에서 찾은 Git 활동이 있다면 각각
`## Jira 업데이트` / `## Confluence 업데이트` / `## Git 활동` 절로 포함)
```

11. `<WIKI_REPO_PATH>`에서 `git add log/<새 파일>` 후 `git commit`을 실행한다 (커밋 메시지: `log: <project> - <한 줄 요약>`). **push는 하지 않는다.**
12. 어떤 내용을 기록했는지 사용자에게 한두 문장으로 보고한다. **4번 a에서 정한 git_watch_repos
    안내 문구를 (파일이 있든 없든) 이 보고에 반드시 눈에 띄게 포함한다** — 로그 파일 본문에는
    넣지 않고, 채팅 응답에만 보여준다.

만약 이번 세션의 작업 내용도 없고(단순 질의응답 등) 3번에서 찾은 새 Jira/Confluence 변경사항, 4번에서
찾은 새 Git 활동도 없다면, 그렇다고 보고하되 **4번 a의 git_watch_repos 안내 문구는 이때도 빠뜨리지
않는다** (파일을 안 만드는 것과 무관하게 매번 보여줘야 함). 아무 파일도 만들지 않는다 (단, 3번/4번의 워터마크 파일
갱신은 조회에 성공했다면 그대로 반영해둔다 — 다음 실행이 불필요하게 오래된 시점부터 다시 훑지 않도록).
