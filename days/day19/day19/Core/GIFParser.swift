//
//  GIFParser.swift
//  day19
//
//  CGImageSource를 사용한 GIF 파싱
//

import Foundation
import ImageIO
import UIKit

/// GIF 프레임 정보
struct GIFFrame {
    /// 프레임 이미지
    let image: UIImage
    
    /// 프레임 딜레이 (초 단위)
    let delay: TimeInterval
    
    /// Disposal Method
    let disposalMethod: DisposalMethod
    
    /// 투명도 여부
    let hasTransparency: Bool
    
    enum DisposalMethod: Int {
        case unspecified = 0
        case doNotDispose = 1
        case restoreToBackground = 2
        case restoreToPrevious = 3
    }
}

/// GIF 파싱 에러
enum GIFError: LocalizedError {
    case invalidURL
    case invalidSource
    case invalidData
    case noFrames
    case frameDecodeFailed(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .invalidSource:
            return "GIF 소스를 생성할 수 없습니다."
        case .invalidData:
            return "유효하지 않은 GIF 데이터입니다."
        case .noFrames:
            return "GIF에 프레임이 없습니다."
        case .frameDecodeFailed(let index):
            return "프레임 \(index) 디코딩에 실패했습니다."
        }
    }
}

/// GIF 파서
class GIFParser {
    private let url: URL?
    private let data: Data?
    private var imageSource: CGImageSource?
    
    /// URL로 초기화
    init(url: URL) {
        self.url = url
        self.data = nil
    }
    
    /// Data로 초기화
    init(data: Data) {
        self.url = nil
        self.data = data
    }
    
    /// 이미지 소스 생성
    private func createImageSource() throws -> CGImageSource {
        if let existingSource = imageSource {
            return existingSource
        }
        
        let source: CGImageSource?
        
        if let url = url {
            source = CGImageSourceCreateWithURL(url as CFURL, nil)
        } else if let data = data {
            source = CGImageSourceCreateWithData(data as CFData, nil)
        } else {
            throw GIFError.invalidSource
        }
        
        guard let imageSource = source else {
            throw GIFError.invalidSource
        }
        
        self.imageSource = imageSource
        return imageSource
    }
    
    /// GIF 프레임 파싱
    func parseFrames() async throws -> [GIFFrame] {
        let source = try createImageSource()
        
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else {
            throw GIFError.noFrames
        }
        
        var frames: [GIFFrame] = []
        
        for index in 0..<frameCount {
            // 프레임 이미지 추출
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                throw GIFError.frameDecodeFailed(index)
            }
            
            let image = UIImage(cgImage: cgImage)
            
            // 프레임 속성 추출
            let properties = try extractFrameProperties(from: source, at: index)
            
            let frame = GIFFrame(
                image: image,
                delay: properties.delay,
                disposalMethod: properties.disposalMethod,
                hasTransparency: properties.hasTransparency
            )
            
            frames.append(frame)
        }
        
        return frames
    }
    
    /// 프레임 속성 추출
    private func extractFrameProperties(from source: CGImageSource, at index: Int) throws -> (delay: TimeInterval, disposalMethod: GIFFrame.DisposalMethod, hasTransparency: Bool) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any] else {
            return (delay: 0.1, disposalMethod: .unspecified, hasTransparency: false)
        }
        
        // 딜레이 추출
        var delay: TimeInterval = 0.1
        
        if let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
            // 딜레이 시간 (1/100초 단위)
            if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                delay = delayTime > 0 ? delayTime : 0.1
            }
            
            // Unclamped Delay Time (더 정확한 딜레이)
            if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                delay = unclampedDelay > 0 ? unclampedDelay : delay
            }
        }
        
        // Disposal Method 추출
        var disposalMethod: GIFFrame.DisposalMethod = .unspecified
        
        if let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
           let disposal = gifProperties[kCGImagePropertyGIFDisposalMethod as String] as? Int {
            disposalMethod = GIFFrame.DisposalMethod(rawValue: disposal) ?? .unspecified
        }
        
        // 투명도 확인
        var hasTransparency = false
        
        if let alphaInfo = CGImageGetAlphaInfo(CGImageSourceCreateImageAtIndex(source, index, nil)!) {
            hasTransparency = alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
        }
        
        // GIF 속성에서 투명 색상 확인
        if let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
           let hasTransparentColor = gifProperties[kCGImagePropertyGIFHasGlobalColorMap as String] as? Bool {
            hasTransparency = hasTransparentColor || hasTransparency
        }
        
        return (delay: delay, disposalMethod: disposalMethod, hasTransparency: hasTransparency)
    }
    
    /// GIF 메타데이터 추출
    func extractMetadata() async throws -> GIFMetadata {
        let source = try createImageSource()
        
        guard let properties = CGImageSourceCopyProperties(source, nil) as? [String: Any] else {
            throw GIFError.invalidData
        }
        
        let frameCount = CGImageSourceGetCount(source)
        
        // 크기 정보
        var width: Int = 0
        var height: Int = 0
        
        if let widthValue = properties[kCGImagePropertyPixelWidth as String] as? Int {
            width = widthValue
        }
        
        if let heightValue = properties[kCGImagePropertyPixelHeight as String] as? Int {
            height = heightValue
        }
        
        // 루프 정보
        var loopCount: Int = 0
        
        if let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
            if let loop = gifProperties[kCGImagePropertyGIFLoopCount as String] as? Int {
                loopCount = loop
            }
        }
        
        // 총 애니메이션 길이 계산
        var totalDuration: TimeInterval = 0
        for index in 0..<frameCount {
            let properties = try extractFrameProperties(from: source, at: index)
            totalDuration += properties.delay
        }
        
        return GIFMetadata(
            frameCount: frameCount,
            width: width,
            height: height,
            loopCount: loopCount,
            totalDuration: totalDuration
        )
    }
    
    /// 첫 프레임만 추출 (썸네일용)
    func extractFirstFrame() async throws -> UIImage {
        let source = try createImageSource()
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw GIFError.frameDecodeFailed(0)
        }
        
        return UIImage(cgImage: cgImage)
    }
}

/// GIF 메타데이터
struct GIFMetadata {
    /// 프레임 개수
    let frameCount: Int
    
    /// 너비 (픽셀)
    let width: Int
    
    /// 높이 (픽셀)
    let height: Int
    
    /// 루프 횟수 (0 = 무한)
    let loopCount: Int
    
    /// 총 애니메이션 길이 (초)
    let totalDuration: TimeInterval
}

