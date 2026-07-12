#!/usr/bin/env bash
# Builds TLNHours in Release configuration and packages it into a distributable DMG.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="TLNHours"
SCHEME="TLNHours"
CONFIGURATION="Release"
BUILD_DIR="$(pwd)/build"
DIST_DIR="$(pwd)/dist"
VERSION="${1:-$(grep -m1 'CFBundleShortVersionString' project.yml | sed -E 's/.*: *"?([0-9.]+)"?.*/\1/')}"

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building ${APP_NAME} ${VERSION} (${CONFIGURATION})"
rm -rf "$BUILD_DIR"
xcodebuild \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  build

APP_PATH="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "error: built app not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Packaging DMG"
mkdir -p "$DIST_DIR"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
rm -f "$DMG_PATH"

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

cp -R "$APP_PATH" "$STAGING_DIR/"
cp GETTING_STARTED.md "$STAGING_DIR/README.md"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "==> Done: $DMG_PATH"
