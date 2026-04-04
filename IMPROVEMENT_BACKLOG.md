# IMPROVEMENT_BACKLOG

| 상태 | 개선점 | 심각도 | 기대 효과 | 난이도 | 선행조건 | 메모 |
|---|---|---:|---|---:|---|---|
| done | 사용 완료 코어의 사용처를 상세 시트에서 추적 가능하게 표시 | 높음 | 코어 귀속 구조 이해도 상승, 반복 테스트 혼란 감소 | 중 | 없음 | 새 알/메인 알/동행체 성장 세 경로 표시 |
| done | 러닝 기록 목록 행에 사용처 축약 배지 표시 | 중 | 목록만 봐도 사용 상태 파악 | 낮음 | 상세 시트 usage summary 로직 존재 | `PhoneRunCoreUsage.swift`로 공용 해석 로직 분리 |
| done | `Runimal 러닝 기록` / `가져온 러닝 기록` 필터 토글 추가 | 중 | 워치 기록과 외부/FIT 기록 탐색성 향상 | 중 | 현재 히스토리 패널 유지 | `전체 / Runimal / 가져온 기록` 필터 구현 완료 |
| done | `watch-healthkit` 기록 수신 직후 iPhone 러닝 화면 강조 배너 | 높음 | 자동 연동 체감 강화 | 중 | 기존 `PhoneConnectivityManager.lastCompletedRun` 활용 가능 | 러닝 페이지 상단에 실시간 요약 카드 추가 |
| done | 워치 러닝 종료 후 생성되는 기록과 iPhone 카드 값 일치성 진단 패널 | 높음 | 거리/평균심박/평균케이던스 검증 효율 향상 | 중 | 현재 워치 최종 통계 저장 로직 존재 | 러닝 페이지에 원본값 vs 저장값 비교 카드 추가 |
| done | 폰/워치 메인 동행체 렌더 규칙 1차 통일 및 중앙 두 점 제거 | 높음 | 이름은 최신인데 외형은 구형처럼 보이는 부조화 감소 | 중 | 공통 렌더 경로와 growth/mutation 입력 경로 정리 필요 | `PixelPetView` 공통 수정, growth/mutation visual state 경로 단일화, 눈 하이라이트 원복 후 중앙 두 점만 제거 |
| done | 워치 sync audit log / 최근 동기화 이벤트 ledger 1차 추가 | 높음 | 반영 지연 원인 추적과 QA 재현성 향상 | 중 | 기존 `recentEvents`/`lastMessage` 경로 확장 | 최근 동기화 이벤트를 UserDefaults에 유지하고 iPhone 러닝 화면에서 바로 확인 가능하게 정리 |
| done | `PhoneDashboardStore` 액션 메서드 분리 | 중 | 테스트 seam 증가, 거대 파일 완화 | 높음 | 개선 후보를 작은 단위로 분리 필요 | `LifecycleActions`, `RunActions`, `CompanionActions`, `CloudActions`로 분리 완료 |
| done | `PhoneDashboardView.swift` 비대화 완화 | 중 | 유지보수성 향상 | 높음 | 액션/파생 상태 분리 | 헤더/탭 크롬을 `PhoneDashboardView+Chrome.swift`로 이동하고 신규 파일 반영용 `xcodegen generate` 기준 정리 |
| done | 워치 첫 페이지 glanceability 추가 압축 | 중 | 운동 중 손목 사용성 향상 | 중 | 실기기에서 글자 크기 재확인 필요 | 메인 동행체 카드를 짧고 큰 신호 중심으로 압축 |
| done | 아침 실기기 설치/권한/QA 플랜 문서화 | 높음 | 오전 10시 이후 즉시 설치/검수 가능 | 낮음 | 문서 기반 현황 파악 완료 | `MORNING_INSTALL_PLAN.md` 생성 및 실패 분기 보강 완료 |
| done | TestFlight 릴리즈 플레이북 / archive-export 스크립트 정리 | 높음 | 수동 배포 반복성 향상, 릴리즈 인수인계 명확화 | 중 | 현재 번들 ID와 서명 상태 정리 필요 | `docs/testflight-release-playbook.ko.md`, `scripts/release/testflight_archive.sh` 추가 |
| done | App Store 메타데이터 템플릿 정리 | 높음 | 출시 입력 속도 향상, 심사 대응 일관성 확보 | 중 | 현재 기능 범위 확정 필요 | `docs/app-store-metadata.ko.md`와 `app_store/metadata/ko-KR/` 템플릿 추가 |
| done | GitHub Actions / TestFlight 업로드 자동화 초안 추가 | 중 | 반복 빌드/업로드 경로 정형화 | 중 | GitHub Secrets, ASC API 키 필요 | `.github/workflows/runimal-release.yml`, `scripts/release/upload_to_testflight.sh` 추가 |
| done | 아이콘 에셋 `46mm` / unassigned children 경고 정리 | 낮음 | 빌드 경고 감소, 자산 정합성 향상 | 낮음 | iPhone/Watch AppIcon 분리 필요 | `AppIconPhone` / `AppIconWatch` 유지, legacy `AppIcon`/`AppIconWatch`는 Xcode 26 단일 1024 아이콘 방식으로 단순화 후 경고 제거 |
| done | iPhone orientation 경고 정리 | 낮음 | 릴리즈 빌드 품질 향상 | 낮음 | target 설정 검토 | iPhone 타깃을 phone-only로 명시해 portrait 경고 경로 정리 |
