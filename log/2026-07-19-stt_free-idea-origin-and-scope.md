---
start_time: 2026-07-19 19:11:48
end_time: 2026-07-19 19:17:52
who: cheojoo
project: stt_free
source_repo: /home/cheoljoo/code/stt_free
branch: main
tags: [stt_free, hermes, aidea-origin, wiki, sop, data-centric]
digested: true
---

# stt_free 프로젝트 아이디어 출처와 배경

## 아이디어 출처

유튜브 영상 [5인 회사 운영하며 직접 헤르메스 에이전트 720시간 돌려본 후기 (feat. Slack, Hostinger)](https://www.youtube.com/watch?v=9m8iMzEBuSU)
를 보고 얻은 아이디어. README.md에 이번 세션에서 다음 맥락을 추가로 보강함.

핵심 인사이트 3가지 (영상에서 얻은 것):

1. **data centric 원칙**: Slack, Teams 등 모든 업무 커뮤니케이션 채널의 내용을 모으는 작업이 필요하다.
   메신저, 이메일, 노션뿐 아니라 **전화 통화·회의 음성**까지 포함해야 조직의 데이터가 온전히 모인다는 관점.
   → 이 지점이 `stt_free`가 다루는 "음성" 축의 근거가 됨.
2. **gstack / gbrain**: 회사 운영을 잘 하는지 보는 관점(YCombinator류 사업 방향성 프레임)을 참고 포인트로 언급.
3. **Hermes의 매일-SOP(우리 조직의 뇌) wiki 개념**: 조직에서 매일 일어나는 일을 LLM wiki 형태로 모아,
   조직 구성원이 "오늘 무슨 일이 있었는지"를 쉽게 받아볼 수 있게 하는 구조.
   → 이 사용자의 개인 `llm_wiki` 저장소(지금 이 로그를 쓰고 있는 시스템 자체)와 같은 철학.
   `stt_free`는 이 SOP wiki 아이디어를 "음성 기록"이라는 소스에 특화해서 개인 단위로 적용한 실험으로 보임.

## stt_free가 이 중 "음성 STT" 파트를 선택하게 된 이유 (추정 근거)

README.md 원문의 "기본 아이디어" 절:
- 사용자는 Android 폰을 사용
- 음성 녹음(통화 녹음 포함)이 생기면 이를 지정 저장소에 commit으로 추가
- 음성 → STT 추출 → AI 분석/요약 → 1페이지 그림 정리

즉, data-centric 통합(메신저+이메일+노션+음성)이라는 큰 그림 중, **가장 구조화가 안 되어 있고 접근성이
떨어지는 "음성"** 채널부터 먼저 파이프라인화한 것이 `stt_free`의 스코프. 텍스트 기반 채널(Slack, Teams,
이메일, 노션)은 이미 API로 데이터 수집이 쉬운 반면, 통화/회의 음성은 녹음 → STT → 구조화라는 별도 파이프라인이
필요해서 독립 프로젝트로 분리한 것으로 보임.

## 현재 프로젝트 상태 (참고용, 코드 기준 아님 — 대화 시점 스냅샷)

- git log 기준 4개 커밋: 스캐폴딩 → Phase 1 STT-분석-원페이저 파이프라인 → uv 전환 → API 과금 없는 분석 백엔드 정책.
- $0 비용 정책: 로컬은 `claude-code` 백엔드(구독료만), CI(GitHub Actions)는 Gemini 무료 티어로 오버라이드.
  유료 Anthropic API 백엔드는 선택 가능하지만 기본 경로에서는 사용하지 않음.
- 설계 문서는 DESIGN.md에 별도로 존재 (이번 세션에서는 다루지 않음).

## 다른 프로젝트에 참고할 만한 점

- "data centric 조직 운영" 이라는 큰 아이디어를 한 번에 구현하려 하지 않고, 채널별(텍스트 vs 음성)로
  독립 파이프라인/저장소로 쪼개서 시작하는 접근 — 이 사용자의 `llm_wiki`(SOP wiki)와 `stt_free`(음성 STT)가
  같은 상위 아이디어에서 갈라져 나온 자매 프로젝트라는 점을 기억해두면, 두 프로젝트 간 데이터 포맷(예: 요약본
  구조, 태깅 방식)을 나중에 통일할 때 이 로그를 참고할 수 있음.
