# Apple 🐳 (U+1F433) override for postmarketOS
PYTHON ?= python3

.PHONY: all font install uninstall test emulator clean

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

clean:
	rm -rf dist
