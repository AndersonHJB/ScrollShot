#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: CODESIGN_IDENTITY='Developer ID Application: ...' $0 <version> <apple-id> <team-id> <app-specific-password>"
  exit 64
fi

VERSION="$1"
APPLE_ID="$2"
TEAM_ID="$3"
APP_PASSWORD="$4"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG="$ROOT/dist/ScrollShot-$VERSION.dmg"

if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
  echo "CODESIGN_IDENTITY is required."
  exit 64
fi

"$ROOT/Scripts/build_release.sh" "$VERSION"

xcrun notarytool submit "$DMG" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PASSWORD" \
  --wait

xcrun stapler staple "$DMG"
spctl -a -t open --context context:primary-signature -v "$DMG"
