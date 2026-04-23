# RunimalWatchAdapterV2

Pure SwiftPM adapter for converting the existing watch-produced `WorkoutSessionArchive` into v2 domain archives.

This target deliberately does not import HealthKit, CoreLocation, WatchKit, or SwiftUI. It sits between existing `RunimalCore` archive assets and `RunimalDomainV2` so v2 can be validated before any app target wiring changes.
