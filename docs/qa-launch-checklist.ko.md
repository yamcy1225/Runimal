# Runimal 런치 QA 체크리스트

## FTUE

- 첫 완주 후 알이 즉시 생성된다.
- 둘째 의미 있는 러닝 후 starter egg가 부화 가능 상태가 된다.
- 첫 먹이 주기 후 첫 stage-up이 즉시 읽힌다.
- 운동 기록과 실시간 동행이 같은 화면 의미로 섞이지 않는다.

## iPhone

- 홈에서 핵심 CTA가 하나씩만 또렷하게 읽힌다.
- workout record 화면에서 거리/페이스/보상 위계가 명확하다.
- hatch 화면에서 이름, 희귀 여부, 확인 CTA가 겹치지 않는다.
- rare mutation 화면에서 일반 개체와 즉시 구분된다.
- share card가 잘림 없이 포스터처럼 읽힌다.

## Apple Watch

- 첫 화면에서 동행/목표/시작 흐름이 한눈에 보인다.
- 러닝 중 숫자와 펫이 동시에 읽힌다.
- 실시간 값 반영이 멈추거나 너무 늦지 않는다.

## 데이터/동기화

- watch run 저장 후 iPhone 반영
- FIT import 후 recent run / reward / feed 동작 일치
- import run과 live run이 starter-loop 분류를 다르게 만들지 않음

## 릴리즈

- `swift test`
- `RunimalPhone` simulator build
- `scripts/release/capture_ui_review.sh`
- review board Playwright screenshots 3종
