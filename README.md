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
개인 clone 경로는 커맨드 파일에 직접 적지 않고, 개인 설정 파일 하나에 저장합니다 —
그래야 `tooling/commands/wiki-log.md`가 git으로 업데이트돼도 매번 경로를 다시 적어 넣을 필요가 없습니다.

1. 이 저장소를 원하는 위치에 clone
2. 본인의 clone 절대경로를 설정 파일에 한 번 기록:
   ```
   mkdir -p ~/.config/llm_wiki
   echo "<본인의 llm_wiki clone 절대경로>" > ~/.config/llm_wiki/repo_path
   ```
3. `tooling/commands/wiki-log.md`를 `~/.claude/commands/wiki-log.md`로 그대로 복사 (수정 없이)

이후 저장소를 `git pull`로 갱신해서 `tooling/commands/wiki-log.md`가 바뀌면,
2번은 그대로 둔 채 3번(복사)만 다시 하면 됩니다.

`/wiki-digest`는 이 저장소 안에서만 쓰므로 이미 `.claude/commands/wiki-digest.md`에 있고 별도 설치가 필요 없습니다.
