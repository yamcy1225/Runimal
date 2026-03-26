import Foundation
import Observation
import RunimalCore

#if canImport(WorkoutKit)
import WorkoutKit
#endif

@MainActor
@Observable
final class PhoneWorkoutPlanner {
    var plannerStatus = "not prepared"

    func syncSuggestedWorkout(for pet: GeneratedPet) async -> WorkoutPlanSuggestion {
        let suggestion = RunimalGameEngine.suggestWorkoutPlan(for: pet)

        #if canImport(WorkoutKit)
        plannerStatus = "WorkoutKit ready: \(suggestion.title)"
        #else
        plannerStatus = "WorkoutKit unavailable on current SDK"
        #endif

        return suggestion
    }
}
