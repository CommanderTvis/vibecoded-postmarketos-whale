# vibecoded-postmarketos-whale

Replace **U+1F433 SPOUTING WHALE (🐳)** with the **Apple** version on
postmarketOS — and *only* that one emoji. Everything else still renders with
the system emoji font (Noto Color Emoji).

> ⚠️ **This repo does not contain Apple's whale.** Apple Color Emoji is
> proprietary and can't be redistributed, so the bundled
> [`assets/apple-whale-placeholder.png`](assets/apple-whale-placeholder.png)
> is just a stand-in Apple-*styled* doodle — **not** the real glyph and not
> what you'll get unless you supply your own Apple font (see
> [Using the genuine Apple glyph](#using-the-genuine-apple-glyph)).

## How it works

postmarketOS uses the same text stack as any Linux desktop:
**fontconfig** (which font?) + **FreeType** (rasterise) + **HarfBuzz** (shape).
There is no per-codepoint "swap this emoji" knob, so the trick is:

1. **A one-glyph colour font** — `AppleWhale.ttf`, an `sbix` font (the same
   colour-bitmap format Apple uses) containing *only* the whale at U+1F433.
2. **A fontconfig rule** — `75-apple-whale.conf` prepends that font ahead of
   Noto Color Emoji. Because the font has no other glyph, every other
   character (and every other emoji) falls straight through to Noto.

```
text "🐳😀"  ──HarfBuzz──▶  🐳 → Apple Whale Override   (our font, U+1F433 only)
                            😀 → Noto Color Emoji        (fallback, unchanged)
```

## Quick start

```sh
make test       # build + verify substitution (no root, no install)
sudo make install   # install system-wide and refresh the font cache
sudo make uninstall # revert
```

Verify by hand:

```sh
fc-match 'emoji:charset=1f433'   # -> Apple Whale Override
fc-match 'emoji:charset=1f600'   # -> Noto Color Emoji  (untouched)
```

## Using the *genuine* Apple glyph

The bundled `assets/apple-whale-placeholder.png` is a hand-drawn,
Apple-*styled* whale — Apple Color Emoji is proprietary and cannot be
redistributed here. To use the real bitmap, build against a copy of an Apple
emoji font **you already own** (e.g. from your own Mac/iPhone):

```sh
make font-apple APPLE="/path/to/Apple Color Emoji.ttc"
sudo make install
```

`build_font.py --from-apple-font` pulls the U+1F433 bitmap straight out of the
font's `sbix` table, so the result is pixel-for-pixel the Apple whale.

## Layout

| Path | What |
|------|------|
| `tools/build_font.py` | builds the single-glyph `sbix` font (placeholder, custom PNG, or extracted from an Apple font) |
| `tools/make_placeholder.py` | draws the Apple-styled placeholder PNG |
| `fontconfig/75-apple-whale.conf` | the substitution rule |
| `install.sh` / `uninstall.sh` | system install / revert |
| `packaging/APKBUILD` | postmarketOS / Alpine package |
| `test/test_substitution.sh` | automated verification |
| `test/run-emulator.sh` | boot it in the postmarketOS QEMU emulator |

## Installing on a device / image (apk)

`packaging/APKBUILD` packages the font + conf as `apple-whale-override`
(runtime deps: `fontconfig`, `font-noto-emoji`). Drop it into your `pmaports`
checkout and:

```sh
pmbootstrap build apple-whale-override
pmbootstrap install --add apple-whale-override   # bake into the image
# or on a running device:
apk add apple-whale-override
```

## Testing on the emulator

`test/run-emulator.sh` automates the official **postmarketOS QEMU** flow
(`pmbootstrap init` → `build` → `install --add` → `qemu`). Boot it, then type
🐳 in any text field to see the Apple whale.

> **Requires KVM** (`/dev/kvm`) and access to the Alpine/postmarketOS mirrors.
> pmbootstrap builds a full rootfs, so it does **not** run inside a minimal
> CI container (no nested virtualisation) — run it on your dev box.

## What was verified, and where

This repo was developed and tested on a stock Linux box whose font stack is
identical to postmarketOS's (fontconfig 2.15 + FreeType + HarfBuzz):

- ✅ the font embeds **exactly** U+1F433, byte-identical to the source image
- ✅ `fc-match` resolves the whale to **Apple Whale Override**, with Noto as the
  next fallback
- ✅ a different emoji (😀 U+1F600) still resolves to **Noto Color Emoji**
- ✅ `install.sh` flips the system result Noto → Apple; `uninstall.sh` reverts it
- ⏭️ pixel rendering of the colour glyph needs a **PNG-enabled FreeType**
  (postmarketOS/Alpine ships one; minimal CI containers do not, so
  `test/render_check.py` skips there instead of failing)

Run `make test` to reproduce.

## License

MIT (code/config). The placeholder artwork is original to this repo. The
genuine Apple glyph is **not** included — supply your own licensed Apple emoji
font via `--from-apple-font`.
