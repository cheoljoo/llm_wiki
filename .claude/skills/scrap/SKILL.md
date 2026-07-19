---
name: scrap
description: Scrapling으로 웹사이트를 스크래핑한다. "이 사이트에서 ~를 가져와줘", "youtube에서 ~를 검색해서 받아줘", "~ 제품을 모두 가져와줘"처럼 사이트 URL이나 자연어 요청이 뒤에 붙는다. Scrapling MCP 서버(get/fetch/stealthy_fetch 등)가 연결돼 있으면 그것을 우선 쓰고, 없으면 scrapling CLI/파이썬 코드로 직접 수행한다.
user-invocable: true
---

`$ARGUMENTS`로 사이트 URL 또는 자연어 요청("유튜브에서 OOO 검색해서 자막 요약해줘", "이 사이트의 상품을 전부 가져와줘" 등)을 받는다.
URL이 없으면 요청 내용에서 어떤 사이트를 대상으로 해야 하는지부터 판단한다 (예: "유튜브에서 검색" → youtube.com 검색 URL 구성).

## 0. 실행 경로 결정

두 가지 실행 경로가 있다. **MCP가 연결돼 있으면 MCP를 우선 사용한다** — 세션 관리, 스텔스 우회,
토큰 절약(CSS selector로 본문만 추출)이 이미 돼 있어 직접 코드를 짜는 것보다 안정적이다.

1. 이 세션에 `ScraplingServer`(또는 이름이 다르더라도 `get`/`fetch`/`stealthy_fetch`/`screenshot` 같은
   도구를 제공하는) MCP가 연결돼 있는지 확인한다.
2. 연결돼 있으면 → **1번(MCP 경로)**으로 진행.
3. 연결돼 있지 않으면 → **2번(CLI/코드 경로)**으로 진행. 이때 사용자에게 "MCP 서버를 연결하면 세션
   유지, Cloudflare 우회, 토큰 절약(main_content_only)이 자동으로 되니 설치를 권장한다"고 한 줄 안내하고
   (아래 "MCP 서버 설치" 참고), 계속 진행 여부는 사용자 결정에 맡기지 말고 CLI 경로로 바로 진행한다
   (이미 요청받은 스크래핑 작업 자체는 막지 않는다).

## 1. MCP 경로 (권장)

Scrapling MCP가 제공하는 도구:

| 도구 | 용도 |
|---|---|
| `get` / `bulk_get` | 정적 페이지, 빠른 HTTP 요청 (JS 렌더링 불필요할 때) |
| `fetch` / `bulk_fetch` | JS 렌더링이 필요한 동적 페이지 (Chromium 사용) |
| `stealthy_fetch` / `bulk_stealthy_fetch` | Cloudflare 등 봇 차단이 강한 사이트 우회 |
| `open_session` / `close_session` / `list_sessions` | 로그인 유지 등 여러 요청에 걸친 브라우저 세션 관리 |
| `screenshot` | 페이지 스크린샷 (PNG/JPEG) |

공통 파라미터: `url`(또는 `urls`), `extraction_type`(markdown/html/text, 기본 markdown),
`css_selector`(범위 축소로 토큰 절약), `main_content_only`(기본 true, 광고/네비 제거),
`timeout`, `cookies`, `proxy`. 스텔스 계열은 `solve_cloudflare`, `hide_canvas`, `block_webrtc`도 지원.

절차:

1. 대상이 정적/단순 페이지로 보이면 `get`부터 시도한다 (가장 빠름).
2. 결과가 비어있거나 JS로 렌더링되는 콘텐츠(무한 스크롤, SPA 등)로 판단되면 `fetch`로 재시도한다.
3. `fetch`도 막히면(403, Cloudflare 챌린지 등) `stealthy_fetch`로 올린다.
4. 여러 URL(검색 결과 목록, 상품 목록 페이지들)을 한 번에 가져와야 하면 `bulk_get`/`bulk_fetch`/`bulk_stealthy_fetch`를 쓴다.
5. 필요한 데이터 범위가 명확하면(예: 상품 카드, 자막 블록) `css_selector`로 좁혀서 요청한다 — 불필요한 페이지 전체를
   끌고 오지 않도록 한다.
6. 로그인 세션이 필요하거나(마이페이지, 검색 후 페이지네이션 등) 같은 사이트에 여러 번 접근해야 하면
   `open_session`으로 세션을 열고 재사용한 뒤, 작업이 끝나면 `close_session`으로 반드시 정리한다.
7. 받아온 markdown/html/text에서 요청받은 항목(제품명, 가격, 자막 등)을 정리해 사용자에게 표 또는
   목록 형태로 제공한다. 원본 페이지 전체를 그대로 붙여넣지 않는다.

### YouTube 검색 예시

