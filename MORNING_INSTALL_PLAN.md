# MORNING_INSTALL_PLAN

## 목표

오전 10시 이후 사용자가 돌아오면 iPhone + Apple Watch 실기기 설치와 핵심 루프 검증을 빠르게 끝내기 위한 실행 계획.

## 설치 순서

1. iPhone 연결 상태 확인
2. Apple Watch 연결 상태 확인
3. `RunimalPhone` signed build/install
4. `RunimalWatch` signed build/install
5. HealthKit 권한 승인 확인
6. Watch Connectivity 큐 상태 확인

## 사전 점검 체크리스트

- iPhone 잠금 해제 유지
- Apple Watch 잠금 해제 유지
- iPhone / Watch 모두 충전기 또는 충분한 배터리 확보
- 두 기기를 맥 가까이에 두기
- Xcode가 기본 DerivedData 잠금 없이 별도 `DerivedDataPath`로 빌드되는지 확인
- 워치 설치 전 `outstandingUserInfoTransfers`가 비정상적으로 누적되지 않았는지 확인

## 권한/서명 확인 포인트

- iPhone / Watch 모두 같은 Apple Development Team
- HealthKit 권한 허용
- Watch 앱이 `reachability`와 `queuedTransferCount`를 정상 보고하는지 확인
- iPhone에서 `Runimal 러닝 기록` 섹션이 보이는지 확인

## 첫 실기기 테스트 시나리오

### 1. 첫 실행

- iPhone 앱 정상 진입
- Watch 앱 정상 진입
- 권한 요청이 끊기지 않는지 확인

### 2. 기본 러닝 흐름

- Watch에서 `러닝 시작하기`
- `3,2,1` 카운트다운 확인
- 러닝 중 거리/시간/평균 페이스/심박/케이던스 표시 확인
- `운동 끝내기`

### 3. iPhone ↔ Watch 연결 흐름

- 러닝 종료 후 iPhone에서 `Runimal 러닝 기록` 갱신 여부
- `watch-healthkit` 기록이 외부/FIT 기록과 분리되어 보이는지 확인
- 값이 거리/평균 심박/평균 케이던스 기준으로 합리적인지 확인

### 4. 러닝/보상/성장 루프

- 러닝 기록 상세 시트 진입
- `메인 동행체에 먹이기` 또는 `메인 알 주입`
- 결과 카드 즉시 노출 확인
- 사용 완료 후 사용처 추적 문구 확인

### 5. 상태 저장/복원

- 앱 강제 종료 후 재진입
- `Runimal 러닝 기록`, 알/동행체 상태, 성장 결과 유지 확인

## 예상 실패 지점

- Watch 연결 상태 불안정으로 설치 재시도 필요
- HealthKit 권한 미승인
- Watch 러닝 종료 후 iPhone 반영 지연
- 외부/FIT 기록과 Runimal 기록 혼동
- 워치 화면 글자 크기/잘림 이슈 재발

## 실패 분기 대응

### 1. iPhone 설치 실패

- signing/team 설정 다시 확인
- `CODE_SIGNING_ALLOWED=NO` generic build가 먼저 통과하는지 확인
- 이후 signed build를 별도 `DerivedDataPath`로 재시도

### 2. Watch 설치 실패

- Apple Watch가 `Offline`인지 먼저 확인
- 잠금 해제 후 손목에 착용하거나 화면 켠 상태 유지
- iPhone/Watch/WCSession 연결 복구 후 signed build 재시도
- 설치 전에 `RunimalWatch.app` 내부 실행 파일 존재 여부 점검

### 3. HealthKit 권한 팝업 미노출

- iPhone / Watch 설정에서 Runimal Health 권한 상태 확인
- 기존 거부 이력이 있으면 설정에서 직접 허용 후 재실행

### 4. Watch 러닝 종료 후 iPhone 반영 지연

- `queuedTransferCount` 확인
- iPhone 앱 전면 진입 후 `Runimal 러닝 기록`과 `워치 동기화 값 점검` 카드 확인
- 즉시 미반영이면 앱 재실행 대신 `WCSession` 큐가 비워지는지 먼저 본다

### 5. 값 차이 의심

- 워치 원본값은 `WatchRunSessionManager` 최종 `HKWorkout` 기준인지 확인
- iPhone에서는 `Runimal 러닝 기록` 상세 시트와 `워치 동기화 값 점검` 카드로 비교
- 외부/FIT와 혼동하지 않도록 source 구분(`watch-healthkit`, `healthkit:*`, `fit:*`) 먼저 확인

## 오전에 사용자와 함께 확인할 항목

- 실제 러닝 한 건이 기대한 값으로 기록되는지
- 워치 종료 후 iPhone 반영 체감이 충분한지
- 러닝 코어 귀속 흐름이 이해되는지
- 코어 사용 후 결과 연출이 부족하지 않은지
- 워치 직접 러닝 / 외부 러닝 / FIT 수입이 서로 헷갈리지 않는지
