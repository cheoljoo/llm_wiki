---
start_time: 2026-07-14 06:27:16
end_time: 2026-07-14 11:13:53
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [sage-check-status, type-mismatch, echo, csv-export, teams-webhook, shell-script, python]
digested: true
---

# sage-check-status.py 타입 불일치 분석 강화 + CSV 출력 + Teams ON/OFF

## 타입 변환 가능/불가 판정 (`_CONVERTIBLE_TYPE_PAIRS`)

- `str ↔ bool/int/float`, `bool ↔ int`, `int ↔ float` → 변환가능
- `str → list/dict`: JSON 파싱으로 조건부 변환가능 (문자열이 JSON 형식이면) → 쌍에 추가
- `dict → list`: `dict.keys()` 로 항상 가능 → 쌍에 추가
- `list → dict`: **변환 불가** (가장 문제적 케이스)
- `_convertible_counts(type_map, dominant_type)` 함수: (변환가능, 변환불가) 카운트 반환

## 타입 불일치 출력 개선

- 1레벨·2레벨 경고 모두 `변환가능=N건, 변환불가=M건` 추가
- **비변환가능 케이스에 예시 3건 자동 표시** — `type_value_samples` dict에 `(model, key_path, type)` 키로 최대 3건 수집
  - level-1: `(model, key1, type)`
  - level-2: `(model, "key1.key2", type)`
- `list → dict` 같은 비변환가능 불일치에서 실제 issue_id + 값 스니펫이 함께 출력됨

## 요약 테이블 컬럼 추가

- `타입 불일치` (기존): 전체 불일치 건수
- `타입 복원` (신규): 그 중 변환가능한 건수 (모델별 세부 포함)
- ECHO 필드 경로 표시: `echo_include` CSV 컬럼이 `Y` 대신 실제 field_path 목록 표시 (`_find_echo_fields` 재사용)

## CSV 내보내기 (`--export-issues-csv`)

- 컬럼: `ISSUE_ID, prompt_file, model, type_mismatch, key_mismatch, echo_include`
- unique key: `(ISSUE_ID, prompt_file, model)` → 모델별 1행
- `type_mismatch`: `key=실제타입(expect:dominant타입)` 형식 (해당 모델에서 dominant와 다른 key만)
- `key_mismatch`: 해당 모델에서 누락된 key 이름만 (model: prefix 제거)
- `echo_include`: `_find_echo_fields()`로 얻은 field_path 목록 (빈 문자열이면 공백)
- 기본값: `sage-check-status-problems.csv`

## Teams ON/OFF 토글 (shell 스크립트 2개)

`sage_check_status.sh` 및 `sage-update-prompt-from-newest-with-exaone-loop.sh` 양쪽에 동일 패턴 적용:

```bash
# ▼▼  Teams POST ON/OFF  ▼▼
TEAMS_ENABLED="ON"   # ON | OFF

send_teams_message() {
    [ "${TEAMS_ENABLED}" != "ON" ] && return 0   # OFF 시 즉바로 리턴
    ...
}
```

→ 한 줄만 바꾸면 전체 Teams 전송 비활성화. 코드 변경 없이 디버그/운영 전환 가능.

## sage-check-status.py 에서 ECHO/key 누락 DB 저장 여부 확인

- `sage_llm_summary.py`: ECHO 체크 없음 → ECHO 있어도 DB 저장됨
- PER_KEY_RETRY 결과: 부분 성공(≥1 key 채워짐) → DB 저장, 완전 실패(0 key) → 저장 안 함 + CSV 기록
- 타입 불일치는 `sage-check-status.py` 통계 전용 (재생성 트리거 없음)
- ECHO/key 누락 감지는 `sage-check-llm-answer.py`가 기존 DB 데이터 읽어서 `regenerate_candidates` 추가 → LLM 재쿼리 후 DB 저장
