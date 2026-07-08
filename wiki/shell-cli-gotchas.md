# 셸/CLI 도구가 아주 긴 경로를 인자로 받으면 알 수 없는 에러를 낼 수 있다

에이전트 세션의 스크래치패드처럼 깊고 긴 경로(`/tmp/claude-.../<uuid>/scratchpad/...`)에 만든 파일을
`crontab <path>`에 바로 넘기니 `crontab: No such file or directory`(파일은 분명히 존재하는데도) 에러가
났다. `/tmp/짧은이름.txt`로 복사해서 넘기니 바로 됐다.

일부 CLI 바이너리는 내부적으로 경로 길이/버퍼에 제약이 있는 것으로 보인다. 파일이 분명히 존재하는데
"파일이 없다"는 에러가 나면, 경로 길이를 의심하고 짧은 경로로 복사해서 재시도해볼 것.

[^hermes]

[^hermes]: `hermes` 프로젝트(`/data01/cheoljoo.lee/code/hermes`) 운영 세션 중 `crontab` 설치에서
  겪은 사례.
