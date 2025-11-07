import UIKit
import ImageIO
import AVFoundation
import SDWebImageWebPCoder

class ImageCompressor {
    
    // MARK: - Singleton
    
    static let shared = ImageCompressor()
    
    private init() {
        // WebP 코더 등록
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
    }
    
    // MARK: - Compression Methods
    
    func compress(
        _ image: UIImage,
        format: ImageFormat,
        quality: Double
    ) -> CompressionResult? {
        let startTime = Date()
        
        // 원본 크기 계산
        guard let originalData = image.pngData() else { return nil }
        let originalSize = originalData.count
        
        // 포맷별 압축
        let compressedData: Data?
        switch format {
        case .jpeg:
            compressedData = compressJPEG(image, quality: quality)
        case .png:
            compressedData = compressPNG(image)
        case .heic:
            compressedData = compressHEIC(image, quality: quality)
        case .webp:
            compressedData = compressWebP(image, quality: quality)
        }
        
        guard let data = compressedData else { return nil }
        
        let compressionTime = Date().timeIntervalSince(startTime)
        let compressedImage = UIImage(data: data)
        
        return CompressionResult(
            format: format,
            quality: quality,
            originalSize: originalSize,
            compressedSize: data.count,
            compressionTime: compressionTime,
            compressedImage: compressedImage
        )
    }
    
    // MARK: - JPEG Compression
    
    private func compressJPEG(_ image: UIImage, quality: Double) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    // MARK: - PNG Compression
    
    private func compressPNG(_ image: UIImage) -> Data? {
        return image.pngData()
    }
    
    // MARK: - HEIC Compression
    
    private func compressHEIC(_ image: UIImage, quality: Double) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data,
            AVFileType.heic as CFString,
            1,
            nil
        ) else { return nil }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
    
    // MARK: - WebP Compression
    
    private func compressWebP(_ image: UIImage, quality: Double) -> Data? {
        let options: [SDImageCoderOption: Any] = [
            .encodeCompressionQuality: quality
        ]
        
        return SDImageWebPCoder.shared.encodedData(
            with: image,
            format: .webP,
            options: options
        )
    }
    
    // MARK: - Batch Compression
    
    func compressBatch(
        _ image: UIImage,
        formats: [ImageFormat],
        qualities: [Double]
    ) async -> [CompressionResult] {
        var results: [CompressionResult] = []
        
        for format in formats {
            for quality in qualities {
                if let result = await Task.detached(priority: .userInitiated) {
                    return self.compress(image, format: format, quality: quality)
                }.value {
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Adaptive Quality
    
    func adaptiveCompress(
        _ image: UIImage,
        format: ImageFormat,
        targetSize: Int
    ) -> CompressionResult? {
        var low: Double = 0.1
        var high: Double = 1.0
        var bestResult: CompressionResult?
        
        // 이진 탐색으로 최적 품질 찾기
        for _ in 0..<10 {
            let quality = (low + high) / 2.0
            
            guard let result = compress(image, format: format, quality: quality) else {
                continue
            }
            
            if result.compressedSize <= targetSize {
                bestResult = result
                low = quality
            } else {
                high = quality
            }
            
            // 충분히 가까우면 종료
            if abs(result.compressedSize - targetSize) < targetSize / 20 {
                break
            }
        }
        
        return bestResult
    }
}


