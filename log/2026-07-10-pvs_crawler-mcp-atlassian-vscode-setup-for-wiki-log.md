---
start_time: 2026-07-10 03:34:57
end_time: 2026-07-10 16:52:34
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [mcp-atlassian, vscode-copilot, mcp, jira, confluence, wiki-log, settings]
digested: true
---

# VS Code Copilot에서 mcp-atlassian 연결 설정 (wiki-log Jira/Confluence 단계 활성화)

## 배경

`wiki-log` 스킬의 3번 단계(Jira/Confluence 변경사항 자동 반영)가 Claude Code에서는
`~/.claude/commands/wiki-log.md`로 동작하지만, VS Code Copilot에서는 `mcp-atlassian` MCP 도구가
연결되어야 동작한다. 이를 위해 VS Code 전역 MCP 서버 설정을 추가했다.

## 설치 현황

`mcp-atlassian` v0.21.1이 이미 `uvx` 경로로 설치되어 있었음 → 별도 설치 불필요.

## 설정 방법 (재사용 가능)

### 1. 인증 정보 파일 생성

```bash
mkdir -p ~/.config/mcp-atlassian
cat > ~/.config/mcp-atlassian/.env << 'EOF'
JIRA_URL=http://jira.lge.com/issue
JIRA_USERNAME=<username>@lge.com
JIRA_PERSONAL_TOKEN=<jira_pat>

CONFLUENCE_URL=http://collab.lge.com/main
CONFLUENCE_USERNAME=<username>@lge.com
CONFLUENCE_PERSONAL_TOKEN=<confluence_pat>

JIRA_SSL_VERIFY=false
CONFLUENCE_SSL_VERIFY=false
MCP_VERBOSE=true
EOF
```

PAT 발급 위치:
- Jira: `http://jira.lge.com` → 우측 상단 프로필 → Personal Access Tokens
- Confluence: `http://collab.lge.com/plugins/personalaccesstokens/usertokens.action`

### 2. VS Code 전역 settings.json에 MCP 서버 등록

파일: `~/.config/Code/User/settings.json`

```json
{
  "mcp": {
    "servers": {
      "mcp-atlassian": {
        "type": "stdio",
        "command": "uvx",
        "args": [
          "--python=3.13",
          "mcp-atlassian",
          "--env-file", "/home/<user>/.config/mcp-atlassian/.env"
        ]
      }
    }
  }
}
```

`--python=3.13` 옵션이 필요한 이유: `mcp-atlassian`이 Python 3.13 환경에서 정상 동작.

### 3. VS Code 재시작

`Developer: Reload Window` (Ctrl+Shift+P) 또는 VS Code 재시작 후
Copilot Chat 패널에서 MCP 서버 목록에 `mcp-atlassian`이 표시되면 연결 완료.

## 주의 사항

- `~/.config/mcp-atlassian/.env`는 PAT를 평문으로 포함하므로 권한 관리 필요:
  ```bash
  chmod 600 ~/.config/mcp-atlassian/.env
  ```
- VS Code의 MCP 설정은 **전역** (`~/.config/Code/User/settings.json`)에 두면 모든 워크스페이스에서 동작.
  프로젝트별로 격리하려면 워크스페이스 `.vscode/mcp.json` 사용.
- wiki-log 스킬의 3번 단계는 best-effort: MCP 미연결 시 Jira/Confluence 단계를 skip하고 git 기반 기록만 수행.
