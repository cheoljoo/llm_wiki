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
project: payment-service
source_repo: /data01/cheoljoo.lee/code/payment-service
tags: [retry, kafka]
digested: false
---
```

- `end_time`: `/wiki-log` 실행 시점 (`date` 명령으로 정확히 구함).
- `start_time`: 이번 세션 중 변경된 파일들의 최초 수정시각으로 추정 (변경 파일이 없으면 `end_time`과 동일).

`digested: false`인 항목이 다음 `/wiki-digest` 실행 시 처리 대상입니다.
