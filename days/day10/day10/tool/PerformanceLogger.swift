//
//  PerformanceLogger.swift
//  day10
//
//  성능 측정 및 로깅 도구
//

import Foundation
import os.log
import os.signpost

/// 성능 측정 결과
struct PerformanceMeasurement {
    let operation: String
    let startTime: Date
    let endTime: Date
    let durationMs: Double
    let metadata: [String: Any]
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        if durationMs < 1 {
            return String(format: "%.2f", durationMs * 1000) + "μs"
        } else if durationMs < 1000 {
            return String(format: "%.2f", durationMs) + "ms"
        } else {
            return String(format: "%.2f", durationMs / 1000) + "s"
        }
    }
}

/// 성능 로거
class PerformanceLogger: ObservableObject {
    // MARK: - Singleton
    
    static let shared = PerformanceLogger()
    
    // MARK: - Properties
    
    @Published private(set) var measurements: [PerformanceMeasurement] = []
    
    private let log = OSLog(subsystem: "com.day10.cache", category: "Performance")
    private let signpostLog: OSLog
    
    private var activeTimers: [String: Date] = [:]
    private let maxMeasurements = 500
    
    // MARK: - Initialization
    
    init() {
        self.signpostLog = OSLog(subsystem: "com.day10.cache", category: .pointsOfInterest)
    }
    
    // MARK: - Timing
    
    /// 측정 시작
    func startMeasuring(_ operation: String) {
        activeTimers[operation] = Date()
        
        if #available(iOS 15.0, *) {
            os_signpost(.begin, log: signpostLog, name: "Operation", "%{public}s", operation)
        }
        
        print("⏱️ 시작: \(operation)")
    }
    
    /// 측정 종료
    @discardableResult
    func endMeasuring(_ operation: String, metadata: [String: Any] = [:]) -> PerformanceMeasurement? {
        guard let startTime = activeTimers[operation] else {
            print("⚠️ '\(operation)' 측정이 시작되지 않았습니다")
            return nil
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let durationMs = duration * 1000
        
        let measurement = PerformanceMeasurement(
            operation: operation,
            startTime: startTime,
            endTime: endTime,
            durationMs: durationMs,
            metadata: metadata
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.addMeasurement(measurement)
        }
        
        activeTimers.removeValue(forKey: operation)
        
        if #available(iOS 15.0, *) {
            os_signpost(.end, log: signpostLog, name: "Operation", "%{public}s: %.2fms", operation, durationMs)
        }
        
        print("⏱️ 완료: \(operation) - \(measurement.formattedDuration)")
        return measurement
    }
    
    /// 측정 및 실행
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation) }
        return try block()
    }
    
    /// 비동기 측정
    func measureAsync(_ operation: String, block: @escaping () async throws -> Void) async rethrows {
        startMeasuring(operation)
        defer { endMeasuring(operation) }
        try await block()
    }
    
    // MARK: - Measurements Management
    
    private func addMeasurement(_ measurement: PerformanceMeasurement) {
        measurements.append(measurement)
        
        // 최대 개수 유지
        if measurements.count > maxMeasurements {
            measurements.removeFirst()
        }
    }
    
    func clearMeasurements() {
        measurements.removeAll()
        print("🗑️ 성능 측정 데이터 삭제 완료")
    }
    
    // MARK: - Statistics
    
    /// 특정 작업의 측정 결과들
    func measurements(for operation: String) -> [PerformanceMeasurement] {
        return measurements.filter { $0.operation == operation }
    }
    
    /// 평균 시간
    func averageDuration(for operation: String) -> Double {
        let filtered = measurements(for: operation)
        guard !filtered.isEmpty else { return 0 }
        
        let sum = filtered.reduce(0.0) { $0 + $1.durationMs }
        return sum / Double(filtered.count)
    }
    
    /// 최소 시간
    func minDuration(for operation: String) -> Double {
        return measurements(for: operation).map { $0.durationMs }.min() ?? 0
    }
    
    /// 최대 시간
    func maxDuration(for operation: String) -> Double {
        return measurements(for: operation).map { $0.durationMs }.max() ?? 0
    }
    
    /// 중앙값
    func medianDuration(for operation: String) -> Double {
        let durations = measurements(for: operation).map { $0.durationMs }.sorted()
        guard !durations.isEmpty else { return 0 }
        
        let mid = durations.count / 2
        if durations.count % 2 == 0 {
            return (durations[mid - 1] + durations[mid]) / 2
        } else {
            return durations[mid]
        }
    }
    
    /// 표준 편차
    func standardDeviation(for operation: String) -> Double {
        let durations = measurements(for: operation).map { $0.durationMs }
        guard durations.count > 1 else { return 0 }
        
        let avg = averageDuration(for: operation)
        let squaredDiffs = durations.map { pow($0 - avg, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(durations.count - 1)
        return sqrt(variance)
    }
    
    // MARK: - Benchmarking
    
    /// 벤치마크 실행
    func benchmark(_ operation: String, iterations: Int, block: () throws -> Void) rethrows -> String {
        var durations: [Double] = []
        
        print("🏃 벤치마크 시작: \(operation) (\(iterations)회)")
        
        for i in 1...iterations {
            let start = Date()
            try block()
            let duration = Date().timeIntervalSince(start) * 1000
            durations.append(duration)
            
            if i % 10 == 0 {
                print("  진행: \(i)/\(iterations)")
            }
        }
        
        let avg = durations.reduce(0, +) / Double(iterations)
        let min = durations.min() ?? 0
        let max = durations.max() ?? 0
        
        let result = """
        📊 벤치마크 결과: \(operation)
        ────────────────────────
        반복 횟수: \(iterations)회
        평균: \(String(format: "%.2f", avg))ms
        최소: \(String(format: "%.2f", min))ms
        최대: \(String(format: "%.2f", max))ms
        """
        
        print(result)
        return result
    }
    
    // MARK: - Report
    
    func summary(for operation: String) -> String {
        let filtered = measurements(for: operation)
        guard !filtered.isEmpty else {
            return "'\(operation)'에 대한 측정 데이터 없음"
        }
        
        return """
        📊 성능 통계: \(operation)
        ────────────────────────
        측정 횟수: \(filtered.count)회
        평균: \(String(format: "%.2f", averageDuration(for: operation)))ms
        최소: \(String(format: "%.2f", minDuration(for: operation)))ms
        최대: \(String(format: "%.2f", maxDuration(for: operation)))ms
        중앙값: \(String(format: "%.2f", medianDuration(for: operation)))ms
        표준편차: \(String(format: "%.2f", standardDeviation(for: operation)))ms
        """
    }
    
    func allOperationsSummary() -> String {
        let operations = Set(measurements.map { $0.operation })
        
        guard !operations.isEmpty else {
            return "측정 데이터 없음"
        }
        
        var result = "📊 전체 성능 요약\n════════════════════════════════════\n\n"
        
        for operation in operations.sorted() {
            result += summary(for: operation) + "\n\n"
        }
        
        return result
    }
}











