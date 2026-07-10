---
start_time: 2026-07-10 03:34:57
end_time: 2026-07-10 16:24:20
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [exaone, semaphore, adaptive-worker, slot-timeout, sage_llm_summary, threading]
digested: false
---

# EXAONE 슬롯 획득 실패 원인 분석 및 adaptive worker 증가 비활성화

## 문제 상황

```
[04:12:53] [ERROR][sage_llm_summary][_call_llm_single] EXAONE 슬롯 획득 실패 (exaone)
[batch=149, worker=ThreadPoolExecutor-262_32, ticket=1/5] — vlm=HMCCCIC-55844:
EXAONE 슬롯 획득 실패: 420.0초 타임아웃 → TIMEOUT_SENTINEL 반환 (해당 ticket skip)
```

## 원인 분석

### 슬롯 구조

`_ExaoneKeySlot`: API 키 1개에 대해 `threading.Semaphore(MAX_WORKERS_EXAONE=5)` 보유.
`_acquire_exaone_slot()`: 라운드로빈으로 활성 슬롯을 찾아 `try_acquire(blocking=False)` 반복.

```
총 슬롯 = N_keys × 5
timeout_sec = 420초 (이전: 300초 → 이번 변경으로 420초로 상향)
```

### 420초 타임아웃 발생 조건

| 원인 | 설명 |
|------|------|
| 슬롯 포화 + 장시간 점유 | EXAONE timeout이 `120 × attempt`(최대 360초)까지 증가 → 먼저 들어간 worker가 슬롯을 장시간 점유 |
| adaptive 증가 악화 | `_initial_workers`가 이미 EXAONE 총 슬롯과 같은 수인데도 정상 완료 시마다 `+1` → 슬롯 초과 요청 |

### adaptive 증가 로직의 문제

```python
# 변경 전
_initial_workers = max(INITIAL_WORKERS, _exaone_key_count * MAX_WORKERS_EXAONE)
# 이미 EXAONE 최대 슬롯 수로 시작
_max_workers = _exaone_key_count * MAX_WORKERS_EXAONE + MAX_WORKERS_OTHER
# 성공 시 OTHER 슬롯만큼 더 증가 → EXAONE 슬롯 초과 요청 유발
```

EXAONE 전용 실행 시 `_initial_workers == N_keys × 5` (이미 포화) 상태에서
정상 완료마다 worker +1 → 슬롯 총량 이상의 배치가 동시 진입 → 슬롯 고갈 → 420s timeout 반복 악화.

## 수정 내용

```python
# 변경 후 (sage_llm_summary.py)
_only_exaone = all(m in _EXAONE_MODELS for m in self.models)
if _only_exaone:
    # EXAONE 전용: adaptive 증가 없이 고정 (슬롯 총량 == _initial_workers)
    _max_workers = _initial_workers
else:
    _max_workers = _exaone_key_count * MAX_WORKERS_EXAONE + MAX_WORKERS_OTHER
```

`_cur_workers[0] < _max_workers` 조건이 항상 false → 정상 완료 후에도 worker 수 불변.

## 설계 원칙 (재사용 가능한 교훈)

**Semaphore 기반 adaptive 조정 시 주의점**:
- `_initial` 값이 이미 실제 서버 한계와 일치할 때 `_max > _initial`로 설정하면 역효과.
- adaptive 증가는 서버가 여유 있을 때 처리량을 높이는 것이 목적 — 이미 포화 상태라면 고정이 맞다.
- EXAONE + GPT 혼합 실행 시에는 GPT 슬롯(`MAX_WORKERS_OTHER=10`)을 활용하기 위해 증가가 의미 있으므로 기존 동작 유지.

## 기타 변경

- `_acquire_exaone_slot` timeout: 300s → 420s 상향 (LLM 처리 시간이 긴 ticket 대응)
- `MAX_RUN_HOURS`: 6 → 8 상향
- `issue_exaone_key_list` → `commit_exaone_key_list`로 키 소스 변경
