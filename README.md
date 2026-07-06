# llm_wiki

팀이 여러 프로젝트에서 얻은 지식/경험을 계속 쌓아가는 개인·팀용 LLM Wiki입니다.
(Andrej Karpathy가 언급한 "LLM이 유지보수하는 위키" 개념을 참고)

## 구조

```
log/    원본 로그. 각 프로젝트 세션이 끝날 때 append-only로 쌓이는 raw 기록.
wiki/   정제된 지식. log/의 내용을 주제별로 통합·정리한 문서. 서로 [[링크]]로 연결.
```

- `log/`는 사람이 직접 편집하지 않습니다. `/wiki-log` 명령으로만 추가됩니다.
- `wiki/`는 `/wiki-digest` 명령이 `log/`를 읽어 자동으로 만들고 업데이트합니다.

## 사용 흐름

1. **어느 프로젝트에서 작업하든** 의미 있는 작업(버그 수정, 설계 결정, 트러블슈팅, 배운 점 등)이 끝나면
   그 프로젝트 세션에서 `/wiki-log` 를 실행합니다. → `log/`에 날짜별 원본 노트가 쌓입니다.
2. 주기적으로 (또는 로그가 어느 정도 쌓이면) 이 저장소에서 `/wiki-digest` 를 실행합니다.
   → 새 로그들을 읽어 `wiki/` 아래 주제별 문서로 정리·통합하고, 처리된 로그는 `digested: true`로 표시합니다.
3. `wiki/README.md`가 전체 주제의 목차 역할을 합니다.

자세한 규칙은 [CLAUDE.md](CLAUDE.md), [log/README.md](log/README.md), [wiki/README.md](wiki/README.md) 참고.

## 설치 (팀원별 1회)

`/wiki-log`는 어느 프로젝트에서든 호출해야 하므로 Claude Code의 **user-level 커맨드**로 설치합니다.

1. 이 저장소를 clone
2. `tooling/commands/wiki-log.md`를 `~/.claude/commands/wiki-log.md`로 복사
3. 복사한 파일에서 `<WIKI_REPO_PATH>`를 본인의 clone 경로로 치환

`/wiki-digest`는 이 저장소 안에서만 쓰므로 이미 `.claude/commands/wiki-digest.md`에 있고 별도 설치가 필요 없습니다.
