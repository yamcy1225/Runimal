# Runimal TestFlight 릴리즈 플레이북

## 목적

`RunimalPhone`과 Watch companion이 붙은 iPhone 아카이브를 반복 가능하게 만들고, TestFlight 업로드 전 점검 기준을 한 문서로 정리한다.

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

## 빠른 실행

```bash
cd /Users/heobella/jaw-bot-2/apps/runimal-apple
TEAM_ID=8YJKN5NZT3 ./scripts/release/testflight_archive.sh
```

생성 결과:

- archive: `build/release/RunimalPhone.xcarchive`
- ipa: `build/release/export/RunimalPhone.ipa`

## GitHub Actions 릴리즈 경로

`Runimal Release` 워크플로우는 두 가지 모드로 나뉜다.

1. `push` to `master`
   - 항상 실행
   - `xcodegen generate`
   - `swift package resolve`
   - `swift test`
   - iPhone / Watch unsigned build 검증 (`CODE_SIGNING_ALLOWED=NO`)
   - 시크릿이 없어도 실패하지 않아야 한다
2. `workflow_dispatch`
   - `archive_release`: Release archive/export 실행
   - `upload_to_testflight`: archive/export 이후 TestFlight 업로드 실행
   - `upload_to_testflight`를 켜면 archive/export가 함께 필요하므로 내부적으로 같이 처리한다

## 필요한 GitHub Secrets

- `DEVELOPMENT_TEAM_ID`
  - archive/export에 필요
- `ASC_KEY_ID`
  - TestFlight 업로드에 필요
- `ASC_ISSUER_ID`
  - TestFlight 업로드에 필요
- `ASC_PRIVATE_KEY_BASE64`
  - App Store Connect API key `.p8`를 base64로 인코딩한 값

시크릿이 없을 때의 동작:

- `push` 검증은 계속 성공/실패를 알려준다
- `workflow_dispatch`에서 archive 요청 시 `DEVELOPMENT_TEAM_ID`가 없으면 즉시 실패한다
- `workflow_dispatch`에서 upload 요청 시 ASC 시크릿이 없으면 즉시 실패한다

## 아카이브 전 체크리스트

1. `xcodegen generate`
2. `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' build`
3. `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' build`
4. orientation 경고, 아이콘 경고가 릴리즈 판단을 막을 수준인지 재확인
5. `docs/real-device-deploy-checklist.md` 기준 PASS/FAIL 갱신

## 업로드 절차

### 로컬 수동 업로드

1. 위 스크립트로 `.xcarchive`와 `.ipa` 생성
2. `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_BASE64`를 설정한 뒤 `./scripts/release/upload_to_testflight.sh` 실행 또는 Xcode Organizer / Transporter 사용
3. TestFlight 내부 테스터 빌드 노트 입력
4. 워치 companion 포함 여부와 HealthKit 권한 문구 재확인

### GitHub Actions 업로드

1. Actions 탭에서 `Runimal Release` 수동 실행
2. `archive_release`를 켠다
3. TestFlight까지 올릴 경우 `upload_to_testflight`도 함께 켠다
4. 업로드가 필요 없으면 생성된 IPA artifact만 다운로드해 수동 검수에 사용한다

## 빌드 노트 권장 항목

1. 워치 함께 달릴 동행 sync 반응 개선
2. 폰/워치 캐릭터 렌더 규칙 공통화
3. 최근 워치 sync audit log 1차 반영
4. 대시보드 스토어 구조 분리로 유지보수성 향상

## 남은 작업

1. TestFlight 내부 테스터 대상 실제 dry-run 1회 수행
2. App Store 메타데이터 / 스크린샷 / 심사 메모 정리
3. 워크플로우 artifact 보존 기간과 릴리즈 노트 템플릿 고정
