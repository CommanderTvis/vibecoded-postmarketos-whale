# vibecoded-postmarketos-whale

Replace **U+1F433 (🐳)** with the **Apple** glyph on postmarketOS — and *only* that emoji; everything else stays on Noto Color Emoji.

**Install:** `sudo make install` (revert: `sudo make uninstall`, test: `make test`). On a device: build `packaging/APKBUILD` → `apk add apple-whale-override`. Emulator: `make emulator` (pmbootstrap QEMU, needs KVM).

**Function:** ships a one-glyph colour font holding *only* the whale and a fontconfig rule preferring it over Noto; all other emoji fall through unchanged. The repo bundles a placeholder doodle, not Apple's glyph; for the real one, extract it from a font you own — on macOS run `sh tools/extract-apple-whale-macos.sh` (commits `assets/apple-whale.png`), or anywhere `make font-apple APPLE="/path/Apple Color Emoji.ttc"`.

**Mechanism:** postmarketOS uses fontconfig (pick font) + FreeType (rasterise) + HarfBuzz (shape). `75-apple-whale.conf` prepends `AppleWhale.ttf` (sbix, U+1F433 only) ahead of Noto, so HarfBuzz takes 🐳 from our font and every other codepoint from Noto.

MIT. Apple Color Emoji is proprietary and not included — supply your own via `--from-apple-font`.
