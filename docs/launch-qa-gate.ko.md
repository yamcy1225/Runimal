# Runimal 런치 QA 게이트

## 1. 자동 게이트

- `swift test` 통과
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build`
- 릴리즈 스크립트 `bash -n` 통과

## 2. 첫 3회 러닝 게이트

- PASS: 첫 성공 러닝 후 `???` 알이 생성된다
- PASS: 둘째 러닝 후 부화 가능 상태 또는 즉시 부화에 도달한다
- PASS: 셋째 러닝 이후 첫 의미 있는 먹이 주기에서 `유아기` 진입이 눈에 보인다
- FAIL: 셋 중 하나라도 랜덤/예외 처리에 막힌다

## 3. 실기기 워치 루프 게이트

- PASS: Watch에서 `3,2,1` 카운트다운 후 러닝 시작
- PASS: 거리/시간/페이스/심박/케이던스 표시
- PASS: 러닝 종료 후 iPhone에 운동 기록 반영
- PASS: 워치에서 함께 달릴 동행 변경 후 첫 화면 반영 속도 체감 가능
- FAIL: 기록이 누락되거나 폰/워치 상태가 다른 동행을 가리킨다

## 4. imported vs live parity 게이트

- PASS: live watch run과 imported FIT/HealthKit run 모두 `운동 기록`으로 남는다
- PASS: 둘 다 성장 재료로 소모 가능하다
- PASS: source 표기는 다르지만 성장 결과 계산은 일관된다
- FAIL: imported 기록이 실시간 동행 기록처럼 오해되거나 보상 계산이 크게 다르다

## 5. 희귀 변이/최종 진화 게이트

- PASS: 희귀 변이 획득 시 일반 개체와 다른 배지/배너/문구가 즉시 보인다
- PASS: 최종 진화 패널과 공유 카드에서 장기 목표로 보인다
- FAIL: 특별 보상이 숫자 상승처럼만 느껴진다

## 6. 공유물 게이트

- PASS: 세로 공유 카드가 텍스트 로그가 아니라 결과를 자랑하는 카드처럼 보인다
- PASS: 거리, 페이스, XP, 경로/출처가 한눈에 읽힌다
- FAIL: 운동 기록 캡처처럼 평면적이다

## 7. 리스크 신호

### Red

- 첫 부화 도달 실패
- 단계 상승이 3회 이상 뒤로 밀림
- 워치 종료 후 iPhone 반영 실패

### Yellow

- reward allocation 문구가 이해되지만 즉시 명확하지 않음
- 희귀 변이 차이가 카드/배너 수준에 머무름
- 최종 진화 가치가 수집 동기까지는 못 밀어줌

### Green

- 첫 3회 루프가 한 번에 이해됨
- imported vs live 구분이 자연스럽다
- 공유 카드와 희귀 변이 연출이 저장하고 싶을 정도로 선명하다
