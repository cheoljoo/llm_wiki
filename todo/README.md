# todo/

`log/`·`wiki/`와는 별개의 개인 Todo 관리 저장소입니다. 어느 프로젝트에서든 `/todo-register`로
등록하고, `/todo-list`·`/todo-done`·`/todo-all`·`/todo-complete`로 조회·완료 처리합니다.

이 폴더는 사람이 직접 편집하지 않습니다. `todo/todos.md` 하나만 있고, 아래 5개 슬래시 커맨드가
그 파일을 읽고 씁니다.

## `todo/todos.md` 항목 형식

```markdown
## TD-0001: <할 일 내용>
- status: open
- registered_by: cheoljoo.lee
- registered_at: 2026-07-23 10:15
- completed_by: -
- completed_at: -
- completed_via: -
```

- `TD-NNNN`: 4자리 0-padded 순번. 등록할 때 기존 항목 중 가장 큰 번호+1로 자동 부여.
- `status`: `open` 또는 `done`.
- `registered_by`/`completed_by`: `git config user.name`(없으면 `user.email` 또는 `whoami`)로 자동 채움 —
  여러 사람이 이 저장소를 쓸 수 있으므로 누가 등록/완료했는지 추적하기 위함.
- `completed_via`: 완료 처리가 어떤 경로로 이뤄졌는지 기록 (현재는 항상 `/todo-complete`).
  수동으로 파일을 직접 고친 경우와 구분하기 위한 필드.
- 완료 전에는 `completed_*` 필드를 `-`로 비워둔다.

## 커맨드

| 커맨드 | 용도 |
|---|---|
| `/todo-register <내용>` | 새 Todo 등록 (`status: open`으로 추가) |
| `/todo-list [키워드]` | 미완료(`open`)만 조회 |
| `/todo-done [키워드]` | 완료(`done`)만 조회 |
| `/todo-all [키워드]` | 전체 조회 |
| `/todo-complete <ID 또는 키워드>` | 해당 항목을 완료 처리 (`status`를 `done`으로 변경) |

각 커맨드는 `tooling/commands/todo-*.md`에 정의돼 있고, `make install`/`make update`로
`~/.claude/commands/`에 설치됩니다 (자세한 설치 방법은 저장소 루트 README.md 참고).

`/todo-register`, `/todo-complete`는 실행할 때마다 `todo/todos.md`를 갱신하고 커밋 하나를
남깁니다 (push는 하지 않음) — 등록/완료 시점이 git 히스토리로도 남도록 하기 위함.
