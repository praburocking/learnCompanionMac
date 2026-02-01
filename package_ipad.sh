#!/bin/bash

# Configuration
APP_NAME="EchoRead"
BUNDLE_ID="com.local.EchoRead"
BUILD_DIR=".build/arm64-apple-ios17.0-simulator/debug"
APP_BUNDLE="${APP_NAME}.app"

# 1. Clean previous build and bundle
echo "🧹 Cleaning up..."
rm -rf "${APP_BUNDLE}"

# 2. Build for iOS Simulator (arm64)
echo "🛠️ Building for iOS Simulator..."
# Build with flags
swift build --triple arm64-apple-ios17.0-simulator \
    --sdk $(xcrun --sdk iphonesimulator --show-sdk-path)

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Get path (needs same flags to resolve correctly)
BUILD_PATH=$(swift build --triple arm64-apple-ios17.0-simulator --show-bin-path)

# 3. Create App Bundle Structure (Flat for iOS)
echo "📦 Creating App Bundle..."
mkdir -p "${APP_BUNDLE}"

# 4. Copy Executable & Info.plist
cp "${BUILD_PATH}/${APP_NAME}" "${APP_BUNDLE}/${APP_NAME}"
cp "Info.plist" "${APP_BUNDLE}/Info.plist"

# 5. Create PkgInfo
echo "APPL????" > "${APP_BUNDLE}/PkgInfo"

# 6. Sign the Bundle (Ad-hoc)
echo "📝 Signing..."
codesign -s - --deep --force "${APP_BUNDLE}"

echo "✅ ${APP_NAME}.app created for iPad Simulator!"

# 7. Install to Booted Simulator
BOOTED_SIM=$(xcrun simctl list devices booted | grep -v "Devices" | grep "Booted" | head -n 1 | sed 's/.*(\([0-9A-F-]*\)).*/\1/')

if [ -n "$BOOTED_SIM" ]; then
    echo "📲 Found booted simulator ($BOOTED_SIM), installing..."
    xcrun simctl install "$BOOTED_SIM" "${APP_BUNDLE}"
    echo "🚀 App installed! You should see it on the Simulator home screen."
    echo "   To launch: xcrun simctl launch \"$BOOTED_SIM\" ${BUNDLE_ID}"
else
    echo "⚠️ No booted simulator found. Launch a simulator."
fi
