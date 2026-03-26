# Runimal Apple

Runimal game-core and Apple platform test apps.

## What works now

- `swift run RunimalCLI`
- `swift run RunimalSelfCheck`
- `xcodegen generate`
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalMac -destination 'platform=macOS' build`
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' build`
- Apple Watch simulator install + launch verified
- iPhone `HealthKit` authorization manager added
- iPhone `WatchConnectivity` sync manager added
- iPhone `WorkoutKit` wrapper added
- Apple Watch live run session manager added
- Apple Watch -> iPhone snapshot sync pipeline added

## Targets

- `RunimalMac`: macOS SwiftUI test app
- `RunimalPhone`: iPhone SwiftUI test app
- `RunimalWatch`: standalone watchOS SwiftUI test app
- `RunimalCore`: shared game logic package

## Integration layers

- `RunimalPhone/PhoneHealthKitManager.swift`
- `RunimalPhone/PhoneConnectivityManager.swift`
- `RunimalPhone/PhoneWorkoutPlanner.swift`
- `RunimalWatch/WatchRunSessionManager.swift`
- `RunimalWatch/WatchConnectivityManager.swift`
- `RunimalCore` live snapshot + workout suggestion models

## Local commands

```bash
cd /Users/heobella/jaw-bot-2/apps/runimal-apple
swift run RunimalCLI
swift run RunimalSelfCheck
xcodegen generate
```

### Build on MacBook

```bash
xcodebuild -project RunimalApple.xcodeproj -scheme RunimalMac -destination 'platform=macOS' build
open ~/Library/Developer/Xcode/DerivedData/RunimalApple-*/Build/Products/Debug/RunimalMac.app
```

### Build on Apple Watch simulator

```bash
xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' build
xcrun simctl boot 'Apple Watch Series 11 (46mm)'
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/RunimalApple-*/Build/Products/Debug-watchsimulator/RunimalWatch.app
xcrun simctl launch booted com.jaw.runimal.watch
```

## Current note

- watchOS simulator launch is verified
- iPhone simulator build is verified
- iPhone simulator install/launch is still flaky on this machine because some booted iOS simulator instances are stalling on system app readiness
- `WorkoutKit` is currently wrapped as a compile-safe planning layer; the next step is to map those suggestions into actual scheduled workout objects
