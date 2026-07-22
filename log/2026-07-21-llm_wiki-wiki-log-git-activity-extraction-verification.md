---
start_time: 2026-07-21 18:42:23
end_time: 2026-07-21 18:42:23
who: charles.lee
project: llm_wiki
source_repo: /home/cheoljoo.lee/code/llm_wiki
branch: main
tags: [wiki-log, git-activity, verification]
digested: true
---

# wiki-log의 git 활동 자동 조회(4번 단계) 5개 저장소 대상 검증

`~/.config/llm_wiki/git_watch_repos`에 등록된 5개 저장소에서 `/wiki-log`의 git 활동 조회
로직(bare mirror clone/fetch → `git log --all --extended-regexp --author --since`)이 실제로
올바르게 동작하는지 처음으로 실행해 확인했다.

## Git 활동

- **llm_wiki** (https://github.com/cheoljoo/llm_wiki.git): 2026-07-21 wiki-log: also search
  GitHub/mod.lge.com git activity via a repo watch list (62f32ac) / herdr setup script:
  auto-merge into existing config.toml (84613a7) / add herdr vim-navigation setup script
  (e3fcb65) / log: ai_resource_management - herdr로 Claude/Gemini 에이전트 핑퐁 리뷰
  오케스트레이션 + Jira 4건 갱신 반영 (03fa78d)
- **hermes** (https://github.com/cheoljoo/hermes.git): 조회 기간(2026-07-18 18:42 이후) 내
  본인 커밋 없음 — 마지막 커밋이 2026-07-17로 윈도우 밖이라 정상 0건.
- **pvs_crawler** (ssh://git@mod.lge.com:2222/swpmviz/pvs_crawler.git): 조회 기간 내 본인 커밋
  없음 — 같은 기간 다른 팀원(keyman.kim, Sang jae) 커밋은 존재해 저장소 자체는 정상 접근됨,
  본인 커밋만 없는 것으로 확인.
- **misc** (http://mod.lge.com/hub/cheoljoo.lee/misc.git): 조회 기간 내 본인 커밋 없음 — 마지막
  커밋이 2026-07-10로 윈도우 밖.
- **ccr** (http://mod.lge.com/hub/cheoljoo.lee/ccr.git): 조회 기간 내 본인 커밋 없음 — 마지막
  커밋이 2026-07-03으로 윈도우 밖.

## 검증 결과 (트러블슈팅 관점에서 남길 가치)

- 5개 저장소 모두 최초 `git clone --bare --filter=blob:none`이 성공했다 — GitHub(HTTPS)와
  mod.lge.com(HTTPS, SSH 둘 다) 모두 이 세션의 자격증명으로 접근 가능함을 확인.
- llm_wiki를 제외한 4곳이 전부 0건으로 나왔는데, 이게 author 매칭 실패인지 실제로 커밋이
  없는 건지 구분하기 위해 `--author` 필터 없이 각 저장소의 최근 커밋 3개를 별도로 조회해
  대조했다. 결과: 전부 "조회 시각 이후 본인 커밋이 실제로 없어서" 0건이었다 — 로직 자체의
  결함이 아니라 데이터가 그런 것이었음을 확인. `--author="<name>|<email>"` +
  `--extended-regexp` 조합이 `charles.lee`/`cheoljoo.lee`처럼 이름 표기가 저장소마다 다를 때도
  이메일(`cheoljoo.lee@lge.com`)로 정상 매칭되는 것도 ccr 저장소에서 확인됐다 (그 저장소는
  `author.name`이 `cheoljoo.lee`로 기록돼 있어 이름 매칭도 됨).
- 결론: 새 로직은 신뢰할 수 있다. "결과가 0건"이라는 것과 "저장소 접근/필터링이 고장났다"는
  것을 혼동하지 않으려면, 의심스러울 때 `--author` 없이 같은 저장소를 다시 조회해 대조하는
  방법이 유효하다.
