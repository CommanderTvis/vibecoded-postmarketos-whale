# Deploying as an apk repo on GitHub Pages

GitHub *Packages* (ghcr.io) can't host Alpine packages — it only speaks
npm/Maven/NuGet/RubyGems/OCI. But an apk repo is just signed
`APKINDEX.tar.gz` + `.apk` files over HTTPS, so **GitHub Pages** is a perfect
static vessel. Because the package is `arch="noarch"`, one build serves every
device.

## One-time setup

1. **Signing key** — apk repos must be signed. Create an RSA key and store the
   private half as a repo secret (the workflow derives the public half):
   ```sh
   openssl genrsa 4096 > key.rsa
   gh secret set ABUILD_PRIVKEY < key.rsa
   rm key.rsa          # keep it only in the secret + somewhere safe offline
   ```
2. **Enable Pages** — repo *Settings → Pages → Source: GitHub Actions*.

That's it. `.github/workflows/publish-apk-repo.yml` runs on every push that
touches the package and publishes the repo to
`https://<owner>.github.io/<repo>/`.

## What the workflow does

`packaging/build-apk-repo.sh` (in an Alpine container) `abuild`s the `.apk`,
then for each arch (`x86_64 aarch64 armv7 armhf x86 riscv64`) drops the noarch
apk in `public/<arch>/`, builds `APKINDEX.tar.gz`, and `abuild-sign`s it with
your key. The public key is published at `public/apple-whale-override.rsa.pub`.

## Installing on a device

```sh
wget -O /etc/apk/keys/apple-whale-override.rsa.pub \
    https://<owner>.github.io/<repo>/apple-whale-override.rsa.pub
echo "https://<owner>.github.io/<repo>" >> /etc/apk/repositories
apk update
apk add apple-whale-override
fc-cache -f          # then type 🐳
```

## Build the repo locally (optional)

Same script, via Docker:

```sh
export ABUILD_PRIVKEY="$(openssl genrsa 4096 2>/dev/null)"
make repo            # -> ./public/
```

## Licensing reminder

This repo ships Apple's copyrighted whale (`assets/apple-whale.png`). Hosting
it on **your** Pages is the same personal-use / DMCA-takedown footing as the
repo itself — it is *not* acceptable for the official postmarketOS `pmaports`
repo, which requires a freely-licensed glyph.
