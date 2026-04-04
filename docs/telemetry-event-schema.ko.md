# Runimal 텔레메트리 이벤트 스키마

## 저장 방식

- iPhone 앱은 `Application Support/RunimalVault/telemetry.jsonl`에 JSONL로 기록한다
- 각 레코드는 `timestamp`, `event`, `detail`, `properties`를 가진다
- 공개 릴리즈 전까지는 로컬 우선 로그이지만, 코호트 설계 기준은 이 문서로 고정한다

## launch critical events

### `first_run_completed`

- 목적: 첫 진입 러닝 완료율
- properties
  - `run_id`
  - `source`
  - `live_companion_id`

### `egg_created`

- 목적: 첫 생명 신호 도달률
- properties
  - `shell`
  - `creation_kind`
  - `source_run_id`

### `egg_hatched`

- 목적: 둘째 러닝 내 부화 도달률
- properties
  - `species`
  - `is_first_hatch`
  - `egg_id`

### `first_stage_up`

- 목적: 첫 성장 체감 시점
- properties
  - `run_id`
  - `stage_label`
  - `companion_id`

### `rare_variant_obtained`

- 목적: 희귀 변이 가시성 / 수집 욕구 측정
- properties
  - `variant`
  - `species`

### `weekly_reward_claimed`

- 목적: 주간 복귀 보상 반응 측정
- properties
  - `reward_id`
  - `season_id`

## cohort review questions

- 첫 러닝 완료 후 알 생성까지 끊김이 있는가
- 둘째 러닝에서 부화가 실제로 열리는가
- 첫 stage up이 너무 늦어지는 세션이 있는가
- imported workout 유저도 같은 속도로 첫 성장에 도달하는가
- rare mutation 이벤트가 수집 가치 신호로 작동하는가
