# Todo

항목 형식과 커맨드 사용법은 [README.md](README.md) 참고. 이 파일은 사람이 직접 편집하지 않고
`/todo-register`, `/todo-complete` 커맨드로만 갱신합니다.

## TD-0001: Telegram을 Linux CLI로 사용 (hermes_charles 방 전용, 폰 QR 로그인)

QR 로그인도 결국 api_id/api_hash 자체는 필요함 — QR은 "SMS 코드 입력"을 생략해주는 것이지,
tdlib/MTProto 라이브러리를 초기화하는 데 필요한 앱 등록 자체를 없애주진 않음. 다만 그 등록은 딱
한 번, my.telegram.org에서 몇 분이면 끝나고, 그 이후로는 폰으로 QR 스캔만 하면 됨 (Telegram
Web/Desktop 연결할 때 쓰는 것과 동일한 방식).

제안하는 방식 (hermes_charles 방 하나만 쓰는 용도):

1. (1회, 필수) my.telegram.org 로그인 → API development tools → 아무 이름/설명이나 넣고 등록 →
   api_id/api_hash 발급.
2. Python + Telethon, qrcode 설치 (`pip install telethon qrcode`).
3. 작은 스크립트 하나 작성:
   - 최초 실행 시 터미널에 QR 코드(ASCII) 표시 → 폰 Telegram 앱 → 설정 → 기기 → "데스크톱 기기
     연결" → QR 스캔 → 로그인 완료, 세션 파일 저장.
   - 이후 실행부터는 QR 없이 바로 접속.
   - hermes_charles 방만 열어서: 새 메시지는 실시간 출력, 터미널 입력은 그 방으로 전송.

미정 사항: 스크립트를 llm_wiki의 `scripts/`(개인 환경설정 스크립트 컨벤션과 맞음)에 둘지, 별도
위치에 둘지 결정 필요.

- status: open
- registered_by: cheoljoo.lee
- registered_at: 2026-07-23 08:08
- completed_by: -
- completed_at: -
- completed_via: -
