#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/RunimalApple.xcodeproj"
SCHEME="${SCHEME:-RunimalPhone}"
CONFIGURATION="${CONFIGURATION:-Release}"
TEAM_ID="${TEAM_ID:-}"
BUILD_ROOT="${BUILD_ROOT:-$PROJECT_ROOT/build/release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$BUILD_ROOT/${SCHEME}.xcarchive}"
EXPORT_DIR="${EXPORT_DIR:-$BUILD_ROOT/export}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$BUILD_ROOT/ExportOptions.plist}"
ALLOW_PROVISIONING_UPDATES="${ALLOW_PROVISIONING_UPDATES:-1}"

if [[ -z "$TEAM_ID" ]]; then
  echo "TEAM_ID environment variable is required."
  echo "Example: TEAM_ID=8YJKN5NZT3 ./scripts/release/testflight_archive.sh"
  exit 1
fi

mkdir -p "$BUILD_ROOT" "$EXPORT_DIR"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "RunimalApple.xcodeproj is missing. Run 'xcodegen generate' first."
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required."
  exit 1
fi

if [[ "${ALLOW_PROVISIONING_UPDATES}" == "1" ]]; then
  PROVISIONING_FLAG=(-allowProvisioningUpdates)
else
  PROVISIONING_FLAG=()
fi

rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"

cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
  <key>method</key>
  <string>app-store</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF

echo "==> Archiving ${SCHEME} (${CONFIGURATION})"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  "${PROVISIONING_FLAG[@]}" \
  clean \
  archive

echo "==> Exporting IPA"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "Archive: $ARCHIVE_PATH"
echo "IPA: $EXPORT_DIR/${SCHEME}.ipa"
