import SwiftUI

struct RushHourEntryView: View {
    @State private var vehicles: [EditableRushHourVehicle] = [
        EditableRushHourVehicle(
            id: UUID(),
            label: "A",
            orientation: .horizontal,
            length: 2,
            row: 2,
            column: 0,
            isTarget: true
        )
    ]
    @State private var validationMessage: String?
    @State private var resultDestination: RushHourResultDestination?

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Rush Hour Entry",
                subtitle: "Build a 6×6 board, then validate and solve."
            )

            boardCard
                .appSurfaceCard()

            vehicleEditorCard
                .appSurfaceCard()

            if let validationMessage {
                TwistyInlineStatusMessage(message: validationMessage)
            }

            Button("Solve") {
                validateAndSolve()
            }
            .buttonStyle(AppPrimaryButtonStyle())

            Button("Reset") {
                resetBoard()
            }
            .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))
        }
        .navigationTitle("Rush Hour")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $resultDestination) { destination in
            RushHourSolvingView(
                initialBoard: destination.board,
                initialValidationMessage: destination.validationMessage
            )
        }
    }

    private var boardCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Board Preview (6×6)")
                .appTextStyle(.h2)

            RushHourBoardPreview(vehicles: vehicles)

            Text("Set one vehicle as the red target car. The solver uses an exit on the right wall at that car's row.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
        }
    }

    private var vehicleEditorCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Vehicles")
                    .appTextStyle(.h2)

                Spacer()

                Button {
                    addVehicle()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))
                .frame(maxWidth: 120)
            }

            ForEach($vehicles) { $vehicle in
                EditableRushHourVehicleRow(
                    vehicle: $vehicle,
                    onDelete: { deleteVehicle(id: vehicle.id) },
                    onToggleTarget: { setTarget(id: vehicle.id) }
                )
                .padding(.vertical, AppTheme.Spacing.xSmall)

                if vehicle.id != vehicles.last?.id {
                    Divider().overlay(AppTheme.Colors.text.opacity(0.15))
                }
            }
        }
    }

    private func addVehicle() {
        let newLabel = nextVehicleLabel()
        vehicles.append(
            EditableRushHourVehicle(
                id: UUID(),
                label: newLabel,
                orientation: .horizontal,
                length: 2,
                row: 0,
                column: 0,
                isTarget: false
            )
        )
    }

    private func deleteVehicle(id: UUID) {
        vehicles.removeAll { $0.id == id }
    }

    private func setTarget(id: UUID) {
        for index in vehicles.indices {
            vehicles[index].isTarget = vehicles[index].id == id
        }
    }

    private func resetBoard() {
        vehicles = [
            EditableRushHourVehicle(
                id: UUID(),
                label: "A",
                orientation: .horizontal,
                length: 2,
                row: 2,
                column: 0,
                isTarget: true
            )
        ]
        validationMessage = nil
        resultDestination = nil
    }

    private func validateAndSolve() {
        validationMessage = nil

        guard !vehicles.isEmpty else {
            presentInvalidResult(message: "Add at least one vehicle before solving.")
            return
        }

        guard vehicles.filter(\.isTarget).count == 1 else {
            presentInvalidResult(message: "Choose exactly one red target car.")
            return
        }

        let domainVehicles = vehicles.compactMap { editable in
            RushHourVehicle(
                id: editable.label,
                orientation: editable.orientation,
                length: editable.length,
                row: editable.row,
                column: editable.column,
                isTarget: editable.isTarget
            )
        }

        guard domainVehicles.count == vehicles.count else {
            presentInvalidResult(message: "One or more vehicles are out of bounds for the 6×6 board.")
            return
        }

        guard let target = domainVehicles.first(where: \.isTarget) else {
            presentInvalidResult(message: "Choose a target car before solving.")
            return
        }

        guard let exit = RushHourExit(wall: .right, index: target.row) else {
            presentInvalidResult(message: "Target row is invalid for the exit.")
            return
        }

        guard let board = RushHourBoardState(vehicles: domainVehicles, exit: exit) else {
            presentInvalidResult(message: "Vehicle placements overlap or are invalid. Please adjust and try again.")
            return
        }

        resultDestination = RushHourResultDestination(board: board, validationMessage: nil)
    }

    private func presentInvalidResult(message: String) {
        validationMessage = message
        resultDestination = RushHourResultDestination(board: nil, validationMessage: message)
    }

    private func nextVehicleLabel() -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        for char in alphabet {
            let candidate = String(char)
            if !vehicles.map(\.label).contains(candidate) {
                return candidate
            }
        }
        return "V\(vehicles.count + 1)"
    }
}

private struct RushHourResultDestination: Identifiable {
    let id = UUID()
    let board: RushHourBoardState?
    let validationMessage: String?
}

private struct EditableRushHourVehicle: Identifiable, Equatable {
    let id: UUID
    var label: String
    var orientation: RushHourOrientation
    var length: Int
    var row: Int
    var column: Int
    var isTarget: Bool
}

private struct EditableRushHourVehicleRow: View {
    @Binding var vehicle: EditableRushHourVehicle
    let onDelete: () -> Void
    let onToggleTarget: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(vehicle.isTarget ? "🔴 \(vehicle.label)" : "Car \(vehicle.label)")
                    .appTextStyle(.h3)

                Spacer()

