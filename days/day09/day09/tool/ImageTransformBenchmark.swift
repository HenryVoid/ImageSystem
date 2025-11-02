//
//  ImageTransformBenchmark.swift
//  day09
//
//  이미지 변환 성능 벤치마크
//

import Foundation
import UIKit

/// 이미지 변환 벤치마크
class ImageTransformBenchmark {
    static let shared = ImageTransformBenchmark()
    
    private init() {}
    
    // MARK: - 리사이징 벤치마크
    
    /// UIGraphicsImageRenderer를 사용한 리사이징
    func benchmarkUIGraphicsResize(image: UIImage, targetSize: CGSize) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        _ = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    /// Core Graphics를 사용한 리사이징
    func benchmarkCoreGraphicsResize(image: UIImage, targetSize: CGSize) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        _ = resized
        
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    /// ImageIO 다운샘플링 (가장 효율적)
    func benchmarkImageIODownsampling(imageData: Data, targetSize: CGSize) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height)
        ]
        
        if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
            _ = UIImage(cgImage: cgImage)
        }
        
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    // MARK: - 회전 벤치마크
    
    /// 이미지 회전 성능 측정
    func benchmarkRotation(image: UIImage, degrees: CGFloat) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        _ = renderer.image { context in
            context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.cgContext.rotate(by: radians)
            context.cgContext.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    // MARK: - 필터 벤치마크
    
    /// Core Image 필터 성능 측정
    func benchmarkCoreImageFilter(image: UIImage, filterName: String) -> TimeInterval {
        guard let cgImage = image.cgImage else { return 0 }
        
        let start = CFAbsoluteTimeGetCurrent()
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: filterName)
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        if let outputImage = filter?.outputImage {
            let context = CIContext(options: nil)
            _ = context.createCGImage(outputImage, from: outputImage.extent)
        }
        
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    /// 가우시안 블러 성능 측정
    func benchmarkGaussianBlur(image: UIImage, radius: CGFloat) -> TimeInterval {
        guard let cgImage = image.cgImage else { return 0 }
        
        let start = CFAbsoluteTimeGetCurrent()
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        
        if let outputImage = filter?.outputImage {
            let context = CIContext(options: nil)
            _ = context.createCGImage(outputImage, from: ciImage.extent)
        }
        
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    // MARK: - 종합 벤치마크
    
    /// 다양한 변환 작업의 종합 벤치마크
    func runComprehensiveBenchmark(image: UIImage, imageData: Data) -> BenchmarkResults {
        let targetSize = CGSize(width: 200, height: 200)
        
        return BenchmarkResults(
            uiGraphicsResize: benchmarkUIGraphicsResize(image: image, targetSize: targetSize),
            coreGraphicsResize: benchmarkCoreGraphicsResize(image: image, targetSize: targetSize),
            imageIODownsampling: benchmarkImageIODownsampling(imageData: imageData, targetSize: targetSize),
            rotation90: benchmarkRotation(image: image, degrees: 90),
            gaussianBlur: benchmarkGaussianBlur(image: image, radius: 10),
            sepiaFilter: benchmarkCoreImageFilter(image: image, filterName: "CISepiaTone")
        )
    }
}

// MARK: - 벤치마크 결과

struct BenchmarkResults {
    let uiGraphicsResize: TimeInterval
    let coreGraphicsResize: TimeInterval
    let imageIODownsampling: TimeInterval
    let rotation90: TimeInterval
    let gaussianBlur: TimeInterval
    let sepiaFilter: TimeInterval
    
    var description: String {
        """
        🎨 이미지 변환 벤치마크 결과
        
        리사이징:
        - UIGraphics: \(String(format: "%.2f", uiGraphicsResize * 1000))ms
        - CoreGraphics: \(String(format: "%.2f", coreGraphicsResize * 1000))ms
        - ImageIO: \(String(format: "%.2f", imageIODownsampling * 1000))ms (최고 효율)
        
        기타 변환:
        - 90도 회전: \(String(format: "%.2f", rotation90 * 1000))ms
        - 가우시안 블러: \(String(format: "%.2f", gaussianBlur * 1000))ms
        - 세피아 필터: \(String(format: "%.2f", sepiaFilter * 1000))ms
        """
    }
    
    var fastestResizeMethod: String {
        let methods = [
            ("UIGraphics", uiGraphicsResize),
            ("CoreGraphics", coreGraphicsResize),
            ("ImageIO", imageIODownsampling)
        ]
        
        let fastest = methods.min { $0.1 < $1.1 }
        return fastest?.0 ?? "Unknown"
    }
}

