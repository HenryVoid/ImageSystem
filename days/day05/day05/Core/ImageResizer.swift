//
//  ImageResizer.swift
//  day05
//
//  이미지 리사이즈 핵심 로직 - 4가지 방법 구현
//

import UIKit
import Accelerate
import ImageIO

/// 리사이즈 방법
enum ResizeMethod: String, CaseIterable {
    case uiGraphics = "UIGraphics"
    case coreGraphics = "Core Graphics"
    case vImage = "vImage"
    case imageIO = "Image I/O"
    
    var description: String {
        switch self {
        case .uiGraphics:
            return "간편하지만 상대적으로 느림"
        case .coreGraphics:
            return "세밀한 제어 가능"
        case .vImage:
            return "초고속 (SIMD 최적화)"
        case .imageIO:
            return "메모리 효율 (다운샘플링)"
        }
    }
}

/// 스케일 모드
enum ScaleMode {
    case aspectFit   // 안에 맞추기
    case aspectFill  // 꽉 채우기
    case fill        // 늘려서 채우기 (비율 무시)
}

/// 이미지 리사이저
class ImageResizer {
    
    // MARK: - Public Methods
    
    /// 이미지 리사이즈 (방법 선택 가능)
    static func resize(
        _ image: UIImage,
        to targetSize: CGSize,
        method: ResizeMethod,
        mode: ScaleMode = .aspectFit
    ) -> UIImage? {
        let calculatedSize = calculateSize(
            from: image.size,
            to: targetSize,
            mode: mode
        )
        
        switch method {
        case .uiGraphics:
            return resizeWithUIGraphics(image: image, targetSize: calculatedSize)
        case .coreGraphics:
            return resizeWithCoreGraphics(image: image, targetSize: calculatedSize)
        case .vImage:
            return resizeWithVImage(image: image, targetSize: calculatedSize)
        case .imageIO:
            // Image I/O는 URL이 필요하므로 임시 파일 사용
            return resizeWithImageIOFromImage(image: image, targetSize: calculatedSize)
        }
    }
    
    /// Image I/O 다운샘플링 (URL에서)
    static func downsample(
        from url: URL,
        to targetSize: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
            return nil
        }
        
        let maxPixelSize = max(targetSize.width, targetSize.height) * scale
        
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            downsampleOptions as CFDictionary
        ) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    /// 크기 계산 (Aspect ratio 유지)
    static func calculateSize(
        from originalSize: CGSize,
        to targetSize: CGSize,
        mode: ScaleMode
    ) -> CGSize {
        switch mode {
        case .aspectFit:
            return aspectFitSize(from: originalSize, to: targetSize)
        case .aspectFill:
            return aspectFillSize(from: originalSize, to: targetSize)
        case .fill:
            return targetSize
        }
    }
    
    // MARK: - Private Methods
    
    /// 1️⃣ UIGraphicsImageRenderer
    private static func resizeWithUIGraphics(image: UIImage, targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // 정확한 픽셀 크기
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// 2️⃣ Core Graphics
    private static func resizeWithCoreGraphics(image: UIImage, targetSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        // 고품질 보간
        context.interpolationQuality = .high
        
        // 이미지 그리기
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let resizedCGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: resizedCGImage)
    }
    
    /// 3️⃣ vImage (Accelerate)
    private static func resizeWithVImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // vImage 포맷 정의
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        // 소스 버퍼 생성
        var sourceBuffer = vImage_Buffer()
        var error = vImageBuffer_InitWithCGImage(
            &sourceBuffer,
            &format,
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags)
        )
        
        guard error == kvImageNoError else { return nil }
        defer { sourceBuffer.data.deallocate() }
        
        // 목적지 버퍼 생성
        var destinationBuffer = vImage_Buffer()
        error = vImageBuffer_Init(
            &destinationBuffer,
            vImagePixelCount(targetSize.height),
            vImagePixelCount(targetSize.width),
            format.bitsPerPixel,
            vImage_Flags(kvImageNoFlags)
        )
        
        guard error == kvImageNoError else { return nil }
        defer { destinationBuffer.data.deallocate() }
        
        // 리사이즈 (고품질)
        error = vImageScale_ARGB8888(
            &sourceBuffer,
            &destinationBuffer,
            nil,
            vImage_Flags(kvImageHighQualityResampling)
        )
        
        guard error == kvImageNoError else { return nil }
        
        // CGImage 생성
        let cgImageFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        guard let resizedCGImage = vImageCreateCGImageFromBuffer(
            &destinationBuffer,
            &cgImageFormat,
            nil,
            nil,
            vImage_Flags(kvImageNoFlags),
            nil
        )?.takeRetainedValue() else {
            return nil
        }
        
        return UIImage(cgImage: resizedCGImage)
    }
    
    /// 4️⃣ Image I/O (UIImage에서 임시 파일 사용)
    private static func resizeWithImageIOFromImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        // UIImage → Data
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
        
        // Data → CGImageSource
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        
        let maxPixelSize = max(targetSize.width, targetSize.height)
        
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        
        guard let resizedCGImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            options as CFDictionary
        ) else {
            return nil
        }
        
        return UIImage(cgImage: resizedCGImage)
    }
    
    // MARK: - Aspect Ratio Calculations
    
    /// Aspect Fit 크기 계산
    private static func aspectFitSize(from originalSize: CGSize, to targetSize: CGSize) -> CGSize {
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        return CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
    }
    
    /// Aspect Fill 크기 계산
    private static func aspectFillSize(from originalSize: CGSize, to targetSize: CGSize) -> CGSize {
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        let ratio = max(widthRatio, heightRatio)
        
        return CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
    }
}

// MARK: - 성능 측정 헬퍼

extension ImageResizer {
    
    /// 리사이즈 벤치마크
    struct BenchmarkResult {
        let method: ResizeMethod
        let originalSize: CGSize
        let targetSize: CGSize
        let resultSize: CGSize
        let duration: TimeInterval  // 초
        let memoryUsed: UInt64      // 바이트
        let image: UIImage?
    }
    
    /// 벤치마크 실행
    static func benchmark(
        _ image: UIImage,
        to targetSize: CGSize,
        method: ResizeMethod
    ) -> BenchmarkResult {
        let memoryBefore = reportMemory()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let resizedImage = resize(image, to: targetSize, method: method)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let memoryAfter = reportMemory()
        let memoryUsed = memoryAfter > memoryBefore ? memoryAfter - memoryBefore : 0
        
        return BenchmarkResult(
            method: method,
            originalSize: image.size,
            targetSize: targetSize,
            resultSize: resizedImage?.size ?? .zero,
            duration: duration,
            memoryUsed: memoryUsed,
            image: resizedImage
        )
    }
    
    /// 현재 메모리 사용량 리포트
    private static func reportMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - 편의 확장

extension ImageResizer.BenchmarkResult {
    
    /// 시간 포맷 (ms)
    var formattedDuration: String {
        String(format: "%.2f ms", duration * 1000)
    }
    
    /// 메모리 포맷 (MB)
    var formattedMemory: String {
        String(format: "%.2f MB", Double(memoryUsed) / 1_000_000.0)
    }
    
    /// 크기 포맷
    var formattedSize: String {
        "\(Int(resultSize.width)) × \(Int(resultSize.height))"
    }
}

