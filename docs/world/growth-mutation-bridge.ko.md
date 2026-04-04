# Runimal 성장-변이 연결 규칙

이 문서는 기본 성장 단계와 변이 계보가 어느 지점에서 만나는지 정의한다.

## 원칙

- 변이는 기본형을 부정하지 않는다.
- 먼저 기본형 파츠가 자라고, 그 다음에 branch가 그 파츠를 다른 방향으로 민다.
- 플레이어는 `이 부위가 원래 이렇게 자라다가, 여기서부터 갈래가 갈라졌다`고 읽을 수 있어야 한다.

## 연결 방식

- `체형` 갈래: 대체로 `유아기`부터 상체, 어깨, 전면선에 개입한다.
- `생태` 갈래: 대체로 `유년기`부터 측면선, 외곽 문양, 코어광을 바꾼다.
- `리듬` 갈래: 대체로 `청소년기`부터 꼬리 파동, 이동 잔상, 하부 리듬에 개입한다.

다만 실제 시작 시점은 축 고정값이 아니라, 해당 branch의 `affectedParts`와 기본 성장 단계의 `developedParts`가 처음 겹치는 지점으로 계산한다.

## 구현 연결

- 연결 계산: `Sources/RunimalCore/SpeciesGrowthMutationBridgeEngine.swift`
- 성장 카드 반영: `RunimalPhone/PhonePetGrowthJourneyPanel.swift`
- 변이 계보 반영: `RunimalPhone/PhonePetDetailPanel.swift`
