---
start_time: 2026-07-18 10:25:22
end_time: 2026-07-18 10:33:09
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [makefile, documentation, developer-experience]
digested: true
---

# 거대 Makefile 문서화 — "전체 target 개별 설명" 대신 "섹션 단위 요약"으로 스코프 조정

## 요청과 스코프 문제

"Makefile에 있는 각각이 어떤 의미를 가지고 어떤 경우에 수행하는지 주석으로 달아달라"는
요청을 받았는데, 실제로 파일을 열어보니 target이 ~150개(그중 `##` 도움말 주석이 이미 달린
것만 109개)에 17개 섹션으로 나뉘어 있었다. "각각"이라는 표현만 보고 target 150개 전부에
개별 설명을 다는 방향으로 바로 들어갔다면 파일이 수천 줄 늘어나고 시간도 오래 걸렸을 것이다.

## 판단: 스코프를 먼저 확인

작업 착수 전에 `AskUserQuestion`으로 "섹션 단위 요약 / target 개별 상세 / 특정 파일 관련
target만" 세 가지 선택지를 제시했고, "섹션 단위 요약"으로 확정했다. 이미 각 target에는
`##` 한 줄 설명이 있으므로(대부분 `make help`에 노출되는 용도), 추가로 필요한 건 "이 섹션의
target들이 왜 존재하고 언제/어떤 순서로 쓰는지"에 대한 상위 맥락이었지 개별 명령어 설명의
중복이 아니었다. **작업량이 10배 이상 차이 나는 갈림길에서는, 시작 전에 한 번 물어보는 비용이
잘못된 방향으로 다 만들고 되돌리는 비용보다 훨씬 싸다**는 걸 다시 확인한 사례.

## 기존 좋은 사례를 스타일 기준으로 재사용

파일 안에 이미 `sage-commit-update-no-llm`, `sage-commit-llm`, `sage-commit-ccr`,
`sage-ccr-gerrit`, `sage-commit-check-llm-status`, `sage-commit-gerrit-info-check`,
`sage-ccr-connectwide` 섹션들은 섹션 헤더 바로 아래 2~4줄짜리 설명(무슨 테이블을 다루고,
어떤 순서로 다른 스크립트와 연결되는지)이 이미 잘 되어 있었다. 이걸 건드리지 않고, 설명이
없던 나머지 섹션(Gerrit, sage-llm, sage-oldest, sage-newest, sage-date-gpt,
prompt-key-generator, 그리고 이번 세션에서 가장 커진 sage-check-llm 섹션)에 **같은 톤과
분량**으로 맞춰 추가했다. "기존에 잘 된 부분을 스타일 가이드로 삼아 새 부분을 맞춘다"는
것은 코드 리팩터링뿐 아니라 문서/주석 작업에도 그대로 적용되는 원칙이다.

## 가장 크고 복잡한 섹션은 하위 그룹으로 쪼개서 설명

`sage-check-llm` 섹션은 실제로는 서로 다른 4가지 워크플로(① 구조 검사/재생성, ② 상태
집계/CSV export, ③ CSV 기반 부분 재질의, ④ JSON 파싱 실패 전체 재생성)가 하나의 섹션
헤더 아래 뭉쳐 있었다. 이걸 한 문단으로 뭉뚱그려 설명하는 대신, 섹션 상단에 4개 그룹의
관계(②의 출력이 ③의 입력이 되는 파이프라인 구조 등)를 먼저 요약하고, 각 하위 그룹
시작점(`sage-check-status:`, `sage-solve-problems-dry-run:`, `sage-solve-failures-dry-run:`
앞)에 짧은 `# -- N) ... --` 구분 주석을 추가해 "긴 섹션 안에 숨은 하위 구조"를 드러냈다.
섹션 헤더(`# ── x ──`)와 그 안의 하위 구분(`# -- N) ... --`)을 시각적으로 다른 굵기로 써서
계층을 구분한 것도 나중에 훑어볼 때 도움이 된다.

## 검증

`##` 텍스트는 건드리지 않고 `#` 설명만 추가했으므로 `make help` 출력에는 영향이 없음을
`make help` 실행으로 확인했고, `make -n <target>` 몇 개로 문법이 깨지지 않았음을 확인했다
— Makefile처럼 공백/탭에 민감한 파일에 주석만 추가할 때도 반드시 dry-run으로 검증하는 습관.
