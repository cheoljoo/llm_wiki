# log/

원본(raw) 기록 보관소. **append-only** — 새 파일 추가만 하고, 기존 파일 내용은 수정하지 않습니다
(단, `/wiki-digest`가 처리 완료 표시를 위해 `digested` 필드만 갱신).

이 폴더의 파일은 사람이 직접 쓰지 않고 `/wiki-log` 슬래시 커맨드로만 생성됩니다.

## 파일명 규칙

```
YYYY-MM-DD-<project>-<slug>.md
```

예: `2026-07-06-payment-service-retry-storm-fix.md`

## Frontmatter

```yaml
---
date: 2026-07-06
start_time: 13:50:12
end_time: 14:32:07
who: cheoljoo.lee
project: payment-service
source_repo: /data01/cheoljoo.lee/code/payment-service
branch: fix/retry-storm
tags: [retry, kafka]
digested: false
---
```

- `end_time`: `/wiki-log` 실행 시점 (`date` 명령으로 정확히 구함).
- `start_time`: 이번 세션 중 변경된 파일들의 최초 수정시각으로 추정 (변경 파일이 없으면 `end_time`과 동일).
- `who`: 기록한 사람 (`git config user.name`, 없으면 `user.email` 또는 `whoami`로 대체). 여러 사람이 이 저장소에 기록을 남기므로 누가 남긴 내용인지 추적하기 위함.
- `branch`: 세션 당시 `source_repo`에서 작업 중이던 git 브랜치. git 저장소가 아니면 생략. 어떤 작업 라인(feature/hotfix 등)에서 나온 내용인지 추적하기 위함.

`digested: false`인 항목이 다음 `/wiki-digest` 실행 시 처리 대상입니다.
