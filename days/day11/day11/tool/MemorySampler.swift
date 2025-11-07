import Foundation
import os

class MemorySampler {
    
    // MARK: - Singleton
    
    static let shared = MemorySampler()
    
    // MARK: - Properties
    
    private var samples: [MemorySample] = []
    private var timer: Timer?
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Memory Sample
    
    struct MemorySample {
        let timestamp: Date
        let usedMemory: UInt64
        let availableMemory: UInt64
        let totalMemory: UInt64
        
        var usedMemoryMB: Double {
            Double(usedMemory) / 1024 / 1024
        }
        
        var availableMemoryMB: Double {
            Double(availableMemory) / 1024 / 1024
        }
        
        var totalMemoryMB: Double {
            Double(totalMemory) / 1024 / 1024
        }
        
        var usagePercentage: Double {
            guard totalMemory > 0 else { return 0 }
            return Double(usedMemory) / Double(totalMemory) * 100.0
        }
    }
    
    // MARK: - Memory Measurement
    
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    func getTotalMemory() -> UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }
    
    func getAvailableMemory() -> UInt64 {
        let total = getTotalMemory()
        let used = getCurrentMemoryUsage()
        return total > used ? total - used : 0
    }
    
    func getCurrentSample() -> MemorySample {
        let used = getCurrentMemoryUsage()
        let total = getTotalMemory()
        let available = getAvailableMemory()
        
        return MemorySample(
            timestamp: Date(),
            usedMemory: used,
            availableMemory: available,
            totalMemory: total
        )
    }
    
    // MARK: - Monitoring
    
    func startMonitoring(interval: TimeInterval = 0.1) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        samples.removeAll()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let sample = self.getCurrentSample()
            self.samples.append(sample)
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    func getSamples() -> [MemorySample] {
        return samples
    }
    
    func clearSamples() {
        samples.removeAll()
    }
    
    // MARK: - Statistics
    
    struct MemoryStats {
        let peakUsage: UInt64
        let averageUsage: UInt64
        let minUsage: UInt64
        let maxUsage: UInt64
        let sampleCount: Int
        
        var peakUsageMB: Double {
            Double(peakUsage) / 1024 / 1024
        }
        
        var averageUsageMB: Double {
            Double(averageUsage) / 1024 / 1024
        }
        
        var formattedPeakUsage: String {
            String(format: "%.1f MB", peakUsageMB)
        }
        
        var formattedAverageUsage: String {
            String(format: "%.1f MB", averageUsageMB)
        }
    }
    
    func getStats() -> MemoryStats? {
        guard !samples.isEmpty else { return nil }
        
        let usages = samples.map { $0.usedMemory }
        
        return MemoryStats(
            peakUsage: usages.max() ?? 0,
            averageUsage: UInt64(usages.reduce(0, +) / UInt64(usages.count)),
            minUsage: usages.min() ?? 0,
            maxUsage: usages.max() ?? 0,
            sampleCount: samples.count
        )
    }
    
    // MARK: - Memory Measurement with Operation
    
    func measureMemory<T>(during operation: () -> T) -> (result: T, memoryUsed: UInt64) {
        let before = getCurrentMemoryUsage()
        let result = operation()
        let after = getCurrentMemoryUsage()
        
        let memoryUsed = after > before ? after - before : 0
        
        return (result, memoryUsed)
    }
    
    func measureMemoryAsync<T>(during operation: () async -> T) async -> (result: T, memoryUsed: UInt64) {
        let before = getCurrentMemoryUsage()
        let result = await operation()
        let after = getCurrentMemoryUsage()
        
        let memoryUsed = after > before ? after - before : 0
        
        return (result, memoryUsed)
    }
    
    // MARK: - Memory Warning
    
    func isMemoryWarning() -> Bool {
        let sample = getCurrentSample()
        return sample.usagePercentage > 80.0 // 80% 이상 사용 시 경고
    }
    
    func getMemoryPressureLevel() -> MemoryPressureLevel {
        let sample = getCurrentSample()
        let percentage = sample.usagePercentage
        
        switch percentage {
        case 0..<50:
            return .normal
        case 50..<70:
            return .moderate
        case 70..<85:
            return .high
        default:
            return .critical
        }
    }
    
    enum MemoryPressureLevel {
        case normal
        case moderate
        case high
        case critical
        
        var description: String {
            switch self {
            case .normal: return "정상"
            case .moderate: return "보통"
            case .high: return "높음"
            case .critical: return "위험"
            }
        }
        
        var color: String {
            switch self {
            case .normal: return "green"
            case .moderate: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}


