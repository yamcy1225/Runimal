#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PROJECT_ROOT/build/ui-review-derived}"
SOURCE_PACKAGES_PATH="${SOURCE_PACKAGES_PATH:-$PROJECT_ROOT/build/source-packages}"
CAPTURE_VARIANT="${CAPTURE_VARIANT:-revised}"
CAPTURE_PHONE="${CAPTURE_PHONE:-1}"
CAPTURE_WATCH="${CAPTURE_WATCH:-1}"
CAPTURE_MAC="${CAPTURE_MAC:-1}"
PHONE_DEVICE_NAME="${PHONE_DEVICE_NAME:-iPhone 17 Pro}"
WATCH_DEVICE_NAME="${WATCH_DEVICE_NAME:-Apple Watch Ultra 3 (49mm)}"
BOOT_TIMEOUT_SECONDS="${BOOT_TIMEOUT_SECONDS:-90}"
CAPTURE_SETTLE_SECONDS="${CAPTURE_SETTLE_SECONDS:-6}"
PHONE_BUNDLE_ID="com.jaw.runimal.phone"
WATCH_BUNDLE_ID="com.jaw.runimal.phone.watch"
MAC_BUNDLE_NAME="RunimalMac.app"
OUTPUT_ROOT="$PROJECT_ROOT/qa/ui-review/captures"
PHONE_OUTPUT_DIR="$OUTPUT_ROOT/iphone/$CAPTURE_VARIANT"
WATCH_OUTPUT_DIR="$OUTPUT_ROOT/watch/$CAPTURE_VARIANT"
MAC_OUTPUT_DIR="$OUTPUT_ROOT/mac/$CAPTURE_VARIANT"

PHONE_SCENARIOS=(home-dashboard workout-record egg-creation hatch first-stage-up rare-mutation showcase-share inventory)
WATCH_SCENARIOS=(dashboard running-companion running-metrics running-pulse)
MAC_SCENARIOS=(dashboard)

mkdir -p "$PHONE_OUTPUT_DIR" "$WATCH_OUTPUT_DIR" "$MAC_OUTPUT_DIR" "$DERIVED_DATA_PATH" "$SOURCE_PACKAGES_PATH"

resolve_device_id() {
  local device_name="$1"
  xcrun simctl list devices available --json | jq -r --arg target "$device_name" '
    .devices
    | to_entries[]
    | .value[]
    | select(.isAvailable == true and .name == $target)
    | .udid
  ' | head -n 1
}

first_available_device_id() {
  local pattern="$1"
  xcrun simctl list devices available --json | jq -r --arg pattern "$pattern" '
    .devices
    | to_entries[]
    | .value[]
    | select(.isAvailable == true and (.name | test($pattern)))
    | .udid
  ' | head -n 1
}

boot_device_if_needed() {
  local device_id="$1"
  xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
  local started_at
  started_at="$(date +%s)"

  while true; do
    local state
    state="$(xcrun simctl list devices available --json | jq -r --arg udid "$device_id" '
      .devices
      | to_entries[]
      | .value[]
      | select(.udid == $udid)
      | .state
    ' | head -n 1)"

    if [[ "$state" == "Booted" ]]; then
      return 0
    fi

    if (( $(date +%s) - started_at >= BOOT_TIMEOUT_SECONDS )); then
      return 1
    fi

    sleep 2
  done
}

install_app() {
  local device_id="$1"
  local app_path="$2"
  xcrun simctl install "$device_id" "$app_path"
}

grant_location_if_possible() {
  local device_id="$1"
  local bundle_id="$2"
  xcrun simctl privacy "$device_id" grant location "$bundle_id" >/dev/null 2>&1 || true
}

phone_device_id=""
watch_device_id=""

if [[ "$CAPTURE_PHONE" == "1" ]]; then
  phone_device_id="$(resolve_device_id "$PHONE_DEVICE_NAME")"
  if [[ -z "$phone_device_id" ]]; then
    phone_device_id="$(first_available_device_id "iPhone")"
  fi
