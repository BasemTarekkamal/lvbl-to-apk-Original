#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/BasemTarekkamal/clinc-os"
APP_NAME="My App"
SOURCE_DIR="source_code"

# Parse App Name from URL if "My App"
if [ "$APP_NAME" == "My App" ]; then
    APP_NAME=$(basename "$REPO_URL" .git)
    echo "🔎 Parsed App Name from URL: $APP_NAME"
fi

# 1. Check for google-services.json
if [ ! -f "google-services.json" ]; then
    echo "❌ Error: google-services.json not found in current directory."
    echo "Please copy your google-services.json here to enable notification support."
    exit 1
fi

# 2. Cleanup and Clone
echo "🧹 Cleaning up old source..."
rm -rf "$SOURCE_DIR"

echo "📥 Cloning repository..."
git clone "$REPO_URL" "$SOURCE_DIR"

# 3. Install and Build Web
cd "$SOURCE_DIR"
echo "📦 Installing dependencies..."
npm install

echo "🏗️ Building web assets..."
npm run build

# 4. Capacitor Setup
echo "⚡ Setting up Capacitor..."
rm -f capacitor.config.ts capacitor.config.json
npm install @capacitor/core @capacitor/cli @capacitor/android

PACKAGE_ID=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
npx cap init "$APP_NAME" "com.lovable.$PACKAGE_ID" --web-dir=dist

if [ ! -d "dist" ]; then
    echo "❌ Error: 'dist' folder missing. Build failed."
    exit 1
fi

echo "🤖 Adding Android platform..."
export CI=true
if [ -d "android" ]; then
    echo "⚠️ Android folder found in repo. Syncing only..."
else
    npx cap add android
fi
npx cap sync android

# 5. Inject google-services.json
echo "💉 Injecting google-services.json..."
cp ../google-services.json android/app/google-services.json

# 6. Build APK
echo "🔨 Building APK..."
cd android
chmod +x gradlew
./gradlew assembleDebug

echo "✅ Build Complete!"
echo "APK Location: $SOURCE_DIR/android/app/build/outputs/apk/debug/app-debug.apk"
