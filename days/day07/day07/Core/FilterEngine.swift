//
//  FilterEngine.swift
//  day07
//
//  Core Image 필터 체인 관리 및 성능 최적화
//

import CoreImage
import UIKit

/// 필터 타입
enum FilterType: String, CaseIterable, Identifiable {
    case none = "원본"
    case blur = "블러"
    case sepia = "세피아"
    case vignette = "비네팅"
    case colorControls = "색상 조정"
    case sharpen = "선명하게"
    
    var id: String { rawValue }
    
    var filterName: String? {
        switch self {
        case .none: return nil
        case .blur: return "CIGaussianBlur"
        case .sepia: return "CISepiaTone"
        case .vignette: return "CIVignette"
        case .colorControls: return "CIColorControls"
        case .sharpen: return "CISharpenLuminance"
        }
    }
}

/// 필터 프리셋
struct FilterPreset: Identifiable {
    let id = UUID()
    let name: String
    let filters: [FilterType]
    
    static let presets: [FilterPreset] = [
        FilterPreset(name: "빈티지", filters: [.sepia, .vignette]),
        FilterPreset(name: "드라마틱", filters: [.colorControls, .sharpen]),
        FilterPreset(name: "소프트", filters: [.blur, .colorControls]),
        FilterPreset(name: "강렬", filters: [.sharpen, .colorControls, .vignette])
    ]
}

/// 필터 엔진
class FilterEngine {
    static let shared = FilterEngine()
    
    // CIContext 재사용 (성능 최적화)
    private let context: CIContext
    
    private init() {
        // Metal 기반 컨텍스트 생성 (GPU 가속)
        self.context = CIContext(options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .cacheIntermediates: true,
            .useSoftwareRenderer: false
        ])
    }
    
    // MARK: - 단일 필터 적용
    
    /// 블러 필터 적용
    func applyBlur(to ciImage: CIImage, radius: Double = 10.0) -> CIImage? {
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        return filter?.outputImage
    }
    
    /// 세피아 필터 적용
    func applySepia(to ciImage: CIImage, intensity: Double = 0.8) -> CIImage? {
        let filter = CIFilter(name: "CISepiaTone")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter?.outputImage
    }
    
    /// 비네팅 필터 적용
    func applyVignette(to ciImage: CIImage, intensity: Double = 1.0) -> CIImage? {
        let filter = CIFilter(name: "CIVignette")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter?.outputImage
    }
    
    /// 색상 조정 필터 적용
    func applyColorControls(to ciImage: CIImage, brightness: Double = 0.1, contrast: Double = 1.2, saturation: Double = 1.2) -> CIImage? {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        return filter?.outputImage
    }
    
    /// 선명하게 필터 적용
    func applySharpen(to ciImage: CIImage, sharpness: Double = 0.5) -> CIImage? {
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(sharpness, forKey: kCIInputSharpnessKey)
        return filter?.outputImage
    }
    
    // MARK: - 필터 체인 적용
    
    /// 필터 체인 적용
    func applyFilterChain(_ filters: [FilterType], to ciImage: CIImage) -> CIImage? {
        var result = ciImage
        
        for filter in filters {
            guard let filtered = applyFilter(filter, to: result) else {
                continue
            }
            result = filtered
        }
        
        return result
    }
    
    /// 단일 필터 적용 (타입에 따라)
    func applyFilter(_ filter: FilterType, to ciImage: CIImage) -> CIImage? {
        switch filter {
        case .none:
            return ciImage
        case .blur:
            return applyBlur(to: ciImage)
        case .sepia:
            return applySepia(to: ciImage)
        case .vignette:
            return applyVignette(to: ciImage)
        case .colorControls:
            return applyColorControls(to: ciImage)
        case .sharpen:
            return applySharpen(to: ciImage)
        }
    }
    
    /// 프리셋 적용
    func applyPreset(_ preset: FilterPreset, to ciImage: CIImage) -> CIImage? {
        return applyFilterChain(preset.filters, to: ciImage)
    }
    
    // MARK: - 이미지 변환
    
    /// CIImage를 UIImage로 변환
    func convertToUIImage(_ ciImage: CIImage) -> UIImage? {
        // extent 사용 (무한 extent 방지)
        let extent = ciImage.extent
        
        guard extent.width > 0 && extent.height > 0 else {
            return nil
        }
        
        guard let cgImage = context.createCGImage(ciImage, from: extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// UIImage에 필터 적용 (편의 메서드)
    func applyFilter(_ filter: FilterType, to uiImage: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: uiImage) else { return nil }
        guard let filtered = applyFilter(filter, to: ciImage) else { return nil }
        return convertToUIImage(filtered)
    }
    
    /// UIImage에 필터 체인 적용 (편의 메서드)
    func applyFilterChain(_ filters: [FilterType], to uiImage: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: uiImage) else { return nil }
        guard let filtered = applyFilterChain(filters, to: ciImage) else { return nil }
        return convertToUIImage(filtered)
    }
    
    // MARK: - 성능 측정용
    
    /// 필터 체인 적용 시간 측정
    func measureFilterChain(_ filters: [FilterType], to ciImage: CIImage) -> (result: CIImage?, time: TimeInterval) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = applyFilterChain(filters, to: ciImage)
        let end = CFAbsoluteTimeGetCurrent()
        return (result, end - start)
    }
}

