import Vision
import UIKit

class VisionManager: ObservableObject {
    
    // MARK: - Face Detection
    
    func detectFaces(in image: UIImage) async throws -> [VNFaceObservation] {
        guard let cgImage = image.cgImage else { return [] }
        
        let request = VNDetectFaceRectanglesRequest()
        
        // Create a request handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform the request
        try await handler.perform([request])
        
        guard let results = request.results else { return [] }
        return results
    }
    
    // MARK: - Text Recognition (OCR)
    
    func recognizeText(in image: UIImage) async throws -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else { return [] }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try await handler.perform([request])
        
        guard let results = request.results else { return [] }
        return results
    }
    
    // MARK: - Combined
    
    func processImage(in image: UIImage) async throws -> (faces: [VNFaceObservation], text: [VNRecognizedTextObservation]) {
        guard let cgImage = image.cgImage else { return ([], []) }
        
        let faceRequest = VNDetectFaceRectanglesRequest()
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try await handler.perform([faceRequest, textRequest])
        
        return (faceRequest.results ?? [], textRequest.results ?? [])
    }
}

// MARK: - Coordinate Conversion Utilities
extension VisionManager {
    /// Converts a Vision normalized rect (bottom-left origin) to a SwiftUI Image coordinate space (top-left origin)
    static func convertBoundingBox(_ box: CGRect, to targetSize: CGSize) -> CGRect {
        let x = box.minX * targetSize.width
        let height = box.height * targetSize.height
        let y = (1 - box.maxY) * targetSize.height // Flip Y
        let width = box.width * targetSize.width
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

