# Docker Compose 다중 서비스 운영 시 반복되는 실수

같은 이미지를 여러 서비스로 나눠 쓰는 docker-compose 구성에서 설정 누락과 소유권 문제를 예방하는 체크포인트.

## 같은 이미지를 쓰는 서비스들은 env_file/volumes를 diff로 대조할 것

같은 이미지를 쓰는 두 서비스(예: gateway/dashboard)가 있는데 한쪽에만 `env_file`이나 커스텀 마운트가
있으면, 그 서비스만 CLI로는 되고 다른 서비스(웹 UI 등)에서는 "API key not found"류 에러가 반복된다.
한쪽만 고치고 넘어가면 같은 클래스의 버그가 다른 서비스에서 또 나오므로, 여러 서비스가 같은
애플리케이션 로직을 실행한다면 설정 목록이 서비스마다 빠짐없이 동일한지 diff로 확인해야 한다.

## `${VAR:-default}` 보간에 쓰는 값 중 파일시스템 소유권에 영향을 주는 건 `.env`에 고정할 것

`HERMES_UID=${HERMES_UID:-10000}`처럼 기본값이 있는 변수를, 최초 설치 때만 `HERMES_UID=$(id -u) docker
compose up -d`로 명시적으로 넘기고 이후 재기동 때 빠뜨리면, 컨테이너가 조용히 기본값으로 재생성되며
bind-mount된 디렉터리의 소유권이 섞인다. 그 결과 `PermissionError`가 나거나 심지어 호스트 계정 자신도
해당 디렉터리를 못 열게 될 수 있다(디렉터리가 700으로 다른 UID 소유가 되어버림). **교훈**: 매번
inline으로 넘겨야 하는 값은 사실상 설정이므로 `.env`(compose가 변수 보간용으로 자동으로 읽는 파일)에
고정해야 한다 — 특히 UID/GID처럼 영향을 주는 값은 빠뜨려도 에러 없이 조용히 반영되어 나중에 엉뚱한
증상으로 나타난다. 복구는 `docker compose exec -u root <service> chown -R <uid>:<gid> <경로>`.

## `docker compose logs`가 멈춘 것처럼 보이면 앱 자체 로그 파일부터 확인할 것

`docker compose logs -f`가 버퍼링 때문에 새 줄을 한참 안 보여줄 수 있다. 애플리케이션이 자체 로그
파일(컨테이너 안 `/opt/data/logs/...`, 즉 호스트에 마운트된 위치)에 더 자세하고 최신인 내용을 쓰고
있을 수 있으니, `docker compose logs`가 정적으로 느껴지면 컨테이너 안에서 앱 자체 로그를 `tail -f`로
직접 읽어보는 게 빠르다.

[[hermes-agent-ops]]

[^hermes]

[^hermes]: `hermes` 프로젝트(`/data01/cheoljoo.lee/code/hermes`, Nous Research Hermes Agent를 gateway+dashboard
  2개 서비스로 docker compose 운영)에서 겪은 문제들.
