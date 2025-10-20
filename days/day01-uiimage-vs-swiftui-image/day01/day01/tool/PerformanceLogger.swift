//
//  PerformanceLogger.swift
//  day01
//
//  성능 측정을 위한 통합 로거
//  Console.app, 인스트루먼트에서 모두 확인 가능
//

import Foundation
import os.log

/// 1) Logger 준비 (콘솔/Console.app/인스트루먼트 공용)
enum PerformanceLogger {
  // subsystem은 앱 번들 ID와 매칭하면 좋음
  static let subsystem = "com.study.day01"
  
  // 카테고리별 로거
  static let bench = Logger(subsystem: subsystem, category: "bench")
  static let scroll = Logger(subsystem: subsystem, category: "scroll")
  static let memory = Logger(subsystem: subsystem, category: "memory")
  static let fps = Logger(subsystem: subsystem, category: "fps")
  
  // OSLog 버전 (signpost용)
  static let benchLog = OSLog(subsystem: subsystem, category: "bench")
  static let scrollLog = OSLog(subsystem: subsystem, category: "scroll")
  
  /// 간단 로그 헬퍼
  static func log(_ message: String, category: String = "bench") {
    switch category {
    case "scroll": scroll.info("\(message)")
    case "memory": memory.info("\(message)")
    case "fps": fps.info("\(message)")
    default: bench.info("\(message)")
    }
  }
  
  /// 에러 로그
  static func error(_ message: String, category: String = "bench") {
    switch category {
    case "scroll": scroll.error("\(message)")
    case "memory": memory.error("\(message)")
    case "fps": fps.error("\(message)")
    default: bench.error("\(message)")
    }
  }
  
  /// 디버그 로그 (개발 중에만)
  static func debug(_ message: String, category: String = "bench") {
#if DEBUG
    switch category {
    case "scroll": scroll.debug("\(message)")
    case "memory": memory.debug("\(message)")
    case "fps": fps.debug("\(message)")
    default: bench.debug("\(message)")
    }
#endif
  }
}

