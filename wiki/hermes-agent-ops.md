# Hermes (Nous Research Hermes Agent) 운영 노트

Hermes 에이전트를 docker compose(gateway+dashboard)로 운영하며 겪은, 이 프로젝트 고유의 동작 패턴.

## Telegram bot은 토큰만 넣으면 자동 활성화되지만, pairing 승인은 별도로 필요

`.env`에 `TELEGRAM_BOT_TOKEN`만 넣으면 hermes가 자동으로 provider를 활성화(`_enable_from_env`)한다
— 별도의 "enable" 설정이 필요 없고, 있으면 자동 감지되는 패턴이다. 다만 기본적으로 pairing 정책
(모르는 발신자 거부)이 걸려 있어서, 사람이 봇에게 먼저 말을 걸어 pairing 코드를 받고 운영자가
`hermes pairing approve <platform> <code>`로 승인하는 절차가 별도로 필요하다. pairing 코드 자체의
보안 설계(목록에 보이는 값과 실제 코드가 다름)는 [[pairing-otp-security-pattern]] 참고.

## Kanban(작업 큐) 티켓은 assignee가 있어야 자동 실행된다

티켓을 "triage" 상태로만 만들면, 별도 스펙 정리용 LLM 설정이 없는 한 dispatcher가 집어가지 않고
멈춰버린다. 이런 종류의 워크플로 자동화 기능은 "생성하면 바로 도나?"가 아니라 "무슨 상태/필드가
채워져야 dispatcher가 집는가"부터 확인해야 한다.

## 관련 문서

- Docker compose 운영 시 겪은 일반적인 함정: [[docker-compose-ops]]
- LLM 에러 발생 시 fallback 모델로 전환하는 설정: [[agent-framework-error-handling]]
- Fallback 모델 선정 기준(무료 tier, tool-calling 지원): [[openrouter-model-selection]]

[^hermes]

[^hermes]: `hermes` 프로젝트(`/data01/cheoljoo.lee/code/hermes`) 운영 세션에서 확인한 내용.
