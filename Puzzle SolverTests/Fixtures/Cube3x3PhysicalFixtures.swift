import Foundation
@testable import Puzzle_Solver

/// Physical 3×3 reference data transcribed for the facelet convention documented
/// in `THREE_BY_THREE_FACELET_CONVENTION.md`. None of these permutations is
/// obtained from `Cube3x3MoveTables` or `Cube3x3MoveEngine`.
enum Cube3x3PhysicalFixtures {
    static let clockwiseSource: [String: [Int]] = [
        "U": [2,5,8,1,4,7,0,3,6, 18,19,20,12,13,14,15,16,17, 36,37,38,21,22,23,24,25,26, 27,28,29,30,31,32,33,34,35, 45,46,47,39,40,41,42,43,44, 9,10,11,48,49,50,51,52,53],
        "R": [0,1,51,3,4,48,6,7,45, 11,14,17,10,13,16,9,12,15, 18,19,2,21,22,5,24,25,8, 27,28,20,30,31,23,33,34,26, 36,37,38,39,40,41,42,43,44, 35,46,47,32,49,50,29,52,53],
        "F": [0,1,2,3,4,5,44,41,38, 6,10,11,7,13,14,8,16,17, 24,21,18,25,22,19,26,23,20, 15,12,9,30,31,32,33,34,35, 36,37,27,39,40,28,42,43,29, 45,46,47,48,49,50,51,52,53],
        "D": [0,1,2,3,4,5,6,7,8, 9,10,11,12,13,14,51,52,53, 18,19,20,21,22,23,15,16,17, 29,32,35,28,31,34,27,30,33, 36,37,38,39,40,41,24,25,26, 45,46,47,48,49,50,42,43,44],
        "L": [18,1,2,21,4,5,24,7,8, 9,10,11,12,13,14,15,16,17, 27,19,20,30,22,23,33,25,26, 53,28,29,50,31,32,47,34,35, 38,41,44,37,40,43,36,39,42, 45,46,6,48,49,3,51,52,0],
        "B": [11,14,17,3,4,5,6,7,8, 9,10,35,12,13,34,15,16,33, 18,19,20,21,22,23,24,25,26, 27,28,29,30,31,32,36,39,42, 2,37,38,1,40,41,0,43,44, 51,48,45,52,49,46,53,50,47]
    ]

    static let clockwiseSolvedColors: [String: [String]] = [
        "U": stickers("UUUUUUUUU FFFRRRRRR LLLFFFFFF DDDDDDDDD BBBLLLLLL RRRBBBBBB"),
        "R": stickers("UUBUUBUUB RRRRRRRRR FFUFFUFFU DDFDDFDDF LLLLLLLLL DBBDBBDBB"),
        "F": stickers("UUUUUULLL URRURRURR FFFFFFFFF RRRDDDDDD LLDLLDLLD BBBBBBBBB"),
        "D": stickers("UUUUUUUUU RRRRRRBBB FFFFFFRRR DDDDDDDDD LLLLLLFFF BBBBBBLLL"),
        "L": stickers("FUUFUUFUU RRRRRRRRR DFFDFFDFF BDDBDDBDD LLLLLLLLL BBUBBUBBU"),
        "B": stickers("RRRUUUUUU RRDRRDRRD FFFFFFFFF DDDDDDLLL ULLULLULL BBBBBBBBB")
    ]

    static let twistedCorner = state { stickers in cycle(&stickers, [8, 9, 20]) }
    static let flippedEdge = state { stickers in stickers.swapAt(5, 10) }
    static let duplicateMissingCorner = state { stickers in
        assign(&stickers, [8:"R", 9:"B", 20:"D", 6:"F", 18:"L", 38:"U",
                           36:"R", 47:"F", 2:"L", 45:"D", 11:"F", 29:"U",
                           15:"L", 27:"L", 44:"D", 24:"B", 33:"U", 53:"R",
                           42:"B", 35:"B", 17:"D", 51:"R"])
    }
    static let duplicateMissingEdge = state { stickers in
        assign(&stickers, [10:"L", 7:"F", 19:"R", 3:"F", 37:"D", 1:"L",
                           46:"U", 32:"R", 16:"B", 28:"R", 25:"D", 43:"B",
                           34:"U", 52:"F", 23:"B", 12:"L", 41:"D", 50:"R",
                           39:"U", 14:"L"])
    }
    static let badCenters = state { $0.swapAt(4, 13) }
    static let parityMismatch = state { stickers in
        // Transpose the complete UR and UF edge cubies, leaving corners fixed.
        stickers.swapAt(5, 7)
        stickers.swapAt(10, 19)
    }

    private static func stickers(_ value: String) -> [String] {
        value.filter { !$0.isWhitespace }.map(String.init)
    }

    private static func state(_ edit: (inout [String]) -> Void) -> CubeState {
        var stickers = CubeState.solved3x3.stickers
        edit(&stickers)
        return CubeState(puzzle: .threeByThree, stickers: stickers)
    }

    private static func cycle(_ stickers: inout [String], _ indices: [Int]) {
        let first = stickers[indices[0]]
        stickers[indices[0]] = stickers[indices[1]]
        stickers[indices[1]] = stickers[indices[2]]
        stickers[indices[2]] = first
    }

    private static func assign(_ stickers: inout [String], _ replacements: [Int: String]) {
        for (index, color) in replacements { stickers[index] = color }
    }
}
