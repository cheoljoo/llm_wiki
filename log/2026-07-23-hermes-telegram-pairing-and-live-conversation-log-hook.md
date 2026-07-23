---
start_time: 2026-07-23 14:28:12
end_time: 2026-07-23 14:35:02
who: cheoljoo.lee
project: hermes
source_repo: /data01/cheoljoo.lee/code/hermes
branch: main
tags: [hermes, telegram, docker, gateway-hooks, jira]
digested: false
---

# Hermes Telegram 페어링 승인 + 사용자별 대화 실시간 로깅 훅 구축

## 한 일

- Telegram 페어링 코드 승인: `hermes pairing approve telegram <code>` 로 처리.
  코드가 만료/오타면 `Code not found or expired` 에러가 나므로, 먼저
  `hermes pairing list`로 pending 목록을 확인하고 재발급을 요청하는 흐름이 안전함.
- 사내 망에서 Telegram 서비스 사용 가능 여부는 `curl`로 `api.telegram.org`,
  `telegram.org`에 대한 DNS resolve + HTTPS 200/302 응답을 직접 찍어서 확인.
  (ICMP ping은 Telegram 쪽에서 흔히 막아두므로 도달성 판단 근거로 쓰면 안 됨 —
  HTTPS 200/302 응답 여부가 실질적 판단 기준.)
- `hermes sessions export --source telegram -` (JSONL)로 사용자별 전체 대화
  이력을 뽑아낼 수 있음을 확인. 각 레코드에 `user_id`, `messages[]`(role/content
  전체)가 포함되어 있어 특정 user_id로 필터링하면 그 사람의 대화만 markdown 등으로
  재구성 가능.
- **Gateway Event Hook**으로 특정 Telegram user_id의 대화를 실시간으로 계속
  markdown에 append하도록 구성 (`~/.hermes/hooks/<name>/{HOOK.yaml,handler.py}`,
  `agent:end` 이벤트 구독 — `platform`, `user_id`, `message`, `response`를 그대로
  받을 수 있어 세션 재조회 없이 바로 append 가능).

## 트러블슈팅 / 배운 점 (재사용 가치 있음)

- **Docker 컨테이너 안에서 `Path.home()`은 신뢰할 수 없다.** Hermes 공식 훅 문서
  예제들은 `Path.home() / ".hermes" / ...` 패턴을 쓰지만, 이 docker-compose 구성
  (`~/.hermes:/opt/data`)에서는 `docker compose exec`로 들어가면 root로 붙어서
  `Path.home()`이 `/root`를 반환하고, 실제 gateway 프로세스는 `HERMES_UID/GID`로
  구동되어 `HOME`이 다르다. 실제로 handler.py에서 `Path.home()`을 썼다가 파일이
  호스트의 `~/.hermes/`가 아니라 컨테이너의 `/root/`에 생기는 버그를 만들었음.
  → **해결**: `os.environ["HERMES_HOME"]` (컨테이너 어디서든 `/opt/data`로 고정된
  값)을 직접 참조하도록 수정. docker 기반 Hermes 배포에서 훅/스크립트를 작성할
  때는 `Path.home()` 대신 항상 `HERMES_HOME` env var를 우선 사용할 것.
- 훅을 실제 gateway 재시작 없이 검증하고 싶으면, `importlib.util.spec_from_file_location`
  으로 handler.py를 직접 로드해서 `asyncio.run(mod.handle(event, context))`을
  호출하는 방식으로 gateway를 안 띄우고도 로직/파일 쓰기 경로를 먼저 검증할 수
  있음 (실제 반영은 `docker compose restart gateway`로 gateway 훅 재검색이 필요).
- `docker inspect <container> --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'`
  로 docker-compose의 볼륨 매핑이 실제로 의도대로 걸렸는지(`~/.hermes` ↔
  `/opt/data`) 바로 확인 가능 — 문서/설정 파일만 보고 판단하지 않고 실물 확인하는
  습관.
- 파일 전송 도구(SendUserFile)의 업로드 한도가 30MiB라 Telegram Desktop 설치
  파일(Linux 74MB, Windows 52MB) 모두 직접 전송은 실패함 — 큰 바이너리는 서버에
  받아두고 경로/체크섬만 안내하는 방식으로 전환.

## Jira 업데이트

(마지막 확인: 2026-07-18 10:33 → 이번: 2026-07-23 14:35, assignee + watcher 쿼리 모두 수행)

- **AGILEDEV-1060 「hermes 사용 해보기」** (담당 이슈): 2026-07-20에 새 댓글 2건.
  ① guide.md/README.md 작성 완료 링크 공유 (`github.com/cheoljoo/hermes`).
  ② Telegram bot 사용법 안내 — `t.me/Hermes_charles_two_bot` 접속 후 pairing
  code를 관리자에게 공유하면 승인 후 사용 가능하다는 절차를 팀에 공지. (오늘
  세션에서 실제로 처리한 pairing 승인 작업이 이 안내의 연장선.)
- **AGILEDEV-1057 「LLM Wiki」** (담당 이슈): 2026-07-20 새 댓글 — llm_wiki
  가이드 링크 공유 (`github.com/cheoljoo/llm_wiki/blob/main/README.md`).
- **AGILEDEV-1053 「[pvs_crawler] ECHO 판정/prompt version 최신화」** (담당 이슈):
  2026-07-20, 2026-07-22에 새 댓글. `--ensure-models`에 `stale_model_snapdate`
  판정 추가 — 기존에는 exaone 결과가 "존재하지만 오래된(stale)" 경우 재처리
  대상에서 빠지는 문제가 있었는데, 다른 모델보다 snapdate가 오래되면 재생성
  후보에 포함하도록 확장. 프로덕션 DB 대상 실행으로 정상 동작 확인 (일부는
  이미 `2026-07-22-pvs_crawler-ensure-models-stale-snapdate.md`에 상세 기록됨 —
  같은 내용 중복).
- **AGILEDEV-1063 「다른 project의 prompt 참조」** (담당 이슈): 마지막 확인 이후
  새 댓글 없음(마지막 댓글 07-15). `updated` 필드만 07-20으로 갱신되어 있으나
  코멘트/설명 변경은 없음 — (내용 없음).
- watcher로만 걸린 **SWUTDB-1214**(Honda AlarmApp 리뷰)는 최근 활동이 전부
  `SWUT Testbot` 자동 코멘트뿐이고 cheoljoo.lee의 직접 댓글/상태 변경 없음 →
  기록 대상에서 제외.

## Confluence 업데이트

`contributor = currentUser() AND lastModified > "2026-07-18 10:33"` 결과 4건
중, 실제 cheoljoo.lee가 작성한 코멘트가 있는 페이지는 없었음(주간업무보고,
Honda SVN ID 요청, vBee/vgit 권한 요청 스레드는 모두 타인 코멘트뿐). SWDEVDIV
스페이스에 이미지 첨부파일 1건(`image-2026-7-22_9-48-12.png`, 2026-07-22
09:48) 업로드 이력만 확인됨 — 상위 페이지 불명, 내용 확인 불가. (내용 없음)
