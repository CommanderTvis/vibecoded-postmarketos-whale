# Apple 🐳 (U+1F433) override for postmarketOS
PYTHON ?= python3

.PHONY: all font font-apple install uninstall test emulator repo clean

all: font

# Build the single-glyph sbix font from the bundled Apple whale.
font:
	$(PYTHON) tools/build_font.py -o dist/AppleWhale.ttf

# Refresh assets/apple-whale.png from your own Apple Color Emoji font, then
# build:  make font-apple APPLE="/path/Apple Color Emoji.ttc"
font-apple:
	$(PYTHON) tools/build_font.py --from-apple-font "$(APPLE)" \
		--dump-png assets/apple-whale.png -o dist/AppleWhale.ttf

install:
	./install.sh

uninstall:
	./uninstall.sh

test:
	sh test/test_substitution.sh

# Boot the real postmarketOS QEMU emulator (needs KVM; run on a dev box).
emulator:
	sh test/run-emulator.sh

# Build a signed apk repo into ./public/ (same as CI). Needs Docker + a key:
#   export ABUILD_PRIVKEY="$$(openssl genrsa 4096 2>/dev/null)"; make repo
repo:
	docker run --rm -e ABUILD_PRIVKEY -e PAGES_URL \
		-v "$$PWD:/src" alpine:3.20 /src/packaging/build-apk-repo.sh

clean:
	rm -rf dist
