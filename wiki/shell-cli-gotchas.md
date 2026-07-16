# 셸/CLI 사용 중 겪은 함정들

## 아주 긴 경로를 인자로 받으면 CLI가 알 수 없는 에러를 낼 수 있다

에이전트 세션의 스크래치패드처럼 깊고 긴 경로(`/tmp/claude-.../<uuid>/scratchpad/...`)에 만든 파일을
`crontab <path>`에 바로 넘기니 `crontab: No such file or directory`(파일은 분명히 존재하는데도) 에러가
났다. `/tmp/짧은이름.txt`로 복사해서 넘기니 바로 됐다.

일부 CLI 바이너리는 내부적으로 경로 길이/버퍼에 제약이 있는 것으로 보인다. 파일이 분명히 존재하는데
"파일이 없다"는 에러가 나면, 경로 길이를 의심하고 짧은 경로로 복사해서 재시도해볼 것.

[^hermes]

## bash `$()` 안에서 싱글쿼트 속 괄호는 라인이 길어지면 파싱이 깨질 수 있다

- **증상**: `line 86: syntax error near unexpected token ')'`
- **원인**: 에디터가 긴 라인을 자동 줄바꿈하면서 `grep -oP '(?<=TAG] )\d+'`의 `(?`가 두 줄로
  갈라짐. bash는 `$()` 내부를 파싱할 때 싱글쿼트 안에 있는 `(`/`)`도 괄호 깊이로 카운팅하기
  때문에, 줄바꿈으로 토큰 위치가 밀리면 엉뚱한 곳의 `)`에서 문법 오류가 난다.
- **해결**: lookbehind regex(`(?<=...)`)를 제거하고 `awk '{print $NF}'` 같은 괄호 없는 방식으로
  대체.
- **교훈**: `$()` 안에서 싱글쿼트 내부에 `(`/`)`가 들어가는 패턴(특히 `grep -oP` lookbehind)은
  라인이 길어지면 위험하다 — `awk`/`sed`로 우회하는 게 안전.

[^pvs_crawler]

## Teams webhook 같은 곳에 보낼 메시지의 줄바꿈은 `printf`로 만들어야 한다

bash 큰따옴표 문자열 안에 직접 적은 `\n`은 실제 줄바꿈이 아니라 리터럴 `\n` 두 글자다. 그대로
Teams MessageCard JSON의 `text` 필드에 넣어 보내면 `\n` 두 글자가 화면에 그대로 출력된다.
`"$(printf 'line1\nline2')"`처럼 `printf`로 값을 만들어서 변수에 담아야 실제 줄바꿈이 들어간다.
단, `tail -n 50 "${LOGFILE}"`처럼 명령 출력 자체에 이미 실제 줄바꿈이 포함된 값은 이 문제와
무관하므로 별도 처리가 필요 없다 — 문제는 "셸 스크립트에 직접 작성한 멀티라인 문자열 리터럴"에서만
생긴다.

[^pvs_crawler]

## `uv run`이 프로젝트 내 `.venv`를 만들어 `pipenv`와 충돌할 수 있다

같은 프로젝트에서 `pipenv`와 `uv`를 함께 쓰면, `uv run`이 기본적으로 프로젝트 루트에 `.venv`를
새로 만들면서 pipenv가 이미 매핑해둔 가상환경 경로와 충돌한다. `UV_PROJECT_ENVIRONMENT`
환경변수로 uv 전용 가상환경 경로를 프로젝트 밖으로 지정하면 분리된다.

```bash
export UV_PROJECT_ENVIRONMENT="${HOME}/.local/share/uv/envs/pvs_crawler"
```

주의:
- 해당 경로에 아직 가상환경이 없으면 `uv run python -c "import sys; print(sys.prefix)"`가 uv venv가
  아니라 base Python 경로를 반환한다 — 최초 1회 `uv sync`를 실행해야 실제로 분리된 venv가 만들어진다.
- `uv venv --show-path`라는 옵션은 존재하지 않는다. 실제 사용 중인 인터프리터 경로 확인은
  `uv run python -c "import sys; print(sys.prefix)"`로 한다.

[^pvs_crawler]

[^hermes]: `hermes` 프로젝트(`/data01/cheoljoo.lee/code/hermes`) 운영 세션 중 `crontab` 설치에서
  겪은 사례.

[^pvs_crawler]: `pvs_crawler` 프로젝트(`/home/cheoljoo.lee/code/pvs_crawler`)의 셸 스크립트
  (`sage_check_status.sh` 등)에서 Teams webhook 통합, `count-only` 루프, `uv`/`pipenv` 병행 사용을
  정리하며 겪은 함정들. [[pvs-crawler-sage-llm-pipeline]]
