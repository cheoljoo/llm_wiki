# mcp-atlassian (Jira/Confluence MCP 서버) 연동·사용 노하우

`mcp-atlassian`(uvx로 실행, Jira/Confluence Personal Access Token 사용)을 Claude Code에 연동하고
쓰면서 겪은 함정들.

## 연동: user-scope로 등록할 것

프로젝트 루트의 `.mcp.json`(project-scope, git으로 팀과 공유)에 토큰을 넣으면 그 저장소를 clone하는
모두에게 토큰이 노출된다. 특정 프로젝트에 종속되지 않고 여러 프로젝트를 넘나드는 용도(예:
`/wiki-log`)로 쓰고 싶다면 `~/.claude.json`의 최상위 `mcpServers` 키(user-scope)에 등록하는 게 맞다
— 이 파일은 git 저장소가 아니고 권한도 사용자 전용(600)이라 상대적으로 안전하다.

주의할 점:

- **상태 파일을 직접 편집할 때는 백업 먼저**: `~/.claude.json`은 캐시/세션 상태를 포함한 복잡한
  JSON이라, 수정 전 타임스탬프를 붙여 복사본을 남겨두는 게 안전하다
  (`cp ~/.claude.json ~/.claude.json.bak.$(date +%Y%m%d%H%M%S)`).
- **auto-mode 권한 분류기가 이 종류의 수정을 자동 차단한다**: "이 설정을 이용합니다" 정도의 맥락
  제공만으로는 Claude Code 자신의 startup config에 라이브 토큰이 든 MCP 서버를 추가하는 걸
  거부당한다(`[Self-Modification]` 사유). 사용자가 "MCP 서버 연결을 먼저 하고..."처럼 명시적으로
  지시한 뒤에야 통과된다 — 자기 자신의 설정 파일을 수정하는 작업은 맥락만으로 추론하지 말고 명시적
  확인을 받을 것.
- **채팅에 붙여넣은 토큰은 유출로 간주**: Personal Access Token을 대화 메시지에 그대로 붙여넣으면
  대화 기록에 평문으로 남으므로, 설정이 끝나면 재발급(rotate)하는 게 안전하다.
- **반영에는 새 세션이 필요**: `mcpServers`를 추가해도 이미 시작된 세션에는 반영되지 않는다. 같은
  세션 안에서 재시도해도 새로 추가한 MCP 도구가 안 보이며, 완전히 새 세션/윈도우를 열어야 로드된다.

## Jira 조회 팁

- 담당 이슈를 최근 순으로 빠르게 보려면: `jira_search`에
  `assignee = currentUser() ORDER BY updated DESC` JQL. `fields`를 필요한 것만 좁혀서
  요청하면(`key,summary,status,priority,updated,issuetype`) 응답 크기도 작아진다.
- `jira_get_all_projects`는 필터 없이 부르면 접근 가능한 전체 프로젝트를 반환하므로, 프로젝트 수가
  많은 인스턴스에서는 응답이 도구 호출 최대 토큰 한도(약 100만 자)를 넘길 수 있다. 도구가 지원하는
  `JIRA_PROJECTS_FILTER` 환경변수로 서버 설정에서 필터링해두거나, 단순 연결 확인 목적이라면
  `jira_search`에 좁은 JQL을 주는 등 더 가벼운 조회를 쓰는 게 낫다.

## VS Code Copilot에서 연동하려면 전역 MCP 서버 설정이 별도로 필요

`/wiki-log` 스킬의 Jira/Confluence 자동 반영 단계는 Claude Code에서는
`~/.claude/commands/wiki-log.md`로 동작하지만, VS Code Copilot에서는 `mcp-atlassian` MCP 서버가
VS Code 쪽에 별도로 연결돼 있어야 같은 단계가 동작한다. `uvx`로 이미 설치돼 있다면(버전 확인만
하면 됨) 추가 설치 없이 설정만 하면 된다.

1. 인증 정보를 `~/.config/mcp-atlassian/.env`에 저장 (`JIRA_URL`, `JIRA_PERSONAL_TOKEN`,
   `CONFLUENCE_URL`, `CONFLUENCE_PERSONAL_TOKEN`, `JIRA_SSL_VERIFY=false` 등). PAT는 평문으로
   들어가므로 `chmod 600`으로 권한을 좁혀둘 것.
2. VS Code **전역** `settings.json`(`~/.config/Code/User/settings.json`)의 `mcp.servers`에 등록:
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
   `--python=3.13`이 필요한 이유: `mcp-atlassian`이 Python 3.13 환경에서 정상 동작하기 때문.
   전역 설정에 두면 모든 워크스페이스에서 동작하고, 프로젝트별로 격리하려면 워크스페이스
   `.vscode/mcp.json`을 대신 쓰면 된다.
3. `Developer: Reload Window` 또는 VS Code 재시작 후 Copilot Chat의 MCP 서버 목록에
   `mcp-atlassian`이 뜨면 연결 완료. MCP가 연결 안 돼 있어도 `/wiki-log`의 Jira/Confluence 단계는
   best-effort로 skip되고 git 기반 기록은 그대로 진행된다([[llm-wiki-log-schema]] 참고).

[^pvs_crawler]

## Confluence 조회 시 CQL 날짜 필터를 곧이곧대로 믿지 말 것

`confluence_search`에 `contributor = currentUser() AND lastModified > "startOfWeek()"`와
`contributor = currentUser() AND lastModified > "2026-07-05 23:01"`처럼 서로 다른 시각 조건을
줬는데도 완전히 동일한 결과가 반환된 사례가 있었다. CQL의 시간 비교 절이 파싱되지 않고, 도구
설명에 나온 "simple query는 siteSearch로, 지원 안 되면 text search로 폴백"하는 경로를 타면서 날짜
조건이 무시되는 것으로 의심된다. 이 도구로 "최근 N일 이내 수정된 페이지"를 걸러내려는 조회를 할 때는,
날짜 조건을 바꿔가며 실제로 결과가 달라지는지 먼저 검증하고, 안 달라지면 그 결과를 신뢰하지 말 것
(CQL 날짜 리터럴 포맷을 `yyyy/MM/dd` 등으로 바꿔보는 것도 시도해볼 만하다).

[[llm-wiki-log-schema]] — `/wiki-log`가 이 도구를 어떻게 best-effort로 통합했는지.

[^llm_wiki]

[^llm_wiki]: `llm_wiki` 프로젝트(`/data01/cheoljoo.lee/code/llm_wiki`) 자체 세션에서 mcp-atlassian을
  연동하고 써보며 확인한 내용.

[^pvs_crawler]: `pvs_crawler` 프로젝트(`/home/cheoljoo.lee/code/pvs_crawler`) 세션에서 VS Code
  Copilot용 mcp-atlassian 전역 설정을 구성하며 확인한 내용. [[pvs-crawler-sage-llm-pipeline]]
