//
//  MetalContext.swift
//  day13
//
//  Created on 11/10/25.
//

import Metal
import MetalKit

/// Metal 디바이스와 커맨드 큐를 관리하는 싱글톤
final class MetalContext {
    static let shared = MetalContext()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    
    private init?() {
        // Metal 디바이스 생성
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ Metal을 지원하지 않는 디바이스입니다.")
            return nil
        }
        self.device = device
        
        // 커맨드 큐 생성
        guard let commandQueue = device.makeCommandQueue() else {
            print("❌ Command Queue 생성 실패")
            return nil
        }
        self.commandQueue = commandQueue
        
        // 기본 라이브러리 로드
        guard let library = device.makeDefaultLibrary() else {
            print("❌ Metal Library 로드 실패")
            return nil
        }
        self.library = library
        
        print("✅ Metal 초기화 성공")
        print("   - 디바이스: \(device.name)")
    }
    
    /// Metal 지원 여부 확인
    static var isSupported: Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }
}

