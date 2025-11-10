//
//  MemoryTracker.swift
//  day14
//
//  메모리 사용량 추적
//

import Foundation

/// 메모리 트래커
@Observable
class MemoryTracker {
    /// 현재 메모리 사용량 (MB)
    private(set) var currentMemoryUsage: Double = 0
    
    /// 피크 메모리 사용량 (MB)
    private(set) var peakMemoryUsage: Double = 0
    
    /// 타이머
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// 모니터링 시작
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    /// 모니터링 중지
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 메모리 사용량 업데이트
    private func updateMemoryUsage() {
        let usage = getMemoryUsage()
        currentMemoryUsage = usage
        
        if usage > peakMemoryUsage {
            peakMemoryUsage = usage
        }
    }
    
    /// 현재 메모리 사용량 가져오기 (MB)
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
            return Double(info.resident_size) / 1024 / 1024 // MB로 변환
        }
        
        return 0
    }
    
    /// 통계 초기화
    func reset() {
        peakMemoryUsage = 0
    }
}

