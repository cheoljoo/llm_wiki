# Claude Code 커스텀 슬래시 커맨드

커스텀 슬래시 커맨드 파일에는 `user-invocable: true` frontmatter가 있어야 사용자가 직접 호출할 수 있다.

## `user-invocable: true` frontmatter 필수

`.claude/commands/*.md`나 프로젝트 내 다른 위치(`tooling/commands/*.md` 등)에 정의한 커스텀 슬래시 커맨드 파일은
`description`만 있어도 파일 자체는 유효하지만, `description`만으로는 사용자가 `/command-name`으로 직접 호출 가능한
커맨드로 노출되지 않을 수 있다. frontmatter에 `user-invocable: true`를 명시적으로 추가해야 사용자가 직접
호출 가능한 커맨드로 등록된다.

새 커스텀 커맨드를 추가할 때는 `description`만 쓰고 끝내지 말고 `user-invocable: true` 여부를 확인할 것.

## VS Code Copilot 스킬 등록 패턴

Claude Code의 `~/.claude/commands/` 커맨드를 VS Code Copilot에서도 쓰려면 별도 등록이 필요하다.

**파일 구조**:
```
.github/skills/<name>/SKILL.md      ← 스킬 정의 (VS Code frontmatter 형식)
.github/vscode-skills/<name>.md     → symlink (.github/skills/<name>/SKILL.md 를 가리킴)
.vscode/settings.json               ← github.copilot.chat.codeGeneration.instructions 에 경로 추가
```

**핵심 포인트**:
- `.vscode/settings.json`의 `github.copilot.chat.codeGeneration.instructions` 배열에 파일 경로를
  등록하면 대화 중 description 키워드 매칭으로 자동 로드된다.
- symlink를 활용하면 `SKILL.md` 파일 하나로 Gemini CLI / VS Code Copilot 양쪽을 동시에 관리할 수
  있다(소스 하나, 참조 두 개).
- Claude Code용 원본(`tooling/commands/wiki-log.md`)을 수정하면 SKILL.md도 재동기화해야 한다
  — "clone-and-copy" 구조와 같은 문제([[llm-wiki-log-schema]] 참고).

[^llm_wiki]
[^pvs_crawler]: `pvs_crawler` 프로젝트(`/home/cheoljoo.lee/code/pvs_crawler`) 세션 중 VS Code Copilot 스킬 등록을 설정하면서 정리.

[^llm_wiki]: `llm_wiki` 프로젝트(`/data01/cheoljoo.lee/code/llm_wiki`)의 `.claude/commands/wiki-digest.md`, `tooling/commands/wiki-log.md`에서 이 필드가 누락되어 있던 것을 발견하고 추가함.
