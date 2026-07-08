---
start_time: 2026-07-08 22:41:31
end_time: 2026-07-08 22:41:31
who: cheoljoo.lee
project: llm_wiki
source_repo: /data01/cheoljoo.lee/code/llm_wiki
branch: main
tags: [mcp-atlassian, jira, confluence]
digested: true
---

# mcp-atlassian로 최근 Jira 이슈 조회 & llm_wiki 프로젝트의 Jira 추적 이슈

- 내가 담당한 최근 Jira 이슈를 빠르게 볼 때는 `jira_search`에
  `assignee = currentUser() ORDER BY updated DESC` JQL을 쓰면 된다. `fields`를 필요한 것만
  좁혀서 요청하면(`key,summary,status,priority,updated,issuetype`) 응답 크기도 작아진다.
- 이 llm_wiki 프로젝트 작업은 Jira **AGILEDEV-1057 "LLM Wiki"** (Story, In Progress)로 추적되고
  있음 — 관련 작업 시 이 이슈에 코멘트/상태 갱신을 남기면 연속성 추적에 도움이 된다.
- Confluence는 `confluence_search`에 CQL `contributor = currentUser() AND lastModified > startOfWeek()`로
  최근 기여한 페이지를 확인했으나, 이번 주 llm_wiki와 직접 관련된 페이지는 없었음 (관련 없는 페이지는 기록에서 제외).
