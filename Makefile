# Apple 🐳 (U+1F433) override for postmarketOS
PYTHON ?= python3

.PHONY: all font placeholder install uninstall test emulator clean

all: font

placeholder: assets/apple-whale-placeholder.png
assets/apple-whale-placeholder.png:
	$(PYTHON) tools/make_placeholder.py

# Build the single-glyph sbix font from the placeholder.
font: placeholder
	$(PYTHON) tools/build_font.py -o dist/AppleWhale.ttf

# Build from your own Apple Color Emoji font:  make font-apple APPLE=path.ttc
font-apple:
	$(PYTHON) tools/build_font.py --from-apple-font "$(APPLE)" -o dist/AppleWhale.ttf

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
	rm -rf dist assets/apple-whale-placeholder.png
