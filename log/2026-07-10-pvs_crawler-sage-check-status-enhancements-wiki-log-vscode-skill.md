---
start_time: 2026-07-09 17:18:53
end_time: 2026-07-10 12:31:04
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [sage-check-status, print-timestamp, wiki-log, vscode-copilot, skill]
digested: true
---

# sage-check-status.py 출력 개선 및 wiki-log VS Code Copilot 스킬 설정

## 1. sage-check-status.py — 모든 print에 타임스탬프 prefix 추가

`builtins.print`를 오버라이드하는 방식으로 구현했다.

```python
import builtins as _builtins

_orig_print = _builtins.print

def _tprint(*args, **kwargs):
    if not args or args == ("",):
        _orig_print(*args, **kwargs)   # 빈 줄은 타임스탬프 없이
        return
    now = _dt.now().strftime("%H:%M:%S")
    _orig_print(f"[{now}]", *args, **kwargs)

_builtins.print = _tprint
```

**포인트**: `tabulate()`는 문자열을 반환할 뿐 `print()`를 직접 호출하지 않으므로,
builtins 오버라이드가 tabulate 내부 동작에 영향을 주지 않는다.
빈 줄(`print()`, `print("")`)은 타임스탬프를 붙이지 않아 출력이 지저분해지지 않는다.

## 2. sage-check-status.py — 실행 시작 시 날짜/시간 1회 출력

```python
print(f"[sage-check-status] 실행 시각: {_dt.now().strftime('%Y-%m-%d %H:%M:%S')}")
```

`main()` 첫 번째 구분선(`=` * 80) 직후에 삽입.

## 3. sage-check-status.py — prompt 버전별 요약 테이블 추가

`print_prompt_summary_table(by_prompt)` 함수를 추가하고 `print_summary()` 직후에 호출한다.
`tabulate(..., tablefmt="fancy_grid")`로 다음 컬럼을 표 형식으로 출력한다:
- prompt_file
- 처리 ticket 수
- commit 있음 (N/total + %)
- commit 없음 (N/total + %)
- model 별 처리 수 (멀티라인 셀)

## 4. wiki-log VS Code Copilot 스킬 등록

Claude(`~/.claude/commands/wiki-log.md`)에서만 동작하던 `/wiki-log` 커맨드를
VS Code Copilot에서도 사용할 수 있도록 설정했다.

**파일 구조**:
```
.github/skills/wiki-log/SKILL.md      ← 스킬 정의 (VS Code frontmatter 형식)
.github/vscode-skills/wiki-log.md     → symlink
.vscode/settings.json                 ← github.copilot.chat.codeGeneration.instructions 에 추가
```

이후 `llm_wiki/tooling/commands/wiki-log.md` 최신 버전(Jira/Confluence MCP 연동,
`date` 필드 제거, `start/end_time`에 날짜 포함)으로 SKILL.md를 재동기화했다.

**배운 점**: VS Code Copilot 스킬은 `.vscode/settings.json`의
`github.copilot.chat.codeGeneration.instructions` 배열에 파일 경로를 등록하면
대화 중 description 키워드 매칭으로 자동 로드된다.
symlink를 활용하면 한 개 소스 파일(`SKILL.md`)로 Gemini CLI / VS Code Copilot 양쪽을 동시에 관리할 수 있다.
