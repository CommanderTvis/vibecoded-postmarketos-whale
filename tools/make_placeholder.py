#!/usr/bin/env python3
"""Generate a placeholder, Apple-styled 🐳 (U+1F433) bitmap.

This draws a recognisably *Apple-style* spouting whale: a baby-blue rounded
body, a lighter belly, a little water spout and the characteristic friendly
look.  It is **not** Apple's copyrighted artwork — Apple Color Emoji is
proprietary and cannot be redistributed.  For the genuine glyph, run
``build_font.py --from-apple-font "Apple Color Emoji.ttc"`` against a font
you already own (copied from your own Mac / iPhone).

The placeholder lets the whole pipeline be built and tested end-to-end
without shipping any Apple assets.
"""
from __future__ import annotations

import argparse

from PIL import Image, ImageDraw

# Apple's spouting whale palette (approximate, Apple-flavoured blues).
BODY = (101, 175, 230, 255)      # baby blue body
BODY_DK = (74, 144, 200, 255)    # slightly darker outline/shadow
BELLY = (213, 236, 250, 255)     # pale belly
WATER = (130, 200, 240, 255)     # spout droplets
EYE = (40, 60, 80, 255)


def draw_whale(size: int = 160) -> Image.Image:
    """Return a square RGBA image of an Apple-style spouting whale."""
    # Supersample for smooth edges, then downscale.
    ss = 4
    s = size * ss
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def px(*xy):
        return [v * ss for v in xy]

    # --- body: a fat rounded ellipse, tail on the right ---
    d.ellipse(px(14, 52, 120, 128), fill=BODY)
    # tail flukes (upper-right), two triangles
    d.polygon(px(112, 86, 150, 56, 138, 92), fill=BODY)
    d.polygon(px(112, 92, 152, 104, 134, 104), fill=BODY)
    # blend tail base
    d.ellipse(px(104, 80, 124, 112), fill=BODY)

    # --- belly: pale underside ---
    d.ellipse(px(20, 84, 116, 130), fill=BELLY)
    d.rectangle(px(0, 0, 0, 0))  # no-op keeps linters calm

    # --- spout: a little fountain from the blowhole (top-left of body) ---
    d.line(px(44, 50, 40, 22), fill=WATER, width=6 * ss)
    for cx, cy, r in [(38, 18, 7), (46, 24, 5), (33, 28, 5), (50, 14, 5)]:
        d.ellipse(px(cx - r, cy - r, cx + r, cy + r), fill=WATER)

    # --- eye ---
    d.ellipse(px(40, 78, 52, 92), fill=EYE)
    d.ellipse(px(43, 80, 48, 85), fill=(255, 255, 255, 255))

    # --- mouth: gentle smile ---
    d.arc(px(26, 86, 64, 116), start=20, end=80, fill=BODY_DK, width=4 * ss)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("-o", "--out", default="assets/apple-whale-placeholder.png")
    ap.add_argument("-s", "--size", type=int, default=160)
    args = ap.parse_args()
    draw_whale(args.size).save(args.out)
    print(f"wrote {args.out} ({args.size}x{args.size})")


if __name__ == "__main__":
    main()
