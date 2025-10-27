//
//  PerformanceLogger.swift
//  day07
//
//  성능 측정을 위한 통합 로거
//  Console.app, Instruments에서 모두 확인 가능
//

import Foundation
import os.log

/// 성능 로거
enum PerformanceLogger {
    // subsystem은 앱 번들 ID와 매칭
    static let subsystem = "com.study.day07"
    
    // 카테고리별 로거
    static let loading = Logger(subsystem: subsystem, category: "loading")
    static let rendering = Logger(subsystem: subsystem, category: "rendering")
    static let filtering = Logger(subsystem: subsystem, category: "filtering")
    static let memory = Logger(subsystem: subsystem, category: "memory")
    static let benchmark = Logger(subsystem: subsystem, category: "benchmark")
    
    // OSLog 버전 (signpost용)
    static let loadingLog = OSLog(subsystem: subsystem, category: "loading")
    static let renderingLog = OSLog(subsystem: subsystem, category: "rendering")
    static let filteringLog = OSLog(subsystem: subsystem, category: "filtering")
    
    /// 간단 로그 헬퍼
    static func log(_ message: String, category: String = "rendering") {
        switch category {
        case "loading": loading.info("\(message)")
        case "filtering": filtering.info("\(message)")
        case "memory": memory.info("\(message)")
        case "benchmark": benchmark.info("\(message)")
        default: rendering.info("\(message)")
        }
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "rendering") {
        switch category {
        case "loading": loading.error("\(message)")
        case "filtering": filtering.error("\(message)")
        case "memory": memory.error("\(message)")
        case "benchmark": benchmark.error("\(message)")
        default: rendering.error("\(message)")
        }
    }
    
    /// 디버그 로그 (개발 중에만)
    static func debug(_ message: String, category: String = "rendering") {
        #if DEBUG
        switch category {
        case "loading": loading.debug("\(message)")
        case "filtering": filtering.debug("\(message)")
        case "memory": memory.debug("\(message)")
        case "benchmark": benchmark.debug("\(message)")
        default: rendering.debug("\(message)")
        }
        #endif
    }
}

