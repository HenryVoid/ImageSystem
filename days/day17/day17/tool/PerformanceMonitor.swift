//
//  PerformanceMonitor.swift
//  day17
//
//  FPS 및 메모리 실시간 모니터링
//

import Foundation
import UIKit
import Combine

/// 성능 모니터 - FPS 및 메모리 측정
@MainActor
class PerformanceMonitor: ObservableObject {
    @Published var fps: Double = 0
    @Published var memoryUsage: String = "0 MB"
    @Published var isMonitoring = false
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsUpdateTimer: Timer?
    private var memoryUpdateTimer: Timer?
    
    /// 모니터링 시작
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // FPS 측정
        lastTimestamp = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .common)
        
        // 메모리 측정 (1초마다)
        memoryUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMemory()
        }
        
        PerformanceLogger.log("성능 모니터링 시작", category: "benchmark")
    }
    
    /// 모니터링 중지
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        
        displayLink?.invalidate()
        displayLink = nil
        
        fpsUpdateTimer?.invalidate()
        fpsUpdateTimer = nil
        
        memoryUpdateTimer?.invalidate()
        memoryUpdateTimer = nil
        
        PerformanceLogger.log("성능 모니터링 중지", category: "benchmark")
    }
    
    /// FPS 업데이트
    @objc private func updateFPS() {
        let currentTimestamp = CACurrentMediaTime()
        frameCount += 1
        
        let elapsed = currentTimestamp - lastTimestamp
        
        // 1초마다 FPS 계산
        if elapsed >= 1.0 {
            fps = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = currentTimestamp
            
            PerformanceLogger.log("FPS: \(String(format: "%.1f", fps))", category: "fps")
        }
    }
    
    /// 메모리 업데이트
    private func updateMemory() {
        let usage = MemorySampler.currentUsage()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        memoryUsage = formatter.string(fromByteCount: usage)
        
        PerformanceLogger.log("메모리: \(memoryUsage)", category: "memory")
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Performance Stats View

struct PerformanceStatsView: View {
    @ObservedObject var monitor: PerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FPS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f", monitor.fps))
                    .font(.caption)
                    .bold()
                    .foregroundColor(monitor.fps >= 25 ? .green : .red)
            }
            
            HStack {
                Text("메모리")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(monitor.memoryUsage)
                    .font(.caption)
                    .bold()
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .foregroundColor(.white)
    }
}

