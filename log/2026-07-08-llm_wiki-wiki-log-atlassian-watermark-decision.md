---
start_time: 2026-07-08 23:01:17
end_time: 2026-07-08 23:01:17
who: cheoljoo.lee
project: llm_wiki
source_repo: /data01/cheoljoo.lee/code/llm_wiki
branch: main
tags: [wiki-log, mcp-atlassian, jira, confluence, design-decision]
digested: true
---

# wiki-log의 Jira/Confluence 조회를 "세션 관련성" 필터에서 "워터마크 기반 diff"로 변경

`tooling/commands/wiki-log.md`(및 `~/.claude/commands/wiki-log.md`)의 1.5번(현재는 3번) 단계를 수정했다.

## 문제

기존에는 "이 세션/프로젝트와 관련된" Jira 이슈·Confluence 페이지만 골라서 로그에 반영했는데,
실제로 필요한 건 프로젝트 관련성과 무관하게 "지난 `/wiki-log` 실행 이후 새로 생긴 변경사항" 자체를
빠짐없이 추적하는 것이었다.

## 변경 내용

- `~/.config/llm_wiki/jira_last_checked`, `~/.config/llm_wiki/confluence_last_checked`에
  마지막 확인 시각을 워터마크로 저장.
- 다음 실행 시 그 시각 이후 갱신된 항목만 조회 (`assignee = currentUser() AND updated > "<워터마크>"` JQL,
  `contributor = currentUser() AND lastModified > "<워터마크>"` CQL).
- 워터마크 파일이 없으면(최초 실행) `end_time` 기준 3일 전을 기본값으로 사용.
- 조회에 성공하면 결과가 없어도 워터마크를 갱신해 다음 실행이 같은 구간을 중복 조회하지 않게 함.
- 여전히 best-effort — mcp-atlassian 미연결/조회 실패 시 무시하고 git 기반 기록은 그대로 진행.

## 알려진 한계: 여러 시스템에서 쓸 때의 중복

워터마크 파일은 `~/.config/llm_wiki/` 아래 시스템별 로컬 파일이라 git으로 동기화되지 않는다.
따라서 서로 다른 시스템에서 각자 `/wiki-log`를 실행하면 워터마크가 독립적으로 진행되어, 같은
Jira/Confluence 변경사항이 여러 시스템의 log에 중복 기록될 수 있다. 중복 범위는 "최초 실행 3일"에
국한되지 않고, 두 시스템 워터마크 간의 격차만큼(예: 한 시스템을 2주 안 쓰면 2주치) 커질 수 있다.

이 문제에 대한 해결책으로 (1) 그냥 둔다, (2) 워터마크를 `<WIKI_REPO_PATH>/log/`에 커밋해 push/pull로
동기화(단, 동시 커밋 시 merge conflict 가능성 있고 push 전까지는 여전히 중복), (3) 이슈 키/페이지 ID
기반으로 기존 log/*.md를 grep해서 중복 제거(정확하지만 매번 log 전체를 훑어야 해서 느림) 세 가지를
검토했고, **(1) 그냥 둔다**로 결정했다 — 중복은 소량이고 `/wiki-digest`가 `wiki/`로 정제하는 과정에서
사람/LLM이 걸러낼 수 있어, 지금 시점에 동기화 복잡도를 추가할 가치가 없다고 판단.
이 워터마크 로직을 다시 만지게 되면 (2)/(3)을 재검토할 것.

## Confluence CQL 날짜 필터가 안 먹는 것으로 보임

`confluence_search`에 `contributor = currentUser() AND lastModified > "startOfWeek()"`와
`contributor = currentUser() AND lastModified > "2026-07-05 23:01"`처럼 서로 다른 시각 조건을 줬는데도
완전히 동일한 5개 결과(Honda SVN, 98.Seminar, gerrit 계정 취합 등 llm_wiki와 무관한 페이지)가 반환됐다.
CQL의 시간 비교 절이 파싱되지 않고 도구 설명에 나온 "siteSearch 폴백"으로 빠지는 것으로 의심된다 —
신뢰할 수 없는 결과라 이번 로그에는 Confluence 업데이트를 반영하지 않았다. 다음에 이 부분을 쓸 때는
CQL 날짜 리터럴 포맷(`yyyy/MM/dd` 등)을 바꿔가며 실제로 필터링되는지 먼저 검증해볼 것.

## Jira 업데이트 (최초 실행, 2026-07-05 23:01 이후 기준)

담당 이슈 중 최근 갱신된 것 (전부 llm_wiki와 무관 — 워터마크 최초 실행 시 3일치를 그대로 반영하는 설계에 따른 것):

- AGILEDEV-1054 [pvs_crawler][sage][VDA] LLM_SUMMARY가 빈 것을 채워라 (Resolved, 07-06 18:12)
- AGILEDEV-1051 [ticketsage][VDA] gerrit에 CCR list 추가 (Resolved, 07-06 18:12)
- AGILEDEV-1044 [pvs_crawler][sage] LLM SUMMARY 커밋 요약 추가 (Resolved, 07-06 18:12)
- AGILEDEV-1043 [pvs_crawler][sage] COMMIT LLM: check-and-fix 기능 추가 (Resolved, 07-06 18:12)
- AGILEDEV-279 adu-기타 (Open, 07-08 10:24)
- AGILEDEV-1057 LLM Wiki (In Progress, 07-08 10:25) — 이 저장소를 추적하는 이슈
- AGILEDEV-1053 [pvs_crawler][VDA][sage] LLM_SUMMARY prompt version 업데이트 + ECHO 처리 (In Progress, 07-08 10:25)
- AGILEDEV-1060 hermes 사용 해보기 (In Progress, 07-08 10:27)
- AGILEDEV-1059 uv run python getPmsExcel.py Return code: 3221225477 (Resolved, 07-08 10:27)
- AGILEDEV-1056 Connectwide commit/CCR 데이터 수집 (Resolved, 07-08 12:43)
