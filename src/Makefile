# SlapMac Makefile
# Build without Xcode project files

APP_NAME = SlapMac
BUNDLE_ID = com.artyomx.slapmac
BUILD_DIR = build
APP_DIR = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

SWIFT_FILES = SlapMac/SlapMacApp.swift SlapMac/ContentView.swift SlapMac/MotionDetector.swift SlapMac/AudioEngine.swift SlapMac/SlapCounter.swift SlapMac/AppSettings.swift

.PHONY: all clean build package

all: build package

build: $(MACOS_DIR)/$(APP_NAME)

$(MACOS_DIR)/$(APP_NAME): $(SWIFT_FILES)
	@echo "🔨 Building $(APP_NAME)..."
	@mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	
	# Compile Swift files
	swiftc \
		-o $(MACOS_DIR)/$(APP_NAME) \
		-framework SwiftUI \
		-framework IOKit \
		-framework AVFoundation \
		-framework Foundation \
		-lobjc \
		$(SWIFT_FILES)
	
	# Copy resources
	@cp -r ../sounds $(RESOURCES_DIR)/ 2>/dev/null || true
	
	# Create Info.plist
	@cat > $(CONTENTS_DIR)/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SlapMac</string>
    <key>CFBundleIdentifier</key>
    <string>$(BUNDLE_ID)</string>
    <key>CFBundleName</key>
    <string>SlapMac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF
	
	@echo "✅ Build complete: $(APP_DIR)"

package: $(BUILD_DIR)/SlapMac.dmg

$(BUILD_DIR)/SlapMac.dmg: build
	@echo "📦 Creating DMG..."
	@mkdir -p $(BUILD_DIR)/installer
	@cp -r $(APP_DIR) $(BUILD_DIR)/installer/
	@ln -s /Applications $(BUILD_DIR)/installer/Applications
	hdiutil create -volname "SlapMac" -srcfolder $(BUILD_DIR)/installer -ov -format UDZO $@
	@echo "✅ DMG created: $@"

clean:
	@rm -rf $(BUILD_DIR)
	@echo "🧹 Cleaned build directory"
