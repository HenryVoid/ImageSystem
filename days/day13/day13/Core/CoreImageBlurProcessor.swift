//
//  CoreImageBlurProcessor.swift
//  day13
//
//  Created on 11/10/25.
//

import UIKit
import CoreImage

/// Core Image의 CIGaussianBlur를 사용하는 프로세서
final class CoreImageBlurProcessor {
    private let context: CIContext
    
    init() {
        // Core Image 컨텍스트 생성 (CPU 기반)
        self.context = CIContext(options: [
            .useSoftwareRenderer: false  // GPU 사용
        ])
    }
    
    /// 이미지에 블러 적용
    func blur(image: UIImage, radius: Int) -> BlurResult? {
        let startTime = CACurrentMediaTime()
        
        guard let inputCGImage = image.cgImage else {
            print("❌ CGImage 변환 실패")
            return nil
        }
        
        let inputImage = CIImage(cgImage: inputCGImage)
        
        // Gaussian Blur 필터 생성
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            print("❌ CIGaussianBlur 필터 생성 실패")
            return nil
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(Float(radius), forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage else {
            print("❌ 필터 출력 이미지 생성 실패")
            return nil
        }
        
        // 블러로 인한 크기 증가를 원본 크기로 크롭
        let extent = inputImage.extent
        let croppedImage = outputImage.cropped(to: extent)
        
        // CGImage로 렌더링
        guard let outputCGImage = context.createCGImage(croppedImage, from: extent) else {
            print("❌ CGImage 렌더링 실패")
            return nil
        }
        
        let endTime = CACurrentMediaTime()
        let processingTime = (endTime - startTime) * 1000.0  // 밀리초로 변환
        
        let resultImage = UIImage(cgImage: outputCGImage)
        
        return BlurResult(
            image: resultImage,
            processingTime: processingTime,
            method: .coreImage,
            radius: radius
        )
    }
}

