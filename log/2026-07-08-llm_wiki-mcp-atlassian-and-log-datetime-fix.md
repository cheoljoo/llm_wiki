---
start_time: 2026-07-08 22:33:27
end_time: 2026-07-08 22:33:27
who: cheoljoo.lee
project: llm_wiki
source_repo: /data01/cheoljoo.lee/code/llm_wiki
branch: main
tags: [claude-code, mcp, atlassian, jira, confluence, log-schema, security]
digested: true
---

# log frontmatter의 start_time/end_time 날짜 누락 버그 수정 + mcp-atlassian 연동

## `start_time`/`end_time`이 자정을 넘기면 날짜를 알 수 없던 버그

기존 스키마는 `date: YYYY-MM-DD`(=end_time 기준 날짜) 하나와, `start_time`/`end_time`을 `HH:MM:SS`만 저장했다.
세션이 자정을 넘기면(`start_time: 17:12:22`, `end_time: 09:29:51` 같은 실제 사례) start_time이 전날인지
당일인지 값만 봐서는 알 수 없었다. 수정: `start_time`/`end_time` 모두 `YYYY-MM-DD HH:MM:SS`로 날짜를 포함해서
기록하고, 중복이자 혼동의 원인이었던 단일 `date` 필드는 제거했다 (파일명의 `YYYY-MM-DD`만으로 충분).
기존에 이미 만들어진 로그 파일은 append-only 원칙(`digested` 필드만 수정 가능)에 따라 그대로 두고, 새 스키마는
이후 생성되는 로그부터 적용된다.

## Jira/Confluence를 위한 `mcp-atlassian` MCP 서버를 user-scope로 연동

`mcp-atlassian` (uvx로 실행, Jira/Confluence Personal Access Token 사용)을 Claude Code에 연동할 때 얻은 노하우:

- **저장 위치**: 프로젝트 루트의 `.mcp.json`(project-scope, git으로 팀과 공유되는 파일)에 토큰을 넣으면 그 저장소를
  clone하는 모두에게 토큰이 노출된다. 특정 프로젝트에 종속되지 않고 모든 세션에서 쓰고 싶다면(예: `/wiki-log`처럼
  프로젝트를 넘나드는 커맨드), `~/.claude.json`의 최상위 `mcpServers` 키(user-scope)에 등록하는 게 맞다. 이 파일은
  git 저장소가 아니고 권한도 사용자 전용(600)이라 상대적으로 안전하다.
- **상태 파일을 직접 편집할 때는 백업 먼저**: `~/.claude.json`은 캐시/세션 상태를 포함한 33KB짜리 복잡한 JSON이라,
  수정 전 타임스탬프를 붙여 복사본을 남겨두는 게 안전하다 (`cp ~/.claude.json ~/.claude.json.bak.$(date +%Y%m%d%H%M%S)`).
- **auto-mode 권한 분류기가 이 종류의 수정을 자동 차단함**: "이 설정을 이용합니다" 정도의 맥락 제공만으로는
  Claude Code 자신의 startup config(`~/.claude.json`)에 라이브 토큰이 든 MCP 서버를 쓰는 걸 거부당했다
  (`[Self-Modification]` 사유). 사용자가 "MCP 서버 연결을 먼저 하고..."처럼 명시적으로 지시한 뒤에야 통과됐다.
  → 자기 자신의 설정 파일을 수정하는 작업은 맥락만으로 추론하지 말고 명시적 확인을 받을 것.
- **채팅에 붙여넣은 토큰은 유출로 간주**: Personal Access Token을 대화 메시지에 그대로 붙여넣으면 대화 기록에
  평문으로 남으므로, 설정이 끝나면 재발급(rotate)하는 게 안전하다.
- **반영에는 새 세션이 필요**: `~/.claude.json`에 `mcpServers`를 추가해도 이미 시작된 세션에는 반영되지 않는다.
  같은 세션 안에서 `/wiki-log`를 다시 실행해봐도 새로 추가한 MCP 도구가 안 보이는 걸로 확인함 — 완전히 새
  세션/윈도우를 열어야 로드된다.

## `/wiki-log`에 Jira/Confluence 반영 여부는 "연결 + 명시적 지시" 둘 다 필요

MCP 서버가 연결되어 있어도, 커맨드 프롬프트(`tooling/commands/wiki-log.md`)에 "Jira/Confluence를 조회하라"는
지시가 없으면 자동으로 반영되지 않는다. 커맨드에 "1.5. mcp-atlassian이 연결되어 있으면 관련 이슈/페이지를
조회해서 반영하되, 연결 안 돼 있거나 조회 실패해도 무시하고 git 기반 기록은 그대로 진행한다"는 best-effort
단계를 추가해서 해결했다. 외부 MCP 도구를 선택적으로 쓰는 워크플로를 설계할 때, "있으면 쓰고 없으면 핵심
경로는 그대로 진행"하는 패턴이 안전하다 — 필수로 만들면 그 도구가 죽었을 때 전체 흐름이 막힌다.
