# vibecoded-postmarketos-whale

Replace **U+1F433 (🐳)** with the **Apple** glyph on postmarketOS — and *only* that emoji; everything else stays on Noto Color Emoji.

**Install:** `sudo make install` (revert: `sudo make uninstall`, test: `make test`). On a device: build `packaging/APKBUILD` → `apk add apple-whale-override`, or pull from a signed apk repo on GitHub Pages — see [packaging/apk-repo.md](packaging/apk-repo.md). Emulator: `make emulator` (pmbootstrap QEMU, needs KVM).

**Function:** ships a one-glyph colour font holding *only* the whale (built from the bundled `assets/apple-whale.png`) and a fontconfig rule preferring it over Noto; all other emoji fall through unchanged. Refresh the glyph from your own Apple font with `make font-apple APPLE="/path/Apple Color Emoji.ttc"`.

**Mechanism:** postmarketOS uses fontconfig (pick font) + FreeType (rasterise) + HarfBuzz (shape). `75-apple-whale.conf` prepends `AppleWhale.ttf` (sbix, U+1F433 only) ahead of Noto, so HarfBuzz takes 🐳 from our font and every other codepoint from Noto.

**License:** the code/config is MIT. `assets/apple-whale.png` is Apple's copyrighted artwork (Apple Color Emoji), **not** MIT-licensed and not mine to relicense — it's bundled here only for personal device use and will be removed on any DMCA request.
