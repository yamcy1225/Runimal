# Runimal 릴리즈 핸드오프

## 현재 릴리즈 수준

- 핵심 루프 유지
  - 첫 러닝 -> 첫 알
  - 둘째 의미 있는 러닝 -> 첫 부화 보장
  - 첫 의미 있는 먹이 주기 -> 첫 눈에 띄는 단계 상승 보장
- iPhone / Apple Watch / macOS 타깃 빌드 경로 유지
- FIT 수동 가져오기 구현 유지
- 워치 실시간 동행과 iPhone 운동 기록 화면 분리 원칙 유지
- GitHub Actions 릴리즈 워크플로우 정리
  - `push`는 시크릿 없이도 `swift test` + iPhone/Watch/Mac 빌드 검증 수행
  - `workflow_dispatch`는 archive/export와 TestFlight 업로드를 분리 실행
  - 시크릿 체크는 `if: secrets.*` 직접 참조 대신 선행 step output으로 게이트
- 릴리즈 스크립트 정리
  - `scripts/release/testflight_archive.sh`
  - `scripts/release/upload_to_testflight.sh`
  - `scripts/release/capture_ui_review.sh`
- UI QA 보드 추가
  - `qa/ui-review/index.html`
  - `qa/ui-review/manifest.json`
  - `qa/ui-review/output/*.png`

## 이번 단계에서 실제 검증한 항목

### 1. 자동화/빌드

- `swift test` 통과
- `RunimalPhone` 시뮬레이터 빌드 통과
- iPhone 캡처 하네스 빌드 및 실행 확인
- Playwright 브라우저 설치 및 정적 리뷰 보드 스크린샷 경로 확인

### 2. UI 캡처

- iPhone 핵심 8개 상태 캡처 완료
  - home/dashboard
  - workout record
  - egg creation
  - hatch
  - first stage-up
  - rare mutation
  - showcase/share
  - inventory
- baseline 이미지를 `qa/ui-review/captures/iphone/current`에 보존
- 같은 세트를 `revised` 슬롯에도 기록해 이후 UI polish 전후 비교 기반 마련

### 3. FTUE/런치 루프

- 첫 알 생성 보장 규칙을 테스트로 고정
- starter egg는 의미 있는 둘째 러닝에서 부화 보장
- starter companion은 첫 의미 있는 먹이 주기에서 첫 가시 단계 상승 보장
- imported workout이 starter-loop 분류를 바꾸지 않음을 테스트로 고정

## 릴리즈 전 최종 점검 항목

### 1. 실기기 QA

- 워치 단독 러닝 후 iPhone 반영 확인
- 러닝 시작 `3,2,1` 카운트다운 확인
- 운동 종료 후 기록 저장 확인
- 심박 / 케이던스 / 페이스 실시간 값 확인
- iPhone에서 함께 달릴 동행 변경 후 Watch 첫 화면 반영 속도 확인
- 희귀 변이 획득 연출과 stage-up 연출의 촉감 확인

### 2. 데이터 연동

- FIT 파일 직접 가져오기 확인
- 가져오기 후 최근 러닝 카드 갱신 확인
- `지우기` 후 동일 FIT 재가져오기 확인
- 외부 러닝을 먹이로 소모한 뒤 상태 반영 확인

### 3. UI/UX

- 워치 컴팩트 화면 잘림 여부 재확인
- iPhone 보관함 / 공유 쇼케이스 가독성 확인
- rare mutation 화면이 한눈에 특별하게 읽히는지 확인
- share card가 실제 게시하고 싶은 수준인지 확인
- home에서 실시간 동행과 운동 기록이 헷갈리지 않는지 확인

## 알려진 주의점

- GitHub 원격은 `origin = https://github.com/yamcy1225/Runimal.git`
- `project.yml`이 원본이므로 새 Swift 파일 추가 뒤에는 `xcodegen generate`가 필요함
- watch simulator는 부팅이 느리거나 `System App` 단계에서 오래 멈출 수 있음
- `scripts/release/capture_ui_review.sh`는 이 상황에서 watch 캡처를 soft-fail 하도록 정리돼 있음
- 현재 자동 캡처는 iPhone 경로를 우선 검증했고, Watch/Mac 리뷰 이미지는 후속 수집 대상임

## 권장 다음 작업

1. Watch/Mac baseline 캡처 확보
2. Phase 4 UI polish 후 `revised` 세트 재캡처
3. TestFlight 내부 테스터 빌드 노트와 App Store 스크린샷 교체
