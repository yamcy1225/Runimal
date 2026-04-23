# Runimal UI 리뷰 재실행 가이드

## 목적

시뮬레이터 캡처와 브라우저 리뷰 보드를 같은 순서로 다시 돌려, 핵심 화면의 전후 비교와 잘림/위계/가독성 확인을 반복 가능하게 만든다.

## 1. 준비

```bash
cd /Users/heobella/jaw-bot-4/apps/runimal-apple
xcodegen generate
swift test
```

필요 시 Playwright 브라우저를 먼저 설치한다.

```bash
npx playwright install chromium webkit
```

## 2. baseline 캡처

iPhone만 빠르게 돌릴 때:

```bash
CAPTURE_WATCH=0 CAPTURE_MAC=0 ./scripts/release/capture_ui_review.sh
```

Watch + macOS까지 같이 돌릴 때:

```bash
BOOT_TIMEOUT_SECONDS=90 ./scripts/release/capture_ui_review.sh
```

macOS만 빠르게 다시 찍을 때:

```bash
CAPTURE_PHONE=0 CAPTURE_WATCH=0 ./scripts/release/capture_ui_review.sh
```

출력:

- iPhone: `qa/ui-review/captures/iphone/revised/*.png`
- Watch: `qa/ui-review/captures/watch/revised/*.png`
- macOS: `qa/ui-review/captures/mac/revised/*.png`

현재 세트를 baseline으로 보존하려면:

```bash
mkdir -p qa/ui-review/captures/iphone/current
cp qa/ui-review/captures/iphone/revised/*.png qa/ui-review/captures/iphone/current/
mkdir -p qa/ui-review/captures/watch/current
cp qa/ui-review/captures/watch/revised/*.png qa/ui-review/captures/watch/current/
mkdir -p qa/ui-review/captures/mac/current
cp qa/ui-review/captures/mac/revised/*.png qa/ui-review/captures/mac/current/
```

## 3. 리뷰 보드 열기

보드 루트:

- `qa/ui-review/index.html`

로컬 서버 예시:

```bash
cd /Users/heobella/jaw-bot-4/apps/runimal-apple/qa/ui-review
python3 -m http.server 4173 --bind 127.0.0.1
```

브라우저에서 `http://127.0.0.1:4173/index.html`을 연다.

## 4. Playwright 리뷰 샷

프로젝트 루트에서 실행:

```bash
npx playwright screenshot --browser chromium --full-page --wait-for-selector '.capture-card' http://127.0.0.1:4173/index.html qa/ui-review/output/desktop-chrome.png
npx playwright screenshot --browser webkit --device 'iPhone 15 Pro' --full-page --wait-for-selector '.capture-card' http://127.0.0.1:4173/index.html qa/ui-review/output/mobile-safari.png
npx playwright screenshot --browser chromium --viewport-size '1024,2200' --full-page --wait-for-selector '.capture-card' http://127.0.0.1:4173/index.html qa/ui-review/output/narrow-desktop.png
```

## 5. 반드시 보는 기준

- 첫 알 / 부화 / 첫 stage-up이 즉시 읽히는가
- reward surface가 디버그 카드처럼 보이지 않는가
- rare mutation이 한눈에 특별하게 보이는가
- watch는 작은 화면에서도 수치와 펫이 동시에 읽히는가
- phone/watch/mac이 같은 게임의 일부처럼 보이는가
- share card가 실제로 올리고 싶은 수준인가

## 6. 현재 제약

- watch simulator는 부팅이 길어질 수 있으므로 soft-fail 처리돼 있다
- macOS 캡처는 앱 내부 오프스크린 렌더 경로를 사용한다
- UI polish 후에는 `revised` 세트를 다시 찍고 review board의 전후 차이를 확인한다
