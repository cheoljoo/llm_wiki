---
start_time: 2026-07-16 14:17:12
end_time: 2026-07-16 14:17:12
who: charles.lee
project: llm_wiki
source_repo: /home/cheoljoo.lee/code/llm_wiki
branch: main
tags: [mcp-atlassian, claude-code, wiki-log, mcp, jira, confluence]
digested: false
---

# Claude Code에서 /wiki-log의 Jira/Confluence 단계가 매번 skip되던 문제

## 증상

다른 프로젝트에서 `/wiki-log`를 실행해도 항상 "mcp-atlassian 미연결" 경고만 뜨고
`## Jira 업데이트` / `## Confluence 업데이트` 절이 채워지지 않았다.

## 진단

- `mcp-atlassian` 패키지 자체는 `uvx mcp-atlassian --help` (exit 0)로 정상 설치 확인됨.
- 인증정보 파일 `~/.config/mcp-atlassian/.env`도 이미 존재(이전에 VS Code Copilot 연동용으로 생성).
- 하지만 등록 위치를 확인해보니 `~/.config/Code/User/settings.json`(VS Code Copilot Chat 전용
  MCP 설정)에만 등록돼 있었고, **Claude Code가 읽는 `~/.claude.json`의 최상위 `mcpServers` 키에는
  전혀 등록돼 있지 않았다.** VS Code Copilot과 Claude Code는 MCP 서버 설정을 공유하지 않는
  완전히 별개의 설정 파일을 쓴다 — 하나를 등록했다고 다른 하나에서도 보이는 게 아니다.
- `~/.claude.json`을 직접 읽어(`python3 -c "json.load(...)['mcpServers']"`) 키 자체가 없음을 확인,
  ToolSearch로 `jira_search` 등 관련 도구를 찾아도 매칭되지 않아 현재 세션에 전혀 로드되지 않은
  상태임을 재확인했다.

## 해결

기존 `~/.config/mcp-atlassian/.env`를 재사용해서 `~/.claude.json`의 `mcpServers`에
`mcp-atlassian`을 user-scope로 새로 등록했다 ([[mcp-atlassian]] 문서의 "user-scope로 등록할 것"
가이드를 Claude Code용으로 적용):

```json
"mcpServers": {
  "mcp-atlassian": {
    "type": "stdio",
    "command": "uvx",
    "args": ["--python=3.13", "mcp-atlassian", "--env-file", "/home/cheoljoo.lee/.config/mcp-atlassian/.env"]
  }
}
```

수정 전 `~/.claude.json`을 타임스탬프 백업(`~/.claude.json.bak.<timestamp>`)했고, 사용자에게
"Claude Code 자신의 startup config를 수정하는 작업"이라는 점을 명시하고 확인을 받은 뒤 진행했다
([[llm-wiki-log-schema]] 문서에 이미 기록된 self-modification 원칙과 일치).

부수적으로 `~/.config/mcp-atlassian/.env` 권한이 `664`로 풀려 있던 것을 발견해 `600`으로 조였다
(PAT 평문 포함 파일이므로).

## 남은 작업 / 확인 방법

MCP 서버 설정은 세션 시작 시에만 로드되므로, 이번 세션에서는 여전히 `jira_search` 등 도구가
보이지 않는다. **새 Claude Code 세션을 열어야 반영된다.** 다음 세션에서 `/wiki-log`를 실행해
`## Jira 업데이트`/`## Confluence 업데이트` 절이 채워지는지로 검증할 것.

## 일반화된 교훈

여러 클라이언트(VS Code Copilot Chat, Claude Code, 다른 IDE 등)에서 동일한 MCP 서버를 쓰려면
**클라이언트별로 각자의 설정 파일에 개별 등록해야 한다** — 한 클라이언트에 등록했다고 다른
클라이언트에서 자동으로 보이지 않는다. `mcp-atlassian`처럼 여러 프로젝트/도구에서 공유하는 MCP
서버를 새 클라이언트에 처음 연결할 때는, 인증정보(.env)는 재사용하되 클라이언트별 설정 파일
(Claude Code: `~/.claude.json`의 `mcpServers`, VS Code Copilot: `~/.config/Code/User/settings.json`의
`mcp.servers`)에 각각 등록되어 있는지 먼저 확인하는 것이 진단의 첫 단계다.

[[mcp-atlassian]], [[llm-wiki-log-schema]]
