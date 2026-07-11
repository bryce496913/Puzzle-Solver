//
//  SudokuImageImport.swift
//  Puzzle Solver
//
//  Local camera/photo Sudoku import pipeline and review UI.
//

import SwiftUI
import UIKit
@preconcurrency import Vision
import CoreImage
import CoreGraphics
import AVFoundation
import PhotosUI

struct SudokuScanConfiguration {
    static let highConfidence: Float = 0.82
    static let mediumConfidence: Float = 0.58
    static let minimumCluesForReview = 8
    static let processingBoardSize: CGFloat = 900
    static let innerCellPaddingRatio: CGFloat = 0.16
    static let minimumInkDensity: CGFloat = 0.010
    static let maximumBlankInkDensity: CGFloat = 0.006
}

struct SudokuDetectedCell: Identifiable, Equatable, Hashable {
    enum SourceType: String { case imported, detected, manual }
    enum ReviewState: String { case blank, highConfidence, needsReview, lowConfidence, conflict }
    var id: String { "\(row)-\(column)" }
    let row: Int
    let column: Int
    var recognizedValue: Int?
    var confidence: Float?
    var sourceType: SourceType = .imported
    var reviewState: ReviewState = .blank
    var needsReview: Bool { reviewState == .needsReview || reviewState == .lowConfidence || reviewState == .conflict }
}

struct SudokuScanResult: Equatable, Identifiable {
    let id = UUID()
    var cells: [SudokuDetectedCell]
    var message: String? = nil
    var diagnostics: [String] = []
    var detectedCount: Int { cells.filter { $0.recognizedValue != nil }.count }
    var reviewCount: Int { cells.filter(\.needsReview).count }
    var conflictCount: Int { SudokuValidator.conflictingCoordinates(in: board).count }
    var board: SudokuBoard {
        var values = Array(repeating: Array<Int?>(repeating: nil, count: SudokuBoard.dimension), count: SudokuBoard.dimension)
        var givens = Set<LogicGridCoordinate>()
        for cell in cells where SudokuBoard.validDigits.contains(cell.recognizedValue ?? 0) {
            values[cell.row][cell.column] = cell.recognizedValue
            givens.insert(LogicGridCoordinate(row: cell.row, column: cell.column))
        }
        return SudokuBoard(values: values, givens: givens)
    }
}

typealias SudokuImageImportResult = SudokuScanResult

enum SudokuScanState: Equatable {
    case idle, loadingImage, detectingBoard, correctingPerspective, readingCells, validating, readyForReview, failed, cancelled
    var progressText: String {
        switch self {
        case .idle: return "Ready to scan."
        case .loadingImage: return "Loading image…"
        case .detectingBoard: return "Finding Sudoku board…"
        case .correctingPerspective: return "Straightening board…"
        case .readingCells: return "Reading cells…"
        case .validating: return "Checking detected numbers…"
        case .readyForReview: return "Preparing review…"
        case .failed: return "Scanning stopped."
        case .cancelled: return "Scan cancelled."
        }
    }
}

enum SudokuImageImportError: LocalizedError, Equatable {
    case cameraPermissionDenied, photoLibraryPermissionDenied, imageCouldNotBeLoaded, boardCouldNotBeDetected, incorrectCrop, boardTooBlurry, ocrCouldNotReadEnoughNumbers, detectedPuzzleHasConflicts(String), importCancelled, processingFailure(String)
    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied: return "Camera permission denied. You can choose a photo or enter the Sudoku manually."
        case .photoLibraryPermissionDenied: return "Photo library permission denied. You can enter the Sudoku manually."
        case .imageCouldNotBeLoaded: return "Image could not be loaded. Try another image or enter it manually."
        case .boardCouldNotBeDetected: return "We could not clearly detect the Sudoku board. Try taking the photo straight above the puzzle."
        case .incorrectCrop: return "We could not find the full Sudoku board. Make sure all four corners are visible."
        case .boardTooBlurry: return "The image is too blurry. Try taking another photo in brighter light."
        case .ocrCouldNotReadEnoughNumbers: return "Some numbers could not be read. Review the highlighted cells or enter them manually."
        case .detectedPuzzleHasConflicts(let detail): return "Detected puzzle contains conflicts. \(detail) Review highlighted cells or enter them manually."
        case .importCancelled: return "Import cancelled. Manual entry is still available."
        case .processingFailure(let detail): return "Processing failed. \(detail) Try another photo or enter the puzzle manually."
        }
    }
}

