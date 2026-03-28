#!/bin/bash
# Build SlapMac locally with Xcode

set -e

echo "🚀 Building SlapMac..."
cd "$(dirname "$0")"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

# Generate sound files
echo "🎙️ Generating sounds..."
chmod +x generate_sounds.sh
./generate_sounds.sh || echo "⚠️ Some sounds failed, continuing..."

# Build with Xcode
echo "🔨 Building with Xcode..."
xcodebuild -project SlapMac.xcodeproj \
    -scheme SlapMac \
    -configuration Release \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty || xcodebuild -project SlapMac.xcodeproj -scheme SlapMac -configuration Release -destination 'platform=macOS' CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

# Find the built app
APP_PATH=$(find build -name "SlapMac.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed - app not found"
    exit 1
fi

echo "✅ Build successful: $APP_PATH"

# Create DMG
echo "📦 Creating DMG..."
mkdir -p installer
cp -r "$APP_PATH" installer/
ln -s /Applications installer/Applications
hdiutil create -volname "SlapMac" -srcfolder installer -ov -format UDZO SlapMac.dmg
echo "✅ DMG created: SlapMac.dmg"

# Clean up
rm -rf installer

echo ""
echo "🎉 Done! Install with:"
echo "   sudo cp -r $APP_PATH /Applications/"
echo "   sudo /Applications/SlapMac.app/Contents/MacOS/SlapMac"
