//
//  GIFPerformanceMonitor.swift
//  day19
//
//  GIF 성능 모니터링 도구
//

import Foundation
import UIKit

/// 성능 메트릭
struct PerformanceMetrics {
    /// 메모리 사용량 (MB)
    var memoryUsage: Double = 0
    
    /// CPU 사용률 (%)
    var cpuUsage: Double = 0
    
    /// 프레임 레이트 (FPS)
    var frameRate: Double = 0
    
    /// 로딩 시간 (초)
    var loadTime: TimeInterval = 0
    
    /// 프레임 드롭 수
    var droppedFrames: Int = 0
}

/// 성능 모니터
class GIFPerformanceMonitor {
    private var startTime: CFTimeInterval = 0
    private var frameCount = 0
    private var lastFrameTime: CFTimeInterval = 0
    private var droppedFrames = 0
    private var expectedFrameInterval: TimeInterval = 0
    
    /// 모니터링 시작
    func start(expectedFrameInterval: TimeInterval) {
        self.expectedFrameInterval = expectedFrameInterval
        startTime = CACurrentMediaTime()
        lastFrameTime = startTime
        frameCount = 0
        droppedFrames = 0
    }
    
    /// 프레임 기록
    func recordFrame() {
        frameCount += 1
        
        let currentTime = CACurrentMediaTime()
        let actualInterval = currentTime - lastFrameTime
        
        // 프레임 드롭 감지 (20% 이상 지연)
        if actualInterval > expectedFrameInterval * 1.2 {
            droppedFrames += 1
        }
        
        lastFrameTime = currentTime
    }
    
    /// 현재 메트릭 가져오기
    func getCurrentMetrics() -> PerformanceMetrics {
        let elapsed = CACurrentMediaTime() - startTime
        let fps = elapsed > 0 ? Double(frameCount) / elapsed : 0
        
        return PerformanceMetrics(
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage(),
            frameRate: fps,
            loadTime: elapsed,
            droppedFrames: droppedFrames
        )
    }
    
    /// 메모리 사용량 측정 (MB)
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        }
        
        return 0
    }
    
    /// CPU 사용률 측정 (%)
    private func getCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        // 간단한 CPU 사용률 추정 (실제로는 더 복잡한 계산 필요)
        // 여기서는 메모리 사용량 기반으로 추정
        if kerr == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / (1024 * 1024)
            // 간단한 추정 (실제 구현에서는 host_statistics 사용)
            return min(memoryMB / 100.0 * 10, 100.0)
        }
        
        return 0
    }
    
    /// 리셋
    func reset() {
        startTime = 0
        frameCount = 0
        lastFrameTime = 0
        droppedFrames = 0
    }
}

/// 메모리 샘플러
class MemorySampler {
    /// 현재 메모리 사용량 측정 (MB)
    static func getCurrentMemory() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        }
        
        return 0
    }
    
    /// 메모리 변화 측정
    static func measureMemoryDelta<T>(_ operation: () throws -> T) rethrows -> (result: T, delta: Double) {
        let before = getCurrentMemory()
        let result = try operation()
        let after = getCurrentMemory()
        let delta = after - before
        return (result, delta)
    }
    
    /// 메모리 로그 출력
    static func logCurrentMemory(label: String) {
        let memory = getCurrentMemory()
        print("[Memory] \(label): \(String(format: "%.2f", memory)) MB")
    }
}

/// 성능 로거
class PerformanceLogger {
    private static let subsystem = "com.study.day19"
    
    /// 로그 출력
    static func log(_ message: String, category: String = "performance") {
        print("[\(category)] \(message)")
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "performance") {
        print("[ERROR][\(category)] \(message)")
    }
    
    /// 메트릭 로그
    static func logMetrics(_ metrics: PerformanceMetrics, label: String) {
        print("""
        [Metrics] \(label):
        - 메모리: \(String(format: "%.2f", metrics.memoryUsage)) MB
        - CPU: \(String(format: "%.1f", metrics.cpuUsage))%
        - FPS: \(String(format: "%.1f", metrics.frameRate))
        - 로딩 시간: \(String(format: "%.3f", metrics.loadTime))초
        - 프레임 드롭: \(metrics.droppedFrames)
        """)
    }
}