@MainActor
final class SudokuImageImportViewModel: ObservableObject {
    enum Source { case camera, photoLibrary }
    @Published var selectedSource: Source?
    @Published var isProcessing = false
    @Published var statusText = ""
    @Published var errorMessage: String?
    @Published var reviewResult: SudokuImageImportResult?
    @Published var scanState: SudokuScanState = .idle
    private let processor = SudokuScanCoordinator()

    func begin(_ source: Source) { errorMessage = nil; source == .camera ? requestCamera() : requestPhotoLibrary() }
    func process(_ image: UIImage?) {
        guard let image else { scanState = .cancelled; errorMessage = SudokuImageImportError.importCancelled.localizedDescription; return }
        isProcessing = true; updateState(.loadingImage)
        Task {
            do {
                reviewResult = try await processor.process(image: image) { [weak self] state in Task { @MainActor in self?.updateState(state) } }
                updateState(.readyForReview)
            } catch let error as SudokuImageImportError { updateState(.failed); errorMessage = error.localizedDescription }
            catch { updateState(.failed); errorMessage = SudokuImageImportError.processingFailure(error.localizedDescription).localizedDescription }
            isProcessing = false; selectedSource = nil
        }
    }
    private func updateState(_ state: SudokuScanState) { scanState = state; statusText = state.progressText }
    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { errorMessage = "Camera is not available on this device. Choose Photo or enter manually."; return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: selectedSource = .camera
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { granted in Task { @MainActor in granted ? (self.selectedSource = .camera) : (self.errorMessage = SudokuImageImportError.cameraPermissionDenied.localizedDescription) } }
        default: errorMessage = SudokuImageImportError.cameraPermissionDenied.localizedDescription
        }
    }
    private func requestPhotoLibrary() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited: selectedSource = .photoLibrary
        case .notDetermined: PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in Task { @MainActor in (newStatus == .authorized || newStatus == .limited) ? (self.selectedSource = .photoLibrary) : (self.errorMessage = SudokuImageImportError.photoLibraryPermissionDenied.localizedDescription) } }
        default: errorMessage = SudokuImageImportError.photoLibraryPermissionDenied.localizedDescription
        }
    }
}

struct SudokuImageImportView: View {
    @StateObject private var viewModel = SudokuImageImportViewModel()
    let onUsePuzzle: (SudokuBoard) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scan Sudoku").font(AppTextStyle.h3).foregroundColor(AppTheme.text)
            Text("Place the full Sudoku board inside the frame. Hold the phone directly above the puzzle. Avoid shadows and glare. Make sure all four corners are visible.").font(AppTextStyle.paragraph).foregroundColor(AppTheme.text.opacity(0.85))
            ZStack { RoundedRectangle(cornerRadius: 10).stroke(AppTheme.highlight.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [8, 6])).aspectRatio(1, contentMode: .fit); Text("Align board inside this guide").font(AppTextStyle.paragraph).foregroundColor(AppTheme.text.opacity(0.7)) }.frame(maxHeight: 160)
            HStack(spacing: 12) { Button("Scan Sudoku") { viewModel.begin(.camera) }.buttonStyle(AppPrimaryButtonStyle()); Button("Choose Photo") { viewModel.begin(.photoLibrary) }.buttonStyle(AppSecondaryButtonStyle()) }
            if viewModel.isProcessing { HStack { ProgressView(); Text(viewModel.statusText).font(AppTextStyle.paragraph).foregroundColor(AppTheme.text) } }
            if let error = viewModel.errorMessage { Text(error).font(AppTextStyle.paragraph).foregroundColor(AppTheme.highlight) }
        }.padding(10).background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .sheet(item: Binding(get: { viewModel.selectedSource.map { SourceSheet(source: $0) } }, set: { if $0 == nil { viewModel.selectedSource = nil } })) { wrapper in SudokuImagePicker(sourceType: wrapper.source == .camera ? .camera : .photoLibrary) { image in viewModel.process(image) } }
        .sheet(item: $viewModel.reviewResult) { result in SudokuScanReviewView(result: result, onUsePuzzle: { board in onUsePuzzle(board); viewModel.reviewResult = nil }, onRescan: { viewModel.reviewResult = nil; viewModel.begin(.camera) }, onRetake: { viewModel.reviewResult = nil; viewModel.begin(.camera) }, onChooseAnother: { viewModel.reviewResult = nil; viewModel.begin(.photoLibrary) }, onManual: { viewModel.reviewResult = nil }) }
    }
    private struct SourceSheet: Identifiable { let source: SudokuImageImportViewModel.Source; var id: Int { source == .camera ? 0 : 1 } }
}

