//
//  PuzzleSolver.swift
//  Puzzle Solver
//
//  Created by Bryce Cameron on 2/3/24.
//

import Foundation

enum SlidingPuzzleMove: String, CaseIterable, Hashable {
    case up
    case down
    case left
    case right

    /// Human-friendly action for UI display.
    var label: String {
        switch self {
        case .up:
            return "Move blank up"
        case .down:
            return "Move blank down"
        case .left:
            return "Move blank left"
        case .right:
            return "Move blank right"
        }
    }
}

/// Reusable board model for NxN sliding puzzles (e.g. 3x3, 4x4).
struct SlidingPuzzleState: Hashable {
    let size: Int
    let tiles: [Int]

    init?(size: Int, tiles: [Int]) {
        guard size > 1 else { return nil }
        let tileCount = size * size
        guard tiles.count == tileCount else { return nil }

        let expectedValues = Set(0..<tileCount)
        let unique = Set(tiles)
        guard unique.count == tileCount, unique == expectedValues else { return nil }

        self.size = size
        self.tiles = tiles
    }

    init?(board: [[Int?]]) {
        guard let size = board.first?.count, size > 1 else { return nil }
        guard board.count == size, board.allSatisfy({ $0.count == size }) else { return nil }
        let flattened = board.flatMap { $0 }.map { $0 ?? 0 }
        self.init(size: size, tiles: flattened)
    }

    var tileCount: Int {
        size * size
    }

    var goalTiles: [Int] {
        Array(1..<tileCount) + [0]
    }

    var isGoal: Bool {
        tiles == goalTiles
    }

    var blankIndex: Int {
        tiles.firstIndex(of: 0) ?? 0
    }

    var blankRow: Int {
        blankIndex / size
    }

    var blankCol: Int {
        blankIndex % size
    }

    /// Row index from bottom, starting at 1.
    var blankRowFromBottom: Int {
        size - blankRow
    }

    func neighbors() -> [(state: SlidingPuzzleState, move: SlidingPuzzleMove)] {
        SlidingPuzzleMove.allCases.compactMap { move in
            guard let target = targetIndex(for: move) else { return nil }
            var nextTiles = tiles
            nextTiles.swapAt(blankIndex, target)
            guard let state = SlidingPuzzleState(size: size, tiles: nextTiles) else { return nil }
            return (state: state, move: move)
        }
    }

    /// Manhattan distance heuristic.
    func manhattanDistance() -> Int {
        var distance = 0

        for (index, tile) in tiles.enumerated() where tile != 0 {
            let goalIndex = tile - 1
            let currentRow = index / size
            let currentCol = index % size
            let goalRow = goalIndex / size
            let goalCol = goalIndex % size
            distance += abs(currentRow - goalRow) + abs(currentCol - goalCol)
        }

        return distance
    }

    func inversionCount() -> Int {
        let values = tiles.filter { $0 != 0 }
        var inversions = 0

        for i in 0..<values.count {
            for j in (i + 1)..<values.count where values[i] > values[j] {
                inversions += 1
            }
        }

        return inversions
    }

    /// Solvability rules:
    /// - Odd width: inversion count must be even.
    /// - Even width: depends on inversion parity and blank row from bottom.
    func isSolvable() -> Bool {
        let inversions = inversionCount()

        if size % 2 == 1 {
            return inversions % 2 == 0
        }

        let blankOnEvenRowFromBottom = blankRowFromBottom % 2 == 0
        let inversionsEven = inversions % 2 == 0
        return blankOnEvenRowFromBottom ? !inversionsEven : inversionsEven
    }

    /// Converts the flat storage to grid rows for rendering.
    func boardRows() -> [[Int?]] {
        stride(from: 0, to: tiles.count, by: size).map { start in
            (0..<size).map { offset in
                let value = tiles[start + offset]
                return value == 0 ? nil : value
            }
        }
    }

    private func targetIndex(for move: SlidingPuzzleMove) -> Int? {
        switch move {
        case .up:
            guard blankRow > 0 else { return nil }
            return blankIndex - size
        case .down:
            guard blankRow < size - 1 else { return nil }
            return blankIndex + size
        case .left:
            guard blankCol > 0 else { return nil }
            return blankIndex - 1
        case .right:
            guard blankCol < size - 1 else { return nil }
            return blankIndex + 1
        }
    }
}

