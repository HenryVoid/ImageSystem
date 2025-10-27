//
//  ImageLoader.swift
//  day07
//
//  이미지 로딩 및 메타데이터 추출 통합 관리
//

import UIKit
import CoreImage
import ImageIO

/// 이미지 메타데이터
struct ImageMetadata {
    let format: ImageFormat
    let size: CGSize
    let fileSize: Int?
    let colorSpace: String?
    let hasAlpha: Bool
    let dpi: (x: Int, y: Int)?
    
    enum ImageFormat: String {
        case jpeg = "JPEG"
        case png = "PNG"
        case heic = "HEIC"
        case webp = "WebP"
        case unknown = "Unknown"
    }
}

/// 이미지 로더
class ImageLoader {
    static let shared = ImageLoader()
    
    private init() {}
    
    // MARK: - 이미지 로딩
    
    /// Asset에서 UIImage 로딩
    func loadUIImage(named: String) -> UIImage? {
        return UIImage(named: named)
    }
    
    /// Asset에서 CIImage 로딩
    func loadCIImage(named: String) -> CIImage? {
        guard let uiImage = UIImage(named: named) else { return nil }
        return CIImage(image: uiImage)
    }
    
    /// 파일 URL에서 UIImage 로딩
    func loadUIImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    /// 파일 URL에서 CIImage 로딩
    func loadCIImage(from url: URL) -> CIImage? {
        return CIImage(contentsOf: url)
    }
    
    // MARK: - 메타데이터 추출
    
    /// Asset 이미지의 메타데이터 추출
    func extractMetadata(named: String) -> ImageMetadata? {
        guard let uiImage = UIImage(named: named) else { return nil }
        return extractMetadata(from: uiImage)
    }
    
    /// UIImage에서 메타데이터 추출
    func extractMetadata(from image: UIImage) -> ImageMetadata {
        let size = image.size
        let scale = image.scale
        let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // CGImage에서 추가 정보 추출
        var hasAlpha = false
        var colorSpaceName: String?
        
        if let cgImage = image.cgImage {
            let alphaInfo = cgImage.alphaInfo
            hasAlpha = alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
            colorSpaceName = cgImage.colorSpace?.name as? String
        }
        
        return ImageMetadata(
            format: .unknown,
            size: pixelSize,
            fileSize: nil,
            colorSpace: colorSpaceName,
            hasAlpha: hasAlpha,
            dpi: nil
        )
    }
    
    /// 파일 URL에서 메타데이터 추출 (ImageIO 사용)
    func extractMetadata(from url: URL) -> ImageMetadata? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        
        return extractMetadata(from: imageSource, fileURL: url)
    }
    
    /// CGImageSource에서 메타데이터 추출
    private func extractMetadata(from imageSource: CGImageSource, fileURL: URL? = nil) -> ImageMetadata? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }
        
        // 포맷 확인
        let format = detectFormat(from: imageSource)
        
        // 크기
        let width = properties[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        let size = CGSize(width: width, height: height)
        
        // 파일 크기
        var fileSize: Int?
        if let url = fileURL {
            fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int
        }
        
        // 색공간
        let colorSpace = properties[kCGImagePropertyColorModel as String] as? String
        
        // 알파 채널
        let hasAlpha = properties[kCGImagePropertyHasAlpha as String] as? Bool ?? false
        
        // DPI
        var dpi: (x: Int, y: Int)?
        if let dpiX = properties[kCGImagePropertyDPIWidth as String] as? Int,
           let dpiY = properties[kCGImagePropertyDPIHeight as String] as? Int {
            dpi = (dpiX, dpiY)
        }
        
        return ImageMetadata(
            format: format,
            size: size,
            fileSize: fileSize,
            colorSpace: colorSpace,
            hasAlpha: hasAlpha,
            dpi: dpi
        )
    }
    
    /// 이미지 포맷 감지
    private func detectFormat(from imageSource: CGImageSource) -> ImageMetadata.ImageFormat {
        guard let type = CGImageSourceGetType(imageSource) as String? else {
            return .unknown
        }
        
        switch type {
        case "public.jpeg":
            return .jpeg
        case "public.png":
            return .png
        case "public.heic":
            return .heic
        case "org.webmproject.webp":
            return .webp
        default:
            return .unknown
        }
    }
    
    // MARK: - 썸네일 생성
    
    /// 썸네일 생성 (ImageIO 활용 - 효율적)
    func generateThumbnail(from image: UIImage, maxSize: CGFloat) -> UIImage? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Asset 이름으로 썸네일 생성
    func generateThumbnail(named: String, maxSize: CGFloat) -> UIImage? {
        guard let image = loadUIImage(named: named) else { return nil }
        return generateThumbnail(from: image, maxSize: maxSize)
    }
}

