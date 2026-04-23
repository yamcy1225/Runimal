# RunimalExportV2

Draft import/export boundary for Runimal v2.

Responsibilities:

- FIT import should create the same canonical workout archive/run-resource path as watch runs.
- FIT/JSON export should read from canonical archives, not UI state.
- HealthKit imports should follow the same unassigned-resource rule.

Current reference files:

- `RunimalPhone/PhoneFITImportManager.swift`
- `RunimalPhone/PhoneFITExportWriter.swift`
- `RunimalPhone/PhoneWorkoutExportManager.swift`
- `RunimalPhone/PhoneHealthKitManager.swift`

Not yet declared in `Package.swift`.
