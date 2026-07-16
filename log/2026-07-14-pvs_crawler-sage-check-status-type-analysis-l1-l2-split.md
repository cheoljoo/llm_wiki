---
start_time: 2026-07-14 10:37:49
end_time: 2026-07-14 16:25:41
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [sage-check-status, type-mismatch, level2, ticket-count, csv-export, empty-value, orjson, wiki-doc]
digested: true
---

# sage-check-status.py 타입 분석 정확도 대폭 개선 (L1/L2 분리, 빈값, list_c/nc 인코딩)

## 타입 불일치 수집/표시 전면 개선

### list_c / list_nc 인코딩
`ticket_compact` 저장 시 `list` 타입을 두 가지로 분류:
- `list_c` : 빈 list(`[]`) 또는 `list[0]` 이 dict → `list→dict` 변환가능
- `list_nc` : 비어있지 않고 `list[0]` 이 dict 아님 → 변환불가

이 인코딩 덕분에 per-ticket 후처리에서 **타입 복원 오버카운트 수정**:
- 이전: `list→dict` 는 모두 "?" (조건부) → 전부 복원 가능으로 카운트 → `타입 복원 = 타입 불일치` (잘못됨)
- 이후: `list_nc→dict` 는 명시적으로 `_all_cv = False`

### 빈 값 (`[]`, `{}`, `''`) 상호 변환 가능
`_is_value_convertible()`에 빈 값 early return 추가:
```python
if isinstance(value, (list, dict)) and len(value) == 0:
    return True
if isinstance(value, str) and value == "":
    return True
```
NC 버킷 수집 조건도 수정: `bool(value1)` → `len(value1) == 0` 으로 빈 list 제외.

### str 타입 수집 시점 분류
`_classify_str_value()` 함수로 수집 시점에 str 값을 분류:
- `"bool"` : `value.lower() in _BOOL_STRINGS`
- `"list"` : 첫 글자 `[` + JSON 파싱 성공
- `"dict"` : 첫 글자 `{` + JSON 파싱 성공
- `"none"` : 변환 불가
→ `type_value_samples_conv[(model, key, "str", target_type)]` 버킷에 conv 확정 샘플 저장
→ `type_value_samples_nc[(model, key, "str")]` 버킷에 nc 확정 샘플 저장

### 변환가능/불가 예시 보장
`type_value_samples_nc` + `type_value_samples_conv` 두 버킷 덕분에:
- 분포 99.9% 가 conv 인 경우에도 nc 샘플 3건 표시 가능 (확정 버킷에서 직접)
- str 변환가능 샘플도 conv 버킷 우선 사용

## L1 / L2 분리 집계

### ticket_compact에 level-2 타입도 수집
1st pass에서 dict 값 내부의 sub-key 타입도 `key1.key2` 경로로 저장:
```python
for _ck2, _cv2 in _cv.items():
    _cp_m[f"{_ck}.{_ck2}"] = enc_type
```

### L1 / L2 별도 dominant types 계산
```python
_dom_g   = {model: {key: dominant_type}}         # level-1
_dom_g2  = {model: {"key1.key2": dominant_type}} # level-2
```

### 테이블 컬럼 변경
| 이전 | 이후 |
|---|---|
| 타입 불일치 | 타입 불일치(L1) |
| 타입 복원 | 타입 복원(L1) |
| (없음) | 타입 불일치(L2) |
| (없음) | 타입 복원(L2) |

## 중복 표시 버그 수정
- global 2레벨 섹션에 중복 코드 블록이 삽입되어 예시가 2번 출력되는 버그 수정
- `변환불가=0건`인데 변환불가 예시가 표시되는 문제: `not_conv == 0` → `_nc_ex = []` 가드 추가

## 구 형식 제거
- `└ [list→dict 변환가능 예시(N건)]` 줄 2곳 제거 (신 형식 `✓/✗` 방식으로 통일)

## DB 저장 동작 재확인
- ECHO / key 누락이 있어도 DB에 저장됨 (PER_KEY_RETRY 부분 성공 시)
- 타입 불일치는 집계 전용 — 재생성 트리거 없음
- `sage-check-status.py` 는 기존 DB 데이터 읽기 전용 (쓰기 없음)

## 기타 개선
- `--max-tickets N` : SQL LIMIT + Python 조기 종료 → 테스트 모드 속도 대폭 향상
- `sage_llm_summary.md` 섹션 9 추가 (오늘 변경 전체 문서화)
