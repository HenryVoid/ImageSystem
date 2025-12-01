//
//  CIContextManager.swift
//  day24
//
//  Created on 12/01/25.
//

import CoreImage
import Metal

/// CIContext를 재사용하기 위한 싱글톤 매니저
/// 매번 CIContext를 생성하는 것은 매우 비효율적이므로, 앱 전체에서 하나를 공유해서 사용합니다.
final class CIContextManager {
    static let shared = CIContextManager()
    
    let context: CIContext
    let device: MTLDevice?
    
    private init() {
        // 1. Metal 디바이스 생성
        self.device = MTLCreateSystemDefaultDevice()
        
        // 2. Metal 기반 CIContext 생성
        // Metal 디바이스를 공유하면 렌더링 성능이 향상되고 메모리 효율이 좋아집니다.
        if let device = self.device {
            self.context = CIContext(mtlDevice: device, options: [
                .cacheIntermediates: false, // 중간 결과 캐싱 끔 (메모리 절약)
                .useSoftwareRenderer: false // 항상 GPU 사용
            ])
        } else {
            // Metal을 지원하지 않는 경우 (거의 없지만 fallback)
            self.context = CIContext()
        }
    }
    
    /// CIImage를 CGImage로 렌더링
    func render(_ ciImage: CIImage) -> CGImage? {
        // 이미지의 전체 영역 렌더링
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

