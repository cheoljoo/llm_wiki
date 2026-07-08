---
date: 2026-07-08
start_time: 22:37:29
end_time: 22:37:29
who: cheoljoo.lee
project: llm_wiki
source_repo: /data01/cheoljoo.lee/code/llm_wiki
branch: main
tags: [mcp-atlassian, jira, troubleshooting]
digested: true
---

# mcp-atlassian: jira_get_all_projects 응답 폭주 주의

mcp-atlassian 서버가 정상 동작하는지 확인하기 위해 `jira_get_all_projects`를 호출했더니,
결과가 1,007,522자로 도구 호출 최대 토큰 한도를 초과해 별도 파일로 저장되었다.

- `jira_get_all_projects`는 필터 없이 부르면 접근 가능한 전체 프로젝트를 반환하므로,
  프로젝트 수가 많은 인스턴스에서는 응답이 매우 커질 수 있다.
- 도구 설명에 `JIRA_PROJECTS_FILTER` 환경변수가 설정되어 있으면 해당 프로젝트만 반환한다고 되어 있음 — 반복적으로
  전체 목록이 필요 없다면 서버 설정에서 이 필터를 지정해두는 것이 좋다.
- 단순히 서버 연결/인증 상태만 확인하고 싶다면, 더 가벼운 도구(예: 특정 프로젝트 하나만 조회하거나
  `jira_search`에 좁은 JQL을 주는 방식)를 쓰는 것이 낫다.
