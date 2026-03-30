#!/usr/bin/env python3
import argparse
import os
import sqlite3
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a raster MBTiles file from a local XYZ tile directory."
    )
    parser.add_argument("--tiles-root", required=True, help="Directory containing z/x/y.(png|jpg|webp) tiles")
    parser.add_argument("--output", required=True, help="Output .mbtiles path")
    parser.add_argument("--title", required=True, help="Pack title")
    parser.add_argument("--format", default="png", choices=["png", "jpg", "webp"], help="Tile image format")
    parser.add_argument("--minzoom", type=int, default=None, help="Override min zoom")
    parser.add_argument("--maxzoom", type=int, default=None, help="Override max zoom")
    parser.add_argument("--bounds", default=None, help="west,south,east,north")
    parser.add_argument("--source", default="OpenStreetMap (self-built)", help="Source label")
    parser.add_argument("--license", dest="license_label", default="ODbL", help="License label")
    parser.add_argument("--attribution", default="© OpenStreetMap contributors", help="Attribution text")
    return parser.parse_args()


def mercator_tile_to_lon(x: int, z: int) -> float:
    return x / (2 ** z) * 360.0 - 180.0


def mercator_tile_to_lat(y: int, z: int) -> float:
    import math
    n = math.pi - (2.0 * math.pi * y) / (2 ** z)
    return math.degrees(math.atan(math.sinh(n)))


def discover_tiles(root: Path, fmt: str):
    records = []
    zooms = set()
    min_x = min_y = None
    max_x = max_y = None
    bbox_zoom = None

    suffixes = [f".{fmt}"]
    for path in root.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in suffixes:
            continue
        try:
            z = int(path.parent.parent.name)
            x = int(path.parent.name)
            y = int(path.stem)
        except ValueError:
            continue
        tms_y = (2 ** z - 1) - y
        records.append((z, x, tms_y, path))
        zooms.add(z)
        if bbox_zoom is None or z > bbox_zoom:
            bbox_zoom = z
            min_x = max_x = x
            min_y = max_y = y
        elif z == bbox_zoom:
            min_x = x if min_x is None else min(min_x, x)
            max_x = x if max_x is None else max(max_x, x)
            min_y = y if min_y is None else min(min_y, y)
            max_y = y if max_y is None else max(max_y, y)

    if not records:
        raise SystemExit("No raster XYZ tiles were found.")

    min_zoom = min(zooms)
    max_zoom = max(zooms)
    bounds = None
    if bbox_zoom is not None and min_x is not None and min_y is not None and max_x is not None and max_y is not None:
        west = mercator_tile_to_lon(min_x, bbox_zoom)
        east = mercator_tile_to_lon(max_x + 1, bbox_zoom)
        north = mercator_tile_to_lat(min_y, bbox_zoom)
        south = mercator_tile_to_lat(max_y + 1, bbox_zoom)
        bounds = (west, south, east, north)
    return records, min_zoom, max_zoom, bounds


def ensure_schema(conn: sqlite3.Connection):
    conn.executescript(
        """
        CREATE TABLE metadata (name TEXT, value TEXT);
        CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);
        CREATE UNIQUE INDEX metadata_name ON metadata (name);
        CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row);
        """
    )


def write_metadata(conn: sqlite3.Connection, values: dict[str, str]):
    conn.executemany(
        "INSERT OR REPLACE INTO metadata(name, value) VALUES(?, ?)",
        list(values.items()),
    )


def main():
    args = parse_args()
    tiles_root = Path(args.tiles_root).expanduser().resolve()
    output = Path(args.output).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()

    records, discovered_min_zoom, discovered_max_zoom, discovered_bounds = discover_tiles(tiles_root, args.format)

    min_zoom = args.minzoom if args.minzoom is not None else discovered_min_zoom
    max_zoom = args.maxzoom if args.maxzoom is not None else discovered_max_zoom
    bounds = args.bounds
    if bounds is None and discovered_bounds is not None:
        bounds = ",".join(f"{value:.6f}" for value in discovered_bounds)

    conn = sqlite3.connect(output)
    try:
        ensure_schema(conn)
        metadata = {
            "name": args.title,
            "type": "baselayer",
            "version": "1.0",
            "description": f"{args.title} raster pack",
            "format": args.format,
            "source": args.source,
            "license": args.license_label,
            "attribution": args.attribution,
            "minzoom": str(min_zoom),
            "maxzoom": str(max_zoom),
        }
        if bounds:
            metadata["bounds"] = bounds
        write_metadata(conn, metadata)

        with conn:
            for z, x, tms_y, path in records:
                with path.open("rb") as handle:
                    blob = handle.read()
                conn.execute(
                    "INSERT OR REPLACE INTO tiles(zoom_level, tile_column, tile_row, tile_data) VALUES(?, ?, ?, ?)",
                    (z, x, tms_y, blob),
                )
    finally:
        conn.close()

    size_mb = output.stat().st_size / 1_000_000
    print(f"Created {output}")
    print(f"Tiles: {len(records)}")
    print(f"Zoom: Z{min_zoom}-{max_zoom}")
    if bounds:
        print(f"Bounds: {bounds}")
    print(f"Size: {size_mb:.2f} MB")


if __name__ == "__main__":
    main()
