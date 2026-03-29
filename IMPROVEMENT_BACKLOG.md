# IMPROVEMENT_BACKLOG

| 상태 | 개선점 | 심각도 | 기대 효과 | 난이도 | 선행조건 | 메모 |
|---|---|---:|---|---:|---|---|
| done | 사용 완료 코어의 사용처를 상세 시트에서 추적 가능하게 표시 | 높음 | 코어 귀속 구조 이해도 상승, 반복 테스트 혼란 감소 | 중 | 없음 | 새 알/메인 알/동행체 성장 세 경로 표시 |
| done | 러닝 기록 목록 행에 사용처 축약 배지 표시 | 중 | 목록만 봐도 사용 상태 파악 | 낮음 | 상세 시트 usage summary 로직 존재 | `PhoneRunCoreUsage.swift`로 공용 해석 로직 분리 |
| done | `Runimal 러닝 기록` / `가져온 러닝 기록` 필터 토글 추가 | 중 | 워치 기록과 외부/FIT 기록 탐색성 향상 | 중 | 현재 히스토리 패널 유지 | `전체 / Runimal / 가져온 기록` 필터 구현 완료 |
| done | `watch-healthkit` 기록 수신 직후 iPhone 러닝 화면 강조 배너 | 높음 | 자동 연동 체감 강화 | 중 | 기존 `PhoneConnectivityManager.lastCompletedRun` 활용 가능 | 러닝 페이지 상단에 실시간 요약 카드 추가 |
| done | 워치 러닝 종료 후 생성되는 기록과 iPhone 카드 값 일치성 진단 패널 | 높음 | 거리/평균심박/평균케이던스 검증 효율 향상 | 중 | 현재 워치 최종 통계 저장 로직 존재 | 러닝 페이지에 원본값 vs 저장값 비교 카드 추가 |
| todo | `PhoneDashboardStore` 액션 메서드 분리 | 중 | 테스트 seam 증가, 거대 파일 완화 | 높음 | 개선 후보를 작은 단위로 분리 필요 | `RunCoreActions`, `CloudActions` 등으로 나눌 수 있음 |
| todo | `PhoneDashboardView.swift` 비대화 완화 | 중 | 유지보수성 향상 | 높음 | 액션/파생 상태 분리 | 파일 500라인 규칙과 충돌 중 |
| done | 워치 첫 페이지 glanceability 추가 압축 | 중 | 운동 중 손목 사용성 향상 | 중 | 실기기에서 글자 크기 재확인 필요 | 메인 동행체 카드를 짧고 큰 신호 중심으로 압축 |
| done | 아침 실기기 설치/권한/QA 플랜 문서화 | 높음 | 오전 10시 이후 즉시 설치/검수 가능 | 낮음 | 문서 기반 현황 파악 완료 | `MORNING_INSTALL_PLAN.md` 생성 및 실패 분기 보강 완료 |
| todo | 아이콘 에셋 `46mm` / unassigned children 경고 정리 | 낮음 | 빌드 경고 감소, 자산 정합성 향상 | 낮음 | 에셋 세트 구조 점검 | 기능 영향은 낮음 |
| todo | iPhone orientation 경고 정리 | 낮음 | 릴리즈 빌드 품질 향상 | 낮음 | target 설정 검토 | README/release-handoff에도 이미 언급 가능 |
