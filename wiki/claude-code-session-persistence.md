# VSCode Claude Code 확장에서 세션이 "비어 보이는" 문제와 memory의 역할

VSCode를 닫았다 다시 열면 Claude Code 확장의 대화 창이 빈 새 세션처럼 보이는 경우가 있다. 이는 세션
기록이 사라진 게 아니라, 확장이 이전 세션을 자동으로 다시 로드하지 않아서 생기는 현상이다.

- 실제 트랜스크립트는 `~/.claude/projects/<프로젝트-경로 인코딩>/`에 JSONL로 그대로 남아 있다.
- 화면과 컨텍스트에 이어붙이려면 명시적으로 이전 세션을 resume해야 한다 (`claude --continue` /
  `claude --resume`, 또는 확장 UI의 세션 히스토리/"Resume session" 메뉴).
- 반면 `~/.claude/projects/<...>/memory/` 아래의 memory 파일(사용자 프로필, feedback, project
  컨텍스트 등)은 새 세션 시작 시 항상 다시 로드되므로, **대화 세부 내용은 안 이어져도 memory에 저장해둔
  내용은 이어진다.** 세션 자체를 못 살릴 상황이라도 memory에 중요한 결정/맥락을 남겨두면 다음 세션에서
  완전히 처음부터 시작하지는 않아도 된다.

[^llm_wiki]

[^llm_wiki]: `llm_wiki` 프로젝트 세션에서 VSCode 확장의 세션 재개 동작을 확인하며 정리한 내용.
