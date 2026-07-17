---
description: 현재(또는 지정한) 프로젝트의 llm_wiki log/wiki 내용을 모아 그 프로젝트 저장소 안에 마무리 요약 문서(wiki-project.md)를 만든다
user-invocable: true
---

중앙 지식 저장소 경로(`WIKI_REPO_PATH`)는 이 파일에 적지 않는다. 실행할 때마다 개인 설정 파일에서 읽는다
(설치 방법은 저장소 루트 README.md의 "설치" 절 참고).

이 커맨드는 **현재 작업 중인 프로젝트 저장소**(llm_wiki가 아니라, 프로젝트 종료/정리 시점에 이 커맨드를
호출한 그 프로젝트)에서 실행하는 것을 전제로 한다. `<WIKI_REPO_PATH>/log/`와 `<WIKI_REPO_PATH>/wiki/`에
쌓인 내용 중 이 프로젝트와 관련된 것만 모아, **현재 저장소 루트**에 `wiki-project.md`라는 정리 문서를
새로 만든다. llm_wiki 저장소 쪽(`log/`, `wiki/`)은 읽기만 하고 아무것도 수정하지 않는다.

다음 순서로 실행한다:

1. `cat ~/.config/llm_wiki/repo_path`를 실행해서 `WIKI_REPO_PATH`를 얻는다.
   파일이 없거나 비어있으면, 다음과 같이 안내하고 **중단한다** (경로를 추측하지 않는다):
   "먼저 `mkdir -p ~/.config/llm_wiki && echo '<본인의 llm_wiki clone 절대경로>' > ~/.config/llm_wiki/repo_path`로 한 번 설정해주세요."
2. 현재 디렉토리가 git 저장소면 `git rev-parse --show-toplevel`로 **대상 저장소 루트**(`TARGET_REPO_ROOT`)를
   구한다. git 저장소가 아니면 현재 작업 디렉토리를 그대로 `TARGET_REPO_ROOT`로 쓴다.
   `wiki-project.md`는 이 경로 바로 아래에 만든다 (llm_wiki 저장소 안이 아니다).
3. 프로젝트명을 정한다: `$ARGUMENTS`가 주어졌으면 그 값을 프로젝트명으로 쓴다 (log의 `project`
   frontmatter가 디렉토리명과 다르게 기록된 경우를 위한 오버라이드). 비어있으면
   `basename "$TARGET_REPO_ROOT"`를 프로젝트명으로 쓴다.
4. **log 수집**: `<WIKI_REPO_PATH>/log/*.md` 중 frontmatter `project`가 3번의 프로젝트명과 일치하는
   파일을 모두 찾아 파일명(날짜) 순으로 정렬해 읽는다. 하나도 없으면 "이 프로젝트명으로 기록된 log가
   없습니다. 프로젝트명이 맞는지 확인해주세요 (다른 이름이면 `/wiki-project-done <실제 project명>`으로
   다시 시도)"라고 안내하고 **중단한다** (빈 파일을 만들지 않는다).
5. **wiki 수집**: `<WIKI_REPO_PATH>/wiki/*.md` 전체에서 이 프로젝트명을 언급하는 부분을 찾는다
   (각주 표기 `[^<project명>]`, 각주 정의, 본문 중 프로젝트명 언급 등을 grep으로 찾는다). 여러
   프로젝트를 다루는 wiki 문서라면 **그 문서 전체를 복사하지 말고**, 이 프로젝트와 관련된 부분만
   골라 요약한다.
6. 아래 형식으로 `<TARGET_REPO_ROOT>/wiki-project.md`를 작성한다. 이미 파일이 있으면 덮어쓰기 전에
   기존 내용을 확인하고, 사용자가 직접 쓴 내용으로 보이면 덮어쓸지 먼저 물어본다:

   ```markdown
   # <프로젝트명> — 작업 요약 (llm_wiki 기준 스냅샷)

   > 이 문서는 `<WIKI_REPO_PATH>`의 log/wiki를 바탕으로 <생성 시각>에 자동 생성된 스냅샷입니다.
   > 이후 진행된 내용은 반영되지 않습니다. 최신 내용을 보려면 llm_wiki에서
   > `/wiki-recall <프로젝트명>` 또는 `/wiki-project-done <프로젝트명>`을 다시 실행하세요.

   ## 개요

   (기간: 가장 이른 log의 start_time ~ 가장 최근 log의 end_time, 총 세션 수, 다룬 wiki 주제 수)

   ## 작업 타임라인

   - <날짜> — <핵심 내용 1~2줄> (관련 있으면 Jira 이슈 키 포함)
   - ...

   ## 설계 결정 · 트러블슈팅 노하우 (wiki에서 정제된 내용)

   ### <wiki topic 제목>
   (이 프로젝트와 관련된 부분만 요약, 결론/이유 위주)
   → 원본: `<WIKI_REPO_PATH>/wiki/<topic>.md`

   (관련 topic마다 반복)

   ## 참고한 원본 log 파일

   - `<WIKI_REPO_PATH>/log/<파일명>` (<날짜>)
   - ...
   ```

7. `git add`/`git commit`은 하지 않는다 — `TARGET_REPO_ROOT`는 llm_wiki와 다른 저장소이므로, 파일만
   만들어두고 검토·커밋은 사용자에게 맡긴다.
8. 몇 개의 log와 몇 개의 wiki topic을 참고했는지, 파일 경로(`<TARGET_REPO_ROOT>/wiki-project.md`)를
   사용자에게 한두 문장으로 보고한다.
