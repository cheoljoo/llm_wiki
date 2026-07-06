---
description: 현재 프로젝트 세션에서 배운 것/한 일을 중앙 llm_wiki 저장소의 log/에 기록한다
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

이 대화에서 지금까지 한 작업 중 재사용 가치가 있는 것(버그 수정, 설계 결정과 이유, 트러블슈팅 과정, 배운 점, 막혔던 부분과 해결법 등)을
간결하게 정리하라. 단순 진행상황이 아니라 나중에 다른 프로젝트에서도 참고할 만한 내용 위주로 쓴다.
사용자가 `$ARGUMENTS`로 특정 주제/힌트를 줬다면 그것을 우선 반영한다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 아직 설치가 안 된 것이므로 다음과 같이 안내하고 **중단한다** (경로를 추측하지 않는다):
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. `date +'%Y-%m-%d %H:%M:%S'`를 실행해서 `end_time`(과 `date`)을 정확히 구한다 (추측하지 말고 반드시 실행해서 값을 얻는다).
3. `start_time`을 추정한다: 현재 작업 디렉토리가 git 저장소면
   `git status --porcelain --untracked-files=all | awk '{print $2}' | xargs -r stat -c '%y %n' | sort | head -1`
   로 이번 세션 중 변경된 파일들 중 가장 이른 수정시각을 구해 `start_time`으로 쓴다.
   변경된 파일이 없거나(순수 대화/조사 세션) git 저장소가 아니면 `start_time`은 `end_time`과 동일하게 둔다.
4. 현재 작업 디렉토리 이름을 `<project>`로 사용한다 (git 저장소면 저장소 이름).
5. 1번에서 얻은 날짜(`YYYY-MM-DD`)와 내용을 요약한 kebab-case `<slug>`로 파일명을 만든다:
   `<WIKI_REPO_PATH>/log/YYYY-MM-DD-<project>-<slug>.md`
6. 아래 형식으로 파일을 작성한다:

```markdown
---
date: YYYY-MM-DD
start_time: HH:MM:SS
end_time: HH:MM:SS
project: <project>
source_repo: <현재 작업 디렉토리의 절대 경로>
tags: [관련 키워드]
digested: false
---

# <제목>

(정리한 내용)
```

7. `<WIKI_REPO_PATH>`에서 `git add log/<새 파일>` 후 `git commit`을 실행한다 (커밋 메시지: `log: <project> - <한 줄 요약>`). **push는 하지 않는다.**
8. 어떤 내용을 기록했는지 사용자에게 한두 문장으로 보고한다.

만약 이번 세션에 기록할 만한 내용이 없으면(단순 질의응답 등), 그렇다고 보고하고 아무 파일도 만들지 않는다.
