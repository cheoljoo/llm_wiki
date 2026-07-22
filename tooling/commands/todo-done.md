---
description: 완료 처리된(done) Todo 목록을 보여준다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고). 이 커맨드는 읽기 전용이다 — 파일을 만들거나
수정하지 않는다.

`<WIKI_REPO_PATH>/todo/todos.md`에서 `status: done`인 항목만 보여준다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 다음과 같이 안내하고 **중단한다**:
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `<WIKI_REPO_PATH>/todo/todos.md`가 없거나 `status: done`인 항목이 하나도 없으면
   "완료된 Todo가 없습니다"라고 보고하고 종료한다.
3. `$ARGUMENTS`가 있으면 키워드로 취급해, 항목 내용에 그 키워드가 (대소문자 무시) 포함된
   항목만 추가로 필터링한다.
4. 남은 `status: done` 항목들을 `completed_at` 내림차순(최근 완료 순)으로 정렬해 다음 형식으로
   나열한다:
   ```
   - TD-<번호>: <내용> (등록: <registered_by> <registered_at> / 완료: <completed_by> <completed_at>, <completed_via>)
   ```
5. 마지막에 "완료 N건"을 한 줄 덧붙인다.
