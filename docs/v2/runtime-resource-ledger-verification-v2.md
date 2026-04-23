# Runtime Resource Ledger Verification v2

This note records the simulator/runtime gate for the phone-side v2 `RunResourceLedger` sidecar. It is intentionally app-target based: the check runs inside `RunimalPhone` so it exercises the same app persistence wrappers used by production code, not only SwiftPM pure seams.

## Scope

The runtime check covers the next five rebuild tasks after the first phone spend wiring:

1. confirm the simulator app can enter a v2 ledger verification path;
2. confirm workout receipt creates `run-resource-ledger-v2.json` with one unspent resource;
3. confirm user growth actions mark resources spent after success;
4. confirm deleting a run prunes an unspent resource but preserves an already-spent resource;
5. leave the verified functional gate ready for the next visual/design pass.

## Entry point

`RunimalPhone` now supports a debug-only environment entry point:

```sh
SIMCTL_CHILD_RUNIMAL_RUNTIME_CHECK=resource-ledger-v2 \
  xcrun simctl launch --terminate-running-process booted com.jaw.runimal.phone
```

When present, `RunimalPhoneApp` shows `PhoneRuntimeCheckRoot` instead of the normal dashboard. The check writes a JSON report to:

```text
Library/Application Support/RunimalPhoneRuntimeChecks/resource-ledger-v2-report.json
```

The check uses isolated persistence directories under `RunimalPhoneRuntimeChecks/*`, so it does not mutate the normal `RunimalPhone` app data directory.

## Verified checks

The current check performs these app-target actions:

- receipt scenario: apply the v2 phone ingest plan, save the phone ledger sidecar, reload it from disk;
- companion feed scenario: create a persisted unspent resource, call `PhoneProgressStore.feed(...)`, save, reload, assert spent;
- egg forge scenario: create a persisted unspent resource, call `forgeEgg(from:)`, save, reload, assert spent;
- egg incubation scenario: create a persisted unspent resource plus selected egg, call `incubateMainEgg(with:)`, save, reload, assert spent;
- unspent prune scenario: create a persisted unspent resource, call `removeRun(id:)`, save, reload, assert removed;
- spent preservation scenario: spend a resource first, call `removeRun(id:)`, save, reload, assert the spent audit resource remains.

## Latest simulator evidence

Device:

```text
iPhone 17 Pro / iOS 26.4 simulator
```

Build:

```sh
xcodebuild -project RunimalApple.xcodeproj \
  -scheme RunimalPhone \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/runimal-phone-v2-runtime-check-build \
  CODE_SIGNING_ALLOWED=NO build
```

Runtime launch:

```sh
xcrun simctl install booted /tmp/runimal-phone-v2-runtime-check-build/Build/Products/Debug-iphonesimulator/RunimalPhone.app
SIMCTL_CHILD_RUNIMAL_RUNTIME_CHECK=resource-ledger-v2 \
  xcrun simctl launch --terminate-running-process \
  --stdout=/tmp/runimal-runtime-check.stdout \
  --stderr=/tmp/runimal-runtime-check.stderr \
  booted com.jaw.runimal.phone
```

Report excerpt:

```json
{
  "checkID" : "resource-ledger-v2",
  "sidecarCreated" : true,
  "sidecarUnspentCountAfterReceipt" : 1,
  "companionFeedSpent" : true,
  "eggForgeSpent" : true,
  "eggIncubationSpent" : true,
  "unspentResourcePrunedAfterDelete" : true,
  "spentResourcePreservedAfterDelete" : true,
  "failures" : []
}
```

## Remaining gap

This is simulator app-target evidence, not a real Apple Watch + iPhone pairing run. The next hardware gate should verify a real watch-only workout archive arrives on iPhone, creates the same sidecar, and then follows the same manual spend/prune rules from visible UI.
