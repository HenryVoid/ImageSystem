//
//  HighlightFilter.swift
//  day24
//
//  Created on 12/01/25.
//

import CoreImage

/// 밝은 영역에만 색상을 입히는 필터 (과제 B)
class HighlightFilter: CIFilter {
    @objc dynamic var inputImage: CIImage?
    
    static var kernel: CIColorKernel? = {
        return CIColorKernel(source: CustomKernelCode.highlight)
    }()
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage,
              let kernel = HighlightFilter.kernel else {
            return nil
        }
        
        return kernel.apply(
            extent: inputImage.extent,
            arguments: [inputImage]
        )
    }
}

