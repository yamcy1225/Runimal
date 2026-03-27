import RunimalCore
import SwiftUI

struct PhoneCloudVerificationPanel: View {
    let records: [DeviceVerificationRecord]
    let onRecord: (String, Bool) -> Void

    var body: some View {
        GameSurface(title: "Signed Verification Log") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(records.prefix(3)) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.title)
                                .foregroundStyle(.white)
                            Text(record.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.66))
                        }
                        Spacer()
                        TraitChip(label: record.passed ? "PASS" : "FAIL", accent: record.passed ? .green.opacity(0.72) : .red.opacity(0.72))
                    }
                }

                HStack {
                    Button("Log Pass") {
                        onRecord("Signed iCloud roundtrip", true)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green.opacity(0.82))

                    Button("Log Fail") {
                        onRecord("Signed iCloud roundtrip", false)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
