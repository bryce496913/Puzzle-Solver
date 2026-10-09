# Sudoku Photo Scan — Physical-device validation matrix

> Historical snapshot. The current V1 contract has eight active modes; Sudoku Photo Scan is Coming Soon, and its implementation and permissions have been removed. Scanner execution rows below are post-V1 work. See [FINAL_V1_CLEANUP_REPORT.md](FINAL_V1_CLEANUP_REPORT.md) for current findings and required checks.

Photo Scan is an **Active** V1 mode. Automated coverage imports repository-owned Sudoku fixtures through the on-device pipeline and exercises the review/result UI through a deterministic test hook; it does not claim to automate live camera reliability in Simulator. The physical-device cases below remain the required Camera/Photos release checklist.

## Setup and recording

Run on the oldest and newest supported iPhone OS versions and on one iPad. Reset privacy decisions between permission cases. Record device, OS, source, lighting, expected/actual outcome, scan state, and a screenshot of the review or recovery message. Images and recognition stay on device.

| Source | Scenario | Expected result | Executed |
|---|---|---|---|
| Camera | Permission denied | Explain denial; Photo and manual entry remain available; no picker opens | ☐ physical device required |
| Camera | Glare across digits | Review cells are explicit or a recoverable quality failure is shown; never silently commit | ☐ physical device required |
| Camera | Strong page shadow | Correct board or mark uncertain cells for review | ☐ physical device required |
| Camera | Mild motion blur | Correct board, review markers, or clear retake guidance | ☐ physical device required |
| Camera | Tilted photograph | Detect and perspective-correct with all four corners visible | ☐ physical device required |
| Camera | Paper puzzle | Produce 81 mapped cells and preserve blanks | ☐ physical device required |
| Camera | Imperfect framing | Missing corner produces full-board/crop guidance | ☐ physical device required |
| Photos | Permission denied | Explain denial; manual entry remains available; no picker opens | ☐ physical device required |
| Photos | Limited access | Picker works for selected assets only; no request to broaden access | ☐ physical device required |
| Photos | Screenshot | Produce the expected 81-cell review board | ☐ physical device required |
| Photos | Glare/shadow/blur photographs | Same review/failure semantics as Camera | ☐ physical device required |
| Photos | Tilted paper puzzle | Perspective-correct and map all 81 cells | ☐ physical device required |

## Permission audit

`NSCameraUsageDescription` says the camera is used to photograph a Sudoku for on-device recognition. `NSPhotoLibraryUsageDescription` says Photos is used to choose a Sudoku image for on-device recognition. The implementation requests read/write Photos authorization because `UIImagePickerController` currently uses that authorization path; it does not request add-only access, contacts, location, microphone, or network access. Limited Photos authorization is accepted.

## Automated boundary

The unit suite owns synthetic, legally repository-owned SVG sources that UIKit decodes into raster pixels before the pipeline receives them. Keeping sources textual satisfies the repository rule against new binary files while ensuring the input to scanning is a raster `CGImage`. Separate JSON files contain hand-authored expected boards and states; OCR never creates expectations at test-definition time. Simulator UI tests should use bundled import, not a simulated camera capture.
