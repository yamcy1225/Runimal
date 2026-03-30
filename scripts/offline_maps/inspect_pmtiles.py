#!/usr/bin/env python3
import argparse
import json
import struct
import sys

HEADER_SIZE = 127

COMPRESSION = {
    0: "unknown",
    1: "none",
    2: "gzip",
    3: "brotli",
    4: "zstd",
}

TILE_TYPE = {
    0: "unknown",
    1: "mvt",
    2: "png",
    3: "jpeg",
    4: "webp",
    5: "avif",
    6: "mlt",
}


def read_header(path: str) -> dict:
    with open(path, "rb") as fp:
        data = fp.read(HEADER_SIZE)

    if len(data) < HEADER_SIZE:
        raise ValueError("header too short")
    if data[:7] != b"PMTiles":
        raise ValueError("not a PMTiles archive")

    version = data[7]
    if version != 3:
        raise ValueError(f"unsupported PMTiles version: {version}")

    def u64(offset: int) -> int:
        return struct.unpack_from("<Q", data, offset)[0]

    def i32(offset: int) -> int:
        return struct.unpack_from("<i", data, offset)[0]

    return {
        "version": version,
        "root_offset": u64(8),
        "root_length": u64(16),
        "metadata_offset": u64(24),
        "metadata_length": u64(32),
        "leaf_directory_offset": u64(40),
        "leaf_directory_length": u64(48),
        "tile_data_offset": u64(56),
        "tile_data_length": u64(64),
        "addressed_tiles_count": u64(72),
        "tile_entries_count": u64(80),
        "tile_contents_count": u64(88),
        "clustered": data[96] == 1,
        "internal_compression": COMPRESSION.get(data[97], f"unknown({data[97]})"),
        "tile_compression": COMPRESSION.get(data[98], f"unknown({data[98]})"),
        "tile_type": TILE_TYPE.get(data[99], f"unknown({data[99]})"),
        "min_zoom": data[100],
        "max_zoom": data[101],
        "min_lon": i32(102) / 10_000_000,
        "min_lat": i32(106) / 10_000_000,
        "max_lon": i32(110) / 10_000_000,
        "max_lat": i32(114) / 10_000_000,
        "center_zoom": data[118],
        "center_lon": i32(119) / 10_000_000,
        "center_lat": i32(123) / 10_000_000,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Inspect PMTiles v3 header metadata.")
    parser.add_argument("pmtiles", help="Path to .pmtiles archive")
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    args = parser.parse_args()

    try:
        header = read_header(args.pmtiles)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(header, ensure_ascii=False, indent=2))
        return 0

    print(f"path: {args.pmtiles}")
    print(f"version: {header['version']}")
    print(f"tile_type: {header['tile_type']}")
    print(f"tile_compression: {header['tile_compression']}")
    print(f"internal_compression: {header['internal_compression']}")
    print(f"zoom: {header['min_zoom']} - {header['max_zoom']}")
    print(
        "bounds: "
        f"{header['min_lon']:.6f},{header['min_lat']:.6f} -> "
        f"{header['max_lon']:.6f},{header['max_lat']:.6f}"
    )
    print(
        "center: "
        f"z{header['center_zoom']} @ {header['center_lat']:.6f}, {header['center_lon']:.6f}"
    )
    print(f"tiles: {header['tile_contents_count']} contents / {header['tile_entries_count']} entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