struct SlidingPuzzleSolutionStep: Hashable {
    let state: SlidingPuzzleState
    let stepNumber: Int
    let move: SlidingPuzzleMove?

    var moveLabel: String? {
        move?.label
    }
}

struct SlidingPuzzleSolveResult {
    let isSolvable: Bool
    let steps: [SlidingPuzzleSolutionStep]

    var moveCount: Int {
        max(steps.count - 1, 0)
    }

    static func unsolvable(initial: SlidingPuzzleState) -> SlidingPuzzleSolveResult {
        SlidingPuzzleSolveResult(
            isSolvable: false,
            steps: [.init(state: initial, stepNumber: 0, move: nil)]
        )
    }
}

protocol SlidingPuzzleHeuristic {
    func estimate(for state: SlidingPuzzleState) -> Int
}

struct ManhattanHeuristic: SlidingPuzzleHeuristic {
    func estimate(for state: SlidingPuzzleState) -> Int {
        state.manhattanDistance()
    }
}

final class SlidingPuzzleSolver {
    private enum Strategy {
        case aStar
        case idaStar
    }

    private struct FrontierNode: Comparable {
        let state: SlidingPuzzleState
        let gCost: Int
        let hCost: Int

        var fCost: Int { gCost + hCost }

        static func < (lhs: FrontierNode, rhs: FrontierNode) -> Bool {
            if lhs.fCost == rhs.fCost {
                return lhs.hCost < rhs.hCost
            }
            return lhs.fCost < rhs.fCost
        }
    }

    private struct StateLink {
        let parent: SlidingPuzzleState?
        let moveFromParent: SlidingPuzzleMove?
    }

    private enum IDAIterationResult {
        case found
        case nextBound(Int)
    }

    private let heuristic: SlidingPuzzleHeuristic

    init(heuristic: SlidingPuzzleHeuristic = ManhattanHeuristic()) {
        self.heuristic = heuristic
    }

    func solve(from initialState: SlidingPuzzleState) -> SlidingPuzzleSolveResult {
        guard initialState.isSolvable() else {
            return .unsolvable(initial: initialState)
        }

        if initialState.isGoal {
            return SlidingPuzzleSolveResult(
                isSolvable: true,
                steps: [.init(state: initialState, stepNumber: 0, move: nil)]
            )
        }

        let strategy = strategy(for: initialState.size)
        switch strategy {
        case .aStar:
            return solveWithAStar(from: initialState)
        case .idaStar:
            return solveWithIDAStar(from: initialState)
        }
    }

    private func strategy(for boardSize: Int) -> Strategy {
        switch boardSize {
        case 4:
            return .idaStar
        default:
            return .aStar
        }
    }

    private func solveWithAStar(from initialState: SlidingPuzzleState) -> SlidingPuzzleSolveResult {
        var frontier = PriorityQueue<FrontierNode>()
        var bestCostByState: [SlidingPuzzleState: Int] = [initialState: 0]
        var links: [SlidingPuzzleState: StateLink] = [
            initialState: StateLink(parent: nil, moveFromParent: nil)
        ]

        frontier.push(.init(state: initialState, gCost: 0, hCost: heuristic.estimate(for: initialState)))

        while let current = frontier.pop() {
            guard current.gCost <= (bestCostByState[current.state] ?? Int.max) else { continue }

            if current.state.isGoal {
                return SlidingPuzzleSolveResult(
                    isSolvable: true,
                    steps: reconstructPath(from: current.state, links: links)
                )
            }

            for neighbor in current.state.neighbors() {
                let tentativeG = current.gCost + 1
                if tentativeG < (bestCostByState[neighbor.state] ?? Int.max) {
                    bestCostByState[neighbor.state] = tentativeG
                    links[neighbor.state] = StateLink(parent: current.state, moveFromParent: neighbor.move)
                    frontier.push(
                        .init(
                            state: neighbor.state,
                            gCost: tentativeG,
                            hCost: heuristic.estimate(for: neighbor.state)
                        )
                    )
                }
            }
        }

        return .unsolvable(initial: initialState)
    }

