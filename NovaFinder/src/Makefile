APP_NAME  = NovaFinder
BUILD_DIR = ../build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
BINARY    = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

SWIFT_FILES = \
	main.swift \
	AppDelegate.swift \
	HotkeyManager.swift \
	StorageManager.swift \
	CommandHandler.swift \
	SearchWindowController.swift

SWIFTC_FLAGS = \
	-framework Carbon \
	-framework AppKit \
	-framework CoreGraphics \
	-target arm64-apple-macos13.0 \
	-O

.PHONY: all clean run

all: $(BINARY)

$(BINARY): $(SWIFT_FILES) Info.plist
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	swiftc $(SWIFTC_FLAGS) -o $(BINARY) $(SWIFT_FILES)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@echo "Build succeeded: $(APP_BUNDLE)"

run: all
	@echo "Starting $(APP_NAME)..."
	open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)

# コード署名 (必要な場合)
sign: all
	codesign --force --deep --sign - $(APP_BUNDLE)
