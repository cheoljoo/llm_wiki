---
start_time: 2026-07-23 22:24:37
end_time: 2026-07-23 22:27:43
who: cheojoo
project: stock_index
source_repo: /home/cheoljoo/code/stock_index
branch: main
tags: [streamlit, pykrx, krx-login, gmail-smtp, uptrend-analysis, deadcat-bounce, systemd, mermaid-docs]
digested: false
---

# 상승 추세 전환 분석 페이지 추가, KRX 로그인 검증, 운영 트러블슈팅

## 배운 점 / 재사용 가능한 내용

- **pykrx는 잘못된 KRX_ID/PW를 예외로 알리지 않는다.** `get_shorting_volume_by_date`,
  `get_market_trading_value_by_date` 등 로그인 필요한 API는 인증 실패 시 그냥 빈 결과를 반환하고,
  상위 코드(`krx_provider.py`)도 관례적으로 `try/except Exception: return pd.DataFrame()`로 감싸서
  실패를 삼킨다. 그래서 "설정 안 함"과 "설정했지만 틀림"을 구분할 수 없었다.
  해결: pykrx 내부의 `pykrx.website.comm.get_auth_session()`을 직접 호출하면 실제 로그인 성공 여부를
  `KRXSession | None`으로 알 수 있다 (`build_krx_session`이 실패 시 None 반환, 성공 시 세션 객체).
  이걸로 `check_krx_login() -> (bool, message)`를 만들어 화면에 직접 노출시켰다.
  → **교훈**: 서드파티 라이브러리가 인증 실패를 조용히 삼키는 경우, 그 라이브러리의 저수준
  세션/인증 함수를 직접 찾아서 별도 헬스체크 함수를 만드는 게 낫다. 상위 API의 반환값(빈 데이터)만으로는
  "데이터가 없음"과 "인증 실패"를 구분할 수 없다.

- **Gmail SMTP 535 BadCredentials**: 일반 계정 비밀번호로는 SMTP 로그인이 안 되고, 2단계 인증이 켜진
  계정에서 발급하는 **앱 비밀번호(App Password)**가 필요하다. 흔한 실수이지만 매번 헷갈리는 포인트.

- **Streamlit systemd 서비스는 다중 파일 변경 후 hot-reload가 불완전하다.** 새 함수(`rsi_chart` 등)를
  추가한 여러 파일을 동시에 바꾼 뒤, 서비스를 재시작하지 않은 상태로 화면을 새로고침하면
  `ImportError: cannot import name 'rsi_chart' from ...`처럼 마치 코드가 깨진 것 같은 에러가 뜬다.
  실제로는 fresh import(`python -c "import ..."`)는 정상 — 원인은 오래 떠 있던 프로세스가 일부만
  재적용된 모듈 캐시를 들고 있는 것. **여러 파일을 고칠 때는 반드시 `systemctl restart`로 프로세스를
  통째로 새로 띄워야 한다.** 또한 `stockindex.service` 유닛 파일 자체가 바뀐 뒤에는
  `systemctl daemon-reload`를 먼저 해야 `service-start`/`restart`가 경고 없이 동작한다.
  → Makefile의 `service-restart` 등 `sudo`가 필요한 타겟은 에이전트 샌드박스에서 실행 불가(tty 필요) →
  사용자에게 직접 실행을 안내해야 한다.

- **비대칭 신호를 대칭으로 확장하는 설계 패턴**: 처음엔 "상승 신호만" 판별하는 7개 함수로 만들었다가,
  나중에 "하락 초입도 알고 싶다"는 요청이 왔다. 각 함수 내부에 이미 계산해둔 지표(이평선 차이, RSI,
  MACD, 피크/트로프 등)에 **반대 방향 조건만 대칭으로 추가**하면 되므로 리팩토링 비용이 낮았다.
  (골든크로스↔데드크로스, RSI 50 상향↔하향, Higher-Low/High↔Lower-High/Low, 저항선 돌파↔지지선 이탈,
  거래량 급증+양봉↔음봉, 쌍끌이 매수↔매도). **교훈**: 방향성 신호를 설계할 때 처음부터 "반대 방향"
  케이스를 염두에 두고 함수를 짜면(예: diff/차이값을 미리 계산해두면) 나중에 대칭 확장이 쉽다.

- **pykrx API 중 로그인 필요 여부가 갈린다**: `get_market_ohlcv_by_date`(시세/거래량)는 로그인 불필요,
  `get_shorting_volume_by_date`/`get_shorting_balance_by_date`/`get_market_trading_value_by_date`
  (공매도·투자자별 수급)는 로그인 필요. 코드 작성 시 이 경계를 문서화해두면 나중에 헷갈리지 않는다.

- **Streamlit UX 팁**: 초보자용 설명과 전문 지표 설명을 같은 화면에 다 넣으면 정보 과부하가 된다.
  `st.expander(..., expanded=False)`로 "쉬운 설명"을 접어두고 기본 화면은 결론/카드/차트만 보이게 하면,
  필요한 사람만 펼쳐서 볼 수 있어 화면이 깔끔하다.

## 이번 세션 작업 요약

- `core/uptrend.py` 신규: 골든/데드크로스·RSI·MACD·가격파동(N자/역N자, `scipy.signal.find_peaks`)·
  박스권·거래량급증·투자자쌍끌이 7개 신호를 상승/하락 대칭으로 판별, 5단계 결론
  (strong_uptrend/building/neutral/weakening/strong_downtrend) 산출.
- `dashboard/components/uptrend_view.py` 신규, `deadcat_view.py`와 함께 사이드바 최상위 메뉴로 완전
  분리 (기존엔 "뷰 선택" 라디오 안에 섞여 있었음).
- `krx_provider.py`에 `check_krx_login()` 추가 — 실제 로그인 성공 여부를 화면에 노출.
- 두 분석 페이지 하단에 프리셋 종목 전체를 일괄 판정하는 요약표(`_summary_rows`, `st.cache_data`) 추가,
  삼성전자우(005935)·하이브(352820) 프리셋 추가.
- 주가 차트에 이동평균선(5/20/50 또는 5/20/60/120일) 오버레이 추가, 최상단 배치.
- 각 지표에 "초등학생도 이해하는" 쉬운 설명(collapsed expander) + 5단계 결론을 "친구 7명에게 물어보기"
  비유로 설명하는 절 추가.
- README.md에 아키텍처/페이지구조 mermaid 다이어그램, "메일이 왜 매일 갱신되는지"(기존 cron이 이미
  `run_daily.py`를 매일 04시 자동 실행 중이었음) 가이드 추가. 핵심 모듈 전반에 docstring 보강.
- 커밋 2개 생성 (`3a33d5c`, `3199cec`), 아직 push 안 함.

## 참고 사항

- `start_time`은 이번 세션에 대한 첫 커밋 시각(3분 전)으로 잡혔으나, 실제 대화는 최소 2026-07-21부터
  이어진 멀티데이(multi-day) 세션이었다 (도중 시스템 날짜가 07-21→07-23으로 두 번 바뀜을 확인함).
  이번 프로젝트의 첫 `/wiki-log` 실행이라 이전 로그 워터마크가 없어 실제 소요시간 추정이 부정확함
  — 소요시간 보고는 참고용으로만 볼 것.
