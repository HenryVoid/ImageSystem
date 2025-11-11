//
//  MemorySampler.swift
//  day10
//
//  메모리 사용량 측정 도구
//

import Foundation
import UIKit

/// 메모리 샘플
struct MemorySample {
    let timestamp: Date
    let usedMB: Double
    let availableMB: Double
    let totalMB: Double
    
    var usagePercentage: Double {
        guard totalMB > 0 else { return 0 }
        return (usedMB / totalMB) * 100
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

/// 메모리 샘플러
class MemorySampler: ObservableObject {
    // MARK: - Singleton
    
    static let shared = MemorySampler()
    
    // MARK: - Properties
    
    @Published private(set) var currentSample: MemorySample?
    @Published private(set) var samples: [MemorySample] = []
    @Published private(set) var isMonitoring = false
    
    private var timer: Timer?
    private let maxSampleCount = 300  // 최대 300개 샘플 (5분)
    
    // MARK: - Initialization
    
    init() {
        updateCurrentSample()
    }
    
    // MARK: - Memory Measurement
    
    /// 현재 메모리 사용량 (bytes)
    func currentMemoryUsageBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        return info.resident_size
    }
    
    /// 현재 메모리 사용량 (MB)
    func currentMemoryUsageMB() -> Double {
        return Double(currentMemoryUsageBytes()) / 1024 / 1024
    }
    
    /// 전체 시스템 메모리
    func totalPhysicalMemoryMB() -> Double {
        return Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
    }
    
    /// 사용 가능한 메모리 추정
    func availableMemoryMB() -> Double {
        let total = totalPhysicalMemoryMB()
        let used = currentMemoryUsageMB()
        return max(0, total - used)
    }
    
    // MARK: - Sampling
    
    /// 현재 샘플 업데이트
    func updateCurrentSample() {
        let sample = MemorySample(
            timestamp: Date(),
            usedMB: currentMemoryUsageMB(),
            availableMB: availableMemoryMB(),
            totalMB: totalPhysicalMemoryMB()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.currentSample = sample
        }
    }
    
    /// 샘플 추가
    private func addSample(_ sample: MemorySample) {
        samples.append(sample)
        
        // 최대 개수 유지
        if samples.count > maxSampleCount {
            samples.removeFirst()
        }
    }
    
    // MARK: - Monitoring
    
    /// 모니터링 시작
    func startMonitoring(interval: TimeInterval = 1.0) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let sample = MemorySample(
                timestamp: Date(),
                usedMB: self.currentMemoryUsageMB(),
                availableMB: self.availableMemoryMB(),
                totalMB: self.totalPhysicalMemoryMB()
            )
            
            DispatchQueue.main.async {
                self.currentSample = sample
                self.addSample(sample)
            }
        }
        
        print("📊 메모리 모니터링 시작 (간격: \(interval)초)")
    }
    
    /// 모니터링 중단
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        print("⏸️ 메모리 모니터링 중단")
    }
    
    /// 샘플 초기화
    func clearSamples() {
        samples.removeAll()
        print("🗑️ 메모리 샘플 삭제 완료")
    }
    
    // MARK: - Statistics
    
    /// 평균 메모리 사용량
    func averageMemoryUsage() -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + $1.usedMB }
        return sum / Double(samples.count)
    }
    
    /// 최대 메모리 사용량
    func maxMemoryUsage() -> Double {
        return samples.map { $0.usedMB }.max() ?? 0
    }
    
    /// 최소 메모리 사용량
    func minMemoryUsage() -> Double {
        return samples.map { $0.usedMB }.min() ?? 0
    }
    
    /// 메모리 사용량 트렌드
    func usageTrend() -> [Double] {
        return samples.map { $0.usedMB }
    }
    
    /// 메모리 경고 확인
    func isMemoryPressureHigh() -> Bool {
        guard let current = currentSample else { return false }
        return current.usagePercentage > 80
    }
    
    // MARK: - Report
    
    func summary() -> String {
        guard let current = currentSample else {
            return "메모리 데이터 없음"
        }
        
        return """
        📊 메모리 사용량
        ────────────────────────
        현재 사용: \(String(format: "%.1f", current.usedMB)) MB
        전체 메모리: \(String(format: "%.1f", current.totalMB)) MB
        사용률: \(String(format: "%.1f", current.usagePercentage))%
        
        \(samples.isEmpty ? "" : statisticsReport())
        """
    }
    
    private func statisticsReport() -> String {
        """
        📈 통계 (샘플 \(samples.count)개)
        ────────────────────────
        평균: \(String(format: "%.1f", averageMemoryUsage())) MB
        최대: \(String(format: "%.1f", maxMemoryUsage())) MB
        최소: \(String(format: "%.1f", minMemoryUsage())) MB
        """
    }
}













