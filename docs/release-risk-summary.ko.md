# Runimal Release Risk Summary

## Green

- package tests 통과
- iPhone simulator build 통과
- Watch simulator build 통과
- macOS build 통과
- release workflow secret gating 정리
- iPhone / Watch / macOS UI capture / review board / Playwright board screenshots 확보
- first egg / hatch / first stage-up FTUE 보장 로직 및 테스트 추가
- revised iPhone polish set 반영 완료

## Yellow

- Watch simulator 자동 캡처는 여전히 iPhone보다 느릴 수 있음
- Hatch와 Workout Record는 안정적이지만 감정 연출 polish 여지가 남아 있음

## Red

- 없음

## 런치 체감 리스크

- `too slow`
  - 초반 성장 보장이 무너지면 바로 이 리스크가 Red가 된다.
- `too ambiguous`
  - home에서 운동 기록과 실시간 동행 구분이 흐려지면 Yellow.
- `not visually rewarding enough`
  - rare mutation / share card / first stage-up이 약하면 Yellow.
- `sync confidence too weak`
  - watch 단독 러닝 반영이 흔들리면 Red.
