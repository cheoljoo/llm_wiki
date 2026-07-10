---
date: 2026-07-10
start_time: 14:54:06
end_time: 12:36:32
who: charles.lee
project: misc
source_repo: /home/cheoljoo.lee/code/misc
branch: main
tags: [outlook, office-addin, office.js, jira, jira-server, jira-rest-api, personal-access-token, webpack, manifest-xml]
digested: false
---

# Outlook Office.js Add-in: Email to Jira (jira.lge.com)

## 작업 개요

Outlook 메일 읽기 화면에서 버튼 클릭으로 jira.lge.com(Jira Server/Data Center)에
이슈를 생성하는 Office.js task pane add-in을 처음부터 구현했다.

## 설계 결정 및 이유

### Jira REST API v2 선택
- jira.lge.com은 사내 Jira Server/Data Center이므로 REST API v2(`/rest/api/2/issue`) 사용
- Atlassian Cloud는 REST API v3(ADF 형식 description)를 쓰지만 Server/DC는 v2에서 plain text description 지원
- v2는 `{"fields": {"project": {"key":…}, "issuetype": {"name":…}, "summary":…, "description": "plain text"}}` 형태로 단순하다

### 인증: Personal Access Token (PAT)
- Bearer 토큰 헤더(`Authorization: Bearer <PAT>`)로 인증
- jira.lge.com → Profile → Personal Access Tokens에서 발급
- PAT는 `localStorage`에만 저장(device-local), Exchange roaming settings는 사용 안 함(보안 위험)

### CORS 주의사항
- Office.js task pane은 브라우저 컨트롤(WebView2/EdgeHTML)에서 실행되므로 CORS 규칙이 적용된다
- `jira.lge.com`이 add-in 오리진(`https://localhost:3000`)에 대해 CORS 헤더를 내려줘야 fetch 성공
- curl/Postman에서는 되지만 브라우저에서 안 될 수 있다 → Jira 관리자에게 오리진 허용 요청하거나 로컬 프록시 백엔드 구성 필요

## 트러블슈팅: manifest.xml 스키마 오류

`npx office-addin-manifest validate`에서 발견한 스키마 오류 2건:

1. **`HighResIconUrl` → `HighResolutionIconUrl`**: 원소 이름 오타.
   - `http://schemas.microsoft.com/office/appforoffice/1.1` 스키마에서 올바른 이름은 `HighResolutionIconUrl`

2. **`Group` 하위에 `Icon` 요소 불가**: VersionOverrides의 `Group`은 `Icon` 자식을 받지 않는다.
   - `Label` → `Control` 순서만 허용; `Icon`은 `Control` 안에만 들어가야 함

→ 두 수정 후 validate 통과, 지원 플랫폼: Outlook on Windows/Mac, Outlook on the web 전부 포함.

## 프로젝트 레이아웃 (재사용 패턴)

```
manifest.xml                 # VersionOverrides v1_0 + MessageReadCommandSurface
src/taskpane/taskpane.html   # Office.js CDN 스크립트 포함 (appsforoffice.microsoft.com)
src/taskpane/taskpane.css
src/taskpane/taskpane.js     # Office.onReady → mailbox.item → body.getAsync(Text)
assets/icon-{16,32,64,80,128}.png
webpack.config.js            # office-addin-dev-certs로 HTTPS dev server (localhost:3000)
package.json                 # office-addin-dev-certs, office-addin-manifest, webpack
```

## Office.js 핵심 API 패턴

```js
Office.onReady(() => { /* init */ });

const item = Office.context.mailbox.item;
item.subject          // string
item.from             // { displayName, emailAddress }
item.to               // Array<{ displayName, emailAddress }>
item.dateTimeCreated  // Date
item.attachments      // Array<{ name, … }>

// 본문은 비동기
item.body.getAsync(Office.CoercionType.Text, (result) => {
  if (result.status === Office.AsyncResultStatus.Succeeded) {
    const bodyText = result.value;
  }
});
```

## Jira REST API v2 이슈 생성 패턴

```js
const res = await fetch(`${baseUrl}/rest/api/2/issue`, {
  method: "POST",
  headers: {
    Authorization: `Bearer ${pat}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    fields: {
      project: { key: projectKey },
      issuetype: { name: issueType },   // "Task", "Bug" 등 이름 문자열
      summary,
      description,                       // plain text (Server/DC v2)
    },
  }),
});
const created = await res.json();
const issueUrl = `${baseUrl}/browse/${created.key}`;
```

## 개발 환경 시작 명령

```bash
cd email_to_jira_in_outlook
npm install
npm run dev-certs   # 자체서명 인증서 신뢰 등록 (최초 1회)
npm start           # https://localhost:3000 에서 webpack dev server 실행
# Outlook에서 manifest.xml 사이드로드 후 테스트
```
