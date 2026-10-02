#!/usr/bin/env python3
"""Generates a survival pod as a surface point cloud, in the same raw XYZ format
the baked models arrive in.

    python3 pod.py pod.bin && python3 pointcloud.py pod.bin pod --side 112

A pod is drawn rather than extracted because the thing it has to do is be
legible at about thirty pixels, falling. A building read at that size is a
smudge; a bell flaring onto a heat-shield cone is still a pod.

Points are spread by area, not by parameter: sampling a revolved profile evenly
in its parameters crowds the axis and starves the rim, and the cloud then reads
as a bright seam down the middle of a dim shell.
"""

import argparse
import math
import random
import struct
from pathlib import Path

# The hull as a profile turned about the Y axis, bottom to top: the heat shield,
# the flange it meets the body at, the body itself, the collar, and the flat lid
# that closes it.
#
# The flanks are all but straight on purpose. A profile that tapers steadily
# from a wide bottom to a narrow top is a bell, whatever is done to the ends —
# what reads as a pod is a plain barrel with hard rings at both ends and a
# shield tucked under it.
PROFILE = [
    (-0.70, 0.00),
    (-0.58, 0.28),
    (-0.48, 0.40),
    (-0.46, 0.47),
    (-0.41, 0.47),
    (-0.39, 0.42),
    (0.40, 0.40),
    (0.42, 0.46),
    (0.49, 0.46),
    (0.51, 0.40),
    (0.55, 0.36),
    (0.58, 0.00),
]

# Vertical ribs down the body, as sectors of the hull pushed outwards. A rib has
# to have width: a plate in a plane through the axis is a blade of no thickness,
# visible only edge-on, and from every other angle it vanishes into the shell.
# Given width, the ribs scallop the outline, which is the one piece of detail
# that survives being thirty pixels tall.
RIB_COUNT = 12
RIB_SPAN = 0.62
RIB_BUMP = 0.05
RIB_RANGE = (-0.38, 0.39)

# The hatch, as one raised panel wide enough to break the ring of ribs. It is
# what gives the pod a front at the sizes where the ribs have merged into a
# texture.
HATCH = (-0.22, 0.26, 0.55, 0.075)

# Bands at the two ends, where the reference has a flange and a collar.
BANDS = [(-0.435, 0.475, 0.05), (0.455, 0.465, 0.07)]

# Antenna studs on the dome, off-axis so the pod has a front.
STUDS = [(0.19, 0.0, 0.57, 0.035, 0.11), (-0.11, 0.15, 0.55, 0.028, 0.08)]


def revolve(rng, y0, r0, y1, r1, count):
    for _ in range(count):
        # Square-rooted so the sample lands uniformly over the slant's area
        # rather than along its length, which would over-sample the narrow end
        # of every taper.
        t = math.sqrt(rng.random()) if r1 > r0 else 1.0 - math.sqrt(rng.random())
        r = r0 + (r1 - r0) * t
        y = y0 + (y1 - y0) * t
        a = rng.random() * math.tau
        yield (math.cos(a) * r, y, math.sin(a) * r)


def band(rng, y, r, height, count):
    for _ in range(count):
        a = rng.random() * math.tau
        yield (math.cos(a) * r, y + (rng.random() - 0.5) * height, math.sin(a) * r)


def sector(rng, y0, r0, y1, r1, a0, a1, bump, count):
    """The rib's face: a slice of the hull, standing `bump` proud of it."""
    for _ in range(count):
        t = rng.random()
        a = a0 + (a1 - a0) * rng.random()
        r = r0 + (r1 - r0) * t + bump
        y = y0 + (y1 - y0) * t
        yield (math.cos(a) * r, y, math.sin(a) * r)


def flank(rng, y0, r0, y1, r1, azimuth, bump, count):
    """The rib's side wall, closing the step between the hull and the face."""
    ca, sa = math.cos(azimuth), math.sin(azimuth)
    for _ in range(count):
        t = rng.random()
        r = r0 + (r1 - r0) * t + bump * rng.random()
        y = y0 + (y1 - y0) * t
        yield (ca * r, y, sa * r)


