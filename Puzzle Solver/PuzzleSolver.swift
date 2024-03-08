//
//  PuzzleSolver.swift
//  Puzzle Solver
//
//  Created by Aditi Abrol on 2/3/24.
//

import Foundation

enum Direction {
    case up, down, left, right
}

struct AStarPuzzle {
    var heuristics: Int
    var boardPathStateList: [[[String]]]
    var movementHistory: [String]
}

class PuzzleSolver {
    var state: [[String]] = []
    let endState = [["1","2","3"],
                    ["4","5","6"],
                    ["7","8","0"]]
    
    func availableMoves(state: [[String]]) -> [[[String]]] {
        var possibleBoardStates: [[[String]]] = []
        let tmpState = state
        
        if let i = tmpState.firstIndex(where: { $0.contains("0") }),
           let j = tmpState[i].firstIndex(of: "0") {
            if i < 2 {
                possibleBoardStates += (movePieceInDirection(.down, board: state, piece: (i, j)))
            }
            
            if i > 0 {
                possibleBoardStates += (movePieceInDirection(.up, board: state, piece: (i, j)))
            }
            
            if j < 2 {
                possibleBoardStates += (movePieceInDirection(.right, board: state, piece: (i, j)))
            }
            
            if j > 0 {
                possibleBoardStates += (movePieceInDirection(.left, board: state, piece: (i, j)))
            }
        }
        
        return possibleBoardStates
    }
    
    func movePieceInDirection(_ direction: Direction, board: [[String]], piece: (Int, Int)) -> [[[String]]] {
        var movements: [[[String]]] = []
        switch direction {
        case .up:
            var boardCopy = board
            let tmp = boardCopy[piece.0][piece.1]
            boardCopy[piece.0][piece.1] = boardCopy[piece.0 - 1][piece.1]
            boardCopy[piece.0 - 1][piece.1] = tmp
            movements.append(boardCopy)
        case .down:
            var boardCopy = board
            let tmp = boardCopy[piece.0][piece.1]
            boardCopy[piece.0][piece.1] = boardCopy[piece.0 + 1][piece.1]
            boardCopy[piece.0 + 1][piece.1] = tmp
            movements.append(boardCopy)
        case .left:
            var boardCopy = board
            let tmp = boardCopy[piece.0][piece.1]
            boardCopy[piece.0][piece.1] = boardCopy[piece.0][piece.1 - 1]
            boardCopy[piece.0][piece.1 - 1] = tmp
            movements.append(boardCopy)
        case .right:
            var boardCopy = board
            let tmp = boardCopy[piece.0][piece.1]
            boardCopy[piece.0][piece.1] = boardCopy[piece.0][piece.1 + 1]
            boardCopy[piece.0][piece.1 + 1] = tmp
            movements.append(boardCopy)
        }
        
        return movements
    }
    
    func misplacedPiecesHeuristic(state: [[String]]) -> Int {
        var misplaced = 0
        var comparator = 1
        for line in state {
            for number in line {
                if number != "\(comparator)" {
                    misplaced += 1
                }
                comparator += 1
            }
        }
        
        return misplaced
    }
    
    func aStarSearch(start: [[String]]) -> AStarPuzzle {
        var explored = [[[String]]]()
        var pathList = [AStarPuzzle(heuristics: misplacedPiecesHeuristic(state: start), boardPathStateList: [start], movementHistory: [])] // Initialize movement history for start state
        var path: AStarPuzzle = AStarPuzzle(heuristics: 1, boardPathStateList: [], movementHistory: [])
        
        while !pathList.isEmpty {
            let currentBestHeuristicIndex = pathList.indices.reduce(0) { pathList[$1].heuristics < pathList[$0].heuristics ? $1 : $0 }
            path = pathList.remove(at: currentBestHeuristicIndex)
            
            let finalStateBoardFromBestHeuristic = path.boardPathStateList.last!
            if explored.contains(finalStateBoardFromBestHeuristic) { continue }
            
            for movement in availableMoves(state: finalStateBoardFromBestHeuristic) {
                if explored.contains(movement) { continue }
                
                let heuristic = path.heuristics + misplacedPiecesHeuristic(state: movement) + misplacedPiecesHeuristic(state: finalStateBoardFromBestHeuristic)
                let new = path.boardPathStateList + [movement]
                
                // Get the direction of the movement
                guard let directionString = directionString(from: path.boardPathStateList.last!, to: movement) else {
                    continue
                }
                
                let newMovementHistory = path.movementHistory + [directionString] // Append direction to movement history
                pathList.append(AStarPuzzle(heuristics: heuristic, boardPathStateList: new, movementHistory: newMovementHistory))
            }
            
            explored.append(finalStateBoardFromBestHeuristic)
            if finalStateBoardFromBestHeuristic == endState {
                break
            }
        }
        
        return path
    }
    
    // Helper function to determine direction of movement
    private func directionString(from: [[String]], to: [[String]]) -> String? {
        // Find the index of the empty space in 'from' and 'to' boards
        guard let fromIndex = findIndex(of: "0", in: from), let toIndex = findIndex(of: "0", in: to) else {
            return nil
        }
        
        // Calculate the movement direction based on the difference between indices
        let rowDiff = toIndex.row - fromIndex.row
        let colDiff = toIndex.col - fromIndex.col
        
        switch (rowDiff, colDiff) {
        case (-1, 0): return "up"
        case (1, 0): return "down"
        case (0, -1): return "left"
        case (0, 1): return "right"
        default: return nil
        }
    }
    
    // Helper function to find the index of a value in a 2D array
    private func findIndex(of value: String, in board: [[String]]) -> (row: Int, col: Int)? {
        for (i, row) in board.enumerated() {
            if let col = row.firstIndex(of: value) {
                return (i, col)
            }
        }
        return nil
    }
}

