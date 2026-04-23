# Runimal v2 Expert Design Briefs

These briefs start the v2 design-quality track without turning generated art into production dependencies. Use `$imagegen` only for original candidate imagery, then translate accepted decisions into SwiftUI, vector, or asset-catalog work after review.

## Design Principles

1. Recording trust comes first: in-run screens must read instantly on Apple Watch.
2. GPS path drawing is the visual spine of completed workouts; map tiles are optional context, not the core.
3. Companion emotion supports the run; it must not imply the completed workout was automatically consumed.
4. Growth visuals should clarify manual resource allocation after the run.
5. Generated candidates must be screened for readability, accessibility, copyright safety, and implementation cost.

## `$imagegen` Candidate Briefs

### 1. Watch In-Run Screen Direction

Prompt seed:

> Original Apple Watch running app UI art direction for Runimal v2, black OLED background, huge readable distance and pace numerals, small heart rate and cadence chips, subtle companion presence as a tiny animated mascot silhouette, no clutter, high contrast, fitness-first, premium game UI, Korean app sensibility, not a map-tile screen.

Acceptance criteria:

- Distance/current pace dominate at a glance.
- Companion element is supportive and non-distracting.
- Works conceptually on a small watch display.

### 2. Post-Run Result Card

Prompt seed:

> Original mobile post-run result card for Runimal v2, GPS route path drawing as central visual line art, distance time average pace heart rate cadence elevation, subtle growth resource capsule, companion reaction separated from workout archive, clean premium sports game aesthetic, dark mode, high readability.

Acceptance criteria:

- Path drawing is visually central.
- Workout archive and growth resource are clearly separate concepts.
- Metrics remain more important than decoration.

### 3. Companion Silhouette System

Prompt seed:

> Original cute running companion creature silhouette exploration for Runimal v2, small readable mascot forms for Apple Watch, distinct species silhouettes, friendly but athletic, simple shapes, no existing character imitation, suitable for vector translation and animation.

Acceptance criteria:

- Silhouettes remain legible at watch size.
- Species differ by shape, not only color.
- Can be translated into vector/SF Symbols-like simplified assets.

### 4. Growth Resource Allocation Screen

Prompt seed:

> Original game UI concept for assigning a completed run resource after workout, unspent run crystal/card separate from companion, user chooses where to spend it, clear hierarchy, premium fitness RPG, route and metrics evidence visible, no lootbox feel.

Acceptance criteria:

- Manual-spend model is obvious.
- The completed run remains auditable.
- The interface avoids gambling/lootbox cues.

## OpenGame Prototype Briefs

Use OpenGame only outside the app to test interaction feel:

1. Post-run resource card: tap-to-preview companion benefit without spending.
2. Companion live reaction loop: low-frequency encouragement that never hides metrics.
3. Growth allocation comprehension: compare “auto feed” vs “manual spend” explanation.
4. Result card pacing: route-first vs companion-first hierarchy test.

## Review Checklist

For every candidate/prototype, record:

- Tool and version
- Prompt or prototype brief
- Screenshot/output path
- Decision: accept / reject / defer
- Reasoning
- SwiftUI translation task, if accepted
- Accessibility/readability notes
