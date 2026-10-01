# Production 3×3 solver limits and preparation

The production sticker-state adapter uses `Cube3x3KociembaSolver`; the retained
legacy shallow solver is not registered with `CubeSolvingService`.

## Preparation lifecycle

Pruning tables remain generated lazily and cached once per process by
`Cube3x3PruningTables.shared`. The production adapter does not touch that
singleton during initialization. Its first access therefore occurs inside
`CubeSolvingService`'s user-initiated background queue rather than while the
service is being constructed on the main thread. Bundling generated tables is
not justified by the measured initialization cost and would add asset/version
synchronization risk.

## Measurements and limits

Measurements were taken from an optimized (`swiftc -O`) command-line build on
the development runner using the deterministic 12-turn scramble
`U D R' L2 F B' U2 R D2 F' L B2`:

| Measurement | Time |
| --- | ---: |
| First pruning-table preparation | 0.426 s |
| First search | 2.260 s |
| Total first solve | 2.685 s |
| Warm preparation lookup | <0.001 s |
| Warm search / total solve | 2.183 s |

That solve explored 2,497,650 nodes. Production therefore uses a 30-second
timeout, 5,000,000-node budget, and 30-move total depth. These are intentionally
well above the former shallow DFS limits (5 seconds, 80,000 nodes, and depth 6),
cover the validated two-phase depth range, and leave roughly 2× node headroom
for this mixed fixture while retaining deterministic responsiveness caps.

Preparation time, search time, and wrapper total time are logged separately by
the production adapter. Subsequent solves reuse the process-wide tables.
