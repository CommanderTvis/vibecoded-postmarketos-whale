#!/bin/sh
# Extract the genuine Apple 🐳 (U+1F433) glyph from THIS Mac's own
# "Apple Color Emoji" font, commit it to the repo, and push to master.
#
# Run it on macOS, from inside your clone of this repo:
#
#   sh tools/extract-apple-whale-macos.sh
#   # or point at a specific font file:
#   sh tools/extract-apple-whale-macos.sh "/path/to/Apple Color Emoji.ttc"
#
# The Apple artwork is read from the font *you* already license on your own
# machine and committed under *your* git identity — no Claude co-authorship,
# clear attribution to you.
set -eu

FONT="${1:-/System/Library/Fonts/Apple Color Emoji.ttc}"
if [ ! -f "$FONT" ]; then
    echo "error: Apple Color Emoji font not found at:"
    echo "  $FONT"
    echo "pass the path explicitly, e.g.:"
    echo "  sh tools/extract-apple-whale-macos.sh \"\$HOME/Library/Fonts/Apple Color Emoji.ttc\""
    exit 1
fi

here=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$here"

command -v python3 >/dev/null 2>&1 || {
    echo "error: python3 not found. Install Xcode Command Line Tools: xcode-select --install"
    exit 1
}

# --- isolated build env so we don't touch your system python -----------------
VENV=".venv-extract"
echo ">> setting up build environment ($VENV)"
python3 -m venv "$VENV"
# shellcheck disable=SC1091
. "$VENV/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet fonttools Pillow

# --- extract the genuine glyph + build the one-glyph font --------------------
echo ">> extracting U+1F433 from: $FONT"
python3 tools/build_font.py \
    --from-apple-font "$FONT" \
    --dump-png assets/apple-whale.png \
    -o dist/AppleWhale.ttf

deactivate 2>/dev/null || true

# --- commit + push to master, authored by YOU --------------------------------
echo ">> committing assets/apple-whale.png to master"
git checkout master
git pull --ff-only origin master || true
git add assets/apple-whale.png
git commit -m "Add genuine Apple 🐳 (U+1F433) glyph extracted from Apple Color Emoji

Bitmap extracted on macOS from this machine's own licensed Apple Color
Emoji font; becomes the default source for build_font.py over the
placeholder doodle."

i=1
while [ "$i" -le 4 ]; do
    if git push origin master; then break; fi
    echo "push failed, retry $i"; sleep $((1 << i)); i=$((i + 1))
done

echo ">> done. assets/apple-whale.png is now the genuine Apple whale."
echo "   Rebuild/install with:  sudo make install"
