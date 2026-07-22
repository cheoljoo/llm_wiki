---
description: 특정 Todo 항목에 메모(진행 결과, 회의록, 생각 정리 등)를 추가한다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

`$ARGUMENTS`의 맨 앞 ID(예: `TD-0003`)로 지정한 Todo 항목에, 그 뒤 내용을 메모로 append한다.
완료 여부와 무관하게 어떤 항목에도 메모를 남길 수 있다 (예: 방문 후 회의록, 작업하며 떠오른 생각,
나중에 참고할 결론). 메모는 여러 번 쌓을 수 있고 기존 메모는 지우거나 고치지 않는다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 다음과 같이 안내하고 **중단한다**:
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `$ARGUMENTS`가 비어있으면 "메모를 남길 항목 ID와 메모 내용을 알려주세요
   (예: `/todo-memo TD-0003 포트폴리오 초안 방향: ...`)"라고 안내하고 **중단한다**.
3. `$ARGUMENTS`의 맨 앞 토큰이 `TD-[0-9]{4}` 형식이면 그것을 ID로 삼고, 나머지(앞뒤 공백 제거)를
   메모 내용으로 쓴다.
4. 맨 앞 토큰이 ID 형식이 아니면 ID를 추측하지 않는다. `<WIKI_REPO_PATH>/todo/todos.md`에서
   항목 제목에 `$ARGUMENTS` 중 일부 단어가 (대소문자 무시) 포함되는 후보를 찾아 보여주고,
   어떤 항목(ID)에 남길 메모인지 되물은 뒤 **중단한다** (추측해서 아무 항목에나 붙이지 않는다).
5. `<WIKI_REPO_PATH>/todo/todos.md`에서 해당 ID의 `## TD-...` 섹션을 찾는다. 없으면
   "TD-<번호> 항목을 찾지 못했습니다"라고 보고하고 **중단한다**.
6. 메모 내용도 비어있으면(ID만 주어졌으면) "남길 메모 내용을 알려주세요"라고 묻고 **중단한다**.
7. 작성자는 `git -C <WIKI_REPO_PATH> config user.name` (없으면 `user.email`, 그것도 없으면
   `whoami`), 시각은 `date '+%Y-%m-%d %H:%M'`로 구한다.
8. 해당 항목 섹션의 맨 끝(다음 `## TD-...` 항목이 시작되기 직전, 또는 파일 끝)에 다음을 추가한다
   (그 항목의 다른 필드나 다른 항목은 건드리지 않는다):
   ```

   ### memo (<시각>, <작성자>)
   <메모 내용>
   ```
   같은 항목에 이미 memo가 있으면 지우거나 고치지 않고 그 아래에 이어서 추가한다.
9. `git -C <WIKI_REPO_PATH> add todo/todos.md` 후
   `git -C <WIKI_REPO_PATH> commit -m "todo: memo on TD-<번호>"`로 커밋 하나를 남긴다.
   **push는 하지 않는다.**
10. "TD-<번호>에 메모를 추가했습니다"라고 짧게 보고한다.
