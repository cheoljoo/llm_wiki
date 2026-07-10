---
description: 현재 프로젝트 세션에서 배운 것/한 일을 중앙 llm_wiki 저장소의 log/에 기록한다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

이 대화에서 지금까지 한 작업 중 재사용 가치가 있는 것(버그 수정, 설계 결정과 이유, 트러블슈팅 과정, 배운 점, 막혔던 부분과 해결법 등)을
간결하게 정리하라. 단순 진행상황이 아니라 나중에 다른 프로젝트에서도 참고할 만한 내용 위주로 쓴다.
Jira/Confluence MCP 도구가 연결되어 있다면, 지난 `/wiki-log` 실행 이후 새로 생긴 Jira/Confluence 변경사항도
함께 반영한다 (아래 3번 참고) — 이 세션·프로젝트와 관련 있는지 여부와 무관하게, "새로 생긴 변경사항" 자체가 기록 대상이다.
사용자가 `$ARGUMENTS`로 특정 주제/힌트를 줬다면 그것을 우선 반영한다.

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
      어느 경우든 step 4 이후는 그대로 진행한다.
   c. **연결되어 있으면** "지난 실행 이후 새로 생긴 변경사항"만 골라서 반영한다 (매번 전체를 다시
      훑지 않도록, 마지막으로 확인한 시각을 개인 설정 파일에 워터마크로 남겨 다음 실행 때 그 이후
      것만 조회한다).

   d. Jira: `cat ~/.config/llm_wiki/jira_last_checked`로 마지막 확인 시각(`YYYY-MM-DD HH:MM`)을 읽는다.
      파일이 없으면 최초 실행이므로 2번에서 구한 `end_time`에서 3일 전을 기준으로 삼는다.
      `assignee = currentUser() AND updated > "<마지막 확인 시각>" ORDER BY updated ASC` JQL로 그 이후 갱신된
      이슈를 조회한다. 결과가 있으면 이슈 키/요약/상태/갱신 시각을 로그 본문에 `## Jira 업데이트` 절로 남긴다
      (현재 프로젝트와 무관해도 모두 반영 — "새로 생긴 변경사항" 자체가 기록 대상이다). 조회에 성공했다면
      (결과가 없어도) `~/.config/llm_wiki/jira_last_checked`를 2번에서 구한 `end_time`으로 덮어써서 다음 실행의 기준점으로 삼는다.
   e. Confluence: `cat ~/.config/llm_wiki/confluence_last_checked`로 마지막 확인 시각을 읽는다 (없으면 d와 동일하게
      3일 전을 기준으로 삼는다). `contributor = currentUser() AND lastModified > "<마지막 확인 시각>"` CQL로 그
      이후 수정된 페이지를 조회한다. 결과가 있으면 페이지 제목/스페이스/링크/수정 시각을 `## Confluence 업데이트`
      절로 남긴다. 조회에 성공했다면 `~/.config/llm_wiki/confluence_last_checked`를 2번에서 구한 `end_time`으로 덮어쓴다.
4. `start_time`을 추정한다: 현재 작업 디렉토리가 git 저장소면
   `git status --porcelain --untracked-files=all | awk '{print $2}' | xargs -r stat -c '%y %n' | sort | head -1`
   로 이번 세션 중 변경된 파일들 중 가장 이른 수정시각을 구한다. 이 출력(`YYYY-MM-DD HH:MM:SS.nnnnnnnnn +ZZZZ`)에서 날짜와 시각(`YYYY-MM-DD HH:MM:SS`)까지만 잘라서 `start_time`으로 쓴다 — 세션이 자정을 넘겨 `end_time`과 날짜가 다를 수 있으므로 시각만 남기지 말 것.
   변경된 파일이 없거나(순수 대화/조사 세션) git 저장소가 아니면 `start_time`은 `end_time`과 동일하게 둔다.
5. 현재 작업 디렉토리 이름을 `<project>`로 사용한다 (git 저장소면 저장소 이름).
6. `who`를 구한다: `git config user.name`을 실행한다. 비어있으면 `git config user.email`, 그것도 비어있으면 `whoami`로 대체한다 (추측하지 말고 반드시 실행해서 값을 얻는다).
7. `branch`를 구한다: 현재 작업 디렉토리가 git 저장소면 `git rev-parse --abbrev-ref HEAD`를 실행한다. git 저장소가 아니면 `branch` 필드는 생략한다.
8. 2번에서 얻은 `end_time`의 날짜 부분(`YYYY-MM-DD`)과 내용을 요약한 kebab-case `<slug>`로 파일명을 만든다:
   `<WIKI_REPO_PATH>/log/YYYY-MM-DD-<project>-<slug>.md`
9. 아래 형식으로 파일을 작성한다 (별도의 `date` 필드는 두지 않는다 — 파일명과 `end_time`의 날짜로 충분하고, 세션이 자정을 넘기면 오히려 어느 날짜를 가리키는지 헷갈린다):

```markdown
---
start_time: YYYY-MM-DD HH:MM:SS
end_time: YYYY-MM-DD HH:MM:SS
who: <6번에서 구한 값>
project: <project>
source_repo: <현재 작업 디렉토리의 절대 경로>
branch: <7번에서 구한 값>
tags: [관련 키워드]
digested: false
---

# <제목>

(정리한 내용 — 3번에서 찾은 Jira/Confluence 업데이트가 있다면 `## Jira 업데이트` / `## Confluence 업데이트` 절로 포함)
```

10. `<WIKI_REPO_PATH>`에서 `git add log/<새 파일>` 후 `git commit`을 실행한다 (커밋 메시지: `log: <project> - <한 줄 요약>`). **push는 하지 않는다.**
11. 어떤 내용을 기록했는지 사용자에게 한두 문장으로 보고한다.

만약 이번 세션의 작업 내용도 없고(단순 질의응답 등) 3번에서 찾은 새 Jira/Confluence 변경사항도 없다면,
그렇다고 보고하고 아무 파일도 만들지 않는다 (단, 3번의 워터마크 파일 갱신은 조회에 성공했다면 그대로 반영해둔다 —
다음 실행이 불필요하게 오래된 시점부터 다시 훑지 않도록).
