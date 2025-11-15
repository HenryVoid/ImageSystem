//
//  PerformanceLogger.swift
//  day18
//
//  썸네일 생성 성능 측정 로깅 유틸리티
//

import Foundation
import os.log

/// 성능 로거
enum PerformanceLogger {
    // subsystem은 앱 번들 ID와 매칭
    static let subsystem = "com.study.day18"
    
    // 카테고리별 로거
    static let thumbnail = Logger(subsystem: subsystem, category: "thumbnail")
    static let memory = Logger(subsystem: subsystem, category: "memory")
    static let benchmark = Logger(subsystem: subsystem, category: "benchmark")
    static let cache = Logger(subsystem: subsystem, category: "cache")
    
    // OSLog 버전 (signpost용)
    static let thumbnailLog = OSLog(subsystem: subsystem, category: "thumbnail")
    static let benchmarkLog = OSLog(subsystem: subsystem, category: "benchmark")
    
    /// 간단 로그 헬퍼
    static func log(_ message: String, category: String = "thumbnail") {
        switch category {
        case "memory": memory.info("\(message)")
        case "benchmark": benchmark.info("\(message)")
        case "cache": cache.info("\(message)")
        default: thumbnail.info("\(message)")
        }
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "thumbnail") {
        switch category {
        case "memory": memory.error("\(message)")
        case "benchmark": benchmark.error("\(message)")
        case "cache": cache.error("\(message)")
        default: thumbnail.error("\(message)")
        }
    }
    
    /// 디버그 로그 (개발 중에만)
    static func debug(_ message: String, category: String = "thumbnail") {
        #if DEBUG
        switch category {
        case "memory": memory.debug("\(message)")
        case "benchmark": benchmark.debug("\(message)")
        case "cache": cache.debug("\(message)")
        default: thumbnail.debug("\(message)")
        }
        #endif
    }
}

/// 성능 측정 헬퍼
struct PerformanceMeasurer {
    /// 실행 시간 측정
    static func measureTime<T>(_ operation: () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
    
    /// 실행 시간 측정 (동기)
    static func measureTimeSync<T>(_ operation: () throws -> T) rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
    
    /// 메모리 사용량 측정
    static func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    /// 메모리 사용량을 읽기 쉬운 형식으로 변환
    static func formatMemoryUsage(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

