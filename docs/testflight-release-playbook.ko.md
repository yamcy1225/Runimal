# Runimal TestFlight 릴리즈 플레이북

## 목적

`RunimalPhone`과 Watch companion이 붙은 iPhone 아카이브를 반복 가능하게 만들고, TestFlight 업로드 전 점검 기준과 UI 리뷰 루프를 한 문서로 정리한다.

## 전제 조건

1. Xcode / command line tools 설치
2. Apple Development 또는 배포용 인증서가 현재 Mac에 로그인된 팀으로 유효
3. `project.yml` 변경 후 `xcodegen generate` 완료
4. 번들 ID
   - `com.jaw.runimal.phone`
   - `com.jaw.runimal.phone.watch`
5. 실기기 QA 최소 통과
   - 워치 러닝 저장
   - iPhone sync
   - 함께 달릴 동행 변경 후 워치 첫 화면 반영
   - 폰/워치 스프라이트 일치
6. UI 리뷰 baseline 확보 권장
   - `qa/ui-review/captures/iphone/current/*.png`

## 빠른 실행

```bash
cd /Users/heobella/jaw-bot-4/apps/runimal-apple
TEAM_ID=8YJKN5NZT3 ./scripts/release/testflight_archive.sh
```

생성 결과:

- archive: `build/release/RunimalPhone.xcarchive`
- ipa: `build/release/export/RunimalPhone.ipa`

옵션:

- `DERIVED_DATA_PATH=/tmp/runimal-release-dd`
- `SOURCE_PACKAGES_PATH=/tmp/runimal-release-spm`
- `EXPORT_IPA=0` 으로 archive만 생성 가능

## 아카이브 전 체크리스트

1. `xcodegen generate`
2. `swift test`
3. `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' build`
4. `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' build`
5. `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalMac -destination 'platform=macOS' build`
6. orientation 경고, 아이콘 경고가 릴리즈 판단을 막을 수준인지 재확인
7. `docs/real-device-deploy-checklist.md` 기준 PASS/FAIL 갱신

## 업로드 절차

자동 업로드 스크립트가 정리돼 있으므로 두 경로 중 하나를 사용한다.

### 로컬 수동 업로드

1. `TEAM_ID=... ./scripts/release/testflight_archive.sh`
2. `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_BASE64`를 세팅했다면:

```bash
./scripts/release/upload_to_testflight.sh
```

3. 아니면 Xcode Organizer 또는 Transporter로 `RunimalPhone.ipa` 업로드
4. TestFlight 내부 테스터 빌드 노트 입력
5. 워치 companion 포함 여부와 HealthKit 권한 문구 재확인

### GitHub Actions 경로

1. `push`는 테스트와 3개 타깃 빌드만 수행
2. `workflow_dispatch`에서
   - `export_archive=true`로 archive/ipa artifact 생성
   - `upload_to_testflight=true`로 TestFlight 업로드까지 진행
3. 업로드는 App Store Connect 시크릿이 모두 존재할 때만 실행됨

## UI 리뷰 체크

archive 전에 최소 한 번은 아래를 돌린다.

```bash
CAPTURE_WATCH=0 ./scripts/release/capture_ui_review.sh
```

그 다음 `qa/ui-review`를 로컬 서버로 열고 Playwright 스크린샷을 남긴다.

출력 위치:

- baseline/revised 캡처: `qa/ui-review/captures/**`
- 브라우저 리뷰 샷: `qa/ui-review/output/*.png`

## 빌드 노트 권장 항목

1. 워치 함께 달릴 동행 sync 반응 개선
2. starter loop 보장 정리
3. 폰/워치 캐릭터 렌더 규칙 공통화
4. UI review board / simulator capture loop 추가

## 남은 작업

1. Watch/Mac 자동 캡처 안정화
2. UI polish 이후 `revised` 세트 재촬영
3. App Store 메타데이터 / 스크린샷 / 심사 메모 정리
