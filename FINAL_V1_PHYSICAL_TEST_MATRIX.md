# Final V1 Physical Test Matrix (Codex Pass 16)

> Historical snapshot. The current V1 contract has eight active modes; Sudoku Photo Scan is Coming Soon, and its implementation and permissions have been removed. Scanner execution rows below are post-V1 work. See [FINAL_V1_CLEANUP_REPORT.md](FINAL_V1_CLEANUP_REPORT.md) for current findings and required checks.

## Release decision

**Status: BLOCKED — physical execution is still required.**

This pass was prepared on 2026-10-01 in a Linux container with no iPhone,
camera, photo library, physical puzzles, VoiceOver, iOS Simulator, or Xcode.
Consequently, none of the real-world scenarios below was executed and none is
marked as passing. This is the release evidence record, not a claim that
hardware behavior was inferred from unit tests. App Store submission hardening
must not begin until every `NOT RUN` row has been replaced with an observed
result and all V1-blocking failures have been fixed and retested.

### Result vocabulary

- `PASS`: the expected result was directly observed on the named device.
- `FAIL`: observed behavior differed from the expected result; add an issue/PR.
- `NOT RUN`: no qualified operator/device/equipment result exists yet.
- `BLOCKED`: execution was attempted but an identified environmental blocker
  prevented an observation.

For every physical run, record the iPhone model, iOS version, app commit, puzzle
source/card identifier, and (for cube/sliding tests) the entered state and exact
returned moves in **Notes**. A move-sequence case passes only after the operator
applies every returned move to the supplied physical state and observes the
solved/cleared state. Screenshots or video should be attached to the linked
issue/PR when practical.

## Sliding Puzzle

Use a physical numbered sliding puzzle or independently tracked tile board.
For the over-limit case, preserve the exact board and the displayed bounded
outcome. For reset/retry, reset while work is active, then solve the one-move
board and confirm that no result from the cancelled request appears.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| 3×3 Sliding | Already solved | Physical puzzle + supported iPhone | Reports already solved; zero moves | Not observed | NOT RUN | Hardware unavailable in Pass 16 environment | — |
| 3×3 Sliding | One move | Physical puzzle + supported iPhone | Returned moves replay to solved board | Not observed | NOT RUN | Record start state and moves | — |
| 3×3 Sliding | Moderate scramble | Physical puzzle + supported iPhone | Returned moves replay to solved board | Not observed | NOT RUN | Record start state and moves | — |
| 3×3 Sliding | Unsolvable parity | Supported iPhone | Rejects state as unsolvable; no moves shown | Not observed | NOT RUN | Swap two numbered tiles from solved | — |
| 3×3 Sliding | Deliberately over limit | Supported iPhone | Ends with explicit bounded limit/timeout; UI remains responsive | Not observed | NOT RUN | Preserve exact board | — |
| 3×3 Sliding | Reset/retry | Supported iPhone | Cancels old work, clears state, and retry has only its own result | Not observed | NOT RUN | Retry with one-move board | — |
| 4×4 Sliding | Already solved | Physical puzzle + supported iPhone | Reports already solved; zero moves | Not observed | NOT RUN | Hardware unavailable in Pass 16 environment | — |
| 4×4 Sliding | One move | Physical puzzle + supported iPhone | Returned moves replay to solved board | Not observed | NOT RUN | Record start state and moves | — |
| 4×4 Sliding | Moderate scramble | Physical puzzle + supported iPhone | Returned moves replay to solved board | Not observed | NOT RUN | Record start state and moves | — |
| 4×4 Sliding | Unsolvable parity | Supported iPhone | Rejects state as unsolvable; no moves shown | Not observed | NOT RUN | Swap two numbered tiles from solved | — |
| 4×4 Sliding | Deliberately over limit | Supported iPhone | Ends with explicit bounded limit/timeout; UI remains responsive | Not observed | NOT RUN | Preserve exact board | — |
| 4×4 Sliding | Reset/retry | Supported iPhone | Cancels old work, clears state, and retry has only its own result | Not observed | NOT RUN | Retry with one-move board | — |
| 5×5 Sliding | Already solved | Physical puzzle + supported iPhone | Reports already solved; zero moves | Not observed | NOT RUN | Hardware unavailable in Pass 16 environment | — |
| 5×5 Sliding | One move | Physical puzzle + supported iPhone | Returned moves replay to solved board | Not observed | NOT RUN | Record start state and moves | — |
| 5×5 Sliding | Moderate scramble | Physical puzzle + supported iPhone | Returned moves replay to solved board, or documented bounded outcome if beyond V1 capability | Not observed | NOT RUN | Record start state and moves | — |
| 5×5 Sliding | Unsolvable parity | Supported iPhone | Rejects state as unsolvable; no moves shown | Not observed | NOT RUN | Swap two numbered tiles from solved | — |
| 5×5 Sliding | Deliberately over limit | Supported iPhone | Ends with explicit bounded limit/timeout; UI remains responsive | Not observed | NOT RUN | Preserve exact board | — |
| 5×5 Sliding | Reset/retry | Supported iPhone | Cancels old work, clears state, and retry has only its own result | Not observed | NOT RUN | Retry with one-move board | — |

