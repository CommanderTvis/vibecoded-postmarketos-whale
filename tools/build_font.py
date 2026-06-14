#!/usr/bin/env python3
"""Build ``AppleWhale.ttf`` — a minimal sbix colour font that contains exactly
one glyph: the Apple 🐳 (U+1F433 SPOUTING WHALE).

Because the font holds *only* that codepoint, dropping it ahead of Noto Color
Emoji in fontconfig substitutes just the whale; every other emoji still falls
through to Noto.

Image source (in priority order):

  --from-apple-font PATH   Extract the genuine U+1F433 bitmap from an Apple
                           Color Emoji font you already own (its ``sbix``
                           strike).  e.g. a copy of
                           "/System/Library/Fonts/Apple Color Emoji.ttc".
  --png PATH               Use an arbitrary square PNG as the whale.
  (default)                assets/apple-whale.png (the genuine glyph, once you
                           have committed it) else assets/apple-whale-placeholder.png

The result is an sbix font (the same colour-bitmap format Apple uses), which
FreeType/HarfBuzz on postmarketOS render natively.
"""
from __future__ import annotations

import argparse
import io
import os
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.ttLib import TTFont, newTable
from fontTools.ttLib.tables._g_l_y_f import Glyph
from fontTools.ttLib.tables.sbixGlyph import Glyph as SbixGlyph
from fontTools.ttLib.tables.sbixStrike import Strike

try:
    from PIL import Image
except ImportError:  # Pillow only needed for --png / placeholder paths
    Image = None

WHALE_CP = 0x1F433
GLYPH = "whale"
UPEM = 1024


def extract_from_apple_font(path: str) -> bytes:
    """Pull the U+1F433 PNG bitmap out of an Apple Color Emoji sbix font."""
    font = TTFont(path, fontNumber=0, lazy=True)
    if "sbix" not in font:
        raise SystemExit(f"{path}: no 'sbix' table — not an Apple emoji font?")
    cmap = font.getBestCmap()
    if WHALE_CP not in cmap:
        raise SystemExit(f"{path}: font has no glyph for U+1F433")
    glyph_name = cmap[WHALE_CP]
    sbix = font["sbix"]
    # Pick the largest strike that actually has a PNG for the whale.
    best = None
    for ppem, strike in sorted(sbix.strikes.items()):
        g = strike.glyphs.get(glyph_name)
        if g is not None and g.imageData and g.graphicType == "png ":
            best = (ppem, g.imageData)
    if best is None:
        raise SystemExit(f"{path}: no PNG strike for the whale glyph")
    print(f"  extracted U+1F433 from {path}: strike {best[0]}px, "
          f"{len(best[1])} bytes")
    return best[1]


def default_source() -> str:
    """The genuine Apple glyph if it has been committed, else the placeholder."""
    genuine = "assets/apple-whale.png"
    placeholder = "assets/apple-whale-placeholder.png"
    if os.path.exists(genuine):
        return genuine
    if os.path.exists(placeholder):
        return placeholder
    raise SystemExit(
        "no source image found: run tools/make_placeholder.py, pass --png, "
        "or extract a genuine glyph with --from-apple-font")


def load_png(path: str) -> bytes:
    with open(path, "rb") as fh:
        data = fh.read()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise SystemExit(f"{path}: not a PNG file")
    return data


def square_size(png: bytes) -> int:
    """Pixel height of the PNG (assumed square)."""
    if Image is None:
        # PNG IHDR: width/height are big-endian uint32 at offset 16/20.
        return int.from_bytes(png[20:24], "big")
    with Image.open(io.BytesIO(png)) as im:
        return im.size[1]


def build(png: bytes, out: str) -> None:
    ppem = square_size(png)

    fb = FontBuilder(UPEM, isTTF=True)
    glyph_order = [".notdef", GLYPH]
    fb.setupGlyphOrder(glyph_order)
    fb.setupCharacterMap({WHALE_CP: GLYPH})

    # Empty TrueType outlines; sbix overlays the colour bitmap on top.
    glyf = {name: Glyph() for name in glyph_order}
    fb.setupGlyf(glyf)

    advance = UPEM  # render the whale across one em square, like other emoji
    fb.setupHorizontalMetrics({".notdef": (advance, 0), GLYPH: (advance, 0)})
    fb.setupHorizontalHeader(ascent=int(UPEM * 0.8), descent=-int(UPEM * 0.2))
    fb.setupNameTable({
        "familyName": "Apple Whale Override",
        "styleName": "Regular",
        "fullName": "Apple Whale Override",
        "psName": "AppleWhaleOverride-Regular",
        "version": "1.0",
        "uniqueFontIdentifier": "AppleWhaleOverride-1.0",
    })
    fb.setupOS2(sTypoAscender=int(UPEM * 0.8), sTypoDescender=-int(UPEM * 0.2),
                usWinAscent=int(UPEM * 0.8), usWinDescent=int(UPEM * 0.2))
    fb.setupPost()

    # --- sbix colour-bitmap table: one strike, one glyph ---
    sbix = newTable("sbix")
    sbix.version = 1
    sbix.flags = 1
    sbix.numStrikes = 1
    sbix.strikes = {}
    strike = Strike(ppem=ppem, resolution=72)
    # originOffsetY drops the bitmap so it straddles the baseline like an emoji.
    strike.glyphs[".notdef"] = SbixGlyph(glyphName=".notdef", rawdata=b"")
    strike.glyphs[GLYPH] = SbixGlyph(
        glyphName=GLYPH,
        graphicType="png ",
        imageData=png,
        originOffsetX=0,
        originOffsetY=-int(UPEM * 0.2),
    )
    sbix.strikes[ppem] = strike
    fb.font["sbix"] = sbix

    fb.font.save(out)
    print(f"  wrote {out}: sbix font, 1 strike @ {ppem}px, "
          f"family 'Apple Whale Override', maps U+1F433 -> {GLYPH}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    src = ap.add_mutually_exclusive_group()
    src.add_argument("--from-apple-font", metavar="TTC",
                     help="extract the genuine glyph from an Apple emoji font")
    src.add_argument("--png", metavar="PNG", help="use a custom square PNG")
    ap.add_argument("--dump-png", metavar="PNG",
                    help="also save the chosen bitmap here (used to commit the "
                         "extracted Apple glyph as assets/apple-whale.png)")
    ap.add_argument("-o", "--out", default="dist/AppleWhale.ttf")
    args = ap.parse_args()

    if args.from_apple_font:
        png = extract_from_apple_font(args.from_apple_font)
    elif args.png:
        png = load_png(args.png)
    else:
        png = load_png(default_source())

    if args.dump_png:
        os.makedirs(os.path.dirname(args.dump_png) or ".", exist_ok=True)
        with open(args.dump_png, "wb") as fh:
            fh.write(png)
        print(f"  wrote {args.dump_png} ({len(png)} bytes)")

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    build(png, args.out)


if __name__ == "__main__":
    sys.exit(main())
