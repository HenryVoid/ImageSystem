//
//  MemorySampler.swift
//  day08
//
//  메모리 사용량 측정

import Foundation
import os.log

/// 메모리 사용량 샘플러
class MemorySampler {
    static let shared = MemorySampler()
    
    private let log = OSLog(subsystem: "com.study.day08", category: "memory")
    
    private init() {}
    
    // MARK: - 메모리 측정
    
    /// 현재 메모리 사용량 (바이트)
    func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return 0
        }
        
        return info.resident_size
    }
    
    /// 현재 메모리 사용량 (MB)
    func currentMemoryUsageMB() -> Double {
        let bytes = currentMemoryUsage()
        return Double(bytes) / 1024.0 / 1024.0
    }
    
    /// 메모리 사용량 로그
    func logMemoryUsage(label: String = "") {
        let usage = currentMemoryUsageMB()
        let message = label.isEmpty ? "메모리 사용량: \(String(format: "%.2f", usage))MB" 
                                    : "\(label): \(String(format: "%.2f", usage))MB"
        
        os_log(.info, log: log, "%{public}s", message)
        print("📊 \(message)")
    }
    
    // MARK: - 메모리 변화 추적
    
    /// 메모리 변화 측정
    func measureMemoryChange<T>(label: String, block: () -> T) -> (result: T, delta: Double) {
        let before = currentMemoryUsageMB()
        let result = block()
        let after = currentMemoryUsageMB()
        let delta = after - before
        
        let message = "\(label) 메모리 변화: \(String(format: "%+.2f", delta))MB (전: \(String(format: "%.2f", before))MB → 후: \(String(format: "%.2f", after))MB)"
        os_log(.info, log: log, "%{public}s", message)
        print("📊 \(message)")
        
        return (result, delta)
    }
    
    /// 비동기 메모리 변화 측정
    func measureMemoryChangeAsync<T>(label: String, block: () async -> T) async -> (result: T, delta: Double) {
        let before = currentMemoryUsageMB()
        let result = await block()
        let after = currentMemoryUsageMB()
        let delta = after - before
        
        let message = "\(label) 메모리 변화: \(String(format: "%+.2f", delta))MB (전: \(String(format: "%.2f", before))MB → 후: \(String(format: "%.2f", after))MB)"
        os_log(.info, log: log, "%{public}s", message)
        print("📊 \(message)")
        
        return (result, delta)
    }
    
    // MARK: - 메모리 경고
    
    /// 메모리 경고 옵저버 등록
    func observeMemoryWarnings(handler: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logMemoryUsage(label: "⚠️ 메모리 경고")
            handler()
        }
    }
}

// MARK: - 메모리 통계

class MemoryStats {
    private(set) var samples: [Double] = []
    
    func addSample(_ memoryMB: Double) {
        samples.append(memoryMB)
    }
    
    func reset() {
        samples.removeAll()
    }
    
    var count: Int {
        samples.count
    }
    
    var average: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0, +) / Double(samples.count)
    }
    
    var minimum: Double {
        samples.min() ?? 0
    }
    
    var maximum: Double {
        samples.max() ?? 0
    }
    
    var peak: Double {
        maximum
    }
    
    var description: String {
        guard !samples.isEmpty else { return "데이터 없음" }
        
        return """
        측정 횟수: \(count)
        평균: \(String(format: "%.2f", average))MB
        최소: \(String(format: "%.2f", minimum))MB
        최대: \(String(format: "%.2f", maximum))MB
        피크: \(String(format: "%.2f", peak))MB
        """
    }
}

// MARK: - 포맷팅 헬퍼

extension MemorySampler {
    /// 바이트를 읽기 쉬운 문자열로 변환
    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// MB를 읽기 쉬운 문자열로 변환
    static func formatMB(_ mb: Double) -> String {
        return String(format: "%.2f MB", mb)
    }
}




