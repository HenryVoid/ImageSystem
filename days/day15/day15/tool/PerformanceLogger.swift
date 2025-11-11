//
//  PerformanceLogger.swift
//  day15
//
//  성능 측정 로깅 유틸리티
//

import Foundation
import os.log

/// 성능 로거
enum PerformanceLogger {
    // subsystem은 앱 번들 ID와 매칭
    static let subsystem = "com.study.day15"
    
    // 카테고리별 로거
    static let photos = Logger(subsystem: subsystem, category: "photos")
    static let permission = Logger(subsystem: subsystem, category: "permission")
    static let memory = Logger(subsystem: subsystem, category: "memory")
    static let benchmark = Logger(subsystem: subsystem, category: "benchmark")
    
    // OSLog 버전 (signpost용)
    static let photosLog = OSLog(subsystem: subsystem, category: "photos")
    static let permissionLog = OSLog(subsystem: subsystem, category: "permission")
    
    /// 간단 로그 헬퍼
    static func log(_ message: String, category: String = "photos") {
        switch category {
        case "permission": permission.info("\(message)")
        case "memory": memory.info("\(message)")
        case "benchmark": benchmark.info("\(message)")
        default: photos.info("\(message)")
        }
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "photos") {
        switch category {
        case "permission": permission.error("\(message)")
        case "memory": memory.error("\(message)")
        case "benchmark": benchmark.error("\(message)")
        default: photos.error("\(message)")
        }
    }
    
    /// 디버그 로그 (개발 중에만)
    static func debug(_ message: String, category: String = "photos") {
        #if DEBUG
        switch category {
        case "permission": permission.debug("\(message)")
        case "memory": memory.debug("\(message)")
        case "benchmark": benchmark.debug("\(message)")
        default: photos.debug("\(message)")
        }
        #endif
    }
}
