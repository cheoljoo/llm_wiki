---
date: 2026-07-07
start_time: 17:12:22
end_time: 09:29:51
project: llm_wiki
source_repo: /data01/cheoljoo.lee/code/llm_wiki
tags: [claude-code, slash-commands, frontmatter]
digested: false
---

# 커스텀 슬래시 커맨드에는 `user-invocable: true` frontmatter가 필요

`.claude/commands/*.md` (또는 `tooling/commands/*.md`처럼 별도 위치의) 커스텀 슬래시 커맨드 정의 파일은
`description`만으로는 사용자가 `/command-name`으로 직접 호출할 수 있는 커맨드로 노출되지 않을 수 있다.
frontmatter에 `user-invocable: true`를 명시적으로 추가해야 사용자가 직접 호출 가능한 커맨드로 등록된다.

이번 세션에서 `wiki-digest.md`와 `wiki-log.md` 두 커맨드 파일 모두에 이 필드가 빠져 있어 추가했다.

향후 이 저장소나 다른 프로젝트에서 새 커스텀 커맨드를 추가할 때, description만 쓰고 끝내지 말고
`user-invocable: true` 여부를 확인할 것.
