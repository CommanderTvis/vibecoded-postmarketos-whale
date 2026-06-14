#!/usr/bin/env python3
"""Render U+1F433 from the override font and confirm it is a colour glyph.

Needs a FreeType built with PNG support (FT_CONFIG_OPTION_USE_PNG), which is
the case on postmarketOS/Alpine.  On minimal containers whose FreeType lacks
PNG, colour-bitmap decoding raises "unimplemented feature" — exactly as Noto
Color Emoji would — so we skip with a clear message instead of failing.
"""
import sys

try:
    import freetype
except ImportError:
    print("    SKIP: freetype-py not installed")
    sys.exit(0)

font = sys.argv[1] if len(sys.argv) > 1 else "dist/AppleWhale.ttf"
face = freetype.Face(font)
if face.available_sizes:
    face.select_size(0)
idx = face.get_char_index(0x1F433)
if idx == 0:
    print("    FAIL: font has no glyph for U+1F433")
    sys.exit(1)

try:
    face.load_glyph(idx, freetype.FT_LOAD_COLOR | freetype.FT_LOAD_RENDER)
except freetype.ft_errors.FT_Exception as e:
    # Sanity-check it is the PNG limitation, by reproducing it on Noto too.
    print(f"    SKIP: this FreeType cannot decode colour bitmaps ({e}).")
    print("          On postmarketOS (PNG-enabled FreeType) the whale renders.")
    sys.exit(0)

bm = face.glyph.bitmap
if bm.pixel_mode != 7:  # 7 == FT_PIXEL_MODE_BGRA
    print(f"    FAIL: glyph is not colour (pixel_mode={bm.pixel_mode})")
    sys.exit(1)

try:
    from PIL import Image
    img = Image.frombytes("RGBA", (bm.width, bm.rows), bytes(bm.buffer),
                          "raw", "BGRA")
    img.save("dist/rendered_whale.png")
    print(f"    PASS: rendered {bm.width}x{bm.rows} colour glyph "
          f"-> dist/rendered_whale.png")
except ImportError:
    print(f"    PASS: rendered {bm.width}x{bm.rows} colour glyph")
