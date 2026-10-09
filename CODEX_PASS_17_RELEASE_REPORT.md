# Codex Pass 17 — V1 Submission Hardening Report

> Historical snapshot. The current V1 contract has eight active modes; Sudoku Photo Scan is Coming Soon, and its implementation and permissions have been removed. Scanner execution rows below are post-V1 work. See [FINAL_V1_CLEANUP_REPORT.md](FINAL_V1_CLEANUP_REPORT.md) for current findings and required checks.

## Release decision

**NO-GO — the candidate is not yet ready for App Store submission.**

This repository pass froze the V1 catalog and completed the release changes
that can be verified statically in the supplied Linux environment. It did not
have macOS, Xcode, signing credentials, App Store Connect access, TestFlight,
or physical Apple devices. Archive, upload, runtime privacy, physical smoke,
screenshot, and store-record work therefore remains a release-owner gate. No
unperformed check is represented as passing.

## Candidate identity

- **Marketing version:** 1.0
- **Build:** 17
- **Bundle identifier:** `Bryce-Cameron-Design.Puzzle-Solver`
- **Minimum app deployment target:** iOS 16.0
- **Candidate commit:** record the final commit SHA after this report is committed
- **CI build:** pending a green `iOS Build and Test / V1 Release Gate` run for
  that exact final commit on `main` or the designated release branch

Both Debug and Release configurations of the application target use the same
version and build settings. Test target version values are not submission
metadata and were intentionally left unchanged.

## Frozen nine-mode catalog

1. 3×3 Sliding Puzzle
2. 4×4 Sliding Puzzle
3. 5×5 Sliding Puzzle
4. 2×2 Cube
5. 3×3 Rubik’s Cube
6. Sudoku
7. Sudoku Photo Scan
8. Killer Sudoku
9. Rush Hour

No tenth mode was activated. The twelve catalog entries marked Coming Soon are
not advertised as available in the V1 App Store copy.

## Automated and static checks

| Gate | Result | Evidence / next action |
| --- | --- | --- |
| Catalog/source freeze | PASS (static) | Catalog tests pin exactly nine active IDs and twelve Coming Soon IDs. |
| Release metadata | PASS (static) | App target Debug and Release are both version 1.0 (17); `Info.plist` expands the build settings. |
| Permission strings | PASS (static) | Camera and photo-library purpose strings are present for Photo Scan. |
| Privacy manifest presence | PASS (static) | Manifest is in the app resources and declares no tracking/no collected data plus the UserDefaults required-reason entry. |
| App icons | PASS (static inventory only) | The asset catalog declares iPhone, iPad, and 1024×1024 marketing slots and each referenced file exists. Archive processing still must validate them. |
| Network API source scan | PASS (static only) | No production `URLSession`, socket, web view, or HTTP endpoint reference was found. This is not a runtime privacy audit. |
| User-facing placeholder scan | REVIEWED | Placeholder terms remain in developer/model names and the explicit Coming Soon screen; no Active catalog destination routes to that screen. |
| Debug navigation scan | PASS (static) | The only `#if DEBUG` occurrence formats scanner cell diagnostics, not navigation or a user-reachable control. |
| Debug build / unit tests / XCUITests / Release build | PENDING | Must pass the repository CI workflow at the final candidate commit on Xcode 26+. |
| Release device archive | NOT RUN — BLOCKER | Create a signed `generic/platform=iOS` Release archive with Xcode 26+/iOS 26 SDK+ and preserve the `.xcarchive` and log. |
| Organizer/App Store validation | NOT RUN — BLOCKER | Validate the signed archive and evaluate every warning, including signing, bundle, architectures, icons, privacy manifest, permissions, and required-reason APIs. |
| TestFlight upload/processing | NOT RUN — BLOCKER | Upload build 17 only after archive validation succeeds; record processing result and build identifier. |
| TestFlight physical smoke | NOT RUN — BLOCKER | Install the processed TestFlight build and exercise all nine modes on the physical-device matrix. |
| Runtime privacy audit | NOT RUN — BLOCKER | Capture App Privacy Report and observed network traffic from the TestFlight build; exercise Camera and Photos and verify Photo Scan produces no transmission. |
| Final App Store screenshots | NOT RUN — BLOCKER | Capture from build 17 shipping UI after smoke testing; exclude debug UI and Coming Soon claims. |

## App Store Connect metadata status

Repository-verifiable metadata:

- **Primary category:** Games (`public.app-category.games`).
- **Privacy manifest:** present; tracking false; collected-data list empty.
- **Description/promotional text:** shipping-only draft is in `README.md`.
- **Copyright:** **PENDING — release owner must provide the legal owner and year.**
- **Support URL:** **PENDING — a live public support URL was not supplied.**
- **Privacy-policy URL:** **PENDING — a live public policy URL was not supplied.**
- **Contact information:** **PENDING — App Store Connect account-holder details are not available in the repository.**
- **Age rating:** **PENDING — complete the current App Store Connect questionnaire against actual behavior; do not infer a rating in source control.**
- **App Privacy answers:** **PENDING runtime audit and release-owner submission.** The source inspection supports an on-device/no-tracking design, but it is not a substitute for observed TestFlight behavior.

## Release-owner archive and submission procedure

1. Check out the exact candidate commit with a clean working tree on a machine
   running Xcode 26 or later and an iOS 26 SDK or supported later toolchain.
2. Confirm the `Puzzle Solver` scheme uses the intended distribution team,
   bundle identifier, version 1.0, build 17, and iOS 16.0 minimum target.
3. Run the CI-equivalent Debug build, unit tests, all V1 XCUITests, and Release
   build. Preserve `.xcresult` bundles and link the green CI run.
4. Archive the Release configuration for `generic/platform=iOS`; validate it
   in Organizer. Review, resolve, and document every warning rather than
   suppressing it.
5. Upload that same archive to TestFlight. After processing, install build 17
   on each physical test device and complete
   `FINAL_V1_PHYSICAL_TEST_MATRIX.md`, including all nine modes.
6. While exercising Camera and Photos, export the App Privacy Report and
   inspect runtime network traffic. Confirm that no Sudoku image, recognized
   digits, puzzle state, or identifier leaves the device before selecting
   no-data-collection privacy answers.
7. Capture final screenshots from the accepted TestFlight build. Review every
   image and all store copy against the nine-mode list above.
8. Complete support URL, privacy-policy URL, contact, copyright, age rating,
   and privacy details in App Store Connect. Have a second reviewer compare the
   saved record to observed behavior.
9. Treat the build as submission-ready only when every blocker below is closed
   against the same binary.

## Known non-blocking limitations

- Sliding and cube searches are intentionally bounded; difficult inputs can
  return timeout/limit feedback instead of a solution.
- Photo Scan requires user review of all recognized clues before solving.
- Coming Soon entries remain visible only as unavailable previews.

These are disclosed product constraints, not permission to waive a failing
test, crash, incorrect solution, privacy discrepancy, or archive warning.

## Unresolved V1 blockers

1. Final candidate CI run has not been observed for the Pass 17 commit.
2. Signed Release archive and App Store validation have not been performed.
3. TestFlight upload, processing, installation, and nine-mode smoke test have
   not been performed.
4. The physical-device matrix remains unexecuted.
5. Runtime privacy/network behavior, particularly Photo Scan, has not been
   observed from the TestFlight binary.
6. Final screenshots have not been captured from the shipping binary.
7. Required App Store Connect metadata listed above is incomplete.

**Explicit blocker confirmation:** unresolved V1 blockers remain. The release
owner must not submit or state that build 17 is ready until all seven items are
closed with evidence and no new release blocker is open.
