#!/bin/sh
# Build the apple-whale-override apk and assemble a *signed* apk repository
# under ./public/, laid out for static hosting (e.g. GitHub Pages).
#
# Runs inside an Alpine container/host (needs abuild). The repo source tree is
# expected at $SRC (default /src). Provide your abuild signing key as the
# ABUILD_PRIVKEY env var (a plain RSA private key is fine):
#
#   openssl genrsa 4096 > key.rsa
#   docker run --rm -e ABUILD_PRIVKEY="$(cat key.rsa)" -v "$PWD:/src" \
#       alpine:3.20 /src/packaging/build-apk-repo.sh
#
# Output: public/<arch>/{APKINDEX.tar.gz,*.apk} for every postmarketOS arch,
# plus public/<keyname>.rsa.pub (the public key devices must trust).
set -eu

SRC="${SRC:-/src}"
KEY="apple-whale-override.rsa"          # signature/key file name devices need
PAGES_URL="${PAGES_URL:-https://USER.github.io/REPO}"
ARCHES="x86_64 aarch64 armv7 armhf x86 riscv64"

echo ">> enabling community repo + installing build tools"
v=$(cut -d. -f1,2 /etc/alpine-release)
grep -q '/community$' /etc/apk/repositories 2>/dev/null \
    || echo "https://dl-cdn.alpinelinux.org/alpine/v$v/community" >> /etc/apk/repositories
apk add --no-cache alpine-sdk openssl >/dev/null

echo ">> importing signing key"
: "${ABUILD_PRIVKEY:?set ABUILD_PRIVKEY to your abuild/RSA private key}"
mkdir -p "$HOME/.abuild"
printf '%s\n' "$ABUILD_PRIVKEY" > "$HOME/.abuild/$KEY"
chmod 600 "$HOME/.abuild/$KEY"
openssl rsa -in "$HOME/.abuild/$KEY" -pubout -out "$HOME/.abuild/$KEY.pub" 2>/dev/null
echo "PACKAGER_PRIVKEY=$HOME/.abuild/$KEY" > "$HOME/.abuild/abuild.conf"
cp "$HOME/.abuild/$KEY.pub" /etc/apk/keys/   # trust our key for local indexing

echo ">> staging + building the package"
stage="/tmp/stage/whale/apple-whale-override"
rm -rf "$stage"; mkdir -p "$stage"
cp "$SRC/packaging/APKBUILD" \
   "$SRC/tools/build_font.py" \
   "$SRC/fontconfig/75-apple-whale.conf" \
   "$SRC/assets/apple-whale.png" "$stage/"
cd "$stage"
abuild checksum
abuild -F -r            # -F: allow root (CI); -r: auto-install makedepends

echo ">> assembling signed repo under public/"
out="$SRC/public"
rm -rf "$out"; mkdir -p "$out"
apk_file=$(find "$HOME/packages" -name 'apple-whale-override-*.apk' | head -n1)
[ -n "$apk_file" ] || { echo "build produced no apk"; exit 1; }
echo "   built: $apk_file"

# noarch package -> serve the same .apk under every arch dir, index + sign each
for arch in $ARCHES; do
    mkdir -p "$out/$arch"
    cp "$apk_file" "$out/$arch/"
    apk index -o "$out/$arch/APKINDEX.tar.gz" "$out/$arch"/*.apk
    abuild-sign -k "$HOME/.abuild/$KEY" "$out/$arch/APKINDEX.tar.gz"
done
cp "$HOME/.abuild/$KEY.pub" "$out/"

cat > "$out/index.html" <<HTML
<!doctype html><meta charset="utf-8"><title>Apple 🐳 apk repo</title>
<h1>Apple 🐳 (U+1F433) override — apk repository</h1>
<p>On a postmarketOS / Alpine device:</p>
<pre>
wget -O /etc/apk/keys/$KEY.pub $PAGES_URL/$KEY.pub
echo "$PAGES_URL" >> /etc/apk/repositories
apk update
apk add apple-whale-override
</pre>
<p>Then refresh the font cache: <code>fc-cache -f</code>. Type 🐳 to test.</p>
<p><em>Contains Apple Color Emoji artwork, bundled for personal use only.</em></p>
HTML

echo ">> done. Repo in $out (base URL: $PAGES_URL)"
find "$out" -maxdepth 2 -type f | sort