## 2×2 Cube

Hold the cube in the app's documented reference orientation throughout entry
and replay. The three scramble rows must use unrelated hand scrambles, not
states generated by reversing a displayed solution.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| 2×2 Cube | Physical scramble A | Real 2×2 + supported iPhone | Manual stickers accepted; exact returned moves physically solve cube | Not observed | NOT RUN | Record all stickers, moves, iPhone/iOS | — |
| 2×2 Cube | Physical scramble B | Real 2×2 + supported iPhone | Manual stickers accepted; exact returned moves physically solve cube | Not observed | NOT RUN | Must be unrelated to A | — |
| 2×2 Cube | Physical scramble C | Real 2×2 + supported iPhone | Manual stickers accepted; exact returned moves physically solve cube | Not observed | NOT RUN | Must be unrelated to A/B | — |
| 2×2 Cube | One twisted corner | Real 2×2 + supported iPhone | Rejects impossible twist before search; no solution displayed | Not observed | NOT RUN | Photograph impossible state | — |
| 2×2 Cube | Wrong color count | Supported iPhone | Identifies incorrect counts and does not solve | Not observed | NOT RUN | Record altered stickers | — |
| 2×2 Cube | Duplicate/missing corner | Supported iPhone | Identifies impossible cubie inventory and does not solve | Not observed | NOT RUN | Keep color totals valid | — |
| 2×2 Cube | Correction workflow | Real 2×2 + supported iPhone | Invalid input can be corrected without re-entering unaffected stickers; corrected state solves physically | Not observed | NOT RUN | Begin with one mistyped sticker | — |

## 3×3 Cube

Use meaningful mixed physical scrambles. Preserve the scramble (if known), all
54 entered stickers, returned sequence, and replay outcome. Do not count only
shallow generated states as this section's physical evidence.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| 3×3 Cube | Mixed physical scramble A | Real 3×3 + supported iPhone | Manual stickers accepted; exact returned moves physically solve cube | Not observed | NOT RUN | Target at least 20 mixed face turns | — |
| 3×3 Cube | Mixed physical scramble B | Real 3×3 + supported iPhone | Manual stickers accepted; exact returned moves physically solve cube | Not observed | NOT RUN | Unrelated to A | — |
| 3×3 Cube | Mixed physical scramble C | Real 3×3 + supported iPhone | Manual stickers accepted; exact returned moves physically solve cube | Not observed | NOT RUN | Unrelated to A/B | — |
| 3×3 Cube | Bad center input | Supported iPhone | Rejects incorrect/fixed-center mapping before search | Not observed | NOT RUN | Record entered centers | — |
| 3×3 Cube | One flipped edge | Real 3×3 + supported iPhone | Rejects impossible edge orientation; no solution displayed | Not observed | NOT RUN | Photograph impossible state | — |
| 3×3 Cube | One twisted corner | Real 3×3 + supported iPhone | Rejects impossible corner orientation; no solution displayed | Not observed | NOT RUN | Photograph impossible state | — |
| 3×3 Cube | Parity-invalid synthetic state | Supported iPhone | Rejects cubie permutation parity mismatch; no solution displayed | Not observed | NOT RUN | Swap exactly two cubies in entry | — |
| 3×3 Cube | Incorrect color counts | Supported iPhone | Identifies incorrect counts and does not solve | Not observed | NOT RUN | Record altered stickers | — |
| 3×3 Cube | Correction workflow | Real 3×3 + supported iPhone | Invalid input can be corrected; corrected state's moves physically solve cube | Not observed | NOT RUN | Begin with one mistyped sticker | — |

