---
description: 아직 완료되지 않은(open) Todo 목록을 보여준다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고). `<WIKI_REPO_PATH>/todo/todos.md`는 읽기만
한다 — 수정하지 않는다 (조회 결과를 `todo/output/`에 저장하는 것은 예외로, 그 파일은 git에 커밋하지
않는 결과 덤프일 뿐이다).

`<WIKI_REPO_PATH>/todo/todos.md`에서 `status: open`인 항목만 보여준다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 다음과 같이 안내하고 **중단한다**:
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `<WIKI_REPO_PATH>/todo/todos.md`가 없거나 `status: open`인 항목이 하나도 없으면
   "미완료 Todo가 없습니다"라고 보고하고 종료한다.
3. `$ARGUMENTS`가 있으면 키워드로 취급해, 항목 내용에 그 키워드가 (대소문자 무시) 포함된
   항목만 추가로 필터링한다.
4. 남은 `status: open` 항목들을 다음 순서로 정렬한다: (1) `due`가 있는 항목을 마감일 오름차순
   (임박한/지난 순부터), (2) 그 다음 `due`가 없는(`-`) 항목들을 `registered_at` 오름차순으로.
5. `date '+%Y-%m-%d'`로 오늘 날짜를 구해, `due`가 오늘보다 이전인 항목에는 경고를 붙인다.
   각 항목을 다음 형식으로 나열한다:
   ```
   - TD-<번호>: <내용> (마감: <due>, 등록: <registered_by>, <registered_at>)
   - TD-<번호>: <내용> (마감: <due> ⚠ 기한 경과, 등록: <registered_by>, <registered_at>)
   - TD-<번호>: <내용> (등록: <registered_by>, <registered_at>)   ← due가 없는 항목은 "마감:" 생략
   ```
6. 마지막에 "미완료 N건"을 한 줄 덧붙이고, 기한이 지난 항목이 하나 이상이면
   "(기한 경과 M건)"을 이어 붙인다. 화면에는 여기까지만 보여준다 (제목 줄 수준의 요약).
7. `mkdir -p <WIKI_REPO_PATH>/todo/output`으로 디렉터리를 만든 뒤,
   `<WIKI_REPO_PATH>/todo/output/todo-list.md`에 지금 보여준 항목들(4~5단계로 정렬/필터링된 것과
   동일한 목록)로 다음 3개 절을 채워 파일로 저장한다 (매 실행마다 덮어쓴다):
   ```markdown
   # Todo List (open) — 생성: <date '+%Y-%m-%d %H:%M'>

   ## 1. 제목 목록

   (6번까지 화면에 보여준 것과 동일한 목록 + 마지막 건수 줄)

   ## 2. 요약 테이블

   | ID | 제목 | 마감 | 등록 | 내용 요약 | 메모 요약 |
   |---|---|---|---|---|---|
   | TD-<번호> | <제목> | <due 또는 -> | <registered_by> <registered_at> | <본문 앞부분을 100자 내외로 요약, 넘으면 "..."> | <memo가 있으면 각 memo 첫 줄을 이어붙여 요약, 없으면 "메모 없음"> |

   ## 3. 상세 내용

   ### TD-<번호>: <제목>
   - 마감: <due 또는 -> / 등록: <registered_by> <registered_at>

   <TD 섹션의 제목 다음 줄부터 metadata 필드(`- status:` 등) 이전까지의 본문 전체>

   **메모**

   <각 `### memo (...)` 블록을 그대로, 시간순으로 전체 나열. 메모가 없으면 "메모 없음">

   (다음 TD 항목도 같은 형식으로 반복)
   ```
8. 화면 출력 마지막에 "(상세: todo/output/todo-list.md)"를 한 줄만 덧붙인다 — 화면은 6번까지의
   제목 요약 그대로 유지하고, 파일 경로만 짧게 알려준다.
