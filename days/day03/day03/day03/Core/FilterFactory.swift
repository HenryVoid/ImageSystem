//
//  FilterFactory.swift
//  day03
//
//  Created on 2025-10-21.
//

import CoreImage

/// 필터 생성 헬퍼
/// 자주 사용하는 필터를 쉽게 생성
enum FilterFactory {
    
    // MARK: - Blur Filters
    
    static func gaussianBlur(radius: Double = 10) -> CIFilter? {
        return CIFilter(name: "CIGaussianBlur", parameters: [
            kCIInputRadiusKey: radius
        ])
    }
    
    static func motionBlur(radius: Double = 20, angle: Double = 0) -> CIFilter? {
        return CIFilter(name: "CIMotionBlur", parameters: [
            kCIInputRadiusKey: radius,
            kCIInputAngleKey: angle
        ])
    }
    
    static func boxBlur(radius: Double = 10) -> CIFilter? {
        return CIFilter(name: "CIBoxBlur", parameters: [
            kCIInputRadiusKey: radius
        ])
    }
    
    // MARK: - Color Adjustment
    
    static func colorControls(brightness: Double = 0,
                              saturation: Double = 1,
                              contrast: Double = 1) -> CIFilter? {
        return CIFilter(name: "CIColorControls", parameters: [
            kCIInputBrightnessKey: brightness,
            kCIInputSaturationKey: saturation,
            kCIInputContrastKey: contrast
        ])
    }
    
    static func exposureAdjust(ev: Double = 0) -> CIFilter? {
        return CIFilter(name: "CIExposureAdjust", parameters: [
            kCIInputEVKey: ev
        ])
    }
    
    static func vibrance(amount: Double = 0) -> CIFilter? {
        return CIFilter(name: "CIVibrance", parameters: [
            "inputAmount": amount
        ])
    }
    
    // MARK: - Stylize
    
    static func sepiaTone(intensity: Double = 1) -> CIFilter? {
        return CIFilter(name: "CISepiaTone", parameters: [
            kCIInputIntensityKey: intensity
        ])
    }
    
    static func vignette(intensity: Double = 1, radius: Double = 1) -> CIFilter? {
        return CIFilter(name: "CIVignette", parameters: [
            kCIInputIntensityKey: intensity,
            kCIInputRadiusKey: radius
        ])
    }
    
    static func pixellate(scale: Double = 8) -> CIFilter? {
        return CIFilter(name: "CIPixellate", parameters: [
            kCIInputScaleKey: scale
        ])
    }
    
    static func comicEffect() -> CIFilter? {
        return CIFilter(name: "CIComicEffect")
    }
    
    static func crystallize(radius: Double = 20) -> CIFilter? {
        return CIFilter(name: "CICrystallize", parameters: [
            kCIInputRadiusKey: radius
        ])
    }
    
    // MARK: - Sharpen
    
    static func sharpenLuminance(sharpness: Double = 0.4) -> CIFilter? {
        return CIFilter(name: "CISharpenLuminance", parameters: [
            kCIInputSharpnessKey: sharpness
        ])
    }
    
    static func unsharpMask(radius: Double = 2.5, intensity: Double = 0.5) -> CIFilter? {
        return CIFilter(name: "CIUnsharpMask", parameters: [
            kCIInputRadiusKey: radius,
            kCIInputIntensityKey: intensity
        ])
    }
    
    // MARK: - Distortion
    
    static func bumpDistortion(center: CIVector,
                               radius: Double = 300,
                               scale: Double = 0.5) -> CIFilter? {
        return CIFilter(name: "CIBumpDistortion", parameters: [
            kCIInputCenterKey: center,
            kCIInputRadiusKey: radius,
            kCIInputScaleKey: scale
        ])
    }
    
    static func pinchDistortion(center: CIVector,
                                radius: Double = 300,
                                scale: Double = 0.5) -> CIFilter? {
        return CIFilter(name: "CIPinchDistortion", parameters: [
            kCIInputCenterKey: center,
            kCIInputRadiusKey: radius,
            kCIInputScaleKey: scale
        ])
    }
    
    static func twirlDistortion(center: CIVector,
                                radius: Double = 300,
                                angle: Double = 3.14) -> CIFilter? {
        return CIFilter(name: "CITwirlDistortion", parameters: [
            kCIInputCenterKey: center,
            kCIInputRadiusKey: radius,
            kCIInputAngleKey: angle
        ])
    }
    
    // MARK: - Validation
    
    /// 필터 이름이 유효한지 확인
    static func isValidFilter(name: String) -> Bool {
        return CIFilter(name: name) != nil
    }
    
    /// 사용 가능한 모든 필터 목록
    static func availableFilters(in category: String? = nil) -> [String] {
        if let category = category {
            return CIFilter.filterNames(inCategory: category).sorted()
        } else {
            return CIFilter.filterNames(inCategory: kCICategoryBuiltIn).sorted()
        }
    }
    
    /// 필터의 속성 정보
    static func attributes(for filterName: String) -> [String: Any]? {
        guard let filter = CIFilter(name: filterName) else { return nil }
        return filter.attributes
    }
    
    // MARK: - Categories
    
    static let categoryBlur = kCICategoryBlur
    static let categoryColorAdjustment = kCICategoryColorAdjustment
    static let categoryStylize = kCICategoryStylize
    static let categoryDistortion = kCICategoryDistortionEffect
    static let categorySharpen = kCICategorySharpen
}

