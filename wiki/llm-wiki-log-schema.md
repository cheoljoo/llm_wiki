# llm_wiki `log/` 스키마와 `/wiki-log` 설계가 겪은 변경들

`llm_wiki` 저장소 자체(`log/` 스키마, `tooling/commands/wiki-log.md`)의 설계 결정과 그 이유를 모은 문서.
이 문서는 llm_wiki 유지보수 자체에 대한 메타 지식이다.

## `start_time`/`end_time`은 날짜를 포함해야 한다

초기 스키마는 `date: YYYY-MM-DD`(=end_time 기준 날짜) 필드 하나와, `start_time`/`end_time`은
`HH:MM:SS`만 저장했다. 세션이 자정을 넘기면(`start_time: 17:12:22`, `end_time: 09:29:51`) start_time이
전날인지 당일인지 값만 봐서는 알 수 없었다. 수정: `start_time`/`end_time` 모두
`YYYY-MM-DD HH:MM:SS`로 날짜를 포함해서 기록하고, 중복이자 혼동의 원인이었던 단일 `date` 필드는
제거했다(파일명의 `YYYY-MM-DD`만으로 충분). 기존에 이미 만들어진 로그 파일은 append-only 원칙
(`digested` 필드만 수정 가능)에 따라 옛 스키마 그대로 두고, 새 스키마는 이후 생성되는 로그부터
적용한다.

## `who`/`branch` 필드 추가 (다중 사용자 대응)

여러 사람이 같은 `log/`에 기록을 남기는 구조라, 기존 `project`/`source_repo`만으로는 "누가", "어떤
브랜치 작업 중에" 남긴 기록인지 알 수 없었다. `who`는 `git config user.name` → (없으면) `user.email`
→ (그것도 없으면) `whoami` 순으로 구하고, `branch`는 `git rev-parse --abbrev-ref HEAD`로 구하되 git
저장소가 아니면 필드 자체를 생략한다. 두 값 모두 "추측하지 말고 반드시 명령을 실행해서 얻는다"는
`start_time`/`end_time`과 동일한 원칙을 따른다.

## clone-and-copy 배포 구조는 갱신이 자동 전파되지 않는다

`/wiki-log`는 `tooling/commands/wiki-log.md`를 각자 `~/.claude/commands/wiki-log.md`로 복사해서 쓰는
구조다(user-level 커맨드로 등록해야 어느 프로젝트에서든 호출 가능하기 때문). 원본 파일을 고쳐도 이미
설치된 사용자의 복사본에는 자동 반영되지 않는다. 이런 "clone-and-copy" 배포 방식을 쓸 때는, 원본을
바꾼 뒤 반드시 재설치(재복사)가 필요하다는 걸 사용자에게 알려야 한다 — 안 그러면 팀원마다 스키마가
조용히 갈라진다.

## 선택적 외부 도구(mcp-atlassian) 통합 원칙: best-effort

외부 MCP 도구를 선택적으로 쓰는 워크플로를 설계할 때는 "연결되어 있으면 쓰고, 없거나 실패하면 핵심
경로(git 기반 기록)는 그대로 진행"하는 패턴이 안전하다 — 필수로 만들면 그 도구가 죽었을 때 전체
흐름이 막힌다. mcp-atlassian 사용법 자체는 [[mcp-atlassian]] 참고.

## Jira/Confluence 추적 방식: "세션 관련성 필터" → "워터마크 기반 diff"

처음에는 "이 세션/프로젝트와 관련된" Jira 이슈·Confluence 페이지만 골라 반영했는데, 실제로 필요한
건 프로젝트 관련성과 무관하게 "지난 실행 이후 새로 생긴 변경사항" 자체를 추적하는 것이었다. 그래서
`~/.config/llm_wiki/jira_last_checked`, `confluence_last_checked`에 마지막 확인 시각을 워터마크로
저장하고, 다음 실행부터는 그 이후 갱신된 항목만 조회(JQL/CQL의 `updated`/`lastModified` 비교)하도록
바꿨다. 워터마크가 없으면(최초 실행) 3일 전을 기본값으로 삼는다.

**알려진 한계**: 이 워터마크는 `~/.config/llm_wiki/` 아래 시스템별 로컬 파일이라 git으로 동기화되지
않는다. 여러 시스템에서 각자 `/wiki-log`를 실행하면 워터마크가 독립적으로 진행되어, 같은
Jira/Confluence 변경사항이 여러 시스템의 log에 중복 기록될 수 있다(중복 범위는 두 시스템 워터마크
간의 격차만큼 커질 수 있어 "최초 3일"에 국한되지 않는다). 검토한 대안: (1) 그냥 둔다, (2) 워터마크를
`log/`에 커밋해 push/pull로 동기화(단, 동시 커밋 시 merge conflict 가능성 있고 push 전까지는 여전히
중복), (3) 이슈 키/페이지 ID 기반으로 기존 `log/*.md`를 grep해서 중복 제거(정확하지만 느림). 현재는
**(1) 그냥 둔다**로 결정했다 — 중복은 소량이고 `/wiki-digest`가 정제하는 과정에서 걸러낼 수 있어,
지금 시점에 동기화 복잡도를 추가할 가치가 없다고 판단했기 때문. 이 워터마크 로직을 다시 만지게 되면
(2)/(3)을 재검토할 것.

[[mcp-atlassian]], [[claude-code-slash-commands]]

[^llm_wiki]

[^llm_wiki]: `llm_wiki` 프로젝트(`/data01/cheoljoo.lee/code/llm_wiki`) 자체의
  `tooling/commands/wiki-log.md`, `log/README.md` 스키마 변경 이력.
