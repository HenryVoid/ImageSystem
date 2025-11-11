//
//  MemorySampler.swift
//  day15
//
//  메모리 사용량 측정 유틸리티
//

import Foundation

/// 메모리 샘플러
class MemorySampler {
    
    /// 현재 메모리 사용량 (바이트)
    static func currentUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    /// 메모리 사용량을 사람이 읽기 쉬운 형태로 포맷
    static func formattedUsage() -> String {
        let usage = currentUsage()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: usage)
    }
    
    /// 메모리 샘플링 시작
    static func startSampling(interval: TimeInterval = 1.0, label: String = "Memory") {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            let usage = formattedUsage()
            PerformanceLogger.log("[\(label)] 메모리 사용량: \(usage)", category: "memory")
        }
    }
    
    /// 메모리 차이 측정
    static func measure<T>(_ label: String, block: () -> T) -> (result: T, memoryUsed: Int64) {
        let before = currentUsage()
        let result = block()
        let after = currentUsage()
        let diff = after - before
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        
        PerformanceLogger.log("[\(label)] 메모리 증가: \(formatter.string(fromByteCount: diff))", category: "memory")
        
        return (result, diff)
    }
}
