#!/bin/sh
# Build the package and boot it inside the official postmarketOS QEMU emulator.
#
# Run this on a Linux host that has KVM (/dev/kvm) and can reach the Alpine /
# postmarketOS mirrors.  pmbootstrap downloads ~hundreds of MB and builds a
# rootfs, so it does NOT run inside a minimal CI container (no /dev/kvm, no
# nested virtualisation) — use your dev box.
#
# What it does:
#   1. installs pmbootstrap (if missing)
#   2. initialises a QEMU (x86_64) postmarketOS target with a UI
#   3. copies this package into pmaports/temp and builds it
#   4. bakes it into the image and launches QEMU
#
# Then, in the booted UI, open a terminal/text field and type 🐳 — it shows
# the Apple whale; every other emoji still uses Noto.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pkg=apple-whale-override

command -v pmbootstrap >/dev/null 2>&1 || {
	echo ">> installing pmbootstrap (pipx)"
	pipx install pmbootstrap || pip install --user pmbootstrap
}

[ -e /dev/kvm ] || echo "!! warning: /dev/kvm missing — QEMU will be very slow"

# One-time, interactive: pick 'qemu-amd64', a UI (e.g. phosh/plasma-mobile),
# username, etc.  Safe to re-run.
pmbootstrap init

# Stage the package sources into pmaports/temp.
aports=$(pmbootstrap config aports 2>/dev/null || echo "$HOME/.local/var/pmbootstrap/cache_git/pmaports")
dest="$aports/temp/$pkg"
echo ">> staging package into $dest"
mkdir -p "$dest"
cp "$here/packaging/APKBUILD"                       "$dest/"
cp "$here/tools/build_font.py"                      "$dest/"
cp "$here/tools/make_placeholder.py"                "$dest/"
cp "$here/fontconfig/75-apple-whale.conf"           "$dest/"
cp "$here/assets/apple-whale-placeholder.png"       "$dest/"

echo ">> building $pkg"
pmbootstrap build "$pkg"

echo ">> baking $pkg into the image"
pmbootstrap install --add "$pkg"

echo ">> launching QEMU — type 🐳 in the UI to see the Apple whale"
pmbootstrap qemu
