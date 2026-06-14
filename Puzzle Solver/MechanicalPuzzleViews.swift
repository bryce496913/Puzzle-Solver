//
//  MechanicalPuzzleViews.swift
//  Puzzle Solver
//
//  Mechanical puzzle menu and Rush Hour builder.
//

import SwiftUI

struct MechanicalPuzzleMenuView: View {
    private let descriptors = PuzzleAvailabilityCatalog.activeDescriptors(in: .mechanical)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.mechanical.rawValue, subtitle: PuzzleCategory.mechanical.subtitle) {
            LazyVStack(spacing: 12) {
                ForEach(descriptors) { descriptor in
                    NavigationLink(destination: destination(for: descriptor)) {
                        AppPuzzleCard(descriptor: descriptor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for descriptor: PuzzleAvailabilityDescriptor) -> some View {
        if descriptor.id == "rush-hour" {
            RushHourEntryView()
        } else {
            AppPlaceholderScreen(descriptor: descriptor)
        }
    }
}

struct RushHourEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var board = RushHourBoard.empty
    @State private var selectedVehicleID: String?
    @State private var orientation = RushHourOrientation.horizontal
    @State private var vehicleLength = 2
    @State private var isTarget = false
    @State private var placementMode = true
    @State private var message = "Choose vehicle details, then tap its starting cell."
    @State private var result: RushHourSolveResult?
    @State private var isSolving = false

    private var selectedVehicle: RushHourVehicle? {
        board.vehicles.first { $0.id == selectedVehicleID }
    }

    var body: some View {
        AppScreenContainer(
            title: "Rush Hour",
            subtitle: "Add vehicles to the 6×6 board, choose one red target car, then solve."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                RushHourBoardView(
                    board: board,
                    selectedVehicleID: selectedVehicleID,
                    onCellTap: handleCellTap
                )

                RushHourVehicleEditorView(
                    orientation: $orientation,
                    length: $vehicleLength,
                    isTarget: $isTarget,
                    placementMode: $placementMode,
                    selectedVehicle: selectedVehicle
                )

                Text(message)
                    .appParagraph()
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Rush Hour status: \(message)")

                HStack(spacing: 10) {
                    Button(placementMode ? "Adding Vehicle" : "Add Vehicle") {
                        placementMode = true
                        selectedVehicleID = nil
                        message = "Tap a starting cell to place the vehicle."
                    }
                    .buttonStyle(AppSecondaryButtonStyle())

                    Button("Remove Selected") { removeSelected() }
                        .buttonStyle(AppDangerButtonStyle())
                        .disabled(selectedVehicle == nil)
                }

                HStack(spacing: 10) {
                    Button("Load Example") { loadExample() }
                        .buttonStyle(AppSecondaryButtonStyle())
                    Button("Reset") { reset() }
                        .buttonStyle(AppResetButtonStyle())
                    Button("Validate") { validate() }
                        .buttonStyle(AppSecondaryButtonStyle())
                }

                Button(isSolving ? "Solving…" : "Solve Rush Hour") { solve() }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!board.isValid || isSolving)

                if isSolving {
                    HStack(spacing: 10) {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.text))
                        Text("Searching for the shortest solution…").appParagraph()
                    }
                }

                if let result {
                    RushHourResultView(result: result)
                }

                Button("Back") { dismiss() }
                    .buttonStyle(AppBackButtonStyle())
            }
            .appCardStyle()
        }
    }

    private func handleCellTap(_ row: Int, _ column: Int) {
        let cell = MechanicalBoardCoordinate(row: row, column: column)
        if let vehicle = board.vehicle(at: cell) {
            selectedVehicleID = vehicle.id
            placementMode = false
            message = "Selected vehicle \(vehicle.label)."
            return
        }
        guard placementMode else {
            selectedVehicleID = nil
            message = "No vehicle occupies that cell. Choose Add Vehicle to place one."
            return
        }
        if isTarget && board.vehicles.contains(where: \.isTarget) {
            message = "Only one red target car is allowed."
            return
        }

        let id = nextVehicleID()
        let vehicle = RushHourVehicle(
            id: id,
            label: isTarget ? "X" : id,
            orientation: orientation,
            length: vehicleLength,
            row: row,
            column: column,
            style: RushHourVehicleStyle.allCases[board.vehicles.count % RushHourVehicleStyle.allCases.count],
            isTarget: isTarget
        )
        let candidate = RushHourBoard(vehicles: board.vehicles + [vehicle])
        if let issue = RushHourBoardValidator.placementIssue(for: candidate) {
            message = issue
        } else {
            board = candidate
            selectedVehicleID = vehicle.id
            placementMode = false
            result = nil
            message = "Added \(isTarget ? "the red target car" : "vehicle \(vehicle.label)")."
        }
    }

    private func nextVehicleID() -> String {
        if isTarget { return "X" }
        let used = Set(board.vehicles.map(\.id))
        for scalar in UnicodeScalar("A").value...UnicodeScalar("Z").value {
            let value = String(UnicodeScalar(scalar)!)
            if value != "X" && !used.contains(value) { return value }
        }
        return "V\(board.vehicles.count + 1)"
    }

    private func removeSelected() {
        guard let selectedVehicleID else { return }
        board = RushHourBoard(vehicles: board.vehicles.filter { $0.id != selectedVehicleID })
        self.selectedVehicleID = nil
        result = nil
        placementMode = true
        message = "Vehicle removed. Tap a starting cell to add another."
    }

    private func loadExample() {
        board = .example
        selectedVehicleID = nil
        result = nil
        placementMode = false
        message = "Example loaded. The board is valid and ready to solve."
    }

    private func reset() {
        board = .empty
        selectedVehicleID = nil
        result = nil
        isSolving = false
        placementMode = true
        message = "Board cleared. Choose vehicle details, then tap a starting cell."
    }

    private func validate() {
        message = board.validationIssue ?? "Board is valid and ready to solve."
    }

    private func solve() {
        guard board.isValid else {
            validate()
            return
        }
        let boardToSolve = board
        result = nil
        isSolving = true
        message = "Searching for the shortest solution…"
        DispatchQueue.global(qos: .userInitiated).async {
            let solved = RushHourSolver().solve(boardToSolve)
            DispatchQueue.main.async {
                result = solved
                isSolving = false
                switch solved.status {
                case .solved: message = "Solution found in \(solved.moveCount) moves."
                case .invalid: message = solved.message ?? "This board is invalid."
                case .noSolution: message = "No solution found for this board."
                case .timedOut: message = "This puzzle took too long to solve. Try simplifying the board."
                case .failed: message = solved.message ?? "The solver could not finish."
                }
            }
        }
    }
}

