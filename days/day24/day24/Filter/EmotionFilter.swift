//
//  EmotionFilter.swift
//  day24
//
//  Created on 12/01/25.
//

import CoreImage

/// 감정 점수에 따라 색감을 조절하는 커스텀 필터 (과제 A)
class EmotionFilter: CIFilter {
    @objc dynamic var inputImage: CIImage?
    
    /// 감정 점수 (0.0 ~ 100.0)
    /// 0에 가까울수록 차가운 톤, 100에 가까울수록 따뜻한 톤
    @objc dynamic var inputEmotion: Float = 50.0
    
    static var kernel: CIColorKernel? = {
        return CIColorKernel(source: CustomKernelCode.emotion)
    }()
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage,
              let kernel = EmotionFilter.kernel else {
            return nil
        }
        
        // kernel 인자: inputImage, emotionScore
        return kernel.apply(
            extent: inputImage.extent,
            arguments: [inputImage, inputEmotion]
        )
    }
}

