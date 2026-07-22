---
description: 등록된 Todo 항목을 완료 처리한다 (todo/todos.md의 status를 done으로 변경)
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

`$ARGUMENTS`로 받은 ID(예: `TD-0003`) 또는 항목을 특정할 수 있는 키워드로,
`<WIKI_REPO_PATH>/todo/todos.md`의 해당 항목을 완료 처리한다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 다음과 같이 안내하고 **중단한다**:
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `$ARGUMENTS`가 비어있으면 "완료 처리할 항목의 ID나 키워드를 알려주세요"라고 묻고 **중단한다**
   (추측해서 아무 항목이나 처리하지 않는다).
3. `<WIKI_REPO_PATH>/todo/todos.md`를 읽는다. `$ARGUMENTS`가 `TD-[0-9]{4}` 형식이면 해당 ID의
   `## TD-...` 섹션을 찾는다. 그렇지 않으면 항목 제목 텍스트에 `$ARGUMENTS`가 (대소문자 무시)
   포함된 섹션을 찾는다.
4. 일치하는 항목이 없으면 "일치하는 Todo 항목을 찾지 못했습니다"라고 보고하고 **중단한다**.
5. 일치하는 항목이 여러 개면 후보 목록(ID + 내용)을 보여주고 어느 것인지 사용자에게 되물은 뒤
   **중단한다** (추측해서 처리하지 않는다).
6. 찾은 항목이 이미 `status: done`이면 "이미 완료 처리된 항목입니다 (완료: <completed_at>)"라고
   보고하고 **중단한다** (중복 처리 방지).
7. 해당 항목 블록만 다음과 같이 갱신한다 (다른 항목이나 다른 필드는 건드리지 않는다):
   - `status: open` → `status: done`
   - `completed_by: -` → `git -C <WIKI_REPO_PATH> config user.name` 결과 (없으면 `user.email`,
     그것도 없으면 `whoami`)
   - `completed_at: -` → `date '+%Y-%m-%d %H:%M'`로 구한 현재 로컬 시각
   - `completed_via: -` → `/todo-complete`
8. `git -C <WIKI_REPO_PATH> add todo/todos.md` 후
   `git -C <WIKI_REPO_PATH> commit -m "todo: complete TD-<번호>"`로 커밋한다.
   **push는 하지 않는다.**
9. "TD-<번호> 완료 처리: <내용>"이라고 짧게 보고한다.
