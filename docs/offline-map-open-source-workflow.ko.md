# Runimal 오프라인 지도: 무료 오픈소스 워크플로우

## 목표
Runimal은 현재 `상용 지도 SDK` 없이도 오프라인 지도 팩을 받을 수 있다.

앱이 기대하는 입력은 다음이다.

- `.mbtiles` 파일
- `metadata` 테이블에 최소한 아래 값이 있으면 좋다
  - `name`
  - `bounds`
  - `minzoom`
  - `maxzoom`
  - `source`
  - `license`
  - `attribution`

현재 앱 구조:

1. iPhone에서 지도 팩 생성
2. `.mbtiles` 연결
3. watch로 전송
4. watch가 `3x3` 타일 모자이크로 렌더

## 무료 오픈소스 기준 권장 소스

- 데이터 원천: `OpenStreetMap`
- 데이터 다운로드: `Geofabrik` 같은 OSM extract 배포처
- 타일 생성: 사용자가 보유한 합법적 오픈소스 렌더러
- MBTiles 패키징: 이 문서와 함께 추가된 `build_mbtiles_from_xyz.py`

중요:

- `tile.openstreetmap.org`를 대량 다운로드해서 오프라인 팩으로 만드는 것은 금지다.
- OSM 데이터는 써도 되지만, 타일 서버 정책과 ODbL 고지는 반드시 지켜야 한다.

## 가장 현실적인 무료 경로

### A. 이미 렌더된 XYZ 타일 폴더가 있는 경우

예시 구조:

```text
tiles/
  12/3492/1586.png
  12/3492/1587.png
  13/6984/3173.png
```

이 경우 아래 스크립트로 바로 MBTiles를 만든다.

```bash
cd /Users/heobella/jaw-bot-4/apps/runimal-apple
python3 scripts/offline_maps/build_mbtiles_from_xyz.py \
  --tiles-root /path/to/tiles \
  --output /path/to/gapyeong.mbtiles \
  --title "가평 러닝" \
  --format png \
  --source "OpenStreetMap (self-built)" \
  --license "ODbL" \
  --attribution "© OpenStreetMap contributors"
```

### B. 가평 팩 예시

가평 주변 러닝 팩이라면 다음 정도가 현실적이다.

- 대략 영역: `37.70,127.35 ~ 37.92,127.62`
- 권장 줌: `12~16`

타일을 준비한 뒤 같은 스크립트로 패키징한다.

```bash
python3 scripts/offline_maps/build_mbtiles_from_xyz.py \
  --tiles-root /path/to/gapyeong_xyz \
  --output /path/to/gapyeong.mbtiles \
  --title "가평 러닝" \
  --minzoom 12 \
  --maxzoom 16 \
  --bounds "127.35,37.70,127.62,37.92"
```

## Runimal에 넣는 방법

1. iPhone 앱에서 `러닝 > 오프라인 지도`
2. `현재 위치 팩` 또는 `지도 팩 만들기`
3. `가평 러닝` 팩 생성
4. 해당 팩의 `파일` 버튼으로 `gapyeong.mbtiles` 선택
5. watch로 전송
6. watch `지도` 페이지에서 팩과 프리뷰 확인

`현재 위치 팩`은 iPhone 현재 위치를 읽어 주변 bbox를 자동으로 계산한다.
지금 구현은 `위치 기반 팩 생성 자동화`까지이며, 타일 데이터 다운로드/생성까지 자동은 아니다.

## 현재 구현 범위

이미 구현된 것:

- 팩 메타데이터 저장
- `.mbtiles` 연결
- 내부 metadata 자동 읽기
- watch 카탈로그 전송
- watch `3x3` 타일 미리보기
- 현재 위치 중심 이동
- route polyline 오버레이

아직 남은 것:

- 앱 안에서 직접 OSM 데이터를 다운로드해 타일 생성
- 대용량 팩 전송 재개/분할 최적화
- 전체 지도 뷰어 수준의 팬/줌 UX

## 권장 운영 원칙

- UI에 `source / license / attribution`을 남긴다
- 상용 공급자 없이 가려면 `OSM + self-built`를 기본값으로 쓴다
- watch 팩은 너무 크게 만들지 않는다
  - 보통 `한 지역 + 12~16줌`부터 시작
