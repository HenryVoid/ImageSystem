//
//  PerformanceLogger.swift
//  day05
//
//  성능 측정을 위한 통합 로거
//  Console.app, 인스트루먼트에서 모두 확인 가능
//

import Foundation
import os.log

/// 성능 로거
enum PerformanceLogger {
    // subsystem은 앱 번들 ID와 매칭
    static let subsystem = "com.study.day05"
    
    // 카테고리별 로거
    static let resize = Logger(subsystem: subsystem, category: "resize")
    static let format = Logger(subsystem: subsystem, category: "format")
    static let memory = Logger(subsystem: subsystem, category: "memory")
    static let benchmark = Logger(subsystem: subsystem, category: "benchmark")
    
    // OSLog 버전 (signpost용)
    static let resizeLog = OSLog(subsystem: subsystem, category: "resize")
    static let formatLog = OSLog(subsystem: subsystem, category: "format")
    
    /// 간단 로그 헬퍼
    static func log(_ message: String, category: String = "resize") {
        switch category {
        case "format": format.info("\(message)")
        case "memory": memory.info("\(message)")
        case "benchmark": benchmark.info("\(message)")
        default: resize.info("\(message)")
        }
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "resize") {
        switch category {
        case "format": format.error("\(message)")
        case "memory": memory.error("\(message)")
        case "benchmark": benchmark.error("\(message)")
        default: resize.error("\(message)")
        }
    }
    
    /// 디버그 로그 (개발 중에만)
    static func debug(_ message: String, category: String = "resize") {
        #if DEBUG
        switch category {
        case "format": format.debug("\(message)")
        case "memory": memory.debug("\(message)")
        case "benchmark": benchmark.debug("\(message)")
        default: resize.debug("\(message)")
        }
        #endif
    }
}

