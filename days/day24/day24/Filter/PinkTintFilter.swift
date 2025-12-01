//
//  PinkTintFilter.swift
//  day24
//
//  Created on 12/01/25.
//

import CoreImage

/// 가장 기본적인 형태의 Custom CIFilter
/// 입력 이미지를 받아 Pink 틴트를 적용합니다.
class PinkTintFilter: CIFilter {
    @objc dynamic var inputImage: CIImage?
    
    // 1. 커널 생성 (지연 초기화)
    // CIColorKernel(source:)는 컴파일 비용이 있으므로 static으로 한 번만 생성하는 것이 좋습니다.
    static var kernel: CIColorKernel? = {
        return CIColorKernel(source: CustomKernelCode.pinkTint)
    }()
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage,
              let kernel = PinkTintFilter.kernel else {
            return nil
        }
        
        // 2. 커널 적용
        // extent: 커널을 적용할 이미지의 영역 (보통 입력 이미지의 extent)
        // arguments: 커널 함수에 전달할 인자들 (inputImage 등)
        return kernel.apply(extent: inputImage.extent, arguments: [inputImage])
    }
}

