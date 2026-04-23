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
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PROJECT_ROOT/build/derived-data/${SCHEME}}"
SOURCE_PACKAGES_PATH="${SOURCE_PACKAGES_PATH:-$PROJECT_ROOT/build/source-packages}"
EXPORT_IPA="${EXPORT_IPA:-1}"

if [[ -z "$TEAM_ID" ]]; then
  echo "TEAM_ID environment variable is required."
  echo "Example: TEAM_ID=8YJKN5NZT3 ./scripts/release/testflight_archive.sh"
  exit 1
fi

mkdir -p "$BUILD_ROOT" "$EXPORT_DIR" "$DERIVED_DATA_PATH" "$SOURCE_PACKAGES_PATH"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "RunimalApple.xcodeproj is missing. Run 'xcodegen generate' first."
  exit 1
fi

cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
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
PLIST

echo "==> Archiving ${SCHEME}"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH" \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo "Archive: $ARCHIVE_PATH"

if [[ "$EXPORT_IPA" != "1" ]]; then
  echo "EXPORT_IPA=$EXPORT_IPA, skipping IPA export."
  exit 0
fi

echo "==> Exporting IPA"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "IPA: $EXPORT_DIR/${SCHEME}.ipa"