struct RushHourVehicleEditorView: View {
    @Binding var orientation: RushHourOrientation
    @Binding var length: Int
    @Binding var isTarget: Bool
    @Binding var placementMode: Bool
    let selectedVehicle: RushHourVehicle?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppSectionHeader(
                selectedVehicle == nil ? "Add a vehicle" : "Selected vehicle",
                subtitle: selectedVehicle.map {
                    "\($0.isTarget ? "Red target car" : "Vehicle \($0.label)") • \($0.orientation.title) • Length \($0.length)"
                } ?? "Configure a piece and place it from its top-left cell."
            )
            Picker("Orientation", selection: $orientation) {
                ForEach(RushHourOrientation.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(!placementMode)

            Picker("Length", selection: $length) {
                Text("Length 2").tag(2)
                Text("Length 3").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(!placementMode)

            Toggle("Red target car", isOn: $isTarget)
                .font(AppTextStyle.h3)
                .foregroundColor(AppTheme.text)
                .disabled(!placementMode)
                .onChange(of: isTarget) { target in
                    if target { orientation = .horizontal }
                }
        }
    }
}

struct RushHourBoardView: View {
    let board: RushHourBoard
    var selectedVehicleID: String?
    var onCellTap: ((Int, Int) -> Void)?

    private let spacing: CGFloat = 3
    private let padding: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width - 22
            let cell = (side - padding * 2 - spacing * 5) / 6
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.surface)
                grid(cell: cell)
                ForEach(board.vehicles) { vehicle in vehicleView(vehicle, cell: cell) }
                exitView(cell: cell)
            }
            .frame(width: side, height: side)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.accent.opacity(0.75), lineWidth: 1.5))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Interactive six by six Rush Hour board")
    }

    private func grid(cell: CGFloat) -> some View {
        VStack(spacing: spacing) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<6, id: \.self) { column in
                        Button(action: { onCellTap?(row, column) }) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.background.opacity(0.82))
                                .frame(width: cell, height: cell)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Row \(row + 1), column \(column + 1)")
                    }
                }
            }
        }
        .padding(padding)
    }

    private func vehicleView(_ vehicle: RushHourVehicle, cell: CGFloat) -> some View {
        let width = vehicle.orientation == .horizontal ? CGFloat(vehicle.length) * cell + CGFloat(vehicle.length - 1) * spacing : cell
        let height = vehicle.orientation == .vertical ? CGFloat(vehicle.length) * cell + CGFloat(vehicle.length - 1) * spacing : cell
        return Button(action: { onCellTap?(vehicle.row, vehicle.column) }) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(vehicle.isTarget ? AppTheme.highlight : color(for: vehicle.style))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(selectedVehicleID == vehicle.id ? AppTheme.text : AppTheme.text.opacity(0.45),
                                lineWidth: selectedVehicleID == vehicle.id ? 3 : 1)
                )
                .overlay(Text(vehicle.label).font(AppTextStyle.h3).foregroundColor(AppTheme.text))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width, height: height)
        .offset(
            x: padding + CGFloat(vehicle.column) * (cell + spacing),
            y: padding + CGFloat(vehicle.row) * (cell + spacing)
        )
        .accessibilityLabel(vehicle.isTarget ? "Red target car" : "Vehicle \(vehicle.label)")
    }

    private func exitView(cell: CGFloat) -> some View {
        let row = board.targetVehicle?.row ?? 2
        return HStack(spacing: 2) {
            Rectangle().fill(AppTheme.highlight).frame(width: 4, height: cell * 0.68)
            Image(systemName: "arrow.right").font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.highlight)
        }
        .offset(x: padding + 6 * (cell + spacing) - spacing + 2,
                y: padding + CGFloat(row) * (cell + spacing) + cell * 0.16)
        .accessibilityLabel("Exit")
    }

    private func color(for style: RushHourVehicleStyle) -> Color {
        switch style {
        case .purple: return AppTheme.accent
        case .blue: return Color(red: 0.24, green: 0.48, blue: 0.92)
        case .teal: return Color(red: 0.12, green: 0.65, blue: 0.66)
        case .orange: return Color(red: 0.92, green: 0.48, blue: 0.18)
        case .indigo: return Color(red: 0.36, green: 0.30, blue: 0.82)
        case .green: return Color(red: 0.25, green: 0.66, blue: 0.38)
        }
    }
}

