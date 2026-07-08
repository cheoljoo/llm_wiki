---
description: 현재 프로젝트 세션에서 배운 것/한 일을 중앙 llm_wiki 저장소의 log/에 기록한다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

이 대화에서 지금까지 한 작업 중 재사용 가치가 있는 것(버그 수정, 설계 결정과 이유, 트러블슈팅 과정, 배운 점, 막혔던 부분과 해결법 등)을
간결하게 정리하라. 단순 진행상황이 아니라 나중에 다른 프로젝트에서도 참고할 만한 내용 위주로 쓴다.
Jira/Confluence MCP 도구가 연결되어 있다면, 이 세션과 관련된 최근 Jira 이슈/Confluence 페이지 작업 내용도 함께 반영한다 (아래 1.5번 참고).
사용자가 `$ARGUMENTS`로 특정 주제/힌트를 줬다면 그것을 우선 반영한다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 아직 설치가 안 된 것이므로 다음과 같이 안내하고 **중단한다** (경로를 추측하지 않는다):
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
1.5. `mcp-atlassian` MCP 도구(Jira/Confluence 조회)가 이 세션에 연결되어 있는지 확인한다. 연결되어 있으면 이번 세션과 관련된
   본인의 최근 Jira 이슈(코멘트/상태 변경 등)와 최근 수정한 Confluence 페이지를 조회해서, 재사용 가치가 있는 내용이면
   본문에 반영하고 이슈 키/페이지 링크를 함께 남긴다. **이 단계는 best-effort다** — 도구가 연결되어 있지 않거나 조회가
   실패해도 무시하고 나머지 단계(git 기반 기록)는 그대로 진행한다. 관련 없는 이슈/페이지까지 억지로 끌어오지 않는다.
2. `date +'%Y-%m-%d %H:%M:%S'`를 실행해서 `end_time`을 정확히 구한다 (추측하지 말고 반드시 실행해서 값을 얻는다). 이 값은 `YYYY-MM-DD HH:MM:SS` 형태로 **날짜를 포함해서** 그대로 `end_time`에 쓴다.
3. `start_time`을 추정한다: 현재 작업 디렉토리가 git 저장소면
   `git status --porcelain --untracked-files=all | awk '{print $2}' | xargs -r stat -c '%y %n' | sort | head -1`
   로 이번 세션 중 변경된 파일들 중 가장 이른 수정시각을 구한다. 이 출력(`YYYY-MM-DD HH:MM:SS.nnnnnnnnn +ZZZZ`)에서 날짜와 시각(`YYYY-MM-DD HH:MM:SS`)까지만 잘라서 `start_time`으로 쓴다 — 세션이 자정을 넘겨 `end_time`과 날짜가 다를 수 있으므로 시각만 남기지 말 것.
   변경된 파일이 없거나(순수 대화/조사 세션) git 저장소가 아니면 `start_time`은 `end_time`과 동일하게 둔다.
4. 현재 작업 디렉토리 이름을 `<project>`로 사용한다 (git 저장소면 저장소 이름).
5. `who`를 구한다: `git config user.name`을 실행한다. 비어있으면 `git config user.email`, 그것도 비어있으면 `whoami`로 대체한다 (추측하지 말고 반드시 실행해서 값을 얻는다).
6. `branch`를 구한다: 현재 작업 디렉토리가 git 저장소면 `git rev-parse --abbrev-ref HEAD`를 실행한다. git 저장소가 아니면 `branch` 필드는 생략한다.
7. 2번에서 얻은 `end_time`의 날짜 부분(`YYYY-MM-DD`)과 내용을 요약한 kebab-case `<slug>`로 파일명을 만든다:
   `<WIKI_REPO_PATH>/log/YYYY-MM-DD-<project>-<slug>.md`
8. 아래 형식으로 파일을 작성한다 (별도의 `date` 필드는 두지 않는다 — 파일명과 `end_time`의 날짜로 충분하고, 세션이 자정을 넘기면 오히려 어느 날짜를 가리키는지 헷갈린다):

```markdown
---
start_time: YYYY-MM-DD HH:MM:SS
end_time: YYYY-MM-DD HH:MM:SS
who: <5번에서 구한 값>
project: <project>
source_repo: <현재 작업 디렉토리의 절대 경로>
branch: <6번에서 구한 값>
tags: [관련 키워드]
digested: false
---

# <제목>

(정리한 내용)
```

9. `<WIKI_REPO_PATH>`에서 `git add log/<새 파일>` 후 `git commit`을 실행한다 (커밋 메시지: `log: <project> - <한 줄 요약>`). **push는 하지 않는다.**
10. 어떤 내용을 기록했는지 사용자에게 한두 문장으로 보고한다.

만약 이번 세션에 기록할 만한 내용이 없으면(단순 질의응답 등), 그렇다고 보고하고 아무 파일도 만들지 않는다.