fi

if [[ "$CAPTURE_WATCH" == "1" ]]; then
  watch_device_id="$(resolve_device_id "$WATCH_DEVICE_NAME")"
  if [[ -z "$watch_device_id" ]]; then
    watch_device_id="$(first_available_device_id "Apple Watch Ultra|Apple Watch Series 11|Apple Watch")"
  fi
fi

if [[ "$CAPTURE_PHONE" == "1" && -z "$phone_device_id" ]]; then
  echo "Unable to resolve any iPhone simulator. Override PHONE_DEVICE_NAME if needed." >&2
  exit 1
fi

if [[ "$CAPTURE_WATCH" == "1" && -z "$watch_device_id" ]]; then
  echo "Unable to resolve any Apple Watch simulator. Continuing without watch capture." >&2
  CAPTURE_WATCH=0
fi

if [[ "$CAPTURE_PHONE" == "1" ]]; then
  if ! boot_device_if_needed "$phone_device_id"; then
    echo "Unable to boot iPhone simulator within $BOOT_TIMEOUT_SECONDS seconds." >&2
    exit 1
  fi
fi

if [[ "$CAPTURE_WATCH" == "1" ]]; then
  if ! boot_device_if_needed "$watch_device_id"; then
    echo "Apple Watch simulator did not finish booting within $BOOT_TIMEOUT_SECONDS seconds. Continuing without watch capture." >&2
    CAPTURE_WATCH=0
  fi
fi

if [[ "$CAPTURE_PHONE" == "1" ]]; then
  xcodebuild \
    -project "$PROJECT_ROOT/RunimalApple.xcodeproj" \
    -scheme RunimalPhone \
    -destination "platform=iOS Simulator,id=$phone_device_id" \
    -derivedDataPath "$DERIVED_DATA_PATH/phone" \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH" \
    build
fi

if [[ "$CAPTURE_WATCH" == "1" ]]; then
  xcodebuild \
    -project "$PROJECT_ROOT/RunimalApple.xcodeproj" \
    -scheme RunimalWatch \
    -destination "platform=watchOS Simulator,id=$watch_device_id" \
    -derivedDataPath "$DERIVED_DATA_PATH/watch" \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH" \
    build
fi

if [[ "$CAPTURE_MAC" == "1" ]]; then
  xcodebuild \
    -project "$PROJECT_ROOT/RunimalApple.xcodeproj" \
    -scheme RunimalMac \
    -derivedDataPath "$DERIVED_DATA_PATH/mac" \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH" \
    build
fi

phone_app=""
watch_app=""
mac_app=""

if [[ "$CAPTURE_PHONE" == "1" ]]; then
  phone_app="$(find "$DERIVED_DATA_PATH/phone" -path '*RunimalPhone.app' | head -n 1)"
  if [[ -z "$phone_app" ]]; then
    echo "Built iPhone app product could not be located in $DERIVED_DATA_PATH." >&2
    exit 1
  fi
fi

if [[ "$CAPTURE_WATCH" == "1" ]]; then
  watch_app="$(find "$DERIVED_DATA_PATH/watch" -path '*RunimalWatch.app' | head -n 1)"
  if [[ -z "$watch_app" ]]; then
    echo "Built watch app product could not be located in $DERIVED_DATA_PATH. Continuing without watch capture." >&2
    CAPTURE_WATCH=0
  fi
fi

if [[ "$CAPTURE_MAC" == "1" ]]; then
  mac_app="$(find "$DERIVED_DATA_PATH/mac" -path "*$MAC_BUNDLE_NAME" | head -n 1)"
  if [[ -z "$mac_app" ]]; then
    echo "Built mac app product could not be located in $DERIVED_DATA_PATH. Continuing without mac capture." >&2
    CAPTURE_MAC=0
  fi