struct SudokuImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType; let onImage: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }
    func makeUIViewController(context: Context) -> UIImagePickerController { let picker = UIImagePickerController(); picker.sourceType = sourceType; picker.delegate = context.coordinator; return picker }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate { let onImage: (UIImage?) -> Void; init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }; func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { picker.dismiss(animated: true); onImage(info[.originalImage] as? UIImage) }; func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true); onImage(nil) } }
}

final class SudokuScanCoordinator {
    private let preprocessor = SudokuImagePreprocessor(); private let detector = SudokuBoardDetector(); private let corrector = SudokuPerspectiveCorrector(); private let segmenter = SudokuGridSegmenter(); private let ocr = SudokuCellOCRService()
    func process(image: UIImage, progress: @escaping (SudokuScanState) -> Void) async throws -> SudokuScanResult {
        try await Task.detached(priority: .userInitiated) { [preprocessor, detector, corrector, segmenter, ocr] in
            progress(.loadingImage); let prepared = try preprocessor.prepare(image)
            progress(.detectingBoard); let detection = try detector.detectBoard(in: prepared.normalized)
            progress(.correctingPerspective); let board = try corrector.correct(image: prepared.contrast, detection: detection)
            progress(.readingCells); var cells = try await ocr.recognize(cells: segmenter.segment(board))
            progress(.validating); cells = SudokuScanValidator.markReviewStates(cells)
            guard cells.filter({ $0.recognizedValue != nil }).count >= SudokuScanConfiguration.minimumCluesForReview else { throw SudokuImageImportError.ocrCouldNotReadEnoughNumbers }
            return SudokuScanResult(cells: cells, message: SudokuScanValidator.summary(for: cells), diagnostics: SudokuDiagnostics.messages(for: cells))
        }.value
    }
}

struct SudokuPreparedImage { let normalized: UIImage; let grayscale: UIImage; let contrast: UIImage; let threshold: UIImage }

final class SudokuImagePreprocessor {
    private let context = CIContext()
    func prepare(_ image: UIImage) throws -> SudokuPreparedImage {
        guard let normalized = image.normalizedForSudokuImport(), let cg = normalized.cgImage else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        let base = CIImage(cgImage: cg)
        let scaled = base.transformed(by: CGAffineTransform(scaleX: min(1, SudokuScanConfiguration.processingBoardSize / max(base.extent.width, base.extent.height)), y: min(1, SudokuScanConfiguration.processingBoardSize / max(base.extent.width, base.extent.height))))
        let gray = scaled.applyingFilter("CIPhotoEffectMono")
        let contrast = gray.applyingFilter("CIColorControls", parameters: [kCIInputContrastKey: 1.35, kCIInputBrightnessKey: 0.02])
        let threshold = contrast.applyingFilter("CIColorControls", parameters: [kCIInputContrastKey: 1.85]).applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: 0.45])
        return try SudokuPreparedImage(normalized: render(scaled, scale: normalized.scale), grayscale: render(gray, scale: normalized.scale), contrast: render(contrast, scale: normalized.scale), threshold: render(threshold, scale: normalized.scale))
    }
    private func render(_ image: CIImage, scale: CGFloat) throws -> UIImage { guard let cg = context.createCGImage(image, from: image.extent) else { throw SudokuImageImportError.processingFailure("Could not render preprocessed image.") }; return UIImage(cgImage: cg, scale: scale, orientation: .up) }
}

struct SudokuBoardDetection { let corners: [CGPoint]; let confidence: Float }