    private func solveWithIDAStar(from initialState: SlidingPuzzleState) -> SlidingPuzzleSolveResult {
        var bound = heuristic.estimate(for: initialState)
        var path: [SlidingPuzzleState] = [initialState]
        var moves: [SlidingPuzzleMove] = []
        var activePathSet: Set<SlidingPuzzleState> = [initialState]

        while true {
            switch searchIDA(
                path: &path,
                moves: &moves,
                gCost: 0,
                bound: bound,
                activePathSet: &activePathSet
            ) {
            case .found:
                return SlidingPuzzleSolveResult(
                    isSolvable: true,
                    steps: makeStepsFromPath(path: path, moves: moves)
                )
            case .nextBound(let nextBound):
                if nextBound == Int.max {
                    return .unsolvable(initial: initialState)
                }
                bound = nextBound
            }
        }
    }

    private func searchIDA(path: inout [SlidingPuzzleState],
                           moves: inout [SlidingPuzzleMove],
                           gCost: Int,
                           bound: Int,
                           activePathSet: inout Set<SlidingPuzzleState>) -> IDAIterationResult {
        guard let current = path.last else {
            return .nextBound(Int.max)
        }

        let fCost = gCost + heuristic.estimate(for: current)
        if fCost > bound {
            return .nextBound(fCost)
        }

        if current.isGoal {
            return .found
        }

        var minimumOverflow = Int.max

        let orderedNeighbors = current.neighbors().sorted {
            heuristic.estimate(for: $0.state) < heuristic.estimate(for: $1.state)
        }

        for neighbor in orderedNeighbors {
            if activePathSet.contains(neighbor.state) {
                continue
            }

            path.append(neighbor.state)
            moves.append(neighbor.move)
            activePathSet.insert(neighbor.state)

            switch searchIDA(
                path: &path,
                moves: &moves,
                gCost: gCost + 1,
                bound: bound,
                activePathSet: &activePathSet
            ) {
            case .found:
                return .found
            case .nextBound(let candidateBound):
                minimumOverflow = min(minimumOverflow, candidateBound)
            }

            _ = path.popLast()
            _ = moves.popLast()
            activePathSet.remove(neighbor.state)
        }

        return .nextBound(minimumOverflow)
    }

    private func reconstructPath(from goal: SlidingPuzzleState,
                                 links: [SlidingPuzzleState: StateLink]) -> [SlidingPuzzleSolutionStep] {
        var reversed: [(SlidingPuzzleState, SlidingPuzzleMove?)] = []
        var cursor: SlidingPuzzleState? = goal

        while let state = cursor {
            let link = links[state]
            reversed.append((state, link?.moveFromParent))
            cursor = link?.parent
        }

        return reversed.reversed().enumerated().map { index, item in
            SlidingPuzzleSolutionStep(state: item.0, stepNumber: index, move: item.1)
        }
    }

    private func makeStepsFromPath(path: [SlidingPuzzleState],
                                   moves: [SlidingPuzzleMove]) -> [SlidingPuzzleSolutionStep] {
        path.enumerated().map { index, state in
            let move = index == 0 ? nil : moves[index - 1]
            return SlidingPuzzleSolutionStep(state: state, stepNumber: index, move: move)
        }
    }
}

private struct PriorityQueue<Element: Comparable> {
    private var storage: [Element] = []

    mutating func push(_ value: Element) {
        storage.append(value)
        siftUp(from: storage.count - 1)
    }

    mutating func pop() -> Element? {
        guard !storage.isEmpty else { return nil }
        if storage.count == 1 {
            return storage.removeLast()
        }

        let first = storage[0]
        storage[0] = storage.removeLast()
        siftDown(from: 0)
        return first
    }

    private mutating func siftUp(from index: Int) {
        var child = index
        var parent = parentIndex(of: child)

        while child > 0, storage[child] < storage[parent] {
            storage.swapAt(child, parent)
            child = parent
            parent = parentIndex(of: child)
        }
    }

    private mutating func siftDown(from index: Int) {
        var parent = index

        while true {
            let left = leftChildIndex(of: parent)
            let right = rightChildIndex(of: parent)
            var candidate = parent

            if left < storage.count, storage[left] < storage[candidate] {
                candidate = left
            }

            if right < storage.count, storage[right] < storage[candidate] {
                candidate = right
            }

            if candidate == parent { return }
            storage.swapAt(parent, candidate)
            parent = candidate
        }
    }

    private func parentIndex(of index: Int) -> Int { (index - 1) / 2 }
    private func leftChildIndex(of index: Int) -> Int { (2 * index) + 1 }
    private func rightChildIndex(of index: Int) -> Int { (2 * index) + 2 }
}
