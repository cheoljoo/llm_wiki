---
description: 새 Python 프로젝트를 ~/code/ 에 만들고 github.com/cheoljoo/ 에 같은 이름으로 올린다
user-invocable: true
---

새 프로젝트를 로컬(`~/code/<name>/`)과 GitHub(`github.com/cheoljoo/<name>`) 양쪽에 만든다.

## 1. 사용자에게 물어보기

인자가 주어졌더라도 **반드시 확인 질문을 한다**. `AskUserQuestion` **한 번**으로 다음 세 가지를 함께 받는다:

- **프로젝트 이름**: `~/code/<name>` 과 GitHub repo 이름으로 함께 쓰인다.
  소문자·하이픈 권장 (예: `my-tool`). 공백이나 `/`가 들어가면 다시 물어본다.
- **프로젝트 개요**: README.md에 들어갈 1~3문장 설명. 이 프로젝트가 무엇이고 무엇을 하는지.
- **공개 범위**: public(기본) / private. 첫 번째 선택지를 public으로 두어 그냥 넘기면
  public이 되게 한다.

## 2. 사전 확인

- `~/code/<name>` 이 이미 있으면 **중단하고 사용자에게 알린다.** 절대 덮어쓰지 않는다.
- `gh auth status`로 인증을 확인한다. 실패하면 3번의 토큰 안내를 따른다.

## 3. GitHub 인증

`gh`가 이미 인증돼 있으면 그대로 쓴다. 아니면 환경변수 `GITHUB_TOKEN`을 확인한다:

```bash
echo "$GITHUB_TOKEN" | gh auth login --with-token
```

둘 다 없으면 **여기서 멈추고** 사용자에게 안내한다 — 토큰을 https://github.com/settings/tokens
에서 `repo` 스코프로 발급받아 `export GITHUB_TOKEN=...` 하라고. 토큰을 대화창에 붙여넣지
말라고 함께 안내한다 (대화 기록에 남으면 유출로 간주해 폐기해야 한다).

**토큰 값을 파일에 쓰거나 커밋하지 않는다.** 항상 환경변수로만 읽는다.

### gh auth login
을 할때 export GITHUB_TOKEN=''
으로 설정 $ gh auth login 을 수행한다. 
web browser를 통해서 set하는게 제일 편하고 빠르다.

## 4. 로컬 스캐폴딩

`~/code/<name>/` 을 만들고 아래 파일을 채운다:

- **`.gitignore`** — Python용. 이 저장소(`llm_wiki`)의 루트 `.gitignore`가 GitHub의 표준
  Python 템플릿이므로 그대로 복사해 쓴다. 없으면
  `curl -sSL https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore` 로 받는다.
- **`LICENSE`** — Apache License 2.0 전문.
  `curl -sSL https://www.apache.org/licenses/LICENSE-2.0.txt` 로 받고,
  맨 끝 APPENDIX의 `[yyyy]`는 올해로, `[name of copyright owner]`는 `cheoljoo`로 바꾼다.
- **`README.md`** — **개요만** 넣는다. 제목(`# <name>`)과 사용자가 준 개요 문단, 그리고
  라이선스 한 줄. 설치법·사용법·기여 가이드 같은 건 넣지 않는다 (아직 코드가 없으므로
  추측해서 쓰면 거짓말이 된다).

## 5. Git 초기화 및 푸시

```bash
git init -b main
git add .
git commit -m "Initial commit: <name> 프로젝트 스캐폴딩"
gh repo create cheoljoo/<name> --<public|private> --source=. --remote=origin --push
```

`--public`/`--private`는 1번에서 사용자가 고른 값을 그대로 쓴다.

## 6. 보고

만든 로컬 경로와 GitHub URL을 알려준다. 커밋은 이 초기 커밋 하나만 남긴다.
