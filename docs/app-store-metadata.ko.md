# Runimal App Store 메타데이터 가이드

## 목적

App Store Connect에 바로 입력할 수 있는 한국어 기준 메타데이터와 심사 메모를 고정 포맷으로 관리한다.

## 기준 파일

- `app_store/metadata/ko-KR/subtitle.txt`
- `app_store/metadata/ko-KR/description.txt`
- `app_store/metadata/ko-KR/keywords.txt`
- `app_store/metadata/ko-KR/promotional_text.txt`
- `app_store/metadata/ko-KR/release_notes.txt`
- `app_store/metadata/ko-KR/review_notes.txt`
- `app_store/metadata/ko-KR/privacy_url.txt`
- `app_store/metadata/ko-KR/support_url.txt`
- `app_store/metadata/ko-KR/marketing_url.txt`

## 스크린샷 권장 순서

1. iPhone 홈 지금 선택한 동행 화면
2. 워치 러닝 시작 카운트다운
3. 워치 러닝 중 실시간 수치
4. 러닝 종료 후 iPhone 반영 화면
5. 먹이 주기 / 성장 반영 화면
6. 보관함 또는 도감 화면

## 심사 전달 포인트

1. 앱 핵심은 iPhone + Apple Watch 연동 러닝 동행 경험
2. HealthKit은 러닝 기록, 심박, 케이던스, 경로 저장/표시에 사용
3. 계정 생성 없이도 기본 체험 가능
4. 워치 companion 앱이 포함되며 운동 종료 후 iPhone으로 기록이 동기화됨

## 업데이트 규칙

1. 기능 문구는 실제 구현된 항목만 기재
2. 워치 관련 설명은 iPhone 설명과 중복되지 않게 요약
3. 릴리즈마다 `release_notes.txt`만 우선 갱신
4. 심사 이슈가 생기면 `review_notes.txt`에 재현 경로를 누적