                Button(vehicle.isTarget ? "Target" : "Set Target") {
                    onToggleTarget()
                }
                .buttonStyle(AppSolidButtonStyle(fillColor: vehicle.isTarget ? AppTheme.Colors.highlight : AppTheme.Colors.surface))
                .frame(maxWidth: 140)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppTheme.Colors.text)
                        .padding(.horizontal, AppTheme.Spacing.small)
                }
                .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))
                .frame(maxWidth: 70)
            }

            HStack(spacing: AppTheme.Spacing.small) {
                Picker("Orientation", selection: $vehicle.orientation) {
                    Text("Horizontal").tag(RushHourOrientation.horizontal)
                    Text("Vertical").tag(RushHourOrientation.vertical)
                }
                .pickerStyle(.segmented)

                Picker("Length", selection: $vehicle.length) {
                    Text("2").tag(2)
                    Text("3").tag(3)
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: AppTheme.Spacing.small) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Row")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.8))
                    Stepper(value: $vehicle.row, in: 0...5) {
                        Text("\(vehicle.row)")
                            .appTextStyle(.h3)
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Column")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.8))
                    Stepper(value: $vehicle.column, in: 0...5) {
                        Text("\(vehicle.column)")
                            .appTextStyle(.h3)
                    }
                }
            }
        }
    }
}

private struct RushHourBoardPreview: View {
    let vehicles: [EditableRushHourVehicle]

    private var boardMap: [String: EditableRushHourVehicle] {
        var map: [String: EditableRushHourVehicle] = [:]
        for vehicle in vehicles {
            let cells = occupiedCells(for: vehicle)
            for cell in cells {
                map["\(cell.row)-\(cell.column)"] = vehicle
            }
        }
        return map
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.xSmall), count: 6)

        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.xSmall) {
            ForEach(0..<6, id: \.self) { row in
                ForEach(0..<6, id: \.self) { column in
                    let key = "\(row)-\(column)"
                    let vehicle = boardMap[key]

                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(vehicle == nil ? AppTheme.Colors.background.opacity(0.35) : (vehicle?.isTarget == true ? AppTheme.Colors.highlight : AppTheme.Colors.accent.opacity(0.9)))

                        Text(vehicle?.label ?? "")
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(AppTheme.Colors.text.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func occupiedCells(for vehicle: EditableRushHourVehicle) -> [(row: Int, column: Int)] {
        (0..<vehicle.length).map { offset in
            switch vehicle.orientation {
            case .horizontal:
                return (vehicle.row, vehicle.column + offset)
            case .vertical:
                return (vehicle.row + offset, vehicle.column)
            }
        }
    }
}

struct RushHourSolvingView: View {
    let initialBoard: RushHourBoardState?
    let initialValidationMessage: String?

    @State private var phase: RushHourSolvePhase = .loading

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Rush Hour Solve",
                subtitle: "Computing shortest move sequence."
            )

            switch phase {
            case .loading:
                MechanicalSolveLoadingCard(title: "Solving Rush Hour…")
            case .invalid(let message):
                MechanicalInvalidBoardCard(message: message)
            case .unsolved(let result):
                summaryCard(result: result)
                MechanicalNoSolutionCard(
                    message: "No solution found from this board state. Try moving blocker cars or changing the target lane."
                )
            case .solved(let result):
                summaryCard(result: result)
                MechanicalOrderedStepsHeader(stepCount: result.orderedSteps.count)
                ForEach(result.orderedSteps) { step in
                    MechanicalResultStepCard(
                        stepNumber: step.stepNumber,
                        moveLabel: step.move?.notation ?? "Initial",
                        instruction: step.instruction
                    ) {
                        if let boardState = step.boardState {
                            RushHourBoardStatePreview(board: boardState)
                        } else {
                            Text("Board preview unavailable")
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
                        }
                    }
                }
            }
        }
        .task {
            await solve()
        }
    }

    private func summaryCard(result: MechanicalSolveResult<RushHourBoardState>) -> some View {
        MechanicalSolveSummaryCard(
            isSolved: result.isSolved,
            moveCount: result.moveCount,
            stepCount: result.orderedSteps.count
        )
    }

    @MainActor
    private func solve() async {
        if let initialValidationMessage {
            phase = .invalid(initialValidationMessage)
            return
        }

        guard let initialBoard else {
            phase = .invalid("This board could not be loaded for solving.")
            return
        }

        phase = .loading
        let result = await RushHourSolver().solve(from: initialBoard)
        phase = result.isSolved ? .solved(result) : .unsolved(result)
    }
}

private enum RushHourSolvePhase {
    case loading
    case invalid(String)
    case unsolved(MechanicalSolveResult<RushHourBoardState>)
    case solved(MechanicalSolveResult<RushHourBoardState>)
}

private struct RushHourBoardStatePreview: View {
    let board: RushHourBoardState

    private var boardMap: [String: RushHourVehicle] {
        var map: [String: RushHourVehicle] = [:]
        for vehicle in board.vehicles {
            for cell in vehicle.occupiedCells {
                map["\(cell.row)-\(cell.column)"] = vehicle
            }
        }
        return map
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.xSmall), count: RushHourBoardState.gridSize)

        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.xSmall) {
            ForEach(0..<RushHourBoardState.gridSize, id: \.self) { row in
                ForEach(0..<RushHourBoardState.gridSize, id: \.self) { column in
                    let key = "\(row)-\(column)"
                    let vehicle = boardMap[key]

                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(vehicleColor(for: vehicle))

                        Text(vehicle?.id ?? "")
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(AppTheme.Colors.text.opacity(0.28), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func vehicleColor(for vehicle: RushHourVehicle?) -> Color {
        guard let vehicle else {
            return AppTheme.Colors.background.opacity(0.35)
        }

        return vehicle.isTarget ? AppTheme.Colors.highlight : AppTheme.Colors.accent.opacity(0.9)
    }
}

#Preview {
    NavigationStack {
        RushHourEntryView()
    }
}
