import UIKit
import CoreVideo

struct ImagePredictor {
    /// UIImage를 지정된 크기(224x224)로 리사이즈하고 CVPixelBuffer로 변환합니다.
    /// CoreML 모델이 직접 CVPixelBuffer를 요구할 때 사용합니다.
    /// Vision 프레임워크를 사용할 경우 이 과정은 내부적으로 처리될 수 있습니다.
    static func pixelBuffer(from image: UIImage, width: Int = 224, height: Int = 224) -> CVPixelBuffer? {
        // 1. CVPixelBuffer 속성 설정
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        // 2. CVPixelBuffer 생성
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        // 3. PixelBuffer 잠금 (쓰기 위해)
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // 4. 그래픽 컨텍스트 생성
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        // 5. 이미지 그리기 (리사이즈 및 포맷 변환 효과)
        // 이미지의 오리엔테이션을 고려하여 그리기 위해 UIGraphicsPushContext 등을 사용할 수도 있으나,
        // 여기서는 간단히 CGContext에 그립니다.
        // UIImage가 오리엔테이션 정보를 가지고 있다면 draw(in:)을 사용하는 것이 더 안전할 수 있습니다.
        // 하지만 CVPixelBuffer로 그릴 때는 CGContext를 직접 사용해야 하므로,
        // 아래 코드는 원본 이미지가 정방향(Up)이라고 가정하거나 CGImage를 직접 사용합니다.
        
        // 더 강력한 방법: UIGraphicsImageRenderer 사용 (SwiftUI/UIKit 환경)
        // 또는 CGContextDrawImage 사용
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        // 6. 잠금 해제
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
    
    /// 이미지를 정사각형으로 크롭하고 리사이즈합니다.
    static func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Aspect Fill 비율 계산
        let ratio = max(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let rect = CGRect(x: (targetSize.width - newSize.width) / 2.0,
                          y: (targetSize.height - newSize.height) / 2.0,
                          width: newSize.width,
                          height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

