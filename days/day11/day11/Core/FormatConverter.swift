import UIKit
import ImageIO
import AVFoundation

class FormatConverter {
    
    // MARK: - Singleton
    
    static let shared = FormatConverter()
    
    private init() {}
    
    // MARK: - Format Detection
    
    func detectFormat(from data: Data) -> ImageFormat? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let uti = CGImageSourceGetType(source) as String? else {
            return nil
        }
        
        switch uti {
        case "public.jpeg":
            return .jpeg
        case "public.png":
            return .png
        case "public.heic":
            return .heic
        case "public.webp", "org.webmproject.webp":
            return .webp
        default:
            return nil
        }
    }
    
    // MARK: - Format Conversion
    
    func convert(
        _ image: UIImage,
        from sourceFormat: ImageFormat,
        to targetFormat: ImageFormat,
        quality: Double = 0.8,
        preserveMetadata: Bool = false
    ) -> Data? {
        // 같은 포맷이면 그냥 압축
        if sourceFormat == targetFormat {
            return ImageCompressor.shared.compress(
                image,
                format: targetFormat,
                quality: quality
            )?.compressedImage?.jpegData(compressionQuality: quality)
        }
        
        // 메타데이터 추출 (필요 시)
        var metadata: [String: Any]?
        if preserveMetadata, let cgImage = image.cgImage {
            metadata = extractMetadata(from: cgImage)
        }
        
        // 타겟 포맷으로 압축
        let compressedData: Data?
        switch targetFormat {
        case .jpeg:
            compressedData = image.jpegData(compressionQuality: quality)
        case .png:
            compressedData = image.pngData()
        case .heic:
            compressedData = convertToHEIC(image, quality: quality, metadata: metadata)
        case .webp:
            compressedData = ImageCompressor.shared.compress(
                image,
                format: .webp,
                quality: quality
            )?.compressedImage?.jpegData(compressionQuality: quality)
        }
        
        return compressedData
    }
    
    // MARK: - HEIC Conversion with Metadata
    
    private func convertToHEIC(
        _ image: UIImage,
        quality: Double,
        metadata: [String: Any]?
    ) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data,
            AVFileType.heic as CFString,
            1,
            nil
        ) else { return nil }
        
        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        // 메타데이터 추가
        if let metadata = metadata {
            options[kCGImageDestinationMetadata] = metadata as CFDictionary
        }
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from cgImage: CGImage) -> [String: Any]? {
        // CGImage에서 직접 메타데이터를 추출할 수 없으므로
        // 실제로는 원본 데이터나 URL에서 추출해야 함
        return nil
    }
    
    func extractMetadata(from data: Data) -> [String: Any]? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        
        return metadata
    }
    
    // MARK: - Batch Conversion
    
    func convertBatch(
        images: [UIImage],
        to targetFormat: ImageFormat,
        quality: Double = 0.8
    ) async -> [Data] {
        await withTaskGroup(of: Data?.self) { group in
            for image in images {
                group.addTask {
                    return ImageCompressor.shared.compress(
                        image,
                        format: targetFormat,
                        quality: quality
                    )?.compressedImage?.jpegData(compressionQuality: quality)
                }
            }
            
            var results: [Data] = []
            for await data in group {
                if let data = data {
                    results.append(data)
                }
            }
            return results
        }
    }
    
    // MARK: - Smart Format Selection
    
    func selectOptimalFormat(for image: UIImage, targetSize: Int? = nil) -> ImageFormat {
        // 투명도 확인
        let hasAlpha = image.hasAlpha
        
        if hasAlpha {
            // 투명도가 있으면 PNG 또는 WebP
            if #available(iOS 14.0, *) {
                return .webp
            } else {
                return .png
            }
        }
        
        // iOS 11 이상이면 HEIC 사용
        if #available(iOS 11.0, *) {
            return .heic
        }
        
        // 기본값은 JPEG
        return .jpeg
    }
    
    // MARK: - Format Info
    
    func getFormatInfo(for data: Data) -> (format: ImageFormat?, size: Int, dimensions: CGSize?) {
        let size = data.count
        let format = detectFormat(from: data)
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return (format, size, nil)
        }
        
        let width = properties[kCGImagePropertyPixelWidth as String] as? CGFloat ?? 0
        let height = properties[kCGImagePropertyPixelHeight as String] as? CGFloat ?? 0
        let dimensions = CGSize(width: width, height: height)
        
        return (format, size, dimensions)
    }
}

// MARK: - UIImage Extension

extension UIImage {
    var hasAlpha: Bool {
        guard let cgImage = cgImage else { return false }
        let alpha = cgImage.alphaInfo
        return alpha == .first || alpha == .last || alpha == .premultipliedFirst || alpha == .premultipliedLast
    }
}


