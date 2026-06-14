#!/bin/sh
# Build the apple-whale-override apk and assemble a *signed* apk repository
# under ./public/, laid out for static hosting (e.g. GitHub Pages).
#
# Runs inside an Alpine container/host. The repo source tree is expected at
# $SRC (default /src). Provide your abuild signing key via ABUILD_PRIVKEY
# (a plain RSA private key is fine):
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

# --- root: enable community, install tools + the package's deps up front -----
# (pre-installing make+runtime deps means abuild never needs root to fetch them)
echo ">> enabling community repo + installing build tools"
v=$(cut -d. -f1,2 /etc/alpine-release)
grep -q '/community$' /etc/apk/repositories 2>/dev/null \
    || echo "https://dl-cdn.alpinelinux.org/alpine/v$v/community" >> /etc/apk/repositories
apk add --no-cache \
    alpine-sdk openssl \
    python3 py3-fonttools py3-pillow \
    fontconfig font-noto-emoji >/dev/null

: "${ABUILD_PRIVKEY:?set ABUILD_PRIVKEY to your abuild/RSA private key}"

# --- abuild refuses to run as root: make an unprivileged builder -------------
adduser -D builder 2>/dev/null || true
addgroup builder abuild 2>/dev/null || true

echo ">> importing signing key (under the builder's home)"
install -d -o builder -g builder /home/builder/.abuild
printf '%s\n' "$ABUILD_PRIVKEY" > "/home/builder/.abuild/$KEY"
openssl rsa -in "/home/builder/.abuild/$KEY" -pubout \
    -out "/home/builder/.abuild/$KEY.pub" 2>/dev/null
echo "PACKAGER_PRIVKEY=/home/builder/.abuild/$KEY" > /home/builder/.abuild/abuild.conf
chmod 600 "/home/builder/.abuild/$KEY"
chown -R builder:builder /home/builder/.abuild
cp "/home/builder/.abuild/$KEY.pub" /etc/apk/keys/   # trust our key for indexing

echo ">> staging sources"
stage=/home/builder/stage/whale/apple-whale-override
install -d -o builder -g builder /home/builder/stage /home/builder/stage/whale "$stage"
cp "$SRC/packaging/APKBUILD" \
   "$SRC/tools/build_font.py" \
   "$SRC/fontconfig/75-apple-whale.conf" \
   "$SRC/assets/apple-whale.png" "$stage/"
chown -R builder:builder /home/builder/stage

# --- build + sign as the builder user ---------------------------------------
echo ">> building + signing as unprivileged user 'builder'"
cat > /home/builder/run.sh <<EOF
set -eu
cd "$stage"
abuild checksum
abuild                      # build + package -> \$HOME/packages/whale/<arch>/
apk_file=\$(find "\$HOME/packages" -name 'apple-whale-override-*.apk' | head -n1)
[ -n "\$apk_file" ] || { echo "build produced no apk"; exit 1; }
echo "   built: \$apk_file"

OUT="\$HOME/public"
rm -rf "\$OUT"; mkdir -p "\$OUT"
# noarch package -> serve the same .apk under every arch dir, index + sign each
for arch in $ARCHES; do
    mkdir -p "\$OUT/\$arch"
    cp "\$apk_file" "\$OUT/\$arch/"
    apk index -o "\$OUT/\$arch/APKINDEX.tar.gz" "\$OUT/\$arch"/*.apk
    abuild-sign -k "\$HOME/.abuild/$KEY" "\$OUT/\$arch/APKINDEX.tar.gz"
done
cp "\$HOME/.abuild/$KEY.pub" "\$OUT/"
EOF
chown builder:builder /home/builder/run.sh
su - builder -c "sh /home/builder/run.sh"

# --- publish into $SRC/public (root, since the mount may be root-owned) ------
echo ">> collecting repo into $SRC/public"
out="$SRC/public"
rm -rf "$out"
cp -r /home/builder/public "$out"

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
