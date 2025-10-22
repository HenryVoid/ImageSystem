//
//  PerformanceLogger.swift
//  day04
//
//  성능 측정을 위한 통합 로거
//  Console.app, 인스트루먼트에서 모두 확인 가능
//

import Foundation
import os.log

/// 성능 로거
enum PerformanceLogger {
    // subsystem은 앱 번들 ID와 매칭
    static let subsystem = "com.study.day04"
    
    // 카테고리별 로거
    static let exif = Logger(subsystem: subsystem, category: "exif")
    static let imageIO = Logger(subsystem: subsystem, category: "imageIO")
    static let memory = Logger(subsystem: subsystem, category: "memory")
    static let benchmark = Logger(subsystem: subsystem, category: "benchmark")
    
    // OSLog 버전 (signpost용)
    static let exifLog = OSLog(subsystem: subsystem, category: "exif")
    static let imageIOLog = OSLog(subsystem: subsystem, category: "imageIO")
    
    /// 간단 로그 헬퍼
    static func log(_ message: String, category: String = "exif") {
        switch category {
        case "imageIO": imageIO.info("\(message)")
        case "memory": memory.info("\(message)")
        case "benchmark": benchmark.info("\(message)")
        default: exif.info("\(message)")
        }
    }
    
    /// 에러 로그
    static func error(_ message: String, category: String = "exif") {
        switch category {
        case "imageIO": imageIO.error("\(message)")
        case "memory": memory.error("\(message)")
        case "benchmark": benchmark.error("\(message)")
        default: exif.error("\(message)")
        }
    }
    
    /// 디버그 로그 (개발 중에만)
    static func debug(_ message: String, category: String = "exif") {
        #if DEBUG
        switch category {
        case "imageIO": imageIO.debug("\(message)")
        case "memory": memory.debug("\(message)")
        case "benchmark": benchmark.debug("\(message)")
        default: exif.debug("\(message)")
        }
        #endif
    }
}

