# llm_wiki 저장소 작업 지침

이 저장소는 "원본 로그 → 정제된 위키" 2단계 구조로 지식을 축적합니다.

## 구조

- `log/YYYY-MM-DD-<project>-<slug>.md`: append-only 원본 기록. 새 파일만 추가, 기존 파일은 `digested` 필드만 수정.
- `wiki/<topic>.md`: 주제별 정제 문서. 여러 log 항목의 내용이 여기로 통합됨.
- `wiki/README.md`: 전체 주제 목차 (digest 시 자동 갱신).

## `/wiki-digest` 실행 시 규칙

1. `log/*.md` 중 frontmatter `digested: false`(또는 없음)인 파일만 대상으로 한다. 이미 `digested: true`인 파일은 건드리지 않는다.
2. 각 로그의 내용을 검토해 어떤 `wiki/<topic>.md`에 속하는지 판단한다. 기존 주제와 겹치면 새 파일을 만들지 말고 기존 파일을 갱신한다.
3. 위키 문서는 "정제된" 지식만 담는다 — 로그의 잡담이나 세션 진행 상황이 아니라, 재사용 가능한 결론·패턴·트러블슈팅 노하우·설계 결정과 그 이유만 남긴다.
4. 관련 있는 다른 주제 문서는 `[[topic-name]]`으로 상호 링크한다.
5. 처리한 로그 파일은 frontmatter의 `digested`를 `true`로 바꾼다 (파일을 지우거나 옮기지 않는다 — 원본 기록은 보존).
6. `wiki/README.md`의 목차를 새/변경된 주제에 맞게 갱신한다.
7. 변경사항을 하나의 커밋으로 남긴다 (`git add log wiki && git commit`). push는 하지 않는다 — 사용자가 검토 후 직접 push.

## 새 주제 문서(`wiki/<topic>.md`) 작성 규칙

- 맨 위에 한 줄 요약.
- "왜"가 비직관적인 경우에만 이유를 남긴다 (당연한 내용은 생략).
- 코드/파일 경로를 인용할 때는 어느 프로젝트(log의 `project` frontmatter)에서 나온 내용인지 각주로 남긴다 — 위키만 보고도 원 출처를 추적할 수 있어야 한다.
