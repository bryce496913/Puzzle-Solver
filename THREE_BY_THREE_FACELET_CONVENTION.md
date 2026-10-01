# 3×3 physical facelet convention

The 3×3 model stores exactly 54 stickers as six contiguous, row-major faces:

| Face | Color in guided orientation | Indices | Center |
| --- | --- | --- | --- |
| Up (`U`) | white | `0...8` | `4` |
| Right (`R`) | red | `9...17` | `13` |
| Front (`F`) | green | `18...26` | `22` |
| Down (`D`) | yellow | `27...35` | `31` |
| Left (`L`) | orange | `36...44` | `40` |
| Back (`B`) | blue | `45...53` | `49` |

Each range is laid out as `top-left, top-middle, top-right, middle-left, center,
middle-right, bottom-left, bottom-middle, bottom-right` while looking directly
at that face from outside the cube. In particular, the Back grid is viewed
from behind the cube looking toward its center; it is not the Front observer's
mirrored view through the cube.

The physical reference orientation is white on top and green facing the
observer. Red is on the right, yellow is down, orange is left, and blue is
back. These six center identities and their order are fixed. Clockwise move
notation means clockwise while looking directly at the face being turned,
following standard Singmaster notation.

`Puzzle SolverTests/Fixtures/Cube3x3PhysicalFixtures.swift` records independent,
static source-position permutations and solved-color results for all six
clockwise face turns. They are regression data, not values produced by the
production move-table implementation.
