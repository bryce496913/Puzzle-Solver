# Compact sliding puzzle picker

## Change

`Puzzle Solver/NewPuzzleView.swift` now uses a shared `SlidingTilePicker` for 3×3, 4×4, and 5×5. Previously the picker used three columns for 3×3 and four columns for larger puzzles, with full-size action-button typography and padding.

The new LazyVGrid uses adaptive columns with a 54pt minimum width and 6pt spacing. Buttons have a 52pt minimum height, compact padding, rounded purple outlines, white text, pink Blank styling, pressed feedback, and dimmed disabled controls. Blank occupies one grid cell. Minimum column width scales with Dynamic Type to allow fewer columns at larger text sizes. Semantic Buttons, disabled behavior, and board selected-state accessibility remain intact. Stable `sliding-key-*` and `sliding-cell-row-column` identifiers and used-number labels were added.

## Width checks

These are arithmetic checks at default text size using current 16pt screen and 14pt card insets, **not simulator measurements or screenshots**. No screenshots were attached to this request or generated in this Linux environment.

| Screen width | Content width | Columns | Button width | 3×3 rows including Blank | 4×4 rows including Blank | 5×5 rows including Blank |
| --- | --- | --- | --- | --- | --- | --- |
| 320pt | 260pt | 4 | 60.5pt | 3 | 4 | 7 |
| 375pt | 315pt | 5 | 58.2pt | 2 | 4 | 5 |
| 390pt | 330pt | 5 | 61.2pt | 2 | 4 | 5 |
| 430pt | 370pt | 6 | 56.7pt | 2 | 3 | 5 |

The smallest width deliberately favors accessible touch targets over squeezing 25 controls into five rows. Normal and large widths provide five to six columns. SwiftUI derives the actual layout from available width rather than a phone model.

## Verification

- Swift frontend syntax parsing of the edited view and UI-test file: passed.
- `git diff --check`: passed.
- Source comparison confirms all existing input methods from `canPlaceBlank` through reset/example/blank lookup remain byte-for-byte unchanged.
- Three new XCUITests cover every number and Blank for each puzzle size, 44pt minimum targets, a 64pt maximum height at default text size, at least five columns for 5×5 on widths of 375pt or more, full visibility and horizontal bounds, assignment, automatic next-cell selection, used-number disabling/labels, Blank placement, and Reset availability.
- Portable existing regression suite: 130 tests passed with zero failures. The temporary Swift package uses the repository's non-SwiftUI sources and tests, excluding eight Apple UI/bundle tests; this does not validate SwiftUI layout or replace the Xcode suite. Log: `/tmp/compact-picker-portable-tests.log`.
- Debug simulator build attempted: unavailable because `xcodebuild` is not installed. UI tests and existing Xcode tests were not executed here.

Before accepting the layout, run the three `testCompactSliding*Picker` tests and existing tests on compact, standard, and large supported iPhone simulators, including larger accessibility text. Capture screenshots and inspect picker spacing, text, and scrolling. Apple SDK type-checking and runtime layout validation remain pending.

No sliding-puzzle state representation, validation, solvability rules, solver algorithms, search limits, availability, or navigation changed. Only the input view, its accessibility metadata, UI tests, and this report were edited.
