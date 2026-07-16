# Python 재사용 패턴

여러 프로젝트에서 반복 등장하는 Python 구현 패턴 모음.

## `builtins.print` 오버라이드로 전체 출력에 타임스탬프 prefix 추가

기존 코드를 건드리지 않고 모든 `print()` 호출에 타임스탬프를 붙이고 싶을 때 유용하다.

```python
import builtins as _builtins
from datetime import datetime as _dt

_orig_print = _builtins.print

def _tprint(*args, **kwargs):
    if not args or args == ("",):
        _orig_print(*args, **kwargs)   # 빈 줄은 타임스탬프 없이
        return
    now = _dt.now().strftime("%H:%M:%S")
    _orig_print(f"[{now}]", *args, **kwargs)

_builtins.print = _tprint
```

**포인트**:
- `tabulate()` 같은 라이브러리는 문자열을 반환할 뿐 `print()`를 직접 호출하지 않으므로,
  builtins 오버라이드가 라이브러리 내부 동작에 영향을 주지 않는다.
- 빈 줄(`print()`, `print("")`)은 타임스탬프를 붙이지 않아 출력이 지저분해지지 않는다.
- 모듈 수준에서 한 번만 실행하면 같은 프로세스 안의 모든 `print()` 호출에 적용된다.

[^pvs_crawler]

## 호출자가 이미 가진 데이터는 인자로 받아 재조회를 생략한다

같은 데이터를 두 곳(예: 상위 checker와 하위 처리 클래스)에서 각각 DB/API로 조회하면 중복
비용이 든다. 하위 클래스 생성자에 `Optional[dict]` 형태의 "preloaded" 인자를 추가해, 호출자가
이미 가진 데이터를 넘기면 그걸 쓰고 없으면 기존 조회 경로를 그대로 타게 하면(두 조건 — 조회
대상 id 목록과 preloaded dict — 이 함께 있어야 preloaded 경로를 타도록) 하위 호환을 유지하면서
중복 조회를 없앨 수 있다.

```python
if self.issue_ids and self.preloaded_rows_by_issue_id:
    rows = [self.preloaded_rows_by_issue_id[iid] for iid in self.issue_ids
            if iid in self.preloaded_rows_by_issue_id]
elif self.issue_ids:
    rows = self._fetch_from_sql(self.issue_ids)  # 기존 경로 (하위 호환)
```

[[pvs-crawler-sage-llm-pipeline]]

[^pvs_crawler]

[^pvs_crawler]: `pvs_crawler` 프로젝트(`/home/cheoljoo.lee/code/pvs_crawler`)의
  `sage-check-status.py`, `sage_llm_summary.py` 개선 세션들에서 정리.
