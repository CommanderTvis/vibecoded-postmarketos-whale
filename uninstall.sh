#!/bin/sh
# Remove the Apple 🐳 override installed by install.sh.
set -eu

PREFIX="${PREFIX:-/usr}"
if [ "$PREFIX" = "/usr" ] || [ "$PREFIX" = "" ]; then
    FONT_DIR="/usr/share/fonts/apple-whale"; CONF="/etc/fonts/conf.d/75-apple-whale.conf"
else
    FONT_DIR="$PREFIX/share/fonts/apple-whale"; CONF="$PREFIX/etc/fonts/conf.d/75-apple-whale.conf"
    [ -n "${XDG_CONFIG_HOME:-}" ] && CONF="$XDG_CONFIG_HOME/fontconfig/conf.d/75-apple-whale.conf"
fi

rm -vf "$FONT_DIR/AppleWhale.ttf" "$CONF"
rmdir "$FONT_DIR" 2>/dev/null || true
fc-cache -f >/dev/null 2>&1 || true
echo ">> removed. 🐳 now falls back to the system emoji font."
