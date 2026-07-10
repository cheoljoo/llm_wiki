# Outlook Office.js Add-in + Jira Server REST API v2 패턴

사내 Jira Server/Data Center(`jira.lge.com`)에 이슈를 생성하는 Outlook task pane add-in 구현 패턴.

## Jira Server는 REST API v2 사용

- Atlassian Cloud는 v3(ADF 형식 description)이지만, 사내 Jira Server/Data Center는 REST API v2
  (`/rest/api/2/issue`)에서 plain text description을 지원한다.
- 요청 구조:
  ```json
  {
    "fields": {
      "project": { "key": "PROJECT_KEY" },
      "issuetype": { "name": "Task" },
      "summary": "...",
      "description": "plain text"
    }
  }
  ```

## 인증: Personal Access Token (PAT)

- `Authorization: Bearer <PAT>` 헤더로 인증.
- `jira.lge.com` → Profile → Personal Access Tokens에서 발급.
- PAT는 `localStorage`에만 저장(device-local); Exchange roaming settings는 보안상 쓰지 않는다.

## CORS 주의: 브라우저에서는 안 되고 curl에서는 되는 경우

Office.js task pane은 WebView2/EdgeHTML 브라우저 컨트롤에서 실행되므로 CORS 규칙이 그대로 적용된다.
`jira.lge.com`이 add-in 오리진에 대해 CORS 헤더를 내려주지 않으면 `fetch()`가 실패한다.
해결책: Jira 관리자에게 오리진 허용 요청 또는 로컬 프록시 백엔드 구성.

## manifest.xml 스키마 오류 2가지

`npx office-addin-manifest validate`로 검증 시 자주 나타나는 실수:

1. **`HighResIconUrl` → `HighResolutionIconUrl`**: 원소 이름 오타. `appforoffice/1.1` 스키마의 올바른 이름.
2. **`Group` 하위에 `Icon` 불가**: VersionOverrides의 `Group`은 `Label` → `Control` 순서만 허용.
   `Icon`은 `Control` 안에만 들어가야 한다.

## Office.js 핵심 API 패턴

```js
Office.onReady(() => { /* init */ });

const item = Office.context.mailbox.item;
// item.subject, item.from, item.to, item.dateTimeCreated, item.attachments

item.body.getAsync(Office.CoercionType.Text, (result) => {
  if (result.status === Office.AsyncResultStatus.Succeeded) {
    const bodyText = result.value;
  }
});
```

## Jira 이슈 생성 코드 패턴

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
      issuetype: { name: issueType },
      summary,
      description,   // plain text (Server/DC v2)
    },
  }),
});
const created = await res.json();
const issueUrl = `${baseUrl}/browse/${created.key}`;
```

## 프로젝트 레이아웃 (재사용 참고)

```
manifest.xml                 # VersionOverrides v1_0 + MessageReadCommandSurface
src/taskpane/taskpane.html   # Office.js CDN (appsforoffice.microsoft.com)
src/taskpane/taskpane.js     # Office.onReady → mailbox.item → body.getAsync
assets/icon-{16,32,64,80,128}.png
webpack.config.js            # office-addin-dev-certs (HTTPS, localhost:3000)
package.json                 # office-addin-dev-certs, office-addin-manifest, webpack
```

[[mcp-atlassian]] — Jira REST API 일반 연동 관련.

[^misc]: `misc` 프로젝트(`/home/cheoljoo.lee/code/misc`) Outlook Office.js add-in 구현 세션에서 정리.
