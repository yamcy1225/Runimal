# AUTONOMOUS_PROGRESS

## 세션 시작

- 시작 시각: 2026-03-29 02:30:20 KST
- 현재 모드: 오전 10시 전 자율 개선 모드
- 실기기 설치/배포: 보류

## 참고한 문서

- [README.md](./README.md)
- [docs/game-concept-and-rewards.ko.md](./docs/game-concept-and-rewards.ko.md)
- [docs/developer-system-spec.ko.md](./docs/developer-system-spec.ko.md)
- [docs/s-grade-transition-checklist.ko.md](./docs/s-grade-transition-checklist.ko.md)
- [docs/reward-research-and-simulation.ko.md](./docs/reward-research-and-simulation.ko.md)
- [docs/real-device-deploy-checklist.md](./docs/real-device-deploy-checklist.md)
- [docs/release-handoff.ko.md](./docs/release-handoff.ko.md)

## 현재 프로젝트 이해 요약

- 앱 목표: Apple Watch 실시간 러닝을 `Run Core -> 알/부화/성장/진화` 루프로 번역하는 수집형 러닝 게임
- iPhone 역할: 보상 해석, 메인 슬롯 선택, 코어 사용 결정, 컬렉션/시즌/레이드 허브
- Watch 역할: 러닝 시작/종료, 실시간 수치 표시, 희귀 신호/목표/보상 피드백
- 공통 코어: `Sources/RunimalCore`에서 모델, 보상, 알 생성, 성장/진화, 시즌/레이드, 스냅샷 병합 담당
- 상태 관리: `PhoneDashboardStore`가 iPhone 허브이고, `PhoneProgressStore`가 영속 상태 저장
- 동기화 구조: `WatchConnectivityManager` -> `PhoneConnectivityManager`의 `WCSession.transferUserInfo` 큐 기반
- 저장 구조: `RunimalProgressSnapshot` / `UserDefaults` / vault / cloud mirror
- 현재 강점: 코어 루프 구현 완료, 워치 단독 러닝 구조 존재, FIT 수동 가져오기, 디코딩 시네마틱/공유 쇼케이스 존재
- 현재 위험: 기록 사용처 추적성 부족, `watch-healthkit`와 imported run UX 분리 미흡, Xcode 기본 DerivedData 잠금으로 generic build 재현성 저하, 아이콘 에셋 경고 잔존

## 루프 로그

### 02:30 KST — 루프 0: 문서/구조 조사

- 선택한 개선점:
  - 문서 전수 조사와 구조 파악
- 우선 선택 이유:
  - 충돌 문서 없이 현재 코드와 가장 맞는 최신 명세를 먼저 고정해야 이후 자율 개선 우선순위가 흔들리지 않음
- 변경 파일:
  - 없음
- 변경 내용 요약:
  - `.md` 문서 전수 조사
  - 엔트리포인트, 상태 관리, 동기화, 저장 구조, 빌드 상태 파악
- 검증 방법:
  - `find ... -name '*.md'`
  - `cat README.md`
  - `cat docs/*.md`
  - `rg -n "@main|PhoneDashboardStore|WatchRunSessionManager|RunimalProgressSnapshot|WCSession|HKHealthStore"`
- 검증 결과:
  - 문서 집합은 7개로 확인
  - `README.md`, `developer-system-spec.ko.md`, `game-concept-and-rewards.ko.md`가 현재 코드와 가장 잘 부합
- 남은 리스크:
  - 루트 표준 문서(`PLAN.md`, `ROADMAP.md`, `ARCHITECTURE.md`, `TODO.md`, `SPEC.md`)는 없음
  - generic build는 기본 DerivedData 잠금 이슈 재발 가능
- 다음 후보:
  - 사용 완료된 러닝 코어의 사용처 추적성 개선
  - 워치 직접 러닝과 외부/FIT 러닝의 시각적 구분 강화
  - `PhoneDashboardStore`의 액션 메서드와 화면 클로저 결합도 완화
  - 아침 실기기 설치/검수 계획 문서화

### 02:38 KST — 루프 1: 사용 완료된 러닝 코어 사용처 추적성 개선

- 선택한 개선점:
  - 러닝 기록 상세 시트에서 `이미 사용한 코어`의 사용처를 구체적으로 보여주기
- 우선 선택 이유:
  - 현재 UX에서 가장 큰 혼란은 "사용 완료" 이후 이 코어가 어디로 갔는지 모른다는 점
  - 제품 목표상 `코어 -> 성장/알` 귀속이 명확히 읽혀야 루프가 완성됨
- 실제 변경 파일:
  - [RunimalPhone/PhoneRunRecordDetailSheet.swift](./RunimalPhone/PhoneRunRecordDetailSheet.swift)
