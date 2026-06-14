#!/bin/sh
# Install the Apple 🐳 (U+1F433) override on this system.
#
#   ./install.sh                       # build from the placeholder + install
#   ./install.sh --from-apple-font F   # use the genuine glyph from font F
#   PREFIX=$HOME/.local ./install.sh   # per-user install (no root needed)
#
# postmarketOS / Alpine note: the font stack here (fontconfig + FreeType +
# HarfBuzz) is the same as any Linux desktop, so this works on a real device,
# the pmbootstrap QEMU image, or your dev box.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$here"

# --- where to install --------------------------------------------------------
PREFIX="${PREFIX:-/usr}"
if [ "$PREFIX" = "/usr" ] || [ "$PREFIX" = "" ]; then
    FONT_DIR="/usr/share/fonts/apple-whale"
    CONF_AVAIL="/etc/fonts/conf.d"
else
    FONT_DIR="$PREFIX/share/fonts/apple-whale"
    CONF_AVAIL="$PREFIX/etc/fonts/conf.d"
    [ -n "${XDG_CONFIG_HOME:-}" ] && CONF_AVAIL="$XDG_CONFIG_HOME/fontconfig/conf.d"
fi

# --- build the font ----------------------------------------------------------
echo ">> building AppleWhale.ttf"
if [ "${1:-}" = "--from-apple-font" ]; then
    [ -n "${2:-}" ] || { echo "--from-apple-font needs a path"; exit 1; }
    python3 tools/build_font.py --from-apple-font "$2" -o dist/AppleWhale.ttf
else
    [ -f assets/apple-whale-placeholder.png ] || python3 tools/make_placeholder.py
    python3 tools/build_font.py -o dist/AppleWhale.ttf
fi

# --- install -----------------------------------------------------------------
echo ">> installing font  -> $FONT_DIR"
mkdir -p "$FONT_DIR"
cp dist/AppleWhale.ttf "$FONT_DIR/AppleWhale.ttf"

echo ">> installing conf  -> $CONF_AVAIL/75-apple-whale.conf"
mkdir -p "$CONF_AVAIL"
cp fontconfig/75-apple-whale.conf "$CONF_AVAIL/75-apple-whale.conf"

echo ">> refreshing font cache"
fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1

echo ">> done. Verify with:  fc-match ':charset=1f433'"
fc-match ':charset=1f433' || true
