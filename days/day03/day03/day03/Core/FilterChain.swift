//
//  FilterChain.swift
//  day03
//
//  Created on 2025-10-21.
//

import CoreImage
import UIKit
import Metal

/// 재사용 가능한 필터 체인 클래스
/// 여러 필터를 연결하여 한번에 렌더링
class FilterChain {
    
    // MARK: - Properties
    
    private var filters: [CIFilter] = []
    
    private let context: CIContext = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return CIContext()
        }
        return CIContext(mtlDevice: device)
    }()
    
    // MARK: - Public Methods
    
    /// 필터 추가 (체이닝 패턴)
    @discardableResult
    func addFilter(_ filter: CIFilter) -> Self {
        filters.append(filter)
        return self
    }
    
    /// 이름으로 필터 추가
    @discardableResult
    func addFilter(name: String, parameters: [String: Any] = [:]) -> Self {
        guard let filter = CIFilter(name: name) else {
            print("⚠️ 필터 생성 실패: \(name)")
            return self
        }
        
        // 파라미터 설정
        for (key, value) in parameters {
            filter.setValue(value, forKey: key)
        }
        
        filters.append(filter)
        return self
    }
    
    /// 필터 체인 적용
    func apply(to image: CIImage) -> UIImage? {
        guard !filters.isEmpty else {
            print("⚠️ 필터가 비어있습니다")
            return nil
        }
        
        var currentImage = image
        
        // 필터 체인 구성
        for (index, filter) in filters.enumerated() {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            
            guard let output = filter.outputImage else {
                print("⚠️ 필터 \(index) 출력 실패")
                continue
            }
            
            currentImage = output
        }
        
        // 한번에 렌더링
        guard let cgImage = context.createCGImage(currentImage, from: image.extent) else {
            print("⚠️ 렌더링 실패")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// CIImage로 반환 (렌더링 없이)
    func applyCIImage(to image: CIImage) -> CIImage? {
        guard !filters.isEmpty else { return nil }
        
        var currentImage = image
        
        for filter in filters {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            guard let output = filter.outputImage else { continue }
            currentImage = output
        }
        
        return currentImage
    }
    
    /// 체인 초기화
    func reset() {
        filters.removeAll()
    }
    
    /// 필터 개수
    var count: Int {
        return filters.count
    }
    
    // MARK: - Preset Chains
    
    /// 프리셋: Instagram 빈티지
    static func vintageChain() -> FilterChain {
        return FilterChain()
            .addFilter(name: "CISepiaTone", parameters: [
                kCIInputIntensityKey: 0.8
            ])
            .addFilter(name: "CIVignette", parameters: [
                kCIInputIntensityKey: 1.5
            ])
            .addFilter(name: "CIColorControls", parameters: [
                kCIInputContrastKey: 1.1,
                kCIInputSaturationKey: 0.9
            ])
            .addFilter(name: "CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.4
            ])
    }
    
    /// 프리셋: 드라마틱
    static func dramaticChain() -> FilterChain {
        return FilterChain()
            .addFilter(name: "CIColorControls", parameters: [
                kCIInputContrastKey: 1.5,
                kCIInputSaturationKey: 1.3
            ])
            .addFilter(name: "CIVignette", parameters: [
                kCIInputIntensityKey: 2.0
            ])
            .addFilter(name: "CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.6
            ])
    }
    
    /// 프리셋: 부드러운 꿈결
    static func dreamyChain() -> FilterChain {
        return FilterChain()
            .addFilter(name: "CIGaussianBlur", parameters: [
                kCIInputRadiusKey: 3
            ])
            .addFilter(name: "CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.2,
                kCIInputSaturationKey: 1.2
            ])
    }
    
    /// 프리셋: 블랙 앤 화이트
    static func bwChain() -> FilterChain {
        return FilterChain()
            .addFilter(name: "CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputContrastKey: 1.2
            ])
            .addFilter(name: "CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.5
            ])
    }
}

