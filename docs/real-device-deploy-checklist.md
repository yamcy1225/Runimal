# Runimal Real-Device Deploy Checklist

## Signing

1. Open `RunimalApple.xcodeproj` in Xcode.
2. Select `RunimalPhone` and `RunimalWatch`.
3. Set the same Apple development team for both targets.
4. Keep signing style as `Automatic`.
5. Confirm bundle identifiers are unique and valid:
   - `com.jaw.runimal.phone`
   - `com.jaw.runimal.phone.watch`

## Device Pairing

1. Connect the iPhone to the Mac with USB or trusted wireless pairing.
2. Confirm the iPhone is trusted by the Mac.
3. Confirm Apple Watch Ultra is paired to that iPhone.
4. In Xcode, verify the paired iPhone and watch appear as run destinations.

## Capabilities

1. Verify HealthKit permission prompts appear on both devices.
2. Verify iCloud entitlement resolves under the selected team.
3. Verify the app launches with no entitlement or signing warning.

## Runimal Flow

1. Launch `RunimalPhone` on iPhone.
2. Launch `RunimalWatch` on Apple Watch Ultra.
3. Start a run on the watch.
4. Confirm live coaching, goal track, and haptic changes appear.
5. End the run on the watch.
6. Confirm the result syncs to the phone.
7. Feed the active companion on the phone.
8. Confirm XP gain, feed cinematic, and evolution pulse all appear.
9. Confirm the watch companion card updates quickly after main companion changes on the phone.
10. Confirm the watch title/name and actual sprite appearance match the latest evolution form.

## iCloud Validation

1. Mirror a vault snapshot from the phone.
2. Reopen the phone app and verify restore still works.
3. If conflict UI appears, test:
   - duplicate priority merge
   - selective merge
   - record diff import

## QA Pass

1. Export the QA runbook from the Mac tools panel.
2. Mark PASS/FAIL for:
   - install
   - HealthKit permissions
   - live watch coaching
   - run save
   - phone sync
   - watch companion sync speed
   - phone/watch sprite consistency
   - feed cinematic
   - iCloud mirror
