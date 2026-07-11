//
//  SudokuImageImport.swift
//  Puzzle Solver
//
//  Local camera/photo Sudoku import pipeline and review UI.
//

import SwiftUI
import UIKit
import Vision
import CoreImage
import AVFoundation
import PhotosUI

struct SudokuDetectedCell: Identifiable, Equatable, Hashable {
    enum SourceType: String { case imported, detected }
    var id: String { "\(row)-\(column)" }
    let row: Int
    let column: Int
    var recognizedValue: Int?
    var confidence: Float?
    var sourceType: SourceType = .imported
    var needsReview: Bool { recognizedValue != nil && ((confidence ?? 0) < 0.70) }
}

struct SudokuImageImportResult: Equatable, Identifiable {
    let id = UUID()
    var cells: [SudokuDetectedCell]
    var message: String? = nil
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

enum SudokuImageImportError: LocalizedError, Equatable {
    case cameraPermissionDenied
    case photoLibraryPermissionDenied
    case imageCouldNotBeLoaded
    case boardCouldNotBeDetected
    case ocrCouldNotReadEnoughNumbers
    case detectedPuzzleHasConflicts(String)
    case importCancelled

    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied: return "Camera permission denied. You can choose a photo or enter the Sudoku manually."
        case .photoLibraryPermissionDenied: return "Photo library permission denied. You can enter the Sudoku manually."
        case .imageCouldNotBeLoaded: return "Image could not be loaded. Try another image or enter it manually."
        case .boardCouldNotBeDetected: return "Could not detect the Sudoku board. Try cropping the image or enter it manually."
        case .ocrCouldNotReadEnoughNumbers: return "OCR could not read enough numbers. Try a clearer image or enter it manually."
        case .detectedPuzzleHasConflicts(let detail): return "Detected puzzle has conflicts. \(detail)"
        case .importCancelled: return "Import cancelled. Manual entry is still available."
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

    private let processor = SudokuImageProcessor()

    func begin(_ source: Source) {
        errorMessage = nil
        switch source {
        case .camera: requestCamera()
        case .photoLibrary: requestPhotoLibrary()
        }
    }

    func process(_ image: UIImage?) {
        guard let image else { errorMessage = SudokuImageImportError.importCancelled.localizedDescription; return }
        isProcessing = true
        statusText = "Loading image…"
        Task {
            do {
                let result = try await processor.process(image: image) { [weak self] status in
                    Task { @MainActor in self?.statusText = status }
                }
                reviewResult = result
            } catch let error as SudokuImageImportError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = SudokuImageImportError.imageCouldNotBeLoaded.localizedDescription
            }
            isProcessing = false
            selectedSource = nil
        }
    }

    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = "Camera is not available on this device. Choose Photo or enter manually."
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: selectedSource = .camera
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        self.selectedSource = .camera
                    } else {
                        self.errorMessage = SudokuImageImportError.cameraPermissionDenied.localizedDescription
                    }
                }
            }
        default: errorMessage = SudokuImageImportError.cameraPermissionDenied.localizedDescription
        }
    }

    private func requestPhotoLibrary() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited: selectedSource = .photoLibrary
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                Task { @MainActor in
                    if newStatus == .authorized || newStatus == .limited {
                        self.selectedSource = .photoLibrary
                    } else {
                        self.errorMessage = SudokuImageImportError.photoLibraryPermissionDenied.localizedDescription
                    }
                }
            }
        default: errorMessage = SudokuImageImportError.photoLibraryPermissionDenied.localizedDescription
        }
    }
}

