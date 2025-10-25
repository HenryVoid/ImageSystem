//
//  PerformanceLogger.swift
//  day06
//
//  성능 측정을 위한 통합 로거
//  Console.app, 인스트루먼트에서 모두 확인 가능
//

import Foundation
import os.log

/// 성능 로거
enum PerformanceLogger {
    // subsystem은 앱 번들 ID와 매칭
    static let subsystem = "com.study.day06"
    
    // 카테고리별 로거
    static let rendering = Logger(subsystem: subsystem, category: "rendering")
    static let interpolation = Logger(subsystem: subsystem, category: "interpolation")
    static let memory = Logger(subsystem: subsystem, category: "memory")
    static let benchmark = Logger(subsystem: subsystem, category: "benchmark")
    
    // OSLog 버전 (signpost용)
    static let renderingLog = OSLog(subsystem: subsystem, category: "rendering")
    static let interpolationLog = OSLog(subsystem: subsystem, category: "interpolation")
    
    /// 간단 로그 헬퍼
    static func log(_ message: String, category: String = "rendering") {
        switch category {
        case "interpolation": interpolation.info("\(message)")
        case "memory": memory.info("\(message)")
        case "benchmark": benchmark.info("\(message)")
        default: rendering.info("\(message)")
        }
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "rendering") {
        switch category {
        case "interpolation": interpolation.error("\(message)")
        case "memory": memory.error("\(message)")
        case "benchmark": benchmark.error("\(message)")
        default: rendering.error("\(message)")
        }
    }
    
    /// 디버그 로그 (개발 중에만)
    static func debug(_ message: String, category: String = "rendering") {
        #if DEBUG
        switch category {
        case "interpolation": interpolation.debug("\(message)")
        case "memory": memory.debug("\(message)")
        case "benchmark": benchmark.debug("\(message)")
        default: rendering.debug("\(message)")
        }
        #endif
    }
}