- 변경 내용 요약:
  - 사용 완료 코어의 사용처를 세 가지로 추적
    - 새 알 생성
    - 메인 알 인큐베이트
    - 동행체 성장
  - 상세 시트에서 generic 경고 문구 대신 대상별 요약 카드로 표시
- 검증 방법:
  - `swift build`
  - `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build`
  - `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' -derivedDataPath /tmp/runimal-phone-autonomous-check CODE_SIGNING_ALLOWED=NO build`
- 검증 결과:
  - `swift build` 통과
  - Watch generic build 통과
  - iPhone generic build 통과
- 남은 리스크:
  - 사용처는 현재 상태 기반 추론이라, 향후 별도 `run usage ledger`가 생기면 그쪽으로 옮기는 편이 더 명확함
  - `PhoneDashboardView` 액션 메서드는 여전히 거대 스토어에 모여 있어 테스트 seam이 약함
- 다음 후보:
  - 러닝 기록 목록 행에도 사용처 요약을 축약 표기
  - `Runimal 러닝 기록` / `가져온 러닝 기록`에 필터 또는 배지 체계 강화
  - 워치 러닝 기록이 iPhone에서 더 눈에 띄게 보이는 첫 화면 진입 동선 강화
  - 아침 설치/권한/QA 플랜 문서 작성

### 02:46 KST — 루프 2: 러닝 기록 목록 단계 사용처 배지 추가

- 선택한 개선점:
  - 목록 행에서 이미 사용한 코어의 사용처를 바로 읽을 수 있게 배지 추가
- 우선 선택 이유:
  - 상세 시트까지 들어가기 전에도 `왜 비활성인지`가 보여야 탐색 비용이 줄어듦
  - 워치 직접 러닝 기록과 외부/FIT 기록 모두 같은 패턴으로 읽히는 것이 중요함
- 실제 변경 파일:
  - [RunimalPhone/PhoneRunCoreUsage.swift](./RunimalPhone/PhoneRunCoreUsage.swift)
  - [RunimalPhone/PhoneRunSyncHistoryPanel.swift](./RunimalPhone/PhoneRunSyncHistoryPanel.swift)
  - [RunimalPhone/PhoneRunDeckView.swift](./RunimalPhone/PhoneRunDeckView.swift)
  - [RunimalPhone/PhoneRunRecordDetailSheet.swift](./RunimalPhone/PhoneRunRecordDetailSheet.swift)
- 변경 내용 요약:
  - 코어 사용처 해석 로직을 `PhoneRunCoreUsage.swift`로 분리
  - 목록 행에서 `새 알 생성 / 메인 알 주입 / 동행체 성장` 배지를 바로 표시
  - 상세 시트도 같은 해석 로직을 재사용하도록 정리
- 검증 방법:
  - `xcodegen generate`
  - `swift build`
  - `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' -derivedDataPath /tmp/runimal-phone-autonomous-check-2 CODE_SIGNING_ALLOWED=NO build`
  - `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' -derivedDataPath /tmp/runimal-watch-autonomous-check-2 CODE_SIGNING_ALLOWED=NO build`
- 검증 결과:
  - 프로젝트 재생성 성공
  - `swift build` 통과
  - iPhone generic build 통과
  - Watch generic build 통과
- 남은 리스크:
  - 현재 사용처 해석은 `progress` 상태 기반 추론이므로, 향후 dedicated usage ledger로 승격하면 더 단단해짐
  - iPhone generic build는 orientation 경고가 남아 있음
  - asset catalog의 `46mm` / `unassigned children` 경고가 여전히 존재
- 다음 후보:
  - `Runimal 러닝 기록` / `가져온 러닝 기록` 필터 토글
  - 워치 직접 러닝 수신 직후 iPhone에서 더 강한 강조 배너
  - `PhoneDashboardView` 액션 분리로 테스트 seam 확장
  - 아침 설치/권한/실기 QA 계획 보강

### 03:05 KST — 루프 3: 러닝 기록 필터 토글 추가

- 선택한 개선점:
  - `Runimal 러닝 기록` / `가져온 러닝 기록`을 빠르게 전환할 수 있는 필터 토글 추가
- 우선 선택 이유:
  - 실제 러닝과 외부/FIT 러닝이 한 화면에 섞이면 탐색 비용이 높음
  - 오전 실기 QA 전에 `전체 / Runimal / 가져온 기록` 축을 먼저 명확히 하는 편이 UX 체감이 큼
- 실제 변경 파일:
  - [RunimalPhone/PhoneRunDeckView.swift](./RunimalPhone/PhoneRunDeckView.swift)
