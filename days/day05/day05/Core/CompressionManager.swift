//
//  CompressionManager.swift
//  day05
//
//  압축 옵션 관리 및 프리셋
//

import UIKit

/// 압축 프리셋
enum CompressionPreset: String, CaseIterable {
    case original = "원본"
    case highQuality = "고품질"
    case standard = "표준"
    case web = "웹"
    case thumbnail = "썸네일"
    case preview = "미리보기"
    
    /// JPEG 품질
    var jpegQuality: CGFloat {
        switch self {
        case .original: return 1.0
        case .highQuality: return 0.9
        case .standard: return 0.8
        case .web: return 0.75
        case .thumbnail: return 0.7
        case .preview: return 0.5
        }
    }
    
    /// HEIC 품질
    var heicQuality: CGFloat {
        switch self {
        case .original: return 1.0
        case .highQuality: return 0.9
        case .standard: return 0.85
        case .web: return 0.8
        case .thumbnail: return 0.75
        case .preview: return 0.6
        }
    }
    
    /// 권장 최대 크기 (픽셀)
    var maxDimension: CGFloat? {
        switch self {
        case .original: return nil
        case .highQuality: return 3000
        case .standard: return 1920
        case .web: return 1080
        case .thumbnail: return 300
        case .preview: return 150
        }
    }
    
    /// 설명
    var description: String {
        switch self {
        case .original:
            return "원본 품질 유지"
        case .highQuality:
            return "높은 화질, 약간의 압축"
        case .standard:
            return "균형잡힌 품질과 크기"
        case .web:
            return "웹 업로드에 최적"
        case .thumbnail:
            return "작은 썸네일용"
        case .preview:
            return "빠른 미리보기용"
        }
    }
    
    /// 예상 파일 크기 비율 (원본 대비)
    var estimatedSizeRatio: Double {
        switch self {
        case .original: return 1.0
        case .highQuality: return 0.45
        case .standard: return 0.25
        case .web: return 0.15
        case .thumbnail: return 0.05
        case .preview: return 0.02
        }
    }
}

/// 압축 용도
enum CompressionPurpose {
    case storage        // 로컬 저장
    case upload         // 업로드
    case display        // 화면 표시
    case sharing        // 공유
    case archiving      // 아카이빙
    
    /// 권장 프리셋
    var recommendedPreset: CompressionPreset {
        switch self {
        case .storage: return .highQuality
        case .upload: return .web
        case .display: return .standard
        case .sharing: return .highQuality
        case .archiving: return .original
        }
    }
    
    /// 권장 포맷
    var recommendedFormat: ImageFormat {
        switch self {
        case .storage:
            if #available(iOS 11.0, *) {
                return .heic(quality: 0.9)
            } else {
                return .jpeg(quality: 0.9)
            }
        case .upload:
            return .jpeg(quality: 0.8)
        case .display:
            return .jpeg(quality: 0.85)
        case .sharing:
            return .jpeg(quality: 0.9)
        case .archiving:
            if #available(iOS 11.0, *) {
                return .heic(quality: 0.95)
            } else {
                return .jpeg(quality: 0.95)
            }
        }
    }
}

/// 압축 매니저
class CompressionManager {
    
    // MARK: - 프리셋 적용
    
    /// 프리셋을 사용하여 이미지 압축
    static func compress(
        _ image: UIImage,
        preset: CompressionPreset,
        format: ImageFormat? = nil
    ) -> Data? {
        // 리사이즈가 필요한 경우
        var processedImage = image
        if let maxDim = preset.maxDimension {
            let targetSize = calculateTargetSize(
                originalSize: image.size,
                maxDimension: maxDim
            )
            
            if targetSize != image.size {
                processedImage = ImageResizer.resize(
                    image,
                    to: targetSize,
                    method: .imageIO,
                    mode: .aspectFit
                ) ?? image
            }
        }
        
        // 포맷 결정
        let targetFormat: ImageFormat
        if let format = format {
            targetFormat = format
        } else {
            // HEIC 가능하면 사용
            if #available(iOS 11.0, *) {
                targetFormat = .heic(quality: preset.heicQuality)
            } else {
                targetFormat = .jpeg(quality: preset.jpegQuality)
            }
        }
        