## Manual Sudoku

Record puzzle title/source and givens. For multiple-solution and under-specified
cases, verify that no completed board is ever presented as *the* answer.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| Manual Sudoku | Easy | Supported iPhone | Unique valid solution matches independently verified answer | Not observed | NOT RUN | Record puzzle source | — |
| Manual Sudoku | Medium | Supported iPhone | Unique valid solution matches independently verified answer | Not observed | NOT RUN | Record puzzle source | — |
| Manual Sudoku | Hard | Supported iPhone | Unique valid solution matches independently verified answer | Not observed | NOT RUN | Record puzzle source | — |
| Manual Sudoku | Already solved | Supported iPhone | Recognizes valid completion without replacing it arbitrarily | Not observed | NOT RUN | — | — |
| Manual Sudoku | Duplicate values | Supported iPhone | Highlights/reports conflict and does not display solution | Not observed | NOT RUN | Exercise row, column, and box | — |
| Manual Sudoku | Unsolvable | Supported iPhone | Reports no solution; no completed board displayed | Not observed | NOT RUN | Valid givens with contradiction downstream | — |
| Manual Sudoku | Multiple solutions | Supported iPhone | Reports ambiguity; never displays an arbitrary answer | Not observed | NOT RUN | Preserve puzzle | — |
| Manual Sudoku | Empty/under-specified | Supported iPhone | Reports insufficient/ambiguous input; no arbitrary answer | Not observed | NOT RUN | Test empty plus sparse board | — |
| Manual Sudoku | Reset/re-entry | Supported iPhone | Reset clears prior input/result; re-entered puzzle solves independently | Not observed | NOT RUN | Watch for stale result | — |

## Sudoku Photo Scan

Each source/condition row requires digit-by-digit comparison of all 81 review
cells with the source before accepting the puzzle. Use at least one blank-heavy
and one dense puzzle across the set. “Recoverable rejection” means the app
clearly asks for another image and does not silently commit incorrect digits.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| Photo Scan | Paper / bright light | Supported physical iPhone | All detected digits match source, or uncertainties are explicit before commit | Not observed | NOT RUN | Camera capture | — |
| Photo Scan | Paper / low light | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Camera capture | — |
| Photo Scan | Paper / glare | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Camera capture | — |
| Photo Scan | Paper / shadow | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Camera capture | — |
| Photo Scan | Paper / mild perspective | Supported physical iPhone | Perspective correction maps all 81 cells accurately | Not observed | NOT RUN | Camera capture | — |
| Photo Scan | Paper / stronger perspective | Supported physical iPhone | Accurate mapping or clear recoverable rejection | Not observed | NOT RUN | Camera capture | — |
| Photo Scan | Paper / slightly cropped | Supported physical iPhone | No silent cell shift; accurate result or crop guidance | Not observed | NOT RUN | Camera capture | — |
| Photo Scan | Paper / different sizes | Supported physical iPhone | Small and large printed grids map accurately | Not observed | NOT RUN | Record dimensions | — |
| Photo Scan | Screenshot / bright display | Supported physical iPhone | All 81 review cells match screenshot | Not observed | NOT RUN | Import from Photos | — |
| Photo Scan | Screenshot / dim display capture | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Photograph screen | — |
| Photo Scan | Screenshot / glare | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Photograph screen | — |
| Photo Scan | Screenshot / shadow | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Photograph screen | — |
| Photo Scan | Screenshot / mild perspective | Supported physical iPhone | Perspective correction maps all 81 cells accurately | Not observed | NOT RUN | Photograph screen | — |
| Photo Scan | Screenshot / stronger perspective | Supported physical iPhone | Accurate mapping or clear recoverable rejection | Not observed | NOT RUN | Photograph screen | — |
| Photo Scan | Screenshot / slightly cropped | Supported physical iPhone | No silent cell shift; accurate result or crop guidance | Not observed | NOT RUN | Import and capture variants | — |
| Photo Scan | Screenshot / different screen sizes | Supported physical iPhone | Source digits map accurately at both sizes | Not observed | NOT RUN | Record source devices | — |
| Photo Scan | Camera photo / bright light | Supported physical iPhone | All 81 review cells match photographed puzzle | Not observed | NOT RUN | Live Camera route | — |
| Photo Scan | Camera photo / low light | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Live Camera route | — |
| Photo Scan | Camera photo / glare | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Live Camera route | — |
| Photo Scan | Camera photo / shadow | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Live Camera route | — |
| Photo Scan | Camera photo / mild perspective | Supported physical iPhone | Perspective correction maps all 81 cells accurately | Not observed | NOT RUN | Live Camera route | — |
| Photo Scan | Camera photo / stronger perspective | Supported physical iPhone | Accurate mapping or clear recoverable rejection | Not observed | NOT RUN | Live Camera route | — |
| Photo Scan | Camera photo / slightly cropped | Supported physical iPhone | No silent cell shift; accurate result or crop guidance | Not observed | NOT RUN | Live Camera route | — |
| Photo Scan | Camera photo / different paper sizes | Supported physical iPhone | Source digits map accurately at both sizes | Not observed | NOT RUN | Record dimensions | — |
| Photo Scan | Photo Library image / bright light | Supported physical iPhone | All 81 review cells match source image | Not observed | NOT RUN | Photos route | — |
| Photo Scan | Photo Library image / low light | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Photos route | — |
| Photo Scan | Photo Library image / glare | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Photos route | — |
| Photo Scan | Photo Library image / shadow | Supported physical iPhone | Digits match source or scan is recoverably rejected | Not observed | NOT RUN | Photos route | — |
| Photo Scan | Photo Library image / mild perspective | Supported physical iPhone | Perspective correction maps all 81 cells accurately | Not observed | NOT RUN | Photos route | — |
| Photo Scan | Photo Library image / stronger perspective | Supported physical iPhone | Accurate mapping or clear recoverable rejection | Not observed | NOT RUN | Photos route | — |
| Photo Scan | Photo Library image / slightly cropped | Supported physical iPhone | No silent cell shift; accurate result or crop guidance | Not observed | NOT RUN | Photos route | — |
| Photo Scan | Photo Library image / different sizes | Supported physical iPhone | Source digits map accurately across resolutions | Not observed | NOT RUN | Record pixel dimensions | — |
| Photo Scan | Camera permission denied | Supported physical iPhone | Explains denial, remains usable, and offers safe alternate/manual path | Not observed | NOT RUN | Reset permission before test | — |
| Photo Scan | Photos permission denied | Supported physical iPhone | Explains denial, remains usable, and offers manual path | Not observed | NOT RUN | Reset permission before test | — |

