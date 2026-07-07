# Claude Code 커스텀 슬래시 커맨드

## `user-invocable: true` frontmatter 필수

`.claude/commands/*.md`나 프로젝트 내 다른 위치(`tooling/commands/*.md` 등)에 정의한 커스텀 슬래시 커맨드 파일은
`description`만 있어도 파일 자체는 유효하지만, `description`만으로는 사용자가 `/command-name`으로 직접 호출 가능한
커맨드로 노출되지 않을 수 있다. frontmatter에 `user-invocable: true`를 명시적으로 추가해야 사용자가 직접
호출 가능한 커맨드로 등록된다.

새 커스텀 커맨드를 추가할 때는 `description`만 쓰고 끝내지 말고 `user-invocable: true` 여부를 확인할 것.

[^llm_wiki]

[^llm_wiki]: `llm_wiki` 프로젝트(`/data01/cheoljoo.lee/code/llm_wiki`)의 `.claude/commands/wiki-digest.md`, `tooling/commands/wiki-log.md`에서 이 필드가 누락되어 있던 것을 발견하고 추가함.
