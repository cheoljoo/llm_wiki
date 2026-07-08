---
date: 2026-07-07
start_time: 17:01:52
end_time: 17:01:52
who: cheoljoo.lee
project: llm_wiki
source_repo: /data01/cheoljoo.lee/code/llm_wiki
branch: main
tags: [claude-code, llm_wiki, log-schema, multi-user]
digested: true
---

# `/wiki-digest` 흐름 확인 + log frontmatter에 `who`/`branch` 필드 추가

## `/wiki-digest` 흐름을 실제로 돌려서 확인함

미처리 log 1건(`digested: false`)을 대상으로 `/wiki-digest`를 실행해 정상 동작을 확인했다:
`log/*.md` 중 `digested: false`인 파일을 찾아 `wiki/<topic>.md`로 정제하고, 처리한 log의
`digested`를 `true`로 바꾸고, `wiki/README.md` 목차를 갱신한 뒤 `log`와 `wiki`만 골라
하나의 커밋으로 남긴다(`git add log wiki && git commit`, push는 안 함). 새 wiki 주제 문서에는
CLAUDE.md 규칙대로 맨 위 한 줄 요약과, 어느 프로젝트에서 나온 내용인지 각주를 남겨야 한다 —
처음 작성 시 이 두 가지를 빠뜨리기 쉬우니 주의.

## `log/` frontmatter에 `who`, `branch` 필드 추가

여러 사람이 같은 llm_wiki 저장소의 `log/`에 기록을 남기는 구조라, 기존 `project`/`source_repo`만으로는
"누가", "어떤 브랜치 작업 중에" 남긴 기록인지 알 수 없었다. `tooling/commands/wiki-log.md`에 다음을 추가:

- `who`: `git config user.name` → (비어있으면) `user.email` → (그것도 없으면) `whoami` 순으로 값을 구해 기록.
- `branch`: `git rev-parse --abbrev-ref HEAD`로 세션 당시 브랜치를 기록. git 저장소가 아니면 필드 자체를 생략.

두 값 모두 "추측하지 말고 반드시 명령을 실행해서 얻는다"는 기존 `start_time`/`end_time` 원칙과 동일하게 적용.

## 배운 점: 사용자별로 복사해서 쓰는 템플릿 파일은 갱신이 전파되지 않는다

`/wiki-log`는 `tooling/commands/wiki-log.md`를 각자 `~/.claude/commands/wiki-log.md`로 복사해서 쓰는 구조라서
(user-level 커맨드로 등록해야 어느 프로젝트에서든 호출 가능하기 때문), 원본 파일을 고쳐도 이미 설치된 사용자의
복사본에는 자동 반영되지 않는다. 이런 "clone-and-copy" 방식의 배포 구조를 쓸 때는, 원본을 바꾼 뒤 반드시
"재설치/재복사가 필요하다"는 점을 사용자에게 알려줘야 한다 — 그렇지 않으면 팀원마다 스키마가 조용히 갈라진다.