- 변경 내용 요약:
  - `전체 / Runimal / 가져온 기록` 필터 스트립 추가
  - 선택된 카테고리에 기록이 없으면 전용 empty state를 노출
  - 기존 히스토리 패널 구조는 유지하면서 탐색만 단순화
- 검증 방법:
  - `swift build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' -derivedDataPath /tmp/runimal-phone-autonomous-check-3 CODE_SIGNING_ALLOWED=NO build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' -derivedDataPath /tmp/runimal-watch-autonomous-check-3 CODE_SIGNING_ALLOWED=NO build`
- 검증 결과:
  - `swift build` 통과
  - iPhone generic build 통과
  - Watch generic build 통과
- 남은 리스크:
  - 필터 상태가 아직 세션 로컬 `@State`라서, 향후 사용 패턴이 명확해지면 저장 필요성 재검토 가능
  - iPhone orientation 경고와 AppIcon 경고는 여전히 잔존
- 다음 후보:
  - 워치 직접 러닝 수신 직후 iPhone에서 더 강한 강조 배너
  - 워치 러닝 기록 값 진단 패널
  - `PhoneDashboardView` 액션 분리로 테스트 seam 확장
  - 아침 설치/권한/실기 QA 계획 보강

### 03:14 KST — 루프 4: 워치 직접 러닝 수신 강조 배너 추가

- 선택한 개선점:
  - 워치에서 직접 측정된 러닝이 들어왔을 때 iPhone 러닝 페이지 상단에서 즉시 눈에 띄게 표시
- 우선 선택 이유:
  - 문서와 코드상 자동 연동은 되더라도, 제품 체감은 `방금 워치 러닝이 들어왔다`는 신호가 보여야 완성됨
  - 실기 설치 전에도 generic build와 로컬 코드 검증만으로 충분히 확인 가능한 작은 단위 개선
- 실제 변경 파일:
  - [RunimalPhone/PhoneDashboardView.swift](./RunimalPhone/PhoneDashboardView.swift)
  - [RunimalPhone/PhoneRunDeckView.swift](./RunimalPhone/PhoneRunDeckView.swift)
- 변경 내용 요약:
  - `latestWatchSyncedRun` 파생 상태 추가
  - 러닝 페이지 상단에 `방금 워치 러닝을 받았습니다` 카드 추가
  - 거리 / 시간 / 페이스 / 평균 심박 / 평균 케이던스를 작은 신호 배지로 즉시 요약
- 검증 방법:
  - `xcodegen generate`
  - `swift build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' -derivedDataPath /tmp/runimal-phone-autonomous-check-4 CODE_SIGNING_ALLOWED=NO build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' -derivedDataPath /tmp/runimal-watch-autonomous-check-4 CODE_SIGNING_ALLOWED=NO build`
- 검증 결과:
  - 프로젝트 재생성 성공
  - `swift build` 통과
  - iPhone generic build 통과
  - Watch generic build 통과
- 남은 리스크:
  - 배너는 현재 `connectivity.lastCompletedRun` 기준이므로 앱 재실행 후 지속 노출되지는 않음
  - 장기적으로는 `최근 동기화 이벤트 ledger`로 분리하는 편이 더 명확함
- 다음 후보:
  - 워치 러닝 종료 후 생성되는 기록과 iPhone 카드 값 일치성 진단 패널
  - `PhoneDashboardView` 액션 분리로 테스트 seam 확장
  - 워치 첫 페이지 glanceability 추가 압축
  - 아이콘 에셋 / orientation 경고 정리

### 03:24 KST — 루프 5: 워치 러닝 값 일치성 진단 패널 추가

- 선택한 개선점:
  - 워치에서 막 넘어온 러닝 값과 iPhone에 저장된 값을 같은 화면에서 비교할 수 있는 QA 패널 추가
- 우선 선택 이유:
  - 최근 실제 러닝에서 거리/심박/케이던스 값 확인 요구가 반복됐고, 오전 실기 QA 전에 진단 시야를 코드 수준에서 확보하는 것이 가치가 큼
  - 설치 없이도 generic build로 안전하게 검증 가능한 작은 단위 개선
- 실제 변경 파일:
  - [RunimalPhone/PhoneDashboardView.swift](./RunimalPhone/PhoneDashboardView.swift)
  - [RunimalPhone/PhoneRunDeckView.swift](./RunimalPhone/PhoneRunDeckView.swift)
- 변경 내용 요약:
  - `latestWatchSyncDiagnostic` 파생 상태 추가
  - 러닝 페이지에 `워치 동기화 값 점검` 카드 추가
  - 워치 원본값과 iPhone 저장값의 거리/시간/평균 페이스/평균 심박/평균 케이던스 차이를 한 줄씩 비교
