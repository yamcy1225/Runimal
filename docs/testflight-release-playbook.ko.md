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

## 아카이브 전 체크리스트

1. `xcodegen generate`
2. `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' build`
3. `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' build`
4. orientation 경고, 아이콘 경고가 릴리즈 판단을 막을 수준인지 재확인
5. `docs/real-device-deploy-checklist.md` 기준 PASS/FAIL 갱신

## 업로드 절차

현재 저장소에는 App Store Connect 자동 업로드 스크립트는 아직 없다.

권장 순서:

1. 위 스크립트로 `.xcarchive`와 `.ipa` 생성
2. Xcode Organizer 또는 Transporter로 `RunimalPhone.ipa` 업로드
3. TestFlight 내부 테스터 빌드 노트 입력
4. 워치 companion 포함 여부와 HealthKit 권한 문구 재확인

## 빌드 노트 권장 항목

1. 워치 함께 달릴 동행 sync 반응 개선
2. 폰/워치 캐릭터 렌더 규칙 공통화
3. 최근 워치 sync audit log 1차 반영
4. 대시보드 스토어 구조 분리로 유지보수성 향상

## 남은 작업

1. App Store Connect API 기반 업로드 자동화
2. GitHub Actions 또는 로컬 CI archive job 추가
3. App Store 메타데이터 / 스크린샷 / 심사 메모 정리
