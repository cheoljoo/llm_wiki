# OpenRouter 무료/tool-calling 지원 모델 고르는 기준

OpenRouter 공개 API로 가격과 기능 지원 여부를 인증 없이 실시간 확인할 수 있다.

`https://openrouter.ai/api/v1/models` (인증 불필요, 공개 엔드포인트)를 curl+jq로 조회하면 모델별로:

- `pricing.prompt` / `pricing.completion`이 둘 다 `"0"`이면 무료 tier. 모델이 나중에 유료로
  전환되는 걸 감시하려면 이 엔드포인트를 주기적으로 조회해서 가격이 0이 아니게 되면 알림/자동 정지를
  트리거하면 된다.
- `supported_parameters` 배열에 `"tools"`가 있는지로 tool-calling(함수 호출) 지원 여부를 미리
  걸러낼 수 있다 — 에이전트 프레임워크의 fallback/보조 모델을 고를 때는 "무료"만 볼 게 아니라 반드시
  tool-calling 지원 여부와 context length도 같이 확인해야 한다. 지원 안 하는 모델을 fallback으로
  넣으면 에이전트의 도구 호출 자체가 깨진다.
- `artificial_analysis` 벤치마크 필드(intelligence/coding/agentic index)는 같은 계열의 여러 변형
  (예: dense vs MoE)을 비교할 때 기준으로 쓸 만하다.

[[agent-framework-error-handling]], [[hermes-agent-ops]]

[^hermes]

[^hermes]: `hermes` 프로젝트(`/data01/cheoljoo.lee/code/hermes`)에서 LLM fallback 모델을 고르며 확인한 내용.
