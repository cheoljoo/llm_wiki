---
start_time: 2026-07-10 16:20:32
end_time: 2026-07-10 16:55:52
who: charles.lee
project: pvs_crawler
source_repo: /home/cheoljoo.lee/code/pvs_crawler
branch: master
tags: [sage_llm_summary, exaone, adaptive-worker, preloaded-rows, timeout, key-list]
digested: false
---

# sage_llm_summary.py — EXAONE 안정화 및 preloaded_rows 지원

## 1. commit_exaone_key_list 로 키 교체

`issue_exaone_key_list` → `commit_exaone_key_list` 로 변경.
커밋 처리 전용 키 풀과 이슈 처리 전용 키 풀을 분리해 자원 경쟁을 줄임.

## 2. EXAONE adaptive worker 증가 비활성화

`_only_exaone=True` 인 경우 `_max_workers = _initial_workers` 로 고정.

```python
if self._only_exaone:
    _max_workers = _initial_workers   # 슬롯 총량 초과 요청 방지
```

**이유**: EXAONE은 키당 동시 요청 한도가 낮아서, adaptive 증가가 오히려
429/timeout을 유발. 처음부터 고정 worker 수로 운영하면 안정적이다.

## 3. `_acquire_exaone_slot` timeout 300s → 420s

모든 EXAONE 슬롯이 rate-limit 상태일 때 대기하는 최대 시간을 300 → 420초로 늘림.
배치 실행이 길어질수록 여러 슬롯이 일시적으로 막히는 빈도가 높아지는 점을 반영.

## 4. MAX_RUN_HOURS 6 → 8

장시간 배치(특히 EXAONE 전용 실행)가 6시간 내에 완료되지 않는 케이스가 발생해
기본값을 8시간으로 늘림. `--max-run-hours` CLI 옵션으로 여전히 오버라이드 가능.

## 5. preloaded_rows_by_issue_id 지원 (SQL 재조회 생략)

`SageLLMSummary` 생성자에 `preloaded_rows_by_issue_id: Optional[dict]` 추가.
`sage-check-llm-answer`가 확장된 `SQL_FETCH_BASE`로 이미 로드한 row를 재사용하면
`--issues` 지정 시 두 번째 DB 조회를 생략할 수 있다.

```python
if self.issue_ids and self.preloaded_rows_by_issue_id:
    rows = [self.preloaded_rows_by_issue_id[iid] for iid in self.issue_ids
            if iid in self.preloaded_rows_by_issue_id]
    return rows
elif self.issue_ids:
    # 기존 로직 (SQL 직접 조회)
    ...
```

**포인트**: `preloaded_rows_by_issue_id` 가 있더라도 `issue_ids` 가 함께 없으면
기존 경로를 타므로 하위 호환이 유지된다.

## 6. save_prompt 파라미터 추가

`save_prompt: bool = False` — `True` 시 치환된 프롬프트를 `debug/` 디렉토리에 저장.
`--issues` CLI 전용 디버그 용도로, 프로덕션 배치에는 영향 없음.

## 7. sage-check-llm-answer.py / sage-check-status.py — 출력 개선

- JSON 실패 CSV 스킵 로그에 `csv file=<path>` 표기 추가 (어느 파일을 참조하는지 명확화).
- sage-check-status.py: prompt 버전별 fancy_grid 요약 테이블 (이전 세션에 커밋).

## 배운 점

- EXAONE처럼 동시 요청 한도가 낮은 LLM 풀은 adaptive worker 증가가 역효과를 낼 수 있다.
  `_only_exaone` 같은 플래그로 전략을 분기하는 것이 안전하다.
- 호출자(checker)에서 이미 DB를 조회했다면, `preloaded_rows` dict를 내려보내
  중복 SQL을 제거하는 패턴은 간단하면서도 효과적이다.
- timeout 상향 시 `MAX_RUN_HOURS` 도 함께 검토해야 한다 — 슬롯 대기 시간이 늘면
  전체 실행 시간도 늘어난다.
