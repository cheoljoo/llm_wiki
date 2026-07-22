# 시작하기

`llm_wiki`를 처음 clone한 사람이 "설치 → 첫 실행 → 다음에 뭘 해볼지"만 5분 안에 훑을 수 있도록 만든 요약입니다.
개념/구조 설명은 [README.md](README.md), 각 단계의 상세 옵션(특히 MCP·git 감시 설정)은 [GUIDE.md](GUIDE.md)를 참고하세요.

## 1. clone 직후 해야 하는 것

```bash
git clone <이 저장소 URL> ~/code/llm_wiki
cd ~/code/llm_wiki
make install
```

`make install`이 하는 일 (필수, 팀원별 1회):
- `~/.config/llm_wiki/repo_path`에 이 clone의 절대경로를 기록
- `/wiki-log`, `/wiki-recall`, `/wiki-report`, `/wiki-todo`, `/wiki-project-done`을
  `~/.claude/commands/`에 설치 — 이후 **어느 프로젝트 디렉터리에서든** 이 커맨드들을 바로 쓸 수 있습니다.

여기까지만 하면 바로 2번으로 넘어가도 됩니다. 아래는 필요할 때만 하는 선택 사항입니다.

- **Jira/Confluence 연동**을 쓰고 싶다면 → [GUIDE.md 2절](GUIDE.md#2-mcp-jiraconfluence-연동--mcp-atlassian)
  (없어도 `/wiki-log`는 그 부분만 생략하고 정상 동작합니다)
- **GitHub/mod.lge.com 저장소의 git 커밋을 자동 기록**하고 싶다면 →
  [GUIDE.md 3절](GUIDE.md#3-github--modlgecom-저장소의-git-활동-자동-조회-옵션)
- VS Code Copilot에서도 쓰려면 → `make install-copilot`

## 2. 설치 후 처음 해볼 것

아무 프로젝트나 하나 골라 그 디렉터리에서 순서대로 실행해보세요 (`llm_wiki` 저장소 자체가 아니어도 됩니다).

1. **작업 하나를 끝낸 뒤 기록해보기**
   ```
   /wiki-log
   ```
   지금까지 세션에서 한 일(버그 수정, 설계 결정, 트러블슈팅 등)을 정리해 `llm_wiki`의 `log/`에
   새 파일로 남기고 커밋합니다. 이게 이 저장소의 유일한 "쓰기" 입구입니다.

2. **로그를 wiki로 정제해보기** (`llm_wiki` 저장소 안에서)
   ```
   cd ~/code/llm_wiki
   /wiki-digest
   ```
   방금 쌓인 `log/`를 읽어 `wiki/<topic>.md`로 통합하고 `wiki/README.md` 목차를 갱신합니다.
   로그가 하나뿐이면 결과가 단출하겠지만, 전체 흐름(log → wiki)을 눈으로 확인하기엔 충분합니다.

3. **방금 만든 지식을 다시 꺼내보기** (다른 프로젝트 디렉터리에서)
   ```
   /wiki-recall <방금 기록한 주제 키워드>
   ```
   `wiki/README.md` 목차에서 관련 문서를 찾아 지금 상황에 맞게 요약해줍니다 — 이 왕복(기록 → 정제 → 조회)이
   이 저장소가 존재하는 이유입니다.

4. 그 다음엔 상황에 맞게:
   - 이번 주에 뭘 했는지 궁금하면 `/wiki-report`
   - 손 놓고 있는 일이 있는지 궁금하면 `/wiki-todo`
   - 프로젝트 하나를 마무리하며 요약 문서가 필요하면 (그 프로젝트 저장소에서) `/wiki-project-done`

각 커맨드의 인자·옵션·예시는 [GUIDE.md 4절](GUIDE.md#4-슬래시-커맨드-사용법)에, 더 다양한 활용 아이디어는
[GUIDE.md 5절](GUIDE.md#5-활용-아이디어-더-보기)에 정리돼 있습니다.
