APP      := awaker.app
BIN      := .build/release/awaker
CONTENTS := $(APP)/Contents
# Per-user; Spotlight and Login Items treat it like /Applications, and it needs no admin rights.
PREFIX   ?= $(HOME)/Applications

.PHONY: all build bundle run install uninstall clean icon

all: bundle

build:
	swift build -c release

# Command Line Tools have no app template, so the bundle is assembled by hand.
bundle: build
	rm -rf $(APP)
	mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	cp $(BIN) $(CONTENTS)/MacOS/awaker
	cp Support/Info.plist $(CONTENTS)/Info.plist
	cp Support/awaker.icns $(CONTENTS)/Resources/awaker.icns
	printf 'APPL????' > $(CONTENTS)/PkgInfo
	codesign --force --sign - $(APP)

run: bundle
	open $(APP)

install: bundle
	rm -rf $(PREFIX)/$(APP)
	cp -R $(APP) $(PREFIX)/

uninstall:
	rm -rf $(PREFIX)/$(APP)

clean:
	rm -rf .build $(APP)

# Regenerates Support/awaker.icns from the drawing code; only needed after editing make-icon.swift.
icon:
	rm -rf .build/awaker.iconset
	swift Support/make-icon.swift icns cup .build/awaker.iconset
	iconutil -c icns .build/awaker.iconset -o Support/awaker.icns