        return FormatConverter.convert(processedImage, to: targetFormat)
    }
    
    /// 용도에 맞게 압축
    static func compress(_ image: UIImage, for purpose: CompressionPurpose) -> Data? {
        let preset = purpose.recommendedPreset
        let format = purpose.recommendedFormat
        return compress(image, preset: preset, format: format)
    }
    
    // MARK: - 타겟 크기 맞추기
    
    /// 특정 파일 크기 이하로 압축
    static func compressToSize(
        _ image: UIImage,
        maxFileSize: Int,
        format: ImageFormat = .jpeg(quality: 1.0)
    ) -> Data? {
        return FormatConverter.adaptiveCompress(
            image,
            targetFileSize: maxFileSize,
            format: format
        )
    }
    
    // MARK: - 최적화 추천
    
    /// 이미지 분석 후 최적 설정 추천
    struct OptimizationRecommendation {
        let shouldResize: Bool
        let recommendedSize: CGSize?
        let recommendedFormat: ImageFormat
        let recommendedPreset: CompressionPreset
        let estimatedFileSize: Int
        let reason: String
    }
    
    static func recommendOptimization(
        for image: UIImage,
        purpose: CompressionPurpose
    ) -> OptimizationRecommendation {
        let originalSize = image.size
        let preset = purpose.recommendedPreset
        let format = purpose.recommendedFormat
        
        // 리사이즈 필요 여부
        var shouldResize = false
        var recommendedSize: CGSize? = nil
        
        if let maxDim = preset.maxDimension {
            let maxOriginalDim = max(originalSize.width, originalSize.height)
            if maxOriginalDim > maxDim {
                shouldResize = true
                recommendedSize = calculateTargetSize(
                    originalSize: originalSize,
                    maxDimension: maxDim
                )
            }
        }
        
        // 예상 파일 크기 계산
        let originalPixels = originalSize.width * originalSize.height
        let bytesPerPixel: CGFloat = 4  // RGBA
        let estimatedOriginalSize = Int(originalPixels * bytesPerPixel)
        let estimatedFileSize = Int(Double(estimatedOriginalSize) * preset.estimatedSizeRatio)
        
        // 추천 이유
        var reason = ""
        if shouldResize {
            reason += "이미지가 너무 큼 (리사이즈 권장). "
        }
        
        switch purpose {
        case .storage:
            reason += "로컬 저장용: HEIC로 공간 절약"
        case .upload:
            reason += "업로드용: 적당한 크기와 품질"
        case .display:
            reason += "화면 표시용: 표준 품질"
        case .sharing:
            reason += "공유용: 높은 품질 유지"
        case .archiving:
            reason += "아카이빙용: 원본 품질 보존"
        }
        
        return OptimizationRecommendation(
            shouldResize: shouldResize,
            recommendedSize: recommendedSize,
            recommendedFormat: format,
            recommendedPreset: preset,
            estimatedFileSize: estimatedFileSize,
            reason: reason
        )
    }
    
    // MARK: - Helper
    
    /// 최대 크기에 맞게 타겟 크기 계산
    private static func calculateTargetSize(
        originalSize: CGSize,
        maxDimension: CGFloat
    ) -> CGSize {
        let maxOriginalDim = max(originalSize.width, originalSize.height)
        
        if maxOriginalDim <= maxDimension {
            return originalSize
        }
        
        let ratio = maxDimension / maxOriginalDim
        
        return CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
    }
}

// MARK: - 배치 압축

extension CompressionManager {
    
    /// 배치 압축 결과
    struct BatchResult {
        let originalCount: Int
        let successCount: Int
        let totalOriginalSize: Int
        let totalCompressedSize: Int
        let duration: TimeInterval
        
        var compressionRatio: Double {
            guard totalOriginalSize > 0 else { return 0 }
            return Double(totalCompressedSize) / Double(totalOriginalSize)
        }
        
        var savedBytes: Int {
            return totalOriginalSize - totalCompressedSize
        }
        
        var savedPercentage: Double {
            guard totalOriginalSize > 0 else { return 0 }
            return Double(savedBytes) / Double(totalOriginalSize) * 100
        }
    }
    
    /// 여러 이미지 일괄 압축
    static func batchCompress(
        images: [UIImage],
        preset: CompressionPreset,
        format: ImageFormat? = nil,
        progress: ((Int, Int) -> Void)? = nil
    ) -> (data: [Data], result: BatchResult) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var compressedData: [Data] = []
        var totalOriginalSize = 0
        var totalCompressedSize = 0
        
        for (index, image) in images.enumerated() {
            autoreleasepool {
                // 원본 예상 크기
                let originalSize = Int(image.size.width * image.size.height * 4)
                totalOriginalSize += originalSize
                
                // 압축
                if let data = compress(image, preset: preset, format: format) {
                    compressedData.append(data)
                    totalCompressedSize += data.count
                }
                
                progress?(index + 1, images.count)
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        let result = BatchResult(
            originalCount: images.count,
            successCount: compressedData.count,
            totalOriginalSize: totalOriginalSize,
            totalCompressedSize: totalCompressedSize,
            duration: duration
        )
        
        return (compressedData, result)
    }
}

// MARK: - 포맷 헬퍼

extension CompressionManager.OptimizationRecommendation {
    var formattedEstimatedSize: String {
        if estimatedFileSize < 1024 {
            return "\(estimatedFileSize) B"
        } else if estimatedFileSize < 1024 * 1024 {
            return String(format: "%.1f KB", Double(estimatedFileSize) / 1024.0)
        } else {
            return String(format: "%.2f MB", Double(estimatedFileSize) / (1024.0 * 1024.0))
        }
    }
}

extension CompressionManager.BatchResult {
    var formattedDuration: String {
        String(format: "%.2f초", duration)
    }
    
    var formattedSaved: String {
        if savedBytes < 1024 {
            return "\(savedBytes) B"
        } else if savedBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(savedBytes) / 1024.0)
        } else {
            return String(format: "%.2f MB", Double(savedBytes) / (1024.0 * 1024.0))
        }
    }
}