def stud(rng, x, z, y, radius, height, count):
    for _ in range(count):
        a = rng.random() * math.tau
        yield (x + math.cos(a) * radius, y + rng.random() * height, z + math.sin(a) * radius)


def build(count, seed=0):
    rng = random.Random(seed)

    hull = []
    for (y0, r0), (y1, r1) in zip(PROFILE, PROFILE[1:]):
        slant = math.hypot(y1 - y0, r1 - r0)
        hull.append(((y0, r0, y1, r1), math.pi * (r0 + r1) * slant))

    bands = [(y, r, h, math.tau * r * h) for y, r, h in BANDS]

    # The profile segments the ribs run over, clipped to their range.
    pitch = math.tau / RIB_COUNT
    half = pitch * RIB_SPAN / 2
    spans = []
    for (y0, r0), (y1, r1) in zip(PROFILE, PROFILE[1:]):
        lo, hi = max(min(y0, y1), RIB_RANGE[0]), min(max(y0, y1), RIB_RANGE[1])
        if hi <= lo or y1 == y0:
            continue
        cut = lambda y: (y, r0 + (r1 - r0) * (y - y0) / (y1 - y0))
        spans.append((cut(lo), cut(hi)))

    ribs = []
    for i in range(RIB_COUNT):
        mid = i * pitch
        for (y0, r0), (y1, r1) in spans:
            slant = math.hypot(y1 - y0, r1 - r0)
            face = (r0 + r1 + 2 * RIB_BUMP) / 2 * (2 * half) * slant
            ribs.append((("face", y0, r0, y1, r1, mid - half, mid + half), face))
            for edge in (mid - half, mid + half):
                ribs.append((("flank", y0, r0, y1, r1, edge), RIB_BUMP * slant))

    studs = [(x, z, y, rad, h, math.tau * rad * h) for x, z, y, rad, h in STUDS]

    y0, y1, mid, arc = HATCH
    r_at = lambda y: next(a + (b - a) * (y - ya) / (yb - ya)
                          for (ya, a), (yb, b) in zip(PROFILE, PROFILE[1:])
                          if ya <= y <= yb and yb != ya)
    hatch = [(y0, r_at(y0), y1, r_at(y1), mid - arc / 2, mid + arc / 2,
              (y1 - y0) * arc * r_at((y0 + y1) / 2))]

    total = (sum(a for _, a in hull) + sum(a for *_, a in bands)
             + sum(a for _, a in ribs) + sum(a for *_, a in studs)
             + sum(a for *_, a in hatch))
    share = count / total

    points = []
    for (y0, r0, y1, r1), area in hull:
        points.extend(revolve(rng, y0, r0, y1, r1, round(area * share)))
    for y, r, h, area in bands:
        points.extend(band(rng, y, r, h, round(area * share)))
    for spec, area in ribs:
        n = round(area * share)
        if spec[0] == "face":
            _, y0, r0, y1, r1, a0, a1 = spec
            points.extend(sector(rng, y0, r0, y1, r1, a0, a1, RIB_BUMP, n))
        else:
            _, y0, r0, y1, r1, edge = spec
            points.extend(flank(rng, y0, r0, y1, r1, edge, RIB_BUMP, n))
    for x, z, y, rad, h, area in studs:
        points.extend(stud(rng, x, z, y, rad, h, round(area * share)))
    for ya, ra, yb, rb, a0, a1, area in hatch:
        points.extend(sector(rng, ya, ra, yb, rb, a0, a1, RIB_BUMP * 1.4, round(area * share)))
        for edge in (a0, a1):
            points.extend(flank(rng, ya, ra, yb, rb, edge, RIB_BUMP * 1.4,
                                round(area * share * 0.25)))

    rng.shuffle(points)
    return points


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("out", type=Path)
    ap.add_argument("--count", type=int, default=12544,
                    help="target point count; the bake thins to side² anyway")
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()

    points = build(args.count, args.seed)
    args.out.write_bytes(b"".join(struct.pack("<3f", *p) for p in points))
    print(f"✓ {args.out}: {len(points)} points")


if __name__ == "__main__":
    main()
