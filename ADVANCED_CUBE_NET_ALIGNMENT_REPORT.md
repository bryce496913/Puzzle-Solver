# Advanced cube net alignment

## Root cause and change

`Puzzle Solver/MainMenuView.swift`, shared by 2×2 and 3×3 entry, previously stacked each face's variable-height label above its grid. The side-face HStack centered those stacks, so wrapped Back guidance shifted the sticker grid. Fixed sticker widths required horizontal scrolling; Up and Down used size-dependent leading padding rather than Front's column.

The net now uses four equal flexible columns with 6pt spacing in Left / Front / Right / Back order. A separate, bottom-aligned header row reserves its tallest label's height for every side face. The grids occupy a shared top-aligned row beneath it. Back retains “Viewed from behind” in secondary caption typography. Labels can wrap with Dynamic Type without shifting individual grids. Up and Down occupy the second column, exactly matching Front, using invisible layout slots for the other columns. Horizontal scrolling and arbitrary face-position padding are removed.

Both 2×2 and 3×3 use available column width with square sticker cells and unchanged 4pt internal spacing. Guided-entry stickers retain their 58pt dimensions. Physical orientation guidance remains unchanged.

## Width checks

Arithmetic checks using the existing default 16pt screen padding and 14pt card inset; these are **not simulator measurements or screenshots**.

| Screen width | Face width | 2×2 square cell | 3×3 square cell |
| --- | --- | --- | --- |
| 320pt | 60.5pt | 28.25pt | 17.5pt |
| 375pt | 74.25pt | 35.125pt | 22.083pt |
| 390pt | 78pt | 37pt | 23.333pt |
| 430pt | 88pt | 42pt | 26.667pt |

Four face widths plus three 6pt gaps fit the content width exactly. The implementation uses SwiftUI flexible layout, with no phone-specific width constants. All six faces preserve their cell counts and model positions. No reference screenshot was attached in this workspace, and no simulator screenshot could be generated on Linux.

## Validation

- Swift frontend syntax parsing of the view and UI tests passed; `git diff --check` passed.
- Portable existing regression suite: 130 tests passed with zero failures. The temporary Swift package uses non-SwiftUI sources and excludes eight Apple UI/bundle tests; it does not validate SwiftUI layout or replace the Xcode suite. Log: `/tmp/cube-net-portable-tests.log`.
- Added `testAdvancedCube2x2NetAlignment` and `testAdvancedCube3x3NetAlignment`: open Advanced Net Input, verify all six labels and every physical cell identifier, square geometry, content bounds, equal side-grid top edges and spacing, Up/Down centering on Front, locked centers, and selection of the expected sticker on all six faces.
- Sticker selection now exposes “Selected” / “Not selected” accessibility values. Existing sticker identifiers and labels remain unchanged.
- Source comparison confirms the sticker index formula, tap action, locked-center behavior, storage order, guided entry, validation, and all solve methods remain unchanged. No cube model, mapping, solver, or availability files were edited.
- Debug simulator build was attempted but `xcodebuild` is unavailable. Apple SDK type checking, Xcode tests, and runtime layout/screenshots remain pending.

Before accepting visual results, run both new tests and existing tests on compact, standard, and large iPhone simulators for both sizes. Check larger accessibility text and capture screenshots to confirm the net's labels, spacing, and card bounds.
