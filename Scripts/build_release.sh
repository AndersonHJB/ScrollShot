#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/ScrollShot.app"
EXECUTABLE="$ROOT/.build/release/ScrollShot"
DMG="$DIST/ScrollShot-$VERSION.dmg"
DMG_STAGING=""
ZIP="$DIST/ScrollShot-$VERSION.zip"
CHECKSUMS="$DIST/ScrollShot-$VERSION-checksums.txt"

cleanup() {
  if [[ -n "$DMG_STAGING" ]]; then
    rm -rf "$DMG_STAGING"
  fi
}
trap cleanup EXIT

cd "$ROOT"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
DMG_STAGING="$(mktemp -d "${TMPDIR:-/tmp}/scrollshot-dmg.XXXXXX")"

swift build -c release

cp "$EXECUTABLE" "$APP/Contents/MacOS/ScrollShot"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/ScrollShotAppIcon.icns" "$APP/Contents/Resources/ScrollShotAppIcon.icns"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${GITHUB_RUN_NUMBER:-1}" "$APP/Contents/Info.plist"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi

ditto -c -k --keepParent "$APP" "$ZIP"
ditto "$APP" "$DMG_STAGING/ScrollShot.app"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "ScrollShot" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG"

(
  cd "$DIST"
  shasum -a 256 "ScrollShot-$VERSION.dmg" "ScrollShot-$VERSION.zip" > "ScrollShot-$VERSION-checksums.txt"
)

echo "Built:"
echo "  $APP"
echo "  $DMG"
echo "  $ZIP"
echo "  $CHECKSUMS"
