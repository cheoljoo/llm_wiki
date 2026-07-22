---
description: 새 Todo 항목을 중앙 저장소(todo/todos.md)에 등록한다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

`$ARGUMENTS`로 받은 내용을 새 Todo 항목으로 `<WIKI_REPO_PATH>/todo/todos.md`에 등록한다.
항목 형식은 `<WIKI_REPO_PATH>/todo/README.md` 참고.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 다음과 같이 안내하고 **중단한다**:
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `$ARGUMENTS`가 비어있으면 등록할 할 일 내용을 물어보고 **중단한다** (추측해서 등록하지 않는다).
3. `<WIKI_REPO_PATH>/todo/todos.md`를 읽어 기존 `## TD-[0-9]{4}` 항목 중 가장 큰 번호를 찾고,
   그 다음 번호를 4자리 0-padding으로 새 ID로 쓴다 (기존 항목이 없으면 `TD-0001`부터 시작).
4. 등록자는 `git -C <WIKI_REPO_PATH> config user.name` 결과를 쓴다 (비어있으면 `user.email`,
   그것도 없으면 `whoami`).
5. 등록 시각은 `date '+%Y-%m-%d %H:%M'`로 구한 현재 로컬 시각을 쓴다.
6. 다음 블록을 `<WIKI_REPO_PATH>/todo/todos.md` 맨 끝에 추가한다 (기존 내용은 건드리지 않는다):
   ```
   ## TD-<번호>: <$ARGUMENTS 내용>
   - status: open
   - registered_by: <등록자>
   - registered_at: <등록 시각>
   - completed_by: -
   - completed_at: -
   - completed_via: -
   ```
7. `git -C <WIKI_REPO_PATH> add todo/todos.md` 후
   `git -C <WIKI_REPO_PATH> commit -m "todo: register TD-<번호>"`로 커밋 하나를 남긴다.
   **push는 하지 않는다.**
8. "TD-<번호> 등록 완료: <내용>"이라고 짧게 보고한다.
