//
//  KakuroSolver.swift
//  Puzzle Solver
//
//  Placeholder solver for future Kakuro support.
//

import Foundation

struct KakuroSolveResult {
    let state: SolveState = .unsupported
    let message = "Kakuro is planned for a future update."
}

final class KakuroSolver: LogicPuzzleSolving {
    func solve(_ board: KakuroBoard) -> KakuroSolveResult {
        KakuroSolveResult()
    }
}
