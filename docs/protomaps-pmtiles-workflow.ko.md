# Runimal PMTiles / Protomaps 워크플로우

## 목표
Runimal이 상용 지도 공급자 없이도 `PMTiles` 단일 파일 팩을 받을 수 있는 방향을 정리한다.

현재 상태:

- iPhone: `.pmtiles` 파일 import 가능
- iPhone: 팩 metadata / manifest / watch 전송 가능
- watch: `.pmtiles` 파일 저장 가능
- watch: 현재 지도 프리뷰 렌더는 `MBTiles`만 지원

즉 지금은 `PMTiles 1차: import / transfer / storage`까지 들어간 상태다.

## 왜 PMTiles인가

- 단일 파일이라 관리가 쉽다
- 자체 호스팅/배포에 유리하다
- Protomaps 생태계와 잘 맞는다
- 대용량 오프라인 팩을 다룰 때 MBTiles보다 운영 경험이 단순한 편이다

## 무료 오픈소스 기준 흐름

1. 합법적인 OSM 기반 데이터 준비
2. Protomaps/PMTiles 생태계에서 `.pmtiles` 생성 또는 확보
3. iPhone `러닝 > 오프라인 지도`
4. 팩 생성 또는 `현재 위치 팩`
5. `.pmtiles` 파일 연결
6. watch로 전송

## 현재 구현 제약

watch 프리뷰는 아직 SQLite 기반 `MBTiles reader`로 렌더한다.  
그래서 `.pmtiles`는 지금 단계에서:

- import 가능
- 저장 가능
- 전송 가능
- 선택 가능

까지만 된다.

watch 지도 화면에서는 `PMTiles 렌더 준비 중` 상태로 안내한다.

## 다음 구현 우선순위

1. `PMTiles local reader`
   - 로컬 파일 header/directory 파서
   - 선택 줌 + x/y tile 조회

2. `watch preview bridge`
   - 현재 `WatchMBTilesTileReader`와 병행 가능한 reader protocol 분리
   - `MBTiles / PMTiles` 공통 preview API

3. `실제 지도 렌더`
   - 3x3 타일 모자이크
   - 현재 위치 중심 이동
   - polyline overlay 재사용

## 제품 판단

Runimal 기준으로는 아래 전략이 가장 안전하다.

- 단기: `MBTiles`로 실제 프리뷰/러닝 지도 유지
- 중기: `PMTiles` import/transfer/storage 지원 확대
- 장기: watch local PMTiles reader 추가 후 완전 전환 여부 판단
