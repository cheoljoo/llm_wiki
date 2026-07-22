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
6. `$ARGUMENTS`에 기한을 암시하는 표현이 있는지 확인하고, 있으면 오늘 날짜(`date '+%Y-%m-%d'`) 기준
   절대 날짜(`YYYY-MM-DD`)로 해석해 `due`에 채운다. 표현이 없으면 `due: -`로 둔다.
   - "오늘까지"/"오늘 방문"/"오늘 안에" 등 → 오늘.
   - "내일까지" → 내일.
   - "이번주 안에"/"이번주까지" → 이번 주 일요일 (오늘이 포함된, 월요일 시작 주의 마지막 날).
   - "다음주까지" → 다음 주 일요일.
   - "7/25까지", "2026-07-25까지"처럼 구체적 날짜가 있으면 그 날짜를 그대로 쓴다 (연도 생략 시
     올해로 간주).
   - 애매하거나 여러 해석이 가능하면 추측해서 채우지 말고 `due: -`로 두고, 등록 완료 보고에
     "기한 표현이 있었지만 명확하지 않아 `due`는 비워뒀습니다"라고 덧붙인다.
7. 다음 블록을 `<WIKI_REPO_PATH>/todo/todos.md` 맨 끝에 추가한다 (기존 내용은 건드리지 않는다):
   ```
   ## TD-<번호>: <$ARGUMENTS 내용>
   - status: open
   - due: <해석한 날짜 또는 ->
   - registered_by: <등록자>
   - registered_at: <등록 시각>
   - completed_by: -
   - completed_at: -
   - completed_via: -
   ```
8. `git -C <WIKI_REPO_PATH> add todo/todos.md` 후
   `git -C <WIKI_REPO_PATH> commit -m "todo: register TD-<번호>"`로 커밋 하나를 남긴다.
   **push는 하지 않는다.**
9. "TD-<번호> 등록 완료: <내용>"이라고 짧게 보고한다. `due`를 채웠으면
   "(마감: <날짜>)"를 덧붙여, 잘못 해석됐으면 바로 알아챌 수 있게 한다.
