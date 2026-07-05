#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/ScrollShot.app"
EXECUTABLE="$ROOT/.build/release/ScrollShot"
DMG="$DIST/ScrollShot-$VERSION.dmg"
ZIP="$DIST/ScrollShot-$VERSION.zip"
CHECKSUMS="$DIST/ScrollShot-$VERSION-checksums.txt"

cd "$ROOT"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swift build -c release

cp "$EXECUTABLE" "$APP/Contents/MacOS/ScrollShot"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${GITHUB_RUN_NUMBER:-1}" "$APP/Contents/Info.plist"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi

ditto -c -k --keepParent "$APP" "$ZIP"
hdiutil create -volname "ScrollShot" -srcfolder "$APP" -ov -format UDZO "$DMG"

(
  cd "$DIST"
  shasum -a 256 "ScrollShot-$VERSION.dmg" "ScrollShot-$VERSION.zip" > "ScrollShot-$VERSION-checksums.txt"
)

echo "Built:"
echo "  $APP"
echo "  $DMG"
echo "  $ZIP"
echo "  $CHECKSUMS"
