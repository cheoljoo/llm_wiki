---
description: 등록된 모든 Todo(미완료+완료)를 보여준다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고). 이 커맨드는 읽기 전용이다 — 파일을 만들거나
수정하지 않는다.

`<WIKI_REPO_PATH>/todo/todos.md`의 모든 항목(`open` + `done`)을 보여준다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 다음과 같이 안내하고 **중단한다**:
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `<WIKI_REPO_PATH>/todo/todos.md`가 없거나 항목이 하나도 없으면 "등록된 Todo가 없습니다"라고
   보고하고 종료한다.
3. `$ARGUMENTS`가 있으면 키워드로 취급해, 항목 내용에 그 키워드가 (대소문자 무시) 포함된
   항목만 추가로 필터링한다.
4. 남은 항목 전체를 `registered_at` 오름차순으로 정렬해 다음 형식으로 나열한다 (완료 항목은
   체크 표시):
   ```
   - [ ] TD-<번호>: <내용> (등록: <registered_by>, <registered_at>)
   - [x] TD-<번호>: <내용> (등록: <registered_by>, <registered_at> / 완료: <completed_by>, <completed_at>)
   ```
5. 마지막에 "전체 N건 (미완료 M건 / 완료 K건)"을 한 줄 덧붙인다.
