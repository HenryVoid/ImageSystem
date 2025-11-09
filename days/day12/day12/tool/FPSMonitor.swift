//
//  FPSMonitor.swift
//  day12
//
//  CADisplayLink 기반 FPS 측정
//

import UIKit
import SwiftUI

/// FPS 모니터
@MainActor
class FPSMonitor: ObservableObject {
    @Published private(set) var currentFPS: Double = 0
    @Published private(set) var averageFPS: Double = 0
    @Published private(set) var minFPS: Double = 60
    @Published private(set) var maxFPS: Double = 0
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsValues: [Double] = []
    
    // MARK: - Public Methods
    
    /// FPS 모니터링 시작
    func startMonitoring() {
        guard displayLink == nil else { return }
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .common)
        
        resetStats()
    }
    
    /// FPS 모니터링 중지
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// 통계 리셋
    func resetStats() {
        lastTimestamp = 0
        frameCount = 0
        fpsValues.removeAll()
        currentFPS = 0
        averageFPS = 0
        minFPS = 60
        maxFPS = 0
    }
    
    // MARK: - Private Methods
    
    @objc private func displayLinkTick(displayLink: CADisplayLink) {
        guard lastTimestamp != 0 else {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        // 프레임 간 시간 계산
        let elapsed = displayLink.timestamp - lastTimestamp
        lastTimestamp = displayLink.timestamp
        
        // FPS 계산
        if elapsed > 0 {
            let fps = 1.0 / elapsed
            updateFPS(fps)
        }
    }
    
    private func updateFPS(_ fps: Double) {
        // 현재 FPS
        currentFPS = fps
        
        // FPS 값 저장 (최근 60개만 유지)
        fpsValues.append(fps)
        if fpsValues.count > 60 {
            fpsValues.removeFirst()
        }
        
        // 평균 FPS
        averageFPS = fpsValues.reduce(0, +) / Double(fpsValues.count)
        
        // 최소/최대 FPS
        minFPS = min(minFPS, fps)
        maxFPS = max(maxFPS, fps)
        
        frameCount += 1
    }
}

// MARK: - Extensions

extension FPSMonitor {
    /// FPS 상태를 색상으로 표현
    var fpsColor: Color {
        switch currentFPS {
        case 55...60:
            return .green  // 매우 좋음
        case 45..<55:
            return .yellow // 양호
        case 30..<45:
            return .orange // 주의
        default:
            return .red    // 나쁨
        }
    }
    
    /// FPS 상태 텍스트
    var fpsStatus: String {
        switch currentFPS {
        case 55...60:
            return "매우 부드러움"
        case 45..<55:
            return "부드러움"
        case 30..<45:
            return "약간 끊김"
        default:
            return "많이 끊김"
        }
    }
    
    /// 통계 요약
    var statistics: String {
        """
        FPS Statistics:
        - Current: \(String(format: "%.1f", currentFPS))
        - Average: \(String(format: "%.1f", averageFPS))
        - Min: \(String(format: "%.1f", minFPS))
        - Max: \(String(format: "%.1f", maxFPS))
        - Frames: \(frameCount)
        """
    }
}