- 검증 방법:
  - `swift build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' -derivedDataPath /tmp/runimal-phone-autonomous-check-5 CODE_SIGNING_ALLOWED=NO build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' -derivedDataPath /tmp/runimal-watch-autonomous-check-5 CODE_SIGNING_ALLOWED=NO build`
- 검증 결과:
  - `swift build` 통과
  - iPhone generic build 통과
  - Watch generic build 통과
- 남은 리스크:
  - 이 패널은 현재 `connectivity.lastCompletedRun`가 살아 있는 세션에서만 진단 기준을 제공함
  - 장기적으로는 별도 sync audit log로 승격하는 편이 더 좋음
- 다음 후보:
  - `PhoneDashboardView` 액션 분리로 테스트 seam 확장
  - 워치 첫 페이지 glanceability 추가 압축
  - 아이콘 에셋 / orientation 경고 정리
  - 아침 실기 QA 순서와 실패 분기 더 구체화

### 03:34 KST — 루프 6: 워치 첫 페이지 glanceability 압축

- 선택한 개선점:
  - 워치 첫 페이지의 메인 동행체 카드를 더 짧고 크게 읽히게 압축
- 우선 선택 이유:
  - 작은 화면에서 첫 페이지는 설명보다 상태 인지 속도가 중요함
  - 실기 설치 없이도 generic watch build로 안전하게 검증 가능한 watchOS 특화 개선
- 실제 변경 파일:
  - [RunimalWatch/WatchCompanionHeroCard.swift](./RunimalWatch/WatchCompanionHeroCard.swift)
- 변경 내용 요약:
  - 카드 타이틀을 `메인 동행체`에서 `동행`으로 축약
  - 상태 문구를 `기록 중 / 출발 대기`로 단순화
  - 스프라이트와 링 크기를 소폭 줄이고 이름 폰트를 더 크게 조정
  - 하단 칩을 하나로 압축해 동기화 상태만 더 짧게 노출
  - 사용하지 않던 상세 설명 상태 제거
- 검증 방법:
  - `swift build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' -derivedDataPath /tmp/runimal-phone-autonomous-check-6 CODE_SIGNING_ALLOWED=NO build`
  - `xcodebuild -quiet -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' -derivedDataPath /tmp/runimal-watch-autonomous-check-6 CODE_SIGNING_ALLOWED=NO build`
- 검증 결과:
  - `swift build` 통과
  - iPhone generic build 통과
  - Watch generic build 통과
- 남은 리스크:
  - 실제 손목에서 폰트 체감은 아침 실기 QA에서 재확인 필요
  - asset catalog 경고와 iPhone orientation 경고는 그대로 남음
- 다음 후보:
  - `PhoneDashboardView` 액션 분리로 테스트 seam 확장
  - 아이콘 에셋 / orientation 경고 정리
  - `MORNING_INSTALL_PLAN.md`에 실패 분기 보강
  - 워치 2페이지 수치 카드의 시선 우선순위 미세조정

### 03:42 KST — 루프 7: 아침 설치/실기 QA 플랜 보강

- 선택한 개선점:
  - `MORNING_INSTALL_PLAN.md`에 실패 분기와 사전 점검 체크리스트 추가
- 우선 선택 이유:
  - 오전 10시 이후에는 실기기 설치/권한/연결 실패를 빠르게 처리할 수 있어야 함
  - 구조/코드 개선만큼이나 설치 준비 상태가 중요하므로 문서 기반 운영 준비를 강화
- 실제 변경 파일:
  - [MORNING_INSTALL_PLAN.md](./MORNING_INSTALL_PLAN.md)
- 변경 내용 요약:
  - 사전 점검 체크리스트 추가
  - iPhone 설치 실패 / Watch 설치 실패 / HealthKit 권한 / 반영 지연 / 값 차이 의심 상황의 대응 분기 추가
  - 오전 사용자 확인 항목에 러닝 source 구분 검수 항목 보강
- 검증 방법:
  - 문서 교차 검토
  - 현재 코드/구조(`watch-healthkit`, `healthkit:*`, `fit:*`, `queuedTransferCount`)와 용어 정합성 점검
- 검증 결과:
  - 현재 코드와 문서의 용어 및 점검 포인트 정합성 확인
- 남은 리스크:
  - 실기기 연결 상태 자체는 아침에 사용자와 함께 다시 확인해야 함
  - 설치 전 provisioning/team 상태는 현 시점 문서화만 가능
- 다음 후보:
  - `PhoneDashboardView` 액션 분리로 테스트 seam 확장
  - 아이콘 에셋 / orientation 경고 정리
  - 워치 2페이지 수치 카드의 시선 우선순위 미세조정
  - 필요 시 `WATCH_UX_NOTES.md` 추가
