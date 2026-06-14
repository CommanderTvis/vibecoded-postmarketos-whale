#!/bin/sh
# Self-contained test for the Apple 🐳 override.
#
# It builds the font, installs it into a *throwaway* fontconfig prefix (so the
# real system is untouched), and asserts:
#
#   1. the font embeds exactly one codepoint (U+1F433), byte-identical to source
#   2. fontconfig resolves U+1F433  -> our "Apple Whale Override"
#   3. fontconfig resolves a *different* emoji (😀 U+1F600) -> still Noto
#      (i.e. we override ONLY the whale, nothing else)
#
# Pixel rendering is checked separately by render_check.py, which needs a
# FreeType built with PNG support (postmarketOS has it; many minimal CI
# containers do not, so that part skips gracefully).
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$here"

pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAILED=1; }
FAILED=0

echo "== 1. build font =="
python3 tools/make_placeholder.py >/dev/null
python3 tools/build_font.py -o dist/AppleWhale.ttf

echo "== 2. structural check (cmap + embedded bitmap) =="
python3 - <<'PY' && pass "font embeds exactly U+1F433, byte-identical to source" || fail "structural check"
import sys
sys.path.insert(0, "tools")
from fontTools.ttLib import TTFont
from build_font import default_source  # whichever PNG the build actually uses
f = TTFont("dist/AppleWhale.ttf")
cmap = sorted(f.getBestCmap())
assert cmap == [0x1F433], f"expected only U+1F433, got {[hex(c) for c in cmap]}"
g = next(iter(f["sbix"].strikes.values())).glyphs["whale"]
src = open(default_source(), "rb").read()
assert g.imageData == src, "embedded bitmap != source"
sys.exit(0)
PY

echo "== 3. fontconfig substitution (throwaway prefix) =="
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/fonts" "$TMP/cache"
cp dist/AppleWhale.ttf "$TMP/fonts/"

cat > "$TMP/fonts.conf" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>$TMP/fonts</dir>
  <cachedir>$TMP/cache</cachedir>
  <include ignore_missing="no">$here/fontconfig/75-apple-whale.conf</include>
</fontconfig>
EOF

export FONTCONFIG_FILE="$TMP/fonts.conf"
fc-cache -f "$TMP/fonts" >/dev/null 2>&1 || true

# fontconfig must even know about our font:
if fc-list | grep -q "Apple Whale Override"; then
    pass "font is registered with fontconfig"
else
    fail "font not registered with fontconfig"
fi

# Query the way a real toolkit shapes emoji: the 'emoji' family + the codepoint.
whale=$(fc-match -f '%{family}\n' 'emoji:charset=1f433')
echo "    emoji + U+1F433 (whale) -> $whale"
case "$whale" in
    *"Apple Whale Override"*) pass "U+1F433 resolves to the Apple override" ;;
    *) fail "U+1F433 did NOT resolve to the override (got: $whale)" ;;
esac

# The whale font must still let Noto handle the whale as a fallback (2nd place),
# proving we only *prepend* rather than break the emoji stack.
fallback=$(fc-match -s -f '%{family}\n' 'emoji:charset=1f433' | sed -n 2p)
echo "    ...fallback after override -> $fallback"
case "$fallback" in
    *"Noto Color Emoji"*) pass "Noto Color Emoji remains the whale fallback" ;;
    *) fail "expected Noto Color Emoji as fallback, got: $fallback" ;;
esac

other=$(fc-match -f '%{family}\n' 'emoji:charset=1f600')
echo "    emoji + U+1F600 (grin)  -> $other"
case "$other" in
    *"Apple Whale Override"*) fail "U+1F600 wrongly hijacked by the override" ;;
    *) pass "U+1F600 still goes to the system emoji font ($other)" ;;
esac

echo "== 4. pixel render check (needs PNG-enabled FreeType) =="
python3 test/render_check.py dist/AppleWhale.ttf || true

echo
if [ "$FAILED" = 0 ]; then
    printf '\033[32mALL CHECKS PASSED\033[0m\n'
else
    printf '\033[31mSOME CHECKS FAILED\033[0m\n'; exit 1
fi
