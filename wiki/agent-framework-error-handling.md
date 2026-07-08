# 커스텀 에러 처리를 짜기 전에 프레임워크의 기존 분류/복구 로직부터 확인

에이전트/프레임워크성 프로젝트에서 "이런 에러 처리 기능이 필요하다"는 요구가 오면, 커스텀 재시도
로직을 짜기 전에 프레임워크가 이미 그 에러 타입을 어떻게 분류(retryable/non-retryable)하고 어떤
built-in 복구 경로(retry/fallback/circuit breaker)를 갖고 있는지 소스에서 먼저 확인해야 한다. 대개
이미 있고, 없어도 config로 조합 가능한 경우가 많다.

## 사례

사내 LLM API가 간헐적으로 `Invalid control character`(JSON 스펙을 어기는 raw control 문자) 에러를
내서 재시도 후 실패하는 문제가 있었다. "N번 실패하면 다른 모델로 전환해서 재시도해달라"는 요구를
받았는데, 커스텀 로직을 짜기 전에 프레임워크 소스(`agent/conversation_loop.py`)를 읽어보니:

- `json.JSONDecodeError`(`ValueError`의 서브클래스)가 이미 "로컬 버그가 아니라 transient
  provider/network failure로 간주해 재시도해야 한다"는 주석과 함께 예외 처리되어 있었다.
- 표준 재시도가 소진되면 `fallback_providers`(설정 파일) 체인으로 자동 전환하는 기능이 이미
  내장되어 있었다.

즉 필요한 건 코드가 아니라 설정 한 줄(`fallback_providers: [{provider: ..., model: ...}]`)이었다.
[[openrouter-model-selection]]에서 다룬 기준으로 fallback 모델을 고르면 된다.

[^hermes]

[^hermes]: `hermes` 프로젝트(`/data01/cheoljoo.lee/code/hermes`)의 `agent/conversation_loop.py`,
  `config.yaml`의 `fallback_providers`에서 확인한 내용.
