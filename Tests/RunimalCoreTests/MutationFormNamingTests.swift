import Testing
@testable import RunimalCore

struct MutationFormNamingTests {
    @Test
    func windrunnerFormGetsCompactCodename() {
        let snapshot = MutationFormSnapshot(
            speciesID: "windrunner",
            formID: "windrunner.aero-swift.river-open.tailwind-pulse",
            shortLabel: "Aero Swift · River Open · Tailwind Pulse",
            bodyBranchID: "aero-swift",
            ecologyBranchID: "river-open",
            rhythmBranchID: "tailwind-pulse",
            confidence: 0.92
        )

        #expect(snapshot.displayTitle == "Zephyr Riverside")
    }

    @Test
    func seedleTwilightFormGetsDistinctCodename() {
        let snapshot = MutationFormSnapshot(
            speciesID: "seedle",
            formID: "seedle.bud-runner.twilight-bud.grow-loop",
            shortLabel: "Bud Runner · Twilight Bud · Grow Loop",
            bodyBranchID: "bud-runner",
            ecologyBranchID: "twilight-bud",
            rhythmBranchID: "grow-loop",
            confidence: 0.86
        )

        #expect(snapshot.displayTitle == "Twilight Bloom")
    }
}