## Killer Sudoku

Use published puzzles whose solutions are independently available. Record the
publication/title and cage transcription; do not treat the bundled example as
all “several” layouts.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| Killer Sudoku | Published layout A | Supported iPhone | Cage entry is usable; solution matches published answer and every cage | Not observed | NOT RUN | Record source/layout | — |
| Killer Sudoku | Published layout B | Supported iPhone | Cage entry is usable; solution matches published answer and every cage | Not observed | NOT RUN | Unrelated layout | — |
| Killer Sudoku | Published layout C | Supported iPhone | Cage entry is usable; solution matches published answer and every cage | Not observed | NOT RUN | Unrelated layout | — |
| Killer Sudoku | Full coverage validation | Supported iPhone | Missing and overlapping cells prevent solve and are identified | Not observed | NOT RUN | Test both defects | — |
| Killer Sudoku | Invalid cage feedback | Supported iPhone | Disconnected/impossible/invalid-total cage gets actionable feedback | Not observed | NOT RUN | Record each invalid cage | — |
| Killer Sudoku | Reset/edit behavior | Supported iPhone | Edit/reset changes only intended data and clears stale result | Not observed | NOT RUN | Include delete/undo if exposed | — |

## Rush Hour

Use physical challenge cards from a named set and reproduce every vehicle. A
case passes only after applying the returned sequence on the physical board and
moving the target car through the exit.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| Rush Hour | Beginner challenge card | Physical set + supported iPhone | Entered layout matches card; returned moves physically clear target car | Not observed | NOT RUN | Record set/card and moves | — |
| Rush Hour | Intermediate challenge card | Physical set + supported iPhone | Entered layout matches card; returned moves physically clear target car | Not observed | NOT RUN | Record set/card and moves | — |
| Rush Hour | Advanced challenge card | Physical set + supported iPhone | Entered layout matches card; returned moves physically clear target car | Not observed | NOT RUN | Record set/card and moves | — |
| Rush Hour | Expert challenge card | Physical set + supported iPhone | Entered layout matches card; returned moves physically clear target car | Not observed | NOT RUN | Record set/card and moves | — |