struct SudokuImageImportView: View {
    @StateObject private var viewModel = SudokuImageImportViewModel()
    let onUsePuzzle: (SudokuBoard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scan Sudoku Beta")
                .font(AppTextStyle.h3)
                .foregroundColor(AppTheme.text)
            Text("Take a photo or upload a screenshot of a Sudoku board. You can review and fix numbers before solving.")
                .font(AppTextStyle.paragraph)
                .foregroundColor(AppTheme.text.opacity(0.85))
            HStack(spacing: 12) {
                Button("Scan Sudoku") { viewModel.begin(.camera) }
                    .buttonStyle(AppPrimaryButtonStyle())
                Button("Choose Photo") { viewModel.begin(.photoLibrary) }
                    .buttonStyle(AppSecondaryButtonStyle())
            }
            if viewModel.isProcessing {
                HStack { ProgressView(); Text(viewModel.statusText).font(AppTextStyle.paragraph).foregroundColor(AppTheme.text) }
            }
            if let error = viewModel.errorMessage {
                Text(error).font(AppTextStyle.paragraph).foregroundColor(AppTheme.highlight)
            }
        }
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .sheet(item: Binding(get: { viewModel.selectedSource.map { SourceSheet(source: $0) } }, set: { if $0 == nil { viewModel.selectedSource = nil } })) { wrapper in
            SudokuImagePicker(sourceType: wrapper.source == .camera ? .camera : .photoLibrary) { image in viewModel.process(image) }
        }
        .sheet(item: $viewModel.reviewResult) { result in
            SudokuImageReviewView(result: result, onUsePuzzle: { board in onUsePuzzle(board); viewModel.reviewResult = nil }, onRetake: { viewModel.reviewResult = nil; viewModel.begin(.camera) }, onChooseAnother: { viewModel.reviewResult = nil; viewModel.begin(.photoLibrary) }, onManual: { viewModel.reviewResult = nil })
        }
    }

    private struct SourceSheet: Identifiable { let source: SudokuImageImportViewModel.Source; var id: Int { source == .camera ? 0 : 1 } }
}

struct SudokuImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImage: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.sourceType = sourceType; picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { picker.dismiss(animated: true); onImage(info[.originalImage] as? UIImage) }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true); onImage(nil) }
    }
}

final class SudokuImageProcessor {
    private let detector = SudokuBoardDetector(); private let ocr = SudokuOCRService()
    func process(image: UIImage, progress: @escaping (String) -> Void) async throws -> SudokuImageImportResult {
        progress("Loading image…")
        guard let normalized = image.normalizedForSudokuImport() else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        progress("Finding Sudoku board…")
        let boardImage = try detector.detectBoard(in: normalized)
        progress("Reading numbers…")
        let cells = try await ocr.recognizeCells(in: boardImage)
        guard cells.filter({ $0.recognizedValue != nil }).count >= 8 else { throw SudokuImageImportError.ocrCouldNotReadEnoughNumbers }
        progress("Preparing review…")
        let result = SudokuImageImportResult(cells: cells, message: nil)
        let validation = SudokuValidator.validate(result.board)
        if !validation.isValid { throw SudokuImageImportError.detectedPuzzleHasConflicts(validation.summary) }
        return result
    }
}

final class SudokuBoardDetector {
    func detectBoard(in image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.75; request.maximumAspectRatio = 1.25; request.minimumSize = 0.35; request.maximumObservations = 1
        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        guard request.results?.first != nil || image.size.width > 100 && image.size.height > 100 else { throw SudokuImageImportError.boardCouldNotBeDetected }
        return image
    }
}

final class SudokuOCRService {
    func recognizeCells(in image: UIImage) async throws -> [SudokuDetectedCell] {
        guard let cgImage = image.cgImage else { throw SudokuImageImportError.imageCouldNotBeLoaded }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error { continuation.resume(throwing: error); return }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                continuation.resume(returning: self.cells(from: observations))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]
            request.customWords = (1...9).map(String.init)
            DispatchQueue.global(qos: .userInitiated).async {
                do { try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request]) } catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func cells(from observations: [VNRecognizedTextObservation]) -> [SudokuDetectedCell] {
        var cells = (0..<9).flatMap { row in (0..<9).map { SudokuDetectedCell(row: row, column: $0, recognizedValue: nil, confidence: nil) } }
        for observation in observations {
            guard let text = observation.topCandidates(3).first, let digit = recognizedDigit(from: text.string) else { continue }
            let confidence = text.confidence
            guard SudokuBoard.validDigits.contains(digit) else { continue }
            let x = observation.boundingBox.midX
            let y = 1 - observation.boundingBox.midY
            let column = min(8, max(0, Int(x * 9)))
            let row = min(8, max(0, Int(y * 9)))
            let index = row * 9 + column
            if (cells[index].confidence ?? -1) < confidence {
                cells[index].recognizedValue = digit; cells[index].confidence = confidence
            }
        }
        return cells
    }

    private func recognizedDigit(from text: String) -> Int? {
        let digits = text.compactMap { Int(String($0)) }.filter { SudokuBoard.validDigits.contains($0) }
        return digits.count == 1 ? digits[0] : nil
    }
}

