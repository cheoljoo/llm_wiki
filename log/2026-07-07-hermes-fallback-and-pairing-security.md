---
date: 2026-07-07
start_time: 13:51:44
end_time: 16:55:10
project: hermes
source_repo: /data01/cheoljoo.lee/code/hermes
tags: [llm-fallback, openrouter, error-handling, telegram, pairing, security, hermes-agent]
digested: true
---

# Hermes: LLM fallback 설정과 Telegram pairing 코드의 보안 설계

이전 로그(`2026-07-07-hermes-docker-ops-lessons.md`)에 이어, 같은 hermes 운영
세션에서 겪은 것 중 다른 프로젝트에도 재사용할 만한 두 가지를 정리.

## 1. "에러 나면 재시도/다른 모델로 전환" 기능을 직접 만들기 전에, 프레임워크 소스의 에러 분류 로직부터 확인할 것

사내 LLM API(exaone/EXACODE)가 간헐적으로 `Invalid control character` (JSON
스펙을 어기는, 이스케이프 안 된 raw control 문자가 응답 문자열에 들어있는
경우) 에러를 내서 3회 재시도 후 실패하는 문제가 있었다. "3번 실패하면
OpenRouter의 무료 모델로 전환해서 3번 더 시도해달라"는 요구를 받고, 커스텀
재시도 로직을 짜기 전에 hermes 소스(`agent/conversation_loop.py`)를 먼저
읽어보니:

- `json.JSONDecodeError`는 `ValueError`의 서브클래스지만, 소스에 명시적으로
  "로컬 프로그래밍 버그가 아니라 transient provider/network failure(응답
  본문 손상, 스트림 중간 절단, 라우팅 계층 손상)로 간주해 재시도해야 한다"는
  주석과 함께 예외 처리되어 있었다 (`#14782` 이슈 참조).
- 이미 표준 재시도 로직이 실패를 다 소진하면 `agent._try_activate_fallback()`을
  호출해 `fallback_providers`(config.yaml) 체인으로 자동 전환하는 기능이
  내장되어 있었다.

즉 필요한 건 코드가 아니라 **config 한 줄**:
```yaml
fallback_providers:
  - provider: openrouter
    model: google/gemma-4-31b-it:free
```
**교훈**: 에이전트/프레임워크성 프로젝트에서 "이런 에러 처리 기능이 필요하다"는
요구가 오면, 커스텀 로직을 짜기 전에 프레임워크가 이미 그 에러 타입을 어떻게
분류(retryable/non-retryable)하고 어떤 built-in 복구 경로(retry/fallback/circuit
breaker)를 갖고 있는지 소스에서 먼저 확인해야 한다. 대개 이미 있고, 없어도
config로 조합 가능한 경우가 많다.

### 무료 모델 선택 기준

OpenRouter 공개 API(`/api/v1/models`, 인증 불필요)의 `pricing.prompt`/`completion`이
둘 다 `"0"`이면 무료. 추가로 `supported_parameters` 배열에 `"tools"`가
있는지로 tool-calling(함수 호출) 지원 여부를 미리 걸러낼 수 있다 — 에이전트
프레임워크의 fallback/보조 모델을 고를 때는 "무료"만 볼 게 아니라 반드시
tool-calling 지원 여부와 context length를 같이 확인해야 한다 (지원 안 하면
에이전트의 도구 호출 자체가 깨짐). `artificial_analysis` 벤치마크 필드
(intelligence/coding/agentic index)도 같은 계열의 여러 변형(예: dense vs
MoE) 중 고를 때 비교 기준으로 쓸 만하다.

## 2. Pairing 코드 시스템: "목록에 보이는 코드"가 실제 코드가 아닐 수 있다

Telegram 봇에 낯선 사용자가 말을 걸면 pairing 코드가 발급되고, `hermes
pairing list`로 대기 목록을 볼 수 있다. 여기 나온 코드(예: `98f327ee`)를 그대로
`hermes pairing approve telegram 98f327ee`에 넣었더니 "not found or expired"
에러가 났다. 소스(`gateway/pairing.py`)를 보니 원인은 버그가 아니라 **의도된
보안 설계**였다:

- 실제 코드는 salt+SHA256으로 해시되어 저장된다.
- `list` 명령이 보여주는 값은 **해시값의 앞 8자리(fingerprint)** 일 뿐,
  관리자가 항목을 구분하라고 보여주는 것이고 "원본 코드를 노출하지 않기
  위해" 일부러 실제 코드가 아니다.
- 진짜 코드는 해당 사용자(요청자)의 DM 화면에만 표시되며, 그 사람이 직접
  운영자에게 알려줘야 승인이 가능하다.

**교훈**: pairing/OTP류 승인 시스템을 만들거나 운영할 때, "관리자 목록
화면에 보이는 식별자"와 "사용자에게 전달되는 실제 비밀 코드"를 다른 값으로
분리하는 건 흔한 보안 패턴이다 (관리자 화면 캡처/로그 유출만으로 승인을
못 하게 막음). 이런 시스템을 처음 쓸 때 "list에 나온 값을 그대로 approve에
넣었는데 안 된다"는 증상을 보면 버그 의심보다 먼저 "이 값이 fingerprint인지
실제 secret인지" 소스에서 확인하는 게 빠르다.

## 3. (부록) 모호한 승인 응답은 에이전트 하니스가 막아준 사례

"Gina Oh 승인해줘"처럼 대상이 명확한 요청 전에, 사용자가 그냥 "1"이라고만
답했을 때 Claude Code의 auto-mode 권한 분류기가 "이 응답이 낯선 사람에게
에이전트 접근권을 주는 것을 명확히 확인한다고 보기 어렵다"며 실행을 자동으로
막았다. 제3자에게 시스템 접근권을 부여하는 것처럼 되돌리기 어려운 액션은,
사용자의 의도가 텍스트로 명시적으로 확인되기 전까지 실행을 보류하는 게
맞다는 걸 보여준 사례.
