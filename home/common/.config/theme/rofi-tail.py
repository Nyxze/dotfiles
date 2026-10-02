#!/usr/bin/env python3
"""Draw the selector's trailing bands as an image, for rofi.

Every other engine can express the tail directly: quickshell draws it as a
Shape, GTK as a gradient bounded by background-size. rofi cannot. rasi takes
colour stops but not positions, and adding transparent stops to push the bands
rightward barely moves them — its placement is not the even distribution it
looks like. An image is scaled to the widget instead, so a fifth of the source
is a fifth of the row whatever the screen.

    python3 rofi-tail.py && ./deploy theme rofi
"""

from PIL import Image, ImageDraw

# The stylesheet loads this with the "width" mode, which scales uniformly until
# the image spans the row and lets the rest hang off the top and bottom. Not
# "both": that one means contain, so it fits the image inside the row and
# leaves the remainder showing plain accent — and on a source much taller than
# the row it squeezes the diagonals into a staircase on the way.
#
# Uniform scaling means the aspect here decides how much is cropped, not what
# the slant ends up being. A source close to the row's own proportions keeps
# that crop small: the row is 40px high, and 34% of the screen wide, which is
# ~512px on the laptop and ~620px on the external display.
WIDTH, HEIGHT = 560, 40

TAIL = 0.20          # share of the width the bands take
SECOND_BAND = 0.34   # of the tail; the first band takes the rest
SLANT = 0.4          # horizontal travel of each diagonal over the height

BAND_1 = (17, 26, 35, 97)     # bg-panel at 38%
BAND_2 = (17, 26, 35, 138)    # bg-panel at 54%
HAIRLINE = (255, 212, 0, 150)  # accent, catching the step between the bands


def main():
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    slant = int(HEIGHT * SLANT)
    tail = int(WIDTH * TAIL)
    second = int(tail * SECOND_BAND)
    body_end = WIDTH - tail
    band_edge = WIDTH - second

    # Each band is a parallelogram whose top edge reaches further right than
    # its bottom, which is the lean the whole language uses. Both run past the
    # right edge so nothing thins out at the corner.
    draw.polygon([(body_end, 0), (band_edge, 0),
                  (band_edge - slant, HEIGHT), (body_end - slant, HEIGHT)], fill=BAND_1)
    draw.polygon([(band_edge, 0), (WIDTH + slant, 0),
                  (WIDTH + slant, HEIGHT), (band_edge - slant, HEIGHT)], fill=BAND_2)
    draw.line([(band_edge, 0), (band_edge - slant, HEIGHT)], fill=HAIRLINE, width=2)

    img.save("rofi-tail.png")
    print(f"rofi-tail.png {img.size}, tail starts at {100 * body_end // WIDTH}%")


if __name__ == "__main__":
    main()