fi

if [[ "$CAPTURE_PHONE" == "1" ]]; then
  install_app "$phone_device_id" "$phone_app"
  grant_location_if_possible "$phone_device_id" "$PHONE_BUNDLE_ID"
fi

if [[ "$CAPTURE_WATCH" == "1" ]]; then
  install_app "$watch_device_id" "$watch_app"
  grant_location_if_possible "$watch_device_id" "$WATCH_BUNDLE_ID"
fi

if [[ "$CAPTURE_PHONE" == "1" ]]; then
  for scenario in "${PHONE_SCENARIOS[@]}"; do
    echo "==> Capturing iPhone $scenario"
    SIMCTL_CHILD_RUNIMAL_UI_CAPTURE_SCENARIO="$scenario" \
      xcrun simctl launch --terminate-running-process "$phone_device_id" "$PHONE_BUNDLE_ID" >/dev/null
    sleep "$CAPTURE_SETTLE_SECONDS"
    xcrun simctl io "$phone_device_id" screenshot "$PHONE_OUTPUT_DIR/$scenario.png" >/dev/null
    xcrun simctl terminate "$phone_device_id" "$PHONE_BUNDLE_ID" >/dev/null 2>&1 || true
    sleep 1
  done

  echo "Phone captures: $PHONE_OUTPUT_DIR"
fi

if [[ "$CAPTURE_WATCH" == "1" ]]; then
  for scenario in "${WATCH_SCENARIOS[@]}"; do
    echo "==> Capturing Watch $scenario"
    output_path="$WATCH_OUTPUT_DIR/$scenario.png"
    rm -f "$output_path"
    SIMCTL_CHILD_RUNIMAL_WATCH_UI_CAPTURE_SCENARIO="$scenario" \
    SIMCTL_CHILD_RUNIMAL_WATCH_UI_CAPTURE_OUTPUT_PATH="$output_path" \
    SIMCTL_CHILD_RUNIMAL_WATCH_CAPTURE_DEVICE_NAME="$WATCH_DEVICE_NAME" \
      xcrun simctl launch --terminate-running-process "$watch_device_id" "$WATCH_BUNDLE_ID" >/dev/null
    started_at="$(date +%s)"
    while [[ ! -f "$output_path" ]]; do
      if (( $(date +%s) - started_at >= BOOT_TIMEOUT_SECONDS )); then
        echo "Timed out waiting for watch capture for scenario $scenario." >&2
        exit 1
      fi
      sleep 1
    done
    xcrun simctl terminate "$watch_device_id" "$WATCH_BUNDLE_ID" >/dev/null 2>&1 || true
    sleep 1
  done

  echo "Watch captures: $WATCH_OUTPUT_DIR"
fi

if [[ "$CAPTURE_MAC" == "1" ]]; then
  mac_executable="$mac_app/Contents/MacOS/RunimalMac"

  for scenario in "${MAC_SCENARIOS[@]}"; do
    echo "==> Capturing macOS $scenario"
    output_path="$MAC_OUTPUT_DIR/$scenario.png"
    rm -f "$output_path"
    RUNIMAL_MAC_UI_CAPTURE_SCENARIO="$scenario" \
      RUNIMAL_MAC_UI_CAPTURE_PATH="$output_path" \
      "$mac_executable" >/dev/null 2>&1 &
    capture_pid=$!

    started_at="$(date +%s)"
    while [[ ! -f "$output_path" ]]; do
      if (( $(date +%s) - started_at >= BOOT_TIMEOUT_SECONDS )); then
        echo "Timed out waiting for macOS capture for scenario $scenario." >&2
        kill "$capture_pid" >/dev/null 2>&1 || true
        exit 1
      fi
      sleep 1
    done
    wait "$capture_pid" >/dev/null 2>&1 || true
  done

  echo "Mac captures: $MAC_OUTPUT_DIR"
fi
