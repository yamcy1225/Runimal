# Runimal Launch Telemetry Schema

## 필수 이벤트

### `first_run_completed`

- 의미: 첫 완주가 저장됨
- 기대 detail: `runID` 또는 첫 러닝 구분값

### `egg_created`

- 의미: 알 생성 성공
- 기대 detail: `shell:first|repeat`

### `egg_hatched`

- 의미: 부화 성공
- 기대 detail: `first:species` 또는 `species`

### `first_stage_up`

- 의미: 첫 비가시 성장 구간을 넘어 stage가 실제로 바뀜
- 기대 detail: 도달한 `stageLabel`

### `rare_variant_obtained`

- 의미: 희귀 변이 확보
- 기대 detail: `rareLabel:species`

### `weekly_reward_claimed`

- 의미: 주간 보상 수령
- 기대 detail: `rewardID`

## 확인 포인트

- 각 이벤트는 FTUE 한 번만 발생해야 하는 것은 중복 발생 여부를 별도 점검한다.
- `first_stage_up`은 starter guarantee가 깨지면 바로 수치 이상으로 드러나야 한다.
- 희귀 변이는 획득 로그와 실제 시각 연출 QA가 같이 가야 한다.
