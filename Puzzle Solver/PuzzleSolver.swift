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

struct SlidingPuzzleState: Hashable {
    static let boardSize = 3
    static let tileCount = boardSize * boardSize
    static let goalTiles = [1, 2, 3, 4, 5, 6, 7, 8, 0]

    let tiles: [Int]

    init?(tiles: [Int]) {
        guard tiles.count == Self.tileCount else { return nil }
        let unique = Set(tiles)
        guard unique.count == Self.tileCount, unique == Set(0..<Self.tileCount) else { return nil }
        self.tiles = tiles
    }

    init?(board: [[Int?]]) {
        let flattened = board.flatMap { $0 }.map { $0 ?? 0 }
        self.init(tiles: flattened)
    }

    var isGoal: Bool {
        tiles == Self.goalTiles
    }

    var blankIndex: Int {
        tiles.firstIndex(of: 0) ?? 0
    }

    var blankRow: Int { blankIndex / Self.boardSize }
    var blankCol: Int { blankIndex % Self.boardSize }

    func neighbors() -> [(state: SlidingPuzzleState, move: SlidingPuzzleMove)] {
        var nextStates: [(SlidingPuzzleState, SlidingPuzzleMove)] = []

        for move in SlidingPuzzleMove.allCases {
            guard let target = targetIndex(for: move) else { continue }
            var nextTiles = tiles
            nextTiles.swapAt(blankIndex, target)
            if let nextState = SlidingPuzzleState(tiles: nextTiles) {
                nextStates.append((nextState, move))
            }
        }

        return nextStates
    }

    func manhattanDistance() -> Int {
        var distance = 0

        for (index, tile) in tiles.enumerated() where tile != 0 {
            let goalIndex = tile - 1
            let currentRow = index / Self.boardSize
            let currentCol = index % Self.boardSize
            let goalRow = goalIndex / Self.boardSize
            let goalCol = goalIndex % Self.boardSize
            distance += abs(currentRow - goalRow) + abs(currentCol - goalCol)
        }

        return distance
    }

    func isSolvable() -> Bool {
        // For odd-width boards (3x3), the puzzle is solvable when inversion count is even.
        let values = tiles.filter { $0 != 0 }
        var inversions = 0

        for i in 0..<values.count {
            for j in (i + 1)..<values.count where values[i] > values[j] {
                inversions += 1
            }
        }

        return inversions % 2 == 0
    }

    func asBoard() -> [[Int?]] {
        var board = Array(
            repeating: Array(repeating: Optional<Int>.none, count: Self.boardSize),
            count: Self.boardSize
        )

        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                let value = tiles[row * Self.boardSize + col]
                board[row][col] = value == 0 ? nil : value
            }
        }

        return board
    }

    private func targetIndex(for move: SlidingPuzzleMove) -> Int? {
        switch move {
        case .up:
            guard blankRow > 0 else { return nil }
            return blankIndex - Self.boardSize
        case .down:
            guard blankRow < Self.boardSize - 1 else { return nil }
            return blankIndex + Self.boardSize
        case .left:
            guard blankCol > 0 else { return nil }
            return blankIndex - 1
        case .right:
            guard blankCol < Self.boardSize - 1 else { return nil }
            return blankIndex + 1
        }
    }
}

struct SlidingPuzzleSolutionStep: Hashable {
    let state: SlidingPuzzleState
    let move: SlidingPuzzleMove?

    var moveLabel: String? {
        move?.label
    }
}

struct SlidingPuzzleSolveResult {
    let isSolvable: Bool
    let steps: [SlidingPuzzleSolutionStep]

    static func unsolvable(initial: SlidingPuzzleState) -> SlidingPuzzleSolveResult {
        SlidingPuzzleSolveResult(isSolvable: false, steps: [.init(state: initial, move: nil)])
    }
}

final class SlidingPuzzleSolver {
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

    func solve(from initialState: SlidingPuzzleState) -> SlidingPuzzleSolveResult {
        guard initialState.isSolvable() else {
            return .unsolvable(initial: initialState)
        }

        if initialState.isGoal {
            return SlidingPuzzleSolveResult(isSolvable: true, steps: [.init(state: initialState, move: nil)])
        }

        var frontier = PriorityQueue<FrontierNode>()
        var bestCostByState: [SlidingPuzzleState: Int] = [initialState: 0]
        var links: [SlidingPuzzleState: StateLink] = [
            initialState: StateLink(parent: nil, moveFromParent: nil)
        ]

        frontier.push(.init(state: initialState, gCost: 0, hCost: initialState.manhattanDistance()))

        while let current = frontier.pop() {
            guard current.gCost <= (bestCostByState[current.state] ?? Int.max) else { continue }

            if current.state.isGoal {
                let orderedSteps = reconstructPath(from: current.state, links: links)
                return SlidingPuzzleSolveResult(isSolvable: true, steps: orderedSteps)
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
                            hCost: neighbor.state.manhattanDistance()
                        )
                    )
                }
            }
        }

        return .unsolvable(initial: initialState)
    }

    private func reconstructPath(from goal: SlidingPuzzleState,
                                 links: [SlidingPuzzleState: StateLink]) -> [SlidingPuzzleSolutionStep] {
        var reversed: [SlidingPuzzleSolutionStep] = []
        var cursor: SlidingPuzzleState? = goal

        while let state = cursor {
            let link = links[state]
            reversed.append(.init(state: state, move: link?.moveFromParent))
            cursor = link?.parent
        }

        return reversed.reversed()
    }
}

private struct PriorityQueue<Element: Comparable> {
    private var storage: [Element] = []

    var isEmpty: Bool {
        storage.isEmpty
    }

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
