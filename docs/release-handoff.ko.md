# Runimal 릴리즈 핸드오프

## 현재 릴리즈 수준

- 핵심 루프 구현 완료
  - 러닝
  - 운동 기록
  - 알 생성
  - 부화
  - 먹이 주기
  - 진화
- iPhone / Apple Watch 실기기 설치 확인
- FIT 수동 가져오기 구현
- 워치 시작 카운트다운 구현
- 워치 함께 달릴 동행 sync 반응 개선 및 폰/워치 렌더 기준 1차 통일 완료
- `PixelPetView` 공통 렌더가 `SpeciesVisualRenderProfile`을 직접 참조하도록 정리 완료
- `PhoneDashboardStore` 액션 분리 / `PhoneDashboardView` 크롬 분리 완료
- TestFlight archive/export 플레이북 및 기본 스크립트 정리 완료
- App Store 메타데이터 템플릿 및 GitHub Actions 릴리즈 워크플로우 정리 완료

## 릴리즈 전 최종 점검 항목

### 1. 실기기 QA

- 워치 단독 러닝 후 iPhone 반영 확인
- 러닝 시작하기 `3,2,1` 카운트다운 확인
- 운동 끝내기 후 기록 저장 확인
- 심박 / 케이던스 / 페이스 실시간 값 확인
- iPhone에서 함께 달릴 동행 변경 후 Watch 첫 화면 반영 속도 확인
- 이름/타이틀과 실제 외형이 같은 최신 진화 형태로 보이는지 확인

### 2. 데이터 연동

- FIT 파일 직접 가져오기 확인
- 가져오기 후 최근 러닝 카드 갱신 확인
- `지우기` 후 동일 FIT 재가져오기 확인
- 외부 러닝을 먹이로 소모한 뒤 상태 반영 확인

### 3. 게임 루프

- 첫 러닝 -> 첫 알 생성
- 두 번째 러닝 -> 첫 부화
- 먹이 주기 -> 첫 단계 상승
- 희귀 변이 획득 시 연출 확인
- 완성 경로 카드와 최종형 가치 확인

### 4. UI/UX

- 워치 페이지별 잘림 여부 재확인
- iPhone 보관함 / 공유 쇼케이스 가독성 확인
- 알과 펫의 도트 기준 통일 여부 확인
- 폰/워치 캐릭터 외형 부조화 재발 여부 확인
- 최근 러닝 카드의 정사각형 맵 필드 확인

## 알려진 주의점

- GitHub 원격은 `origin = https://github.com/yamcy1225/Runimal.git`
- 워치 빌드는 연결 상태에 따라 설치 재시도가 필요할 수 있음
- 최근 워치 sync 반응 저하와 폰/워치 렌더 불일치는 2차 정리까지 반영돼 공통 렌더 프로파일 기준으로 맞춰진 상태
- `project.yml`이 원본이므로 새 Swift 파일 추가 뒤에는 `xcodegen generate`가 필요함
- GitHub Actions 워크플로우는 `push`에서 unsigned validation, `workflow_dispatch`에서 archive/export/upload를 분리해 동작함
- `workflow_dispatch` archive에는 `DEVELOPMENT_TEAM_ID`, TestFlight 업로드에는 `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_BASE64`가 필요함

## 권장 다음 작업

1. 워치 실러닝 장시간 QA
2. GitHub Secrets / App Store Connect API 키 연결
3. App Store 스크린샷 실제 제작