struct SudokuImageReviewView: View {
    @State private var cells: [SudokuDetectedCell]
    @State private var selected = LogicGridCoordinate(row: 0, column: 0)
    let onUsePuzzle: (SudokuBoard) -> Void; let onRetake: () -> Void; let onChooseAnother: () -> Void; let onManual: () -> Void
    init(result: SudokuImageImportResult, onUsePuzzle: @escaping (SudokuBoard) -> Void, onRetake: @escaping () -> Void, onChooseAnother: @escaping () -> Void, onManual: @escaping () -> Void) {
        _cells = State(initialValue: result.cells); self.onUsePuzzle = onUsePuzzle; self.onRetake = onRetake; self.onChooseAnother = onChooseAnother; self.onManual = onManual
    }
    private var board: SudokuBoard { SudokuImageImportResult(cells: cells).board }
    private var conflicts: Set<LogicGridCoordinate> { SudokuValidator.conflictingCoordinates(in: board) }
    var body: some View {
        NavigationView { ScrollView { VStack(spacing: 14) {
            Text("Review detected numbers. Low-confidence cells are highlighted; tap any cell to correct or clear it.").font(AppTextStyle.paragraph).foregroundColor(AppTheme.text)
            LogicGridView(rows: 9, columns: 9, majorLineFrequency: 3) { coordinate in
                let cell = cells[coordinate.row * 9 + coordinate.column]
                Text(cell.recognizedValue.map(String.init) ?? "")
                    .font(AppTextStyle.h2).fontWeight(.bold).foregroundColor(AppTheme.text).frame(width: 34, height: 34)
                    .background(conflicts.contains(coordinate) ? AppTheme.highlight.opacity(0.8) : (cell.needsReview ? Color.yellow.opacity(0.45) : AppTheme.surface))
                    .overlay(Rectangle().stroke(selected == coordinate ? AppTheme.highlight : AppTheme.text.opacity(0.2), lineWidth: selected == coordinate ? 2.5 : 0.5))
                    .onTapGesture { selected = coordinate }
            }.padding(3).background(AppTheme.background)
            Text(SudokuValidator.validate(board).summary).font(AppTextStyle.paragraph).foregroundColor(conflicts.isEmpty ? AppTheme.text : AppTheme.highlight).frame(maxWidth: .infinity, alignment: .leading)
            SudokuKeypadView { value in cells[selected.row * 9 + selected.column].recognizedValue = value; cells[selected.row * 9 + selected.column].confidence = 1 }
            Button("Use This Puzzle") { onUsePuzzle(board) }.buttonStyle(AppPrimaryButtonStyle()).disabled(!SudokuValidator.validate(board).isValid)
            HStack { Button("Retake Photo") { onRetake() }.buttonStyle(AppSecondaryButtonStyle()); Button("Choose Another Photo") { onChooseAnother() }.buttonStyle(AppSecondaryButtonStyle()) }
            Button("Enter Manually") { onManual() }.buttonStyle(AppResetButtonStyle())
        }.padding().background(AppTheme.background) } .navigationTitle("Review Sudoku") }
    }
}

private extension UIImage {
    func normalizedForSudokuImport() -> UIImage? {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized
    }
}
