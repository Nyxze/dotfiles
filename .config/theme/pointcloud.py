#!/usr/bin/env python3
"""Bakes a raw XYZ point cloud into the texture pair the greeter's cloud shader
samples.

    python3 pointcloud.py ../../.assets/globe/anchor.bin ankhor --side 128

The input is float32 triplets, little-endian, no header — one point per twelve
bytes. The output is two RGBA8 images holding the high and low byte of each
axis: a single image gives 256 steps per axis, and the quantisation lattice
that leaves is plainly visible as the cloud turns. Two bytes put the error far
below the spacing between points, where it belongs.

Positions are centred and divided by the largest half-extent, so the shader
receives a cloud in [-1, 1] on its longest axis and needs to know nothing about
the model it came from.
"""

import argparse
import struct
import sys
import zlib
from pathlib import Path


def read_cloud(path):
    raw = path.read_bytes()
    if len(raw) % 12:
        sys.exit(f"{path}: {len(raw)} bytes is not a whole number of XYZ triplets")
    flat = struct.unpack(f"<{len(raw) // 4}f", raw)
    return [flat[i:i + 3] for i in range(0, len(flat), 3)]


def normalise(points):
    lo = [min(p[a] for p in points) for a in range(3)]
    hi = [max(p[a] for p in points) for a in range(3)]
    mid = [(lo[a] + hi[a]) / 2 for a in range(3)]
    # One scale for all three axes, not one per axis: per-axis would stretch a
    # long hull into a cube and lose the proportions that make it recognisable.
    half = max((hi[a] - lo[a]) / 2 for a in range(3)) or 1.0
    return [tuple((p[a] - mid[a]) / half for a in range(3)) for p in points]


def thin(points, count, seed=0):
    if len(points) <= count:
        return points
    # A deterministic stride rather than a random draw, so a re-bake of the same
    # model produces the same cloud and a diff of the textures stays empty.
    step = len(points) / count
    return [points[int(i * step)] for i in range(count)]


def png(path, rows, side):
    def chunk(tag, body):
        return (struct.pack(">I", len(body)) + tag + body
                + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF))

    raw = b"".join(b"\x00" + bytes(row) for row in rows)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", side, side, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b""))


def bake(source, name, side, out_dir):
    points = thin(normalise(read_cloud(source)), side * side)

    planes = {"hi": [], "lo": []}
    for row in range(side):
        line = {"hi": [], "lo": []}
        for col in range(side):
            i = row * side + col
            p = points[i] if i < len(points) else (0.0, 0.0, 0.0)
            for axis in range(3):
                q = round((p[axis] + 1.0) * 0.5 * 65535)
                line["hi"].append(q >> 8)
                line["lo"].append(q & 0xFF)
            # Alpha marks a real point. The grid is square and the cloud is not,
            # so the tail of the last row would otherwise draw as a stripe of
            # dots sitting at the model's centre.
            for key in line:
                line[key].append(255 if i < len(points) else 0)
        for key in planes:
            planes[key].append(line[key])

    for key, rows in planes.items():
        png(out_dir / f"{name}-{key}.png", rows, side)
    return len(points)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path, help="raw float32 XYZ point cloud")
    ap.add_argument("name", help="base name for the emitted texture pair")
    ap.add_argument("--side", type=int, default=128,
                    help="texture edge; the cloud is thinned to side² points")
    ap.add_argument("--out", type=Path, default=Path("."), help="output directory")
    args = ap.parse_args()

    kept = bake(args.source, args.name, args.side, args.out)
    print(f"✓ {args.name}: {kept} points into {args.side}×{args.side} hi/lo pair")


if __name__ == "__main__":
    main()