final class SudokuBoardDetector {
    func detectBoard(in image: UIImage) throws -> SudokuBoardDetection {
        guard let cgImage = image.cgImage else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        let request = VNDetectRectanglesRequest(); request.minimumAspectRatio = 0.78; request.maximumAspectRatio = 1.22; request.minimumSize = 0.30; request.quadratureTolerance = 18; request.maximumObservations = 8
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        let imageArea = image.size.width * image.size.height
        let candidates = (request.results ?? []).map { observation -> SudokuBoardDetection in
            let corners = [observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft].map { CGPoint(x: $0.x * image.size.width, y: (1 - $0.y) * image.size.height) }
            let rect = CGRect(x: corners.map(\.x).min() ?? 0, y: corners.map(\.y).min() ?? 0, width: (corners.map(\.x).max() ?? 0) - (corners.map(\.x).min() ?? 0), height: (corners.map(\.y).max() ?? 0) - (corners.map(\.y).min() ?? 0))
            let aspectScore = Float(1 - min(abs(rect.width / max(rect.height, 1) - 1), 1)); let areaScore = Float(min((rect.width * rect.height) / max(imageArea, 1), 1)); return SudokuBoardDetection(corners: corners, confidence: observation.confidence * 0.55 + aspectScore * 0.25 + areaScore * 0.20)
        }.sorted { $0.confidence > $1.confidence }
        if let best = candidates.first, best.confidence >= 0.35 { return best }
        if image.size.width > 200 && image.size.height > 200 { return SudokuBoardDetection(corners: [CGPoint(x: 0, y: 0), CGPoint(x: image.size.width, y: 0), CGPoint(x: image.size.width, y: image.size.height), CGPoint(x: 0, y: image.size.height)], confidence: 0.35) }
        throw SudokuImageImportError.boardCouldNotBeDetected
    }
}

final class SudokuPerspectiveCorrector {
    private let context = CIContext()
    func correct(image: UIImage, detection: SudokuBoardDetection) throws -> UIImage {
        guard let cg = image.cgImage else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        let ci = CIImage(cgImage: cg); let height = image.size.height
        func vector(_ point: CGPoint) -> CIVector { CIVector(x: point.x, y: height - point.y) }
        let corrected = ci.applyingFilter("CIPerspectiveCorrection", parameters: ["inputTopLeft": vector(detection.corners[0]), "inputTopRight": vector(detection.corners[1]), "inputBottomRight": vector(detection.corners[2]), "inputBottomLeft": vector(detection.corners[3])])
        let square = corrected.cropped(to: corrected.extent).transformed(by: CGAffineTransform(scaleX: SudokuScanConfiguration.processingBoardSize / max(corrected.extent.width, 1), y: SudokuScanConfiguration.processingBoardSize / max(corrected.extent.height, 1)))
        guard let output = context.createCGImage(square, from: CGRect(x: 0, y: 0, width: SudokuScanConfiguration.processingBoardSize, height: SudokuScanConfiguration.processingBoardSize)) else { throw SudokuImageImportError.incorrectCrop }
        return UIImage(cgImage: output, scale: image.scale, orientation: .up)
    }
}

struct SudokuSegmentedCell { let row: Int; let column: Int; let original: UIImage; let enhanced: UIImage; let inkDensity: CGFloat }

final class SudokuGridSegmenter {
    private let preprocessor = SudokuImagePreprocessor()
    func segment(_ board: UIImage) throws -> [SudokuSegmentedCell] {
        guard let cg = board.cgImage else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        let cellWidth = CGFloat(cg.width) / 9; let cellHeight = CGFloat(cg.height) / 9; let insetX = cellWidth * SudokuScanConfiguration.innerCellPaddingRatio; let insetY = cellHeight * SudokuScanConfiguration.innerCellPaddingRatio
        return try (0..<9).flatMap { row in try (0..<9).map { column in
            let rect = CGRect(x: CGFloat(column) * cellWidth + insetX, y: CGFloat(row) * cellHeight + insetY, width: cellWidth - insetX * 2, height: cellHeight - insetY * 2).integral
            guard let crop = cg.cropping(to: rect) else { throw SudokuImageImportError.incorrectCrop }
            let original = UIImage(cgImage: crop, scale: board.scale, orientation: .up)
            let enhanced = try preprocessor.prepare(original).threshold
            return SudokuSegmentedCell(row: row, column: column, original: original, enhanced: enhanced, inkDensity: SudokuGridSegmenter.inkDensity(in: enhanced))
        } }
    }
    static func inkDensity(in image: UIImage) -> CGFloat {
        guard let cg = image.cgImage, let data = cg.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return 0 }
        let count = CFDataGetLength(data); guard count > 0 else { return 0 }
        var dark = 0; stride(from: 0, to: count, by: max(cg.bitsPerPixel / 8, 1)).forEach { if bytes[$0] < 110 { dark += 1 } }
        return CGFloat(dark) / CGFloat(max(count / max(cg.bitsPerPixel / 8, 1), 1))
    }
}

