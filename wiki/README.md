# wiki/ 목차

`/wiki-digest`가 `log/`의 내용을 정제해서 만드는 주제별 문서 목록입니다.

**찾아볼 때는 이 파일 전체를 읽지 말고, 관련 키워드로 grep해서 일치하는 줄만 확인하세요**
(예: `grep -i docker wiki/README.md`). 주제가 늘어나도 grep 비용은 거의 그대로라, 통째로 읽는
것보다 훨씬 확장성이 좋습니다. 아래 카테고리 구분도 grep 키워드를 좁히는 데 도움이 됩니다.

## Claude Code / llm_wiki 자체

- [claude-code-slash-commands](claude-code-slash-commands.md) — 커스텀 슬래시 커맨드 작성 시 주의할 frontmatter 필드
- [claude-code-agent-permissions](claude-code-agent-permissions.md) — auto-mode가 제3자에게 영향 주는 모호한 승인을 자동 차단하는 사례
- [llm-wiki-log-schema](llm-wiki-log-schema.md) — llm_wiki 자체 log/ 스키마와 /wiki-log 설계 변경 이력

## MCP / 외부 도구 연동

- [mcp-atlassian](mcp-atlassian.md) — Jira/Confluence MCP 서버(mcp-atlassian) 연동·조회 시 함정

## 에이전트 프레임워크 설계 패턴

- [agent-framework-error-handling](agent-framework-error-handling.md) — 커스텀 재시도/폴백 로직 전에 프레임워크 내장 기능부터 확인
- [openrouter-model-selection](openrouter-model-selection.md) — OpenRouter 무료/tool-calling 지원 모델 고르는 기준
- [pairing-otp-security-pattern](pairing-otp-security-pattern.md) — pairing/OTP 승인 시스템의 fingerprint-vs-secret 분리 패턴

## 인프라 운영 (Docker / Shell)

- [docker-compose-ops](docker-compose-ops.md) — 같은 이미지를 쓰는 다중 서비스 docker-compose 운영 시 체크포인트
- [shell-cli-gotchas](shell-cli-gotchas.md) — 아주 긴 경로를 인자로 주면 CLI가 알 수 없는 에러를 낼 수 있음

## 프로젝트별 노트

- [hermes-agent-ops](hermes-agent-ops.md) — Hermes 에이전트(Telegram pairing, Kanban dispatcher) 운영 노트

<!-- /wiki-digest가 새 주제를 추가할 때마다, 맞는 카테고리(## 섹션) 아래에 항목을 추가합니다.
어느 카테고리에도 안 맞으면 새 ## 섹션을 만들어도 됩니다.
예: - [retry-patterns](retry-patterns.md) — 재시도/백오프 전략 -->