struct RushHourResultView: View {
    let result: RushHourSolveResult
    @State private var stepIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader("Solution", subtitle: result.message)
            if result.status == .solved, !result.steps.isEmpty {
                Text("\(result.moveCount) moves").appH2()
                RushHourBoardView(board: result.steps[stepIndex].board, selectedVehicleID: nil, onCellTap: nil)
                Text("Step \(stepIndex) of \(result.moveCount): \(result.steps[stepIndex].moveLabel)").appH3()
                HStack(spacing: 10) {
                    Button("Previous") { stepIndex = max(0, stepIndex - 1) }
                        .buttonStyle(AppSecondaryButtonStyle()).disabled(stepIndex == 0)
                    Button("Next") { stepIndex = min(result.steps.count - 1, stepIndex + 1) }
                        .buttonStyle(AppPrimaryButtonStyle()).disabled(stepIndex == result.steps.count - 1)
                    Button("Restart") { stepIndex = 0 }
                        .buttonStyle(AppSecondaryButtonStyle()).disabled(stepIndex == 0)
                }
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.steps.dropFirst()) { step in
                        Text("\(step.stepNumber). \(step.moveLabel)").appParagraph()
                    }
                }
            } else {
                Text(result.message ?? "The solver could not produce a solution.").appParagraph()
            }
        }
        .onChange(of: result.status) { _ in stepIndex = 0 }
    }
}

// Keep the old destination name available for existing navigation and previews.
typealias RushHourView = RushHourEntryView

struct MechanicalPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { MechanicalPuzzleMenuView() }
    }
}
