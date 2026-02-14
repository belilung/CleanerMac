#!/bin/bash
set -e

APP_NAME="CleanerMac"
VERSION="1.0"
BUILD_DIR="build"
DMG_DIR="$BUILD_DIR/dmg"
DMG_NAME="$APP_NAME-$VERSION.dmg"

echo "Building $APP_NAME..."
xcodebuild -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/derived" \
  CODE_SIGN_IDENTITY="-" \
  build

APP_PATH="$BUILD_DIR/derived/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: App not found at $APP_PATH"
  exit 1
fi

echo "Creating DMG..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

rm -f "$BUILD_DIR/$DMG_NAME"
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov -format UDZO \
  "$BUILD_DIR/$DMG_NAME"

rm -rf "$DMG_DIR"
echo ""
echo "DMG created: $BUILD_DIR/$DMG_NAME"
echo "Size: $(du -sh "$BUILD_DIR/$DMG_NAME" | cut -f1)"
