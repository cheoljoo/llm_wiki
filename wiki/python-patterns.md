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

[^pvs_crawler]: `pvs_crawler` 프로젝트(`/home/cheoljoo.lee/code/pvs_crawler`) `sage-check-status.py` 개선 세션에서 정리.
