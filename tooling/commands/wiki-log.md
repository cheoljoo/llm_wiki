---
description: 현재 프로젝트 세션에서 배운 것/한 일을 중앙 llm_wiki 저장소의 log/에 기록한다
---

중앙 지식 저장소 경로: `<WIKI_REPO_PATH>`  <!-- 설치 시 본인의 llm_wiki clone 경로로 바꿔서 ~/.claude/commands/wiki-log.md 로 복사하세요 -->

이 대화에서 지금까지 한 작업 중 재사용 가치가 있는 것(버그 수정, 설계 결정과 이유, 트러블슈팅 과정, 배운 점, 막혔던 부분과 해결법 등)을
간결하게 정리하라. 단순 진행상황이 아니라 나중에 다른 프로젝트에서도 참고할 만한 내용 위주로 쓴다.
사용자가 `$ARGUMENTS`로 특정 주제/힌트를 줬다면 그것을 우선 반영한다.

다음 순서로 실행한다:

1. 현재 작업 디렉토리 이름을 `<project>`로 사용한다 (git 저장소면 저장소 이름).
2. 오늘 날짜(`YYYY-MM-DD`)와 내용을 요약한 kebab-case `<slug>`로 파일명을 만든다:
   `<WIKI_REPO_PATH>/log/YYYY-MM-DD-<project>-<slug>.md`
3. 아래 형식으로 파일을 작성한다:

```markdown
---
date: YYYY-MM-DD
project: <project>
source_repo: <현재 작업 디렉토리의 절대 경로>
tags: [관련 키워드]
digested: false
---

# <제목>

(정리한 내용)
```

4. `<WIKI_REPO_PATH>`에서 `git add log/<새 파일>` 후 `git commit`을 실행한다 (커밋 메시지: `log: <project> - <한 줄 요약>`). **push는 하지 않는다.**
5. 어떤 내용을 기록했는지 사용자에게 한두 문장으로 보고한다.

만약 이번 세션에 기록할 만한 내용이 없으면(단순 질의응답 등), 그렇다고 보고하고 아무 파일도 만들지 않는다.