## Device and Accessibility

Run representative entry, solve, result, and playback screens. Record exact
models and iOS versions. “Maximum relevant” means the largest accessibility
category at which the app is expected to remain operable, plus AX5 to expose
clipping even where compact puzzle grids necessarily constrain glyph scaling.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| Device layout | Smallest supported iPhone class | Physical smallest-supported iPhone | All nine modes remain operable; no clipped critical controls/content | Not observed | NOT RUN | Record model/iOS | — |
| Device layout | Current large iPhone class | Physical current large iPhone | All nine modes use space correctly; no obscured content | Not observed | NOT RUN | Record model/iOS | — |
| Dynamic Type | Largest standard size | Small and large iPhones | Navigation and critical controls remain readable/operable | Not observed | NOT RUN | Run representative flows | — |
| Dynamic Type | AX5 / maximum accessibility size | Small and large iPhones | Content scrolls/reflows; critical controls remain reachable and labeled | Not observed | NOT RUN | Note any intentional grid constraint | — |
| VoiceOver | Entry and validation | Supported physical iPhone | Controls/cells have meaningful labels, values, order, and actions | Not observed | NOT RUN | Cover each input style | — |
| VoiceOver | Solve results/playback | Supported physical iPhone | Status and moves are announced; playback is operable without sight | Not observed | NOT RUN | Cover sliding/cubes/Rush Hour | — |
| Appearance | System appearance | Supported physical iPhone | App follows documented System setting without unreadable states | Not observed | NOT RUN | Toggle while active | — |
| Appearance | Dark appearance | Supported physical iPhone | Text, selection, errors, boards, and controls retain contrast | Not observed | NOT RUN | Cover all nine modes | — |
| Appearance | Light availability disclosure | Supported physical iPhone | If Light is unsupported, it is absent or clearly disabled/explained—not misleadingly selectable | Not observed | NOT RUN | Record Settings behavior | — |

## Lifecycle and Concurrency

Run each row in at least one long-running sliding/cube solve and one logic or
scan flow where applicable. A case fails if any result from an older operation
replaces or contaminates the newest state.

| Feature | Case | Device | Expected result | Actual result | Pass/fail | Notes | Related issue/PR |
|---|---|---|---|---|---|---|---|
| Lifecycle | Start solve → background → return | Supported physical iPhone | UI remains consistent; only current operation may publish a result | Not observed | NOT RUN | Test short and prolonged background | — |
| Lifecycle | Start solve → reset | Supported physical iPhone | Work is cancelled/ignored; reset screen never receives stale result | Not observed | NOT RUN | Use a deliberately slow state | — |
| Lifecycle | Start solve → navigate back | Supported physical iPhone | No crash, hang, or stale result on later entry | Not observed | NOT RUN | Reopen same mode | — |
| Lifecycle | Solve repeatedly | Supported physical iPhone | Each result belongs to its submitted state; memory/UI remain stable | Not observed | NOT RUN | At least 10 alternating states | — |
| Lifecycle | Scan repeatedly | Supported physical iPhone | Each review belongs to latest image; cancellation stays cancelled | Not observed | NOT RUN | Alternate Camera/Photos | — |
| Lifecycle | Rapidly start second operation | Supported physical iPhone | Second request wins; first request never overwrites it | Not observed | NOT RUN | Preserve both inputs/timestamps | — |

## Execution sign-off

The following must be completed by the release owner after all rows are no
longer `NOT RUN` or `BLOCKED`:

- **Test operator:** _pending_
- **Physical-device inventory and iOS versions:** _pending_
- **App commit/build tested:** _pending_
- **Evidence attachment location:** _pending_
- **Open V1-blocking issues:** _pending_
- **Final decision (GO / NO-GO):** **NO-GO — matrix unexecuted**
- **Sign-off date:** _pending_

## Automated evidence available separately

The repository's XCTest/XCUITest suites provide useful regression coverage but
do not replace this matrix. Run the CI-equivalent commands from
`.github/workflows/ios-ci.yml` on Xcode 26 or later and link the resulting
`UnitTestResults.xcresult` and `UITestResults.xcresult` here. No such result
bundle was produced in this Linux-only pass because `xcodebuild` is absent.
