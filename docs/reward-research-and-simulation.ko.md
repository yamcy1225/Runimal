# Runimal 보상 강화 연구 메모 및 시뮬레이션

## 1. 목적

이 문서는 Runimal의 보상 강화를 `감`이 아니라 연구 근거와 예측 가능한 시뮬레이션 결과를 바탕으로 조정하기 위한 메모다.

이번 라운드의 원칙은 다음 세 가지다.

- `즉시 피드백`은 강화하되, 조작적인 확률 연출은 피한다.
- `자율성`과 `유능감`을 올리는 방향으로 보상을 설계한다.
- `거의 됐는데 실패`한 상황은 암묵적 near-miss로 자극하지 않고, 명시적이고 작은 보정으로 마무리한다.

## 2. 참고한 연구

### 2.1 기술 + 게임화는 실제 신체활동 유지에 도움

- Columbia Moves pilot (cluster RCT)
- 링크: https://pubmed.ncbi.nlm.nih.gov/37924083/
- 해석:
  - 단순 기술 사용보다 `gamification`이 붙은 조건에서 자기 모니터링과 개입 유지가 더 좋게 나타났다.
  - Runimal에서는 `러닝 결과를 그냥 저장`하는 것보다, 바로 읽히는 보너스와 피드백 이름을 붙이는 것이 유리하다.

### 2.2 자율성과 유능감은 운동 지속의 핵심 변수

- Chatzisarantis & Hagger, SDT 기반 개입
- 링크: https://pubmed.ncbi.nlm.nih.gov/20186638/
- 해석:
  - autonomy-supportive intervention은 운동 의도와 실제 참여 빈도를 높였다.
  - Runimal에서는 사용자가 `알로 만들지 / 먹일지 / 인큐베이트할지` 직접 고르는 구조를 유지하고, 그 선택이 보상으로 연결되어야 한다.

- Meta-analysis on autonomous motivation / perceived competence
- 링크: https://pubmed.ncbi.nlm.nih.gov/34881939/
- 해석:
  - autonomous motivation과 perceived competence는 건강행동 변화의 유효한 타깃이다.
  - 즉, 보상은 단순 잭팟이 아니라 `내가 잘해서 얻었다`는 감각을 강화해야 한다.

### 2.3 near-miss는 암묵적 판단을 왜곡할 수 있음

- Banks et al., near-miss valuation study
- 링크: https://pubmed.ncbi.nlm.nih.gov/28668981/
- 해석:
  - near-miss는 기대와 맥락에 따라 선택을 왜곡하고, implicit decision을 흔들 수 있다.
  - Runimal에서는 `거의 희귀였음` 같은 도박형 연출을 세게 밀기보다, 명시적으로 읽히는 `Signal Lock / Decode Lock` 같은 작은 보호 보정이 더 안전하다.

## 3. 이번에 도입한 보상 강화 규칙

### 3.1 Run Reward Pulse

러닝 직후 보상에 `투명한 이름이 붙은 XP 보정`을 추가했다.

- `Mastery Pulse`
  - 핵심 퀘스트를 2개 이상 달성한 러닝
  - 보상: `+14 XP`

- `Rare Signal`
  - 돌발 목표를 달성한 러닝
  - 보상: `+20 XP`

- `Field Sync`
  - 환경 신호가 읽힌 4km+ 러닝
  - 보상: `+8 XP`

이 보정은 숨겨진 승률 조작이 아니라, 러닝 결과 카드에 이름이 보이는 형태로 붙는다.

### 3.2 Signal Lock

진화 임계점 직전에서 조금 모자라는 경우, 작은 범위에서만 명시적으로 밀어준다.

- 조건:
  - Mythic 전 단계 이하
  - 이번 먹이 주기 뒤 남는 XP가 `18 이하`
- 보정:
  - 부족한 XP만큼만 추가 지급
  - 라벨: `Signal Lock`

의도:
- “아깝게 못 넘은” 구간을 반복해서 frustration loop로 만들지 않는다.
- 사용자는 `왜 넘었는지`를 보너스 라벨로 읽을 수 있다.

### 3.3 Decode Lock

알 부화 직전에서 조금 모자라는 경우, 디코딩 임계점만 고정해준다.

- 조건:
  - 이번 인큐베이트 뒤 남는 XP가 `18 이하`
- 보정:
  - 부족한 XP만큼만 추가 지급
  - 라벨: `Decode Lock`

의도:
- 부화 직전 러닝의 감정 피크를 살리고,
- near-miss를 계속 쌓아 frustration을 키우지 않는다.

## 4. 시뮬레이션 결과

실행 타깃:

- `swift run RunimalRewardSimulation`

시뮬레이션 출력:

### 4.1 러닝 보상 비교

| 시나리오 | 기존 XP | 보정 후 XP | 붙은 라벨 |
| --- | ---: | ---: | --- |
| steady_5k | 90 | 98 | Field Sync |
| tempo_rare | 100 | 142 | Mastery Pulse, Rare Signal, Field Sync |
| climb_sync | 143 | 165 | Mastery Pulse, Field Sync |

### 4.2 임계점 보호 보정

| 시나리오 | 추가 XP | 라벨 |
| --- | ---: | --- |
| stage_lock | 0 | 없음 |
| decode_lock | 6 | Decode Lock |

해석:

- 일반적인 안정 러닝도 `Field Sync` 정도의 작은 보상이 붙어, “아무 것도 못 받은 느낌”을 줄인다.
- 고강도/희귀 목표 달성 러닝은 보상이 확실히 커져서, 훈련 행동과 결과가 더 직접적으로 연결된다.
- 임계점 보호 보정은 항상 발동하는 게 아니라, 정말 가까운 구간에서만 작동한다.

## 5. 제품 적용 포인트

현재 반영된 위치:

- 러닝 보상 계산: `RunimalRewardPulseEngine.runPulse(...)`
- 진화 직전 보호: `RunimalRewardPulseEngine.stageLock(...)`
- 부화 직전 보호: `RunimalRewardPulseEngine.hatchLock(...)`
- 최근 러닝 카드: bonus 라벨 노출
- 성장 연출 카드: `Signal Lock` 노출

## 6. 다음 권장 작업

이후에는 아래 순서가 좋다.

1. `Telemetry`
   - `reward_pulse_applied`
   - `signal_lock_applied`
   - `decode_lock_applied`
   - `rare_signal_triggered`

2. `시뮬레이션 확장`
   - 첫 3회 FTUE
   - 희귀 변이 획득률
   - Mythic 도달 러닝 수

3. `공유 카드 반영`
   - `Mastery Pulse`
   - `Rare Signal`
   - `Signal Lock`
   - `Decode Lock`

이렇게 가면 보상이 단순 XP 숫자가 아니라, 행동을 설명하는 시스템 언어가 된다.