final class SudokuCellOCRService {
    func recognize(cells: [SudokuSegmentedCell]) async throws -> [SudokuDetectedCell] {
        try await withThrowingTaskGroup(of: SudokuDetectedCell.self) { group in
            for cell in cells { group.addTask { try await self.recognize(cell) } }
            var output: [SudokuDetectedCell] = []
            for try await cell in group { output.append(cell) }
            return output.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        }
    }
    private func recognize(_ cell: SudokuSegmentedCell) async throws -> SudokuDetectedCell {
        guard cell.inkDensity >= SudokuScanConfiguration.maximumBlankInkDensity else { return SudokuDetectedCell(row: cell.row, column: cell.column, recognizedValue: nil, confidence: nil, reviewState: .blank) }
        let variants = [cell.original, cell.enhanced, cell.enhanced.invertedForOCR()].compactMap { $0 }
        var best: (digit: Int, confidence: Float)?
        for variant in variants { if let candidate = try await recognizeDigit(in: variant), (best?.confidence ?? -1) < candidate.confidence { best = candidate } }
        guard let best, best.confidence >= SudokuScanConfiguration.mediumConfidence, cell.inkDensity >= SudokuScanConfiguration.minimumInkDensity else { return SudokuDetectedCell(row: cell.row, column: cell.column, recognizedValue: nil, confidence: best?.confidence, reviewState: .lowConfidence) }
        return SudokuDetectedCell(row: cell.row, column: cell.column, recognizedValue: best.digit, confidence: best.confidence, sourceType: .detected, reviewState: best.confidence >= SudokuScanConfiguration.highConfidence ? .highConfidence : .needsReview)
    }
    private func recognizeDigit(in image: UIImage) async throws -> (digit: Int, confidence: Float)? {
        guard let cgImage = image.cgImage else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error { continuation.resume(throwing: error); return }
                let candidates = ((request.results as? [VNRecognizedTextObservation]) ?? []).flatMap { $0.topCandidates(3) }.compactMap { candidate -> (Int, Float)? in guard let digit = SudokuCellOCRService.recognizedDigit(from: candidate.string) else { return nil }; return (digit, candidate.confidence) }
                continuation.resume(returning: candidates.max { $0.1 < $1.1 })
            }
            request.recognitionLevel = .accurate; request.usesLanguageCorrection = false; request.recognitionLanguages = ["en-US"]; request.customWords = (1...9).map(String.init); request.minimumTextHeight = 0.20
            do { try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request]) } catch { continuation.resume(throwing: error) }
        }
    }
    static func recognizedDigit(from text: String) -> Int? { let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines); guard trimmed.count == 1, let value = Int(trimmed), SudokuBoard.validDigits.contains(value) else { return nil }; return value }
}

enum SudokuScanValidator {
    static func markReviewStates(_ cells: [SudokuDetectedCell]) -> [SudokuDetectedCell] {
        let result = SudokuScanResult(cells: cells); let conflicts = SudokuValidator.conflictingCoordinates(in: result.board)
        return cells.map { cell in var copy = cell; if conflicts.contains(LogicGridCoordinate(row: cell.row, column: cell.column)) { copy.reviewState = .conflict }; return copy }
    }
    static func summary(for cells: [SudokuDetectedCell]) -> String { let result = SudokuScanResult(cells: cells); return "\(result.detectedCount) numbers detected • \(result.reviewCount) cells need review • \(result.conflictCount) conflicts found" }
}

enum SudokuDiagnostics {
    static func messages(for cells: [SudokuDetectedCell]) -> [String] {
        #if DEBUG
        return cells.map { "r\($0.row)c\($0.column): \($0.recognizedValue.map(String.init) ?? "blank") confidence=\($0.confidence ?? 0) state=\($0.reviewState.rawValue)" }
        #else
        return []
        #endif
    }
}

