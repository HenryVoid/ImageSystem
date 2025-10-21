//
//  ImageProcessor.swift
//  day03
//
//  Created on 2025-10-21.
//

import CoreImage
import UIKit
import Metal

/// Core Image 필터 처리 클래스
/// CIContext를 재사용하여 성능 최적화
class ImageProcessor {
    
    // MARK: - Properties
    
    /// Metal 기반 CIContext (GPU 가속)
    /// ⚠️ Context 생성 비용이 매우 높으므로 반드시 재사용!
    private let context: CIContext = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("⚠️ Metal 디바이스 생성 실패, CPU 폴백")
            return CIContext()
        }
        print("✅ Metal 기반 CIContext 생성 완료")
        return CIContext(mtlDevice: device)
    }()
    
    /// 필터 객체 재사용 (성능 최적화)
    private let blurFilter = CIFilter(name: "CIGaussianBlur")!
    private let sepiaFilter = CIFilter(name: "CISepiaTone")!
    private let sharpenFilter = CIFilter(name: "CISharpenLuminance")!
    private let vignetteFilter = CIFilter(name: "CIVignette")!
    private let colorControlsFilter = CIFilter(name: "CIColorControls")!
    
    // MARK: - Singleton
    
    static let shared = ImageProcessor()
    
    private init() {
        print("🎨 ImageProcessor 초기화")
    }
    
    // MARK: - Basic Filters
    
    /// 블러 필터 적용
    func applyBlur(to image: CIImage, radius: Double = 10) -> CIImage? {
        blurFilter.setValue(image, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
        return blurFilter.outputImage
    }
    
    /// 세피아 필터 적용
    func applySepia(to image: CIImage, intensity: Double = 0.8) -> CIImage? {
        sepiaFilter.setValue(image, forKey: kCIInputImageKey)
        sepiaFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        return sepiaFilter.outputImage
    }
    
    /// 샤픈 필터 적용
    func applySharpen(to image: CIImage, sharpness: Double = 0.4) -> CIImage? {
        sharpenFilter.setValue(image, forKey: kCIInputImageKey)
        sharpenFilter.setValue(sharpness, forKey: kCIInputSharpnessKey)
        return sharpenFilter.outputImage
    }
    
    /// 비네팅 필터 적용 (가장자리 어둡게)
    func applyVignette(to image: CIImage, intensity: Double = 1.0) -> CIImage? {
        vignetteFilter.setValue(image, forKey: kCIInputImageKey)
        vignetteFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        return vignetteFilter.outputImage
    }
    
    /// 밝기 조정
    func adjustBrightness(to image: CIImage, brightness: Double = 0.0) -> CIImage? {
        colorControlsFilter.setValue(image, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        colorControlsFilter.setValue(1.0, forKey: kCIInputSaturationKey)
        colorControlsFilter.setValue(1.0, forKey: kCIInputContrastKey)
        return colorControlsFilter.outputImage
    }
    
    /// 채도 조정
    func adjustSaturation(to image: CIImage, saturation: Double = 1.0) -> CIImage? {
        colorControlsFilter.setValue(image, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
        colorControlsFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        colorControlsFilter.setValue(1.0, forKey: kCIInputContrastKey)
        return colorControlsFilter.outputImage
    }
    
    /// 대비 조정
    func adjustContrast(to image: CIImage, contrast: Double = 1.0) -> CIImage? {
        colorControlsFilter.setValue(image, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
        colorControlsFilter.setValue(1.0, forKey: kCIInputSaturationKey)
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
        return colorControlsFilter.outputImage
    }
    
    // MARK: - Rendering
    
    /// CIImage를 UIImage로 변환 (렌더링)
    func render(_ ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    /// CIImage를 CGImage로 변환
    func renderToCGImage(_ ciImage: CIImage) -> CGImage? {
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    /// 특정 영역만 렌더링
    func render(_ ciImage: CIImage, in rect: CGRect) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: rect) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Filter Chains
    
    /// 필터 체인: 블러 + 밝기 + 채도
    func applyBasicChain(to image: CIImage,
                        blurRadius: Double = 10,
                        brightness: Double = 0.3,
                        saturation: Double = 1.5) -> CIImage? {
        // 1단계: 블러
        guard let blurred = applyBlur(to: image, radius: blurRadius) else { return nil }
        
        // 2단계: 밝기
        let brightnessFilter = CIFilter(name: "CIColorControls")!
        brightnessFilter.setValue(blurred, forKey: kCIInputImageKey)
        brightnessFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        brightnessFilter.setValue(1.0, forKey: kCIInputSaturationKey)
        brightnessFilter.setValue(1.0, forKey: kCIInputContrastKey)
        
        guard let brightened = brightnessFilter.outputImage else { return nil }
        
        // 3단계: 채도
        let saturationFilter = CIFilter(name: "CIColorControls")!
        saturationFilter.setValue(brightened, forKey: kCIInputImageKey)
        saturationFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
        saturationFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        saturationFilter.setValue(1.0, forKey: kCIInputContrastKey)
        
        return saturationFilter.outputImage
    }
    
    /// Instagram 스타일 빈티지 필터
    func applyVintageFilter(to image: CIImage) -> CIImage? {
        // 1. 세피아 톤
        guard let sepia = applySepia(to: image, intensity: 0.8) else { return nil }
        
        // 2. 비네팅
        guard let vignette = applyVignette(to: sepia, intensity: 1.5) else { return nil }
        
        // 3. 색상 조정
        let colorControls = CIFilter(name: "CIColorControls")!
        colorControls.setValue(vignette, forKey: kCIInputImageKey)
        colorControls.setValue(1.1, forKey: kCIInputContrastKey)
        colorControls.setValue(0.9, forKey: kCIInputSaturationKey)
        
        guard let adjusted = colorControls.outputImage else { return nil }
        
        // 4. 샤픈
        return applySharpen(to: adjusted, sharpness: 0.4)
    }
    
    // MARK: - Utilities
    
    /// UIImage를 CIImage로 변환
    func ciImage(from uiImage: UIImage) -> CIImage? {
        return CIImage(image: uiImage)
    }
    
    /// 이미지 크롭 (extent 관리)
    func crop(_ image: CIImage, to rect: CGRect) -> CIImage {
        return image.cropped(to: rect)
    }
}

