//
//  PerformanceLogger.swift
//  day08
//
//  성능 측정을 위한 os_signpost 래퍼

import Foundation
import os.log
import os.signpost

/// 성능 로깅 헬퍼
class PerformanceLogger {
    static let shared = PerformanceLogger()
    
    private let subsystem = "com.study.day08"
    private let log: OSLog
    
    private init() {
        log = OSLog(subsystem: subsystem, category: "performance")
    }
    
    // MARK: - Signpost API
    
    /// Signpost 시작
    func beginSignpost(name: StaticString) -> OSSignpostID {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        return id
    }
    
    /// Signpost 종료
    func endSignpost(name: StaticString, id: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }
    
    /// Signpost 이벤트 (단일 시점)
    func signpostEvent(name: StaticString, message: String = "") {
        if message.isEmpty {
            os_signpost(.event, log: log, name: name)
        } else {
            os_signpost(.event, log: log, name: name, "%{public}s", message)
        }
    }
    
    // MARK: - 간편 로깅
    
    /// 정보 로그
    func log(_ message: String, category: String = "general") {
        let categoryLog = OSLog(subsystem: subsystem, category: category)
        os_log(.info, log: categoryLog, "%{public}s", message)
    }
    
    /// 에러 로그
    func error(_ message: String, category: String = "general") {
        let categoryLog = OSLog(subsystem: subsystem, category: category)
        os_log(.error, log: categoryLog, "%{public}s", message)
    }
    
    /// 디버그 로그
    func debug(_ message: String, category: String = "general") {
        let categoryLog = OSLog(subsystem: subsystem, category: category)
        os_log(.debug, log: categoryLog, "%{public}s", message)
    }
    
    // MARK: - 시간 측정 헬퍼
    
    /// 블록 실행 시간 측정
    func measure<T>(name: String, block: () -> T) -> (result: T, duration: TimeInterval) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        log("\(name): \(String(format: "%.2f", duration * 1000))ms", category: "timing")
        
        return (result, duration)
    }
    
    /// 비동기 블록 실행 시간 측정
    func measureAsync<T>(name: String, block: () async -> T) async -> (result: T, duration: TimeInterval) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = await block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        log("\(name): \(String(format: "%.2f", duration * 1000))ms", category: "timing")
        
        return (result, duration)
    }
}

// MARK: - 편의 확장

extension PerformanceLogger {
    /// 이미지 로딩 시작 signpost
    func beginImageLoad(url: String) -> OSSignpostID {
        let id = beginSignpost(name: "Image_Load")
        log("로딩 시작: \(url)", category: "loading")
        return id
    }
    
    /// 이미지 로딩 종료 signpost
    func endImageLoad(id: OSSignpostID, url: String, success: Bool) {
        endSignpost(name: "Image_Load", id: id)
        let status = success ? "성공" : "실패"
        log("로딩 \(status): \(url)", category: "loading")
    }
    
    /// 캐시 히트
    func logCacheHit(url: String) {
        signpostEvent(name: "Cache_Hit", message: url)
        log("✅ 캐시 히트: \(url)", category: "cache")
    }
    
    /// 캐시 미스
    func logCacheMiss(url: String) {
        signpostEvent(name: "Cache_Miss", message: url)
        log("❌ 캐시 미스: \(url)", category: "cache")
    }
}

// MARK: - 통계 추적

class PerformanceStats {
    private(set) var samples: [TimeInterval] = []
    
    func addSample(_ duration: TimeInterval) {
        samples.append(duration)
    }
    
    func reset() {
        samples.removeAll()
    }
    
    var count: Int {
        samples.count
    }
    
    var average: TimeInterval {
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0, +) / Double(samples.count)
    }
    
    var minimum: TimeInterval {
        samples.min() ?? 0
    }
    
    var maximum: TimeInterval {
        samples.max() ?? 0
    }
    
    var total: TimeInterval {
        samples.reduce(0, +)
    }
    
    var description: String {
        guard !samples.isEmpty else { return "데이터 없음" }
        
        return """
        횟수: \(count)
        평균: \(String(format: "%.2f", average * 1000))ms
        최소: \(String(format: "%.2f", minimum * 1000))ms
        최대: \(String(format: "%.2f", maximum * 1000))ms
        총합: \(String(format: "%.2f", total))s
        """
    }
}































