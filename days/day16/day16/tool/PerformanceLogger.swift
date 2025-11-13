//
//  PerformanceLogger.swift
//  day16
//
//  성능 측정 로깅 유틸리티
//

import Foundation
import os.log

/// 성능 로거
enum PerformanceLogger {
    // subsystem은 앱 번들 ID와 매칭
    static let subsystem = "com.study.day16"
    
    // 카테고리별 로거
    static let camera = Logger(subsystem: subsystem, category: "camera")
    static let permission = Logger(subsystem: subsystem, category: "permission")
    static let memory = Logger(subsystem: subsystem, category: "memory")
    static let benchmark = Logger(subsystem: subsystem, category: "benchmark")
    static let fps = Logger(subsystem: subsystem, category: "fps")
    
    // OSLog 버전 (signpost용)
    static let cameraLog = OSLog(subsystem: subsystem, category: "camera")
    static let permissionLog = OSLog(subsystem: subsystem, category: "permission")
    
    /// 간단 로그 헬퍼
    static func log(_ message: String, category: String = "camera") {
        switch category {
        case "permission": permission.info("\(message)")
        case "memory": memory.info("\(message)")
        case "benchmark": benchmark.info("\(message)")
        case "fps": fps.info("\(message)")
        default: camera.info("\(message)")
        }
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "camera") {
        switch category {
        case "permission": permission.error("\(message)")
        case "memory": memory.error("\(message)")
        case "benchmark": benchmark.error("\(message)")
        case "fps": fps.error("\(message)")
        default: camera.error("\(message)")
        }
    }
    
    /// 디버그 로그 (개발 중에만)
    static func debug(_ message: String, category: String = "camera") {
        #if DEBUG
        switch category {
        case "permission": permission.debug("\(message)")
        case "memory": memory.debug("\(message)")
        case "benchmark": benchmark.debug("\(message)")
        case "fps": fps.debug("\(message)")
        default: camera.debug("\(message)")
        }
        #endif
    }
}

