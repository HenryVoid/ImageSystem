import Foundation
import os.signpost

class PerformanceLogger {
    
    // MARK: - Singleton
    
    static let shared = PerformanceLogger()
    
    // MARK: - Properties
    
    private let log: OSLog
    private var activeSignposts: [String: OSSignpostID] = [:]
    
    // MARK: - Initialization
    
    private init() {
        log = OSLog(subsystem: "com.study.day11", category: "Compression")
    }
    
    // MARK: - Signpost Methods
    
    func logCompressionStart(format: ImageFormat, quality: Double) {
        let name = "Compression-\(format.rawValue)-\(quality)"
        let signpostID = OSSignpostID(log: log)
        
        activeSignposts[name] = signpostID
        
        os_signpost(
            .begin,
            log: log,
            name: "Compression",
            signpostID: signpostID,
            "Format: %{public}s, Quality: %.2f",
            format.rawValue,
            quality
        )
    }
    
    func logCompressionEnd(format: ImageFormat, quality: Double, size: Int) {
        let name = "Compression-\(format.rawValue)-\(quality)"
        
        guard let signpostID = activeSignposts[name] else {
            return
        }
        
        os_signpost(
            .end,
            log: log,
            name: "Compression",
            signpostID: signpostID,
            "Size: %d bytes",
            size
        )
        
        activeSignposts.removeValue(forKey: name)
    }
    
    func logBenchmarkStart() {
        let signpostID = OSSignpostID(log: log)
        activeSignposts["Benchmark"] = signpostID
        
        os_signpost(
            .begin,
            log: log,
            name: "Benchmark",
            signpostID: signpostID
        )
    }
    
    func logBenchmarkEnd(resultsCount: Int) {
        guard let signpostID = activeSignposts["Benchmark"] else {
            return
        }
        
        os_signpost(
            .end,
            log: log,
            name: "Benchmark",
            signpostID: signpostID,
            "Results: %d",
            resultsCount
        )
        
        activeSignposts.removeValue(forKey: "Benchmark")
    }
    
    // MARK: - Event Logging
    
    func logEvent(_ message: String, type: OSSignpostType = .event) {
        os_signpost(
            type,
            log: log,
            name: "Event",
            "%{public}s",
            message
        )
    }
    
    // MARK: - Interval Measurement
    
    func measureTime<T>(_ operation: () -> T) -> (result: T, duration: TimeInterval) {
        let start = Date()
        let result = operation()
        let duration = Date().timeIntervalSince(start)
        
        return (result, duration)
    }
    
    func measureTimeAsync<T>(_ operation: () async -> T) async -> (result: T, duration: TimeInterval) {
        let start = Date()
        let result = await operation()
        let duration = Date().timeIntervalSince(start)
        
        return (result, duration)
    }
    
    // MARK: - Statistics
    
    struct CompressionStats {
        let format: ImageFormat
        let quality: Double
        let count: Int
        let totalTime: TimeInterval
        let averageTime: TimeInterval
        let minTime: TimeInterval
        let maxTime: TimeInterval
        let totalSize: Int
        let averageSize: Int
        
        var formattedAverageTime: String {
            String(format: "%.1f ms", averageTime * 1000)
        }
        
        var formattedTotalTime: String {
            String(format: "%.2f s", totalTime)
        }
        
        var formattedAverageSize: String {
            ByteCountFormatter.string(fromByteCount: Int64(averageSize), countStyle: .file)
        }
    }
    
    func calculateStats(from results: [CompressionResult]) -> [CompressionStats] {
        let grouped = Dictionary(grouping: results) { result in
            "\(result.format.rawValue)-\(result.quality)"
        }
        
        return grouped.compactMap { (key, results) in
            guard let first = results.first else { return nil }
            
            let times = results.map { $0.compressionTime }
            let sizes = results.map { $0.compressedSize }
            
            return CompressionStats(
                format: first.format,
                quality: first.quality,
                count: results.count,
                totalTime: times.reduce(0, +),
                averageTime: times.reduce(0, +) / Double(times.count),
                minTime: times.min() ?? 0,
                maxTime: times.max() ?? 0,
                totalSize: sizes.reduce(0, +),
                averageSize: sizes.reduce(0, +) / sizes.count
            )
        }
    }
}