struct SudokuScanReviewView: View {
    @State private var cells: [SudokuDetectedCell]
    @State private var selected = LogicGridCoordinate(row: 0, column: 0)
    let onUsePuzzle: (SudokuBoard) -> Void; let onRescan: () -> Void; let onRetake: () -> Void; let onChooseAnother: () -> Void; let onManual: () -> Void
    init(result: SudokuImageImportResult, onUsePuzzle: @escaping (SudokuBoard) -> Void, onRescan: @escaping () -> Void, onRetake: @escaping () -> Void, onChooseAnother: @escaping () -> Void, onManual: @escaping () -> Void) { _cells = State(initialValue: result.cells); self.onUsePuzzle = onUsePuzzle; self.onRescan = onRescan; self.onRetake = onRetake; self.onChooseAnother = onChooseAnother; self.onManual = onManual }
    private var result: SudokuScanResult { SudokuScanResult(cells: cells) }
    private var board: SudokuBoard { result.board }
    private var conflicts: Set<LogicGridCoordinate> { SudokuValidator.conflictingCoordinates(in: board) }
    private var status: String { !conflicts.isEmpty ? "Detected puzzle contains conflicts" : (result.reviewCount > 0 ? "Review highlighted cells" : "Ready to use") }
    var body: some View { NavigationView { ScrollView { VStack(spacing: 14) {
        Text("Review detected numbers. Low-confidence and conflict cells are highlighted; tap any cell to correct or clear it.").font(AppTextStyle.paragraph).foregroundColor(AppTheme.text)
        Text("\(result.detectedCount) numbers detected • \(result.reviewCount) cells need review • \(result.conflictCount) conflicts found").font(AppTextStyle.paragraph).foregroundColor(AppTheme.text).frame(maxWidth: .infinity, alignment: .leading)
        Text(status).font(AppTextStyle.h3).foregroundColor(conflicts.isEmpty ? AppTheme.text : AppTheme.highlight).frame(maxWidth: .infinity, alignment: .leading)
        LogicGridView(rows: 9, columns: 9, majorLineFrequency: 3) { coordinate in reviewCell(at: coordinate) }.padding(3).background(AppTheme.background)
        SudokuKeypadView { value in setSelected(value) }
        Button("Clear Cell") { setSelected(nil) }.buttonStyle(AppSecondaryButtonStyle())
        Button("Use This Puzzle") { onUsePuzzle(board) }.buttonStyle(AppPrimaryButtonStyle()).disabled(!conflicts.isEmpty)
        HStack { Button("Rescan") { onRescan() }.buttonStyle(AppSecondaryButtonStyle()); Button("Retake Photo") { onRetake() }.buttonStyle(AppSecondaryButtonStyle()) }
        Button("Choose Another Photo") { onChooseAnother() }.buttonStyle(AppSecondaryButtonStyle())
        Button("Enter Manually") { onManual() }.buttonStyle(AppResetButtonStyle())
    }.padding().background(AppTheme.background) }.navigationTitle("Review Sudoku") } }
    private func setSelected(_ value: Int?) { var cell = cells[selected.row * 9 + selected.column]; cell.recognizedValue = value; cell.confidence = value == nil ? nil : 1; cell.sourceType = .manual; cell.reviewState = value == nil ? .blank : .highConfidence; cells[selected.row * 9 + selected.column] = cell; cells = SudokuScanValidator.markReviewStates(cells) }
    private func reviewCell(at coordinate: LogicGridCoordinate) -> some View { let cell = cells[coordinate.row * 9 + coordinate.column]; return Text(cell.recognizedValue.map(String.init) ?? "").font(AppTextStyle.h2).fontWeight(.bold).foregroundColor(AppTheme.text).frame(width: 34, height: 34).background(cellBackground(cell, coordinate: coordinate)).overlay(Rectangle().stroke(selected == coordinate ? AppTheme.highlight : AppTheme.text.opacity(0.2), lineWidth: selected == coordinate ? 2.5 : 0.5)).onTapGesture { selected = coordinate } }
    private func cellBackground(_ cell: SudokuDetectedCell, coordinate: LogicGridCoordinate) -> Color { if conflicts.contains(coordinate) || cell.reviewState == .conflict { return AppTheme.highlight.opacity(0.8) }; switch cell.reviewState { case .blank: return AppTheme.background.opacity(0.5); case .highConfidence: return AppTheme.surface; case .needsReview: return Color.yellow.opacity(0.45); case .lowConfidence: return Color.orange.opacity(0.45); case .conflict: return AppTheme.highlight.opacity(0.8) } }
}

typealias SudokuImageReviewView = SudokuScanReviewView

private extension UIImage {
    func normalizedForSudokuImport() -> UIImage? { if imageOrientation == .up { return self }; UIGraphicsBeginImageContextWithOptions(size, false, scale); draw(in: CGRect(origin: .zero, size: size)); let normalized = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return normalized }
    func invertedForOCR() -> UIImage? { guard let cg = cgImage else { return nil }; let ci = CIImage(cgImage: cg).applyingFilter("CIColorInvert"); guard let out = CIContext().createCGImage(ci, from: ci.extent) else { return nil }; return UIImage(cgImage: out, scale: scale, orientation: .up) }
}
