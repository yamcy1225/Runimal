#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_ROOT="${BUILD_ROOT:-$PROJECT_ROOT/build/release}"
EXPORT_DIR="${EXPORT_DIR:-$BUILD_ROOT/export}"
IPA_PATH="${IPA_PATH:-$EXPORT_DIR/RunimalPhone.ipa}"
KEY_FILE="$BUILD_ROOT/AuthKey_${ASC_KEY_ID:-missing}.p8"

if [[ -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" || -z "${ASC_PRIVATE_KEY_BASE64:-}" ]]; then
  echo "ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY_BASE64 are required."
  exit 1
fi

if [[ ! -f "$IPA_PATH" ]]; then
  echo "IPA not found at $IPA_PATH"
  exit 1
fi

mkdir -p "$BUILD_ROOT"
echo "$ASC_PRIVATE_KEY_BASE64" | base64 --decode > "$KEY_FILE"
chmod 600 "$KEY_FILE"
trap 'rm -f "$KEY_FILE"' EXIT

echo "==> Uploading $IPA_PATH to TestFlight"
xcrun altool \
  --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"