"유튜브에서 OOO 검색해서 XX를 받아줘" 요청 시:

1. `https://www.youtube.com/results?search_query=<검색어 URL 인코딩>` 을 `fetch`(YouTube는 JS 렌더링 필요)로 가져온다.
2. 검색 결과에서 영상 제목/링크를 추출한다 (`css_selector`로 결과 목록만 좁히면 좋다).
3. 사용자가 요청한 게 자막/설명 요약이면, 개별 영상 URL을 다시 `fetch`해 필요한 정보를 뽑는다.
   자막 자체는 YouTube 페이지 스크래핑만으로는 안 나올 수 있다 — 안 나오면 그렇다고 사용자에게 알린다
   (추측해서 지어내지 않는다).

### 사이트 전체 수집 (예: "OOO 제품을 모두 가져와줘")

1. 목록/카테고리 페이지를 먼저 가져와 페이지네이션 구조(다음 페이지 링크, `?page=` 파라미터 등)를 파악한다.
2. 전체 페이지 수 또는 다음 링크를 반복 추적하며 `bulk_get`/`bulk_fetch`로 모은다.
3. 상품 상세까지 필요하면 목록에서 얻은 링크들을 다시 `bulk_get`/`bulk_fetch`한다.
4. 결과가 많으면(수십~수백 건) 사용자에게 파일(CSV/JSON 등)로 저장해 줄지 확인한다 — 대화창에 전부
   출력하면 낭비다.

## 2. CLI / 파이썬 코드 경로 (MCP 미연결 시)

### 설치 확인 및 안내

```bash
python3 -c "import scrapling" 2>&1
```

없으면 사용자에게 설치를 요청한다 (자동으로 pip install을 실행하지 않는다 — 가상환경/의존성 관리
방침은 프로젝트마다 다르므로):

```bash
pip install "scrapling[fetchers]"
scrapling install   # 브라우저 등 시스템 의존성 다운로드 (최초 1회)
```

### 빠른 1회성 조회: CLI

```bash
scrapling extract <url> '<css selector>'
```

### 대화형 탐색 (selector를 모를 때)

```bash
scrapling shell
```

### 파이썬 코드로 수행 (반복/후처리가 필요할 때)

```python
from scrapling.fetchers import Fetcher, DynamicFetcher, StealthyFetcher

# 정적 페이지
page = Fetcher.fetch('https://example.com')

# JS 렌더링 필요
page = DynamicFetcher.fetch('https://example.com', network_idle=True)

# 봇 차단 우회 필요
page = StealthyFetcher.fetch('https://example.com', headless=True)

# 추출 — adaptive=True면 사이트 구조가 바뀌어도 같은 요소를 재탐색
items = page.css('.product', adaptive=True)
for item in items:
    print(item.css('h2::text').get(), item.css('.price::text').get())
```

선택자 우선순위: `page.css(...)` → 안 되면 `page.xpath(...)` → 텍스트로만 찾을 수 있으면
`page.text_search('키워드')`.

여러 페이지를 체계적으로 순회해야 하는 큰 작업(사이트 전체 크롤)이면 `scrapling.spiders.Spider`를
쓰는 것도 고려한다:

```python
from scrapling.spiders import Spider, Response

class TargetSpider(Spider):
    name = "target"
    start_urls = ["https://example.com/"]

    async def parse(self, response: Response):
        for item in response.css('.product'):
            yield {"title": item.css('h2::text').get()}

TargetSpider().start()
```

## MCP 서버 설치 (참고 안내용)

사용자가 MCP 연결을 원하면 안내한다 (설치 자체를 이 스킬이 대신 실행하지 않는다 — 클라이언트
설정 파일 편집이 필요하므로 사용자 확인 후 진행):

```bash
pip install "scrapling[ai]"
scrapling install
```

Claude Code/Desktop 설정(mcpServers)에 추가:

```json
{
  "mcpServers": {
    "ScraplingServer": {
      "command": "scrapling",
      "args": ["mcp"]
    }
  }
}
```

## 공통 주의사항

- robots.txt나 이용약관상 명백히 스크래핑이 금지된 사이트, 로그인 없이 접근 불가한 개인정보 페이지는
  진행 전에 사용자에게 확인한다.
- 대량 요청 시 대상 서버에 과도한 부하를 주지 않도록 `bulk_*` 도구의 동시성/딜레이 옵션을 과하게 낮추지 않는다.
- 스크래핑 결과를 리포지토리에 커밋할지 여부는 사용자에게 묻는다 (수집 데이터는 대개 산출물이지 코드가 아니다).
- https://www.youtube.com/watch?v=hdEweGeZpuE 를 보고 만든 skill 입니다.  : 7만 GitHub star를 받은 Scrapling, Cloudflare 차단 어디까지 우회할 수 있을까? 적응형 웹스크래핑