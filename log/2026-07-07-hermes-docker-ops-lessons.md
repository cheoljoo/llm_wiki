---
date: 2026-07-07
start_time: 10:31:33
end_time: 13:51:44
project: hermes
source_repo: /data01/cheoljoo.lee/code/hermes
tags: [docker, docker-compose, permissions, telegram, openrouter, kanban, crontab, debugging]
digested: true
---

# Hermes Docker 운영 중 겪은 재사용 가능한 교훈들

Nous Research Hermes Agent를 docker compose로 운영(gateway + dashboard 2개
서비스)하면서 겪은 문제들과 해결 과정. 이 프로젝트에 국한되지 않고 다른
docker-compose 기반 프로젝트에도 적용 가능한 일반적인 교훈 위주로 정리.

## 1. 같은 이미지를 쓰는 다중 서비스는 env_file/volumes를 반드시 통일해서 감사할 것

`gateway`와 `dashboard`가 같은 이미지를 쓰지만 별도 서비스로 정의되어 있었는데,
`gateway`에만 `env_file: .env`와 커스텀 plugin 마운트(`./plugins:/opt/data/...`)가
있고 `dashboard`에는 둘 다 빠져 있었다. 결과: CLI(`docker compose exec gateway ...`)로는
잘 되는데 대시보드 웹 UI(Chat)에서는 "Unknown provider" → (마운트 추가 후)
"API key not found" 순서로 계속 실패. 두 서비스가 같은 애플리케이션 로직을 실행한다면
env_file/volumes 목록이 서비스마다 빠짐없이 동일한지 diff 떠서 확인해야 한다.
한쪽만 고치고 "됐다"고 넘어가면 다른 쪽에서 같은 클래스의 버그가 반복된다.

## 2. docker compose의 `${VAR:-default}` 보간용 `.env`에 중요 값은 반드시 고정할 것

`docker-compose.yml`이 `HERMES_UID=${HERMES_UID:-10000}` 식으로 기본값을 갖고
있었고, 최초 설치 시엔 `HERMES_UID=$(id -u) docker compose up -d --build`로
호스트 계정(1003)에 맞게 띄웠었다. 그런데 이후 유지보수 중 여러 번
`docker compose up -d <service>` / `docker compose restart`를 이 값 없이 실행하니
컨테이너가 조용히 기본값(10000)으로 재생성됐고, bind-mount된 `~/.hermes`
안 파일 소유권이 1003과 10000으로 뒤섞였다. 그 결과 일부 lock 파일에 대해
`PermissionError`가 나면서 kanban 대시보드가 500 에러를 냈고, 심지어 호스트
계정 자신도 `~/.hermes` 디렉터리를 못 열게 됐다(디렉터리 자체가 700으로
10000 소유가 되어버림). **교훈**: 매번 inline으로 넘겨야 하는 값이 있다면
그건 사실상 설정이니 `.env`(docker compose가 변수 보간용으로 자동으로 읽는
파일)에 고정해두는 게 맞다. "항상 기억해서 넘기기"에 의존하는 설정은 언젠가
빠뜨리게 되고, 특히 UID/GID처럼 파일시스템 소유권에 영향을 주는 값은 그
빠뜨림이 조용히(에러 없이) 반영되어 나중에야 엉뚱한 증상으로 나타난다.
복구: `docker compose exec -u root <service> chown -R <uid>:<gid> /opt/data`.

## 3. `docker compose logs`는 버퍼링 때문에 오래된 내용만 보여줄 수 있다

런타임 문제를 디버깅할 때 `docker compose logs -f gateway`가 몇 초씩 지나도
새 줄을 안 보여줘서 "연결이 멈췄나?" 했는데, 실제로는 애플리케이션이 자체
로그 파일(`/opt/data/logs/gateway.log`, 즉 호스트의 `~/.hermes/logs/gateway.log`)에
훨씬 자세하고 최신인 내용을 쓰고 있었다. 컨테이너 안에서 `tail -f
/opt/data/logs/gateway.log`로 직접 읽으니 실제로는 문제없이 잘 연결되어
있었다는 걸 바로 확인할 수 있었다. `docker compose logs`가 이상하게 정적으로
느껴지면, 앱 자체 로그 파일이 따로 있는지부터 확인하는 게 빠르다.

## 4. OpenRouter 무료 모델 여부는 공개 API로 실시간 확인 가능

`https://openrouter.ai/api/v1/models` (인증 불필요, 공개 엔드포인트)가 각
모델의 `pricing.prompt` / `pricing.completion`을 반환하며, 둘 다 `"0"`이면
무료 tier. 모델이 나중에 유료로 전환되는 걸 감시하려면 이 엔드포인트를
매일 curl+jq로 조회해서 가격이 0이 아니게 되면 알림/자동 정지 등을 트리거하면
된다. API 키 없이도 가격표 전체를 볼 수 있다는 게 포인트.

## 5. crontab 설치 시 아주 긴 경로의 파일을 인자로 주면 알 수 없는 에러가 남

에이전트 세션의 스크래치패드처럼 깊고 긴 경로(`/tmp/claude-.../<uuid>/scratchpad/...`)에
만든 파일을 `crontab <path>`에 바로 넘기니 `crontab: No such file or directory`
(파일은 분명히 존재하는데도)가 났다. `/tmp/짧은이름.txt`로 복사해서 넘기니
바로 됐다. `crontab` 바이너리가 내부적으로 경로 길이/버퍼에 제약이 있는 것으로
보이며, 비슷한 증상이 나면 짧은 경로로 복사해서 재시도해볼 것.

## 기타 메모

- Telegram bot 연동은 `.env`에 `TELEGRAM_BOT_TOKEN`만 넣으면 hermes가
  자동으로 provider를 활성화(`_enable_from_env`)하는 패턴이었음 — 별도의
  "enable" 설정이 필요 없고, 있으면 자동 감지. 다만 기본적으로 pairing
  정책(모르는 발신자 거부)이 걸려 있어서, 사람이 봇에게 먼저 말을 걸어
  pairing 코드를 받고 `hermes pairing approve <platform> <code>`로 승인하는
  절차가 별도로 필요했다.
- Kanban(작업 큐) 티켓은 assignee(담당 profile)가 지정되어 있어야만 자동
  실행되고, "triage" 상태로 만들면 별도 스펙 정리용 LLM 설정이 없는 한
  멈춰버린다 — 이런 종류의 워크플로 자동화 기능은 "생성하면 바로 도나?"가
  아니라 "무슨 상태/필드가 채워져야 dispatcher가 집는가"부터 확인해야 한다.
