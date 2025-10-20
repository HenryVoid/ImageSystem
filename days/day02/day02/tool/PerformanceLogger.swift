//
//  PerformanceLogger.swift
//  day02
//
//  성능 측정을 위한 통합 로거
//  Console.app, 인스트루먼트에서 모두 확인 가능
//

import Foundation
import os.log

/// 1) Logger 준비 (콘솔/Console.app/인스트루먼트 공용)
enum PerformanceLogger {
  // subsystem은 앱 번들 ID와 매칭하면 좋음
  static let subsystem = "com.study.day02"
  
  // 카테고리별 로거
  static let bench = Logger(subsystem: subsystem, category: "bench")
  static let render = Logger(subsystem: subsystem, category: "render")
  static let memory = Logger(subsystem: subsystem, category: "memory")
  static let graphics = Logger(subsystem: subsystem, category: "graphics")
  
  // OSLog 버전 (signpost용)
  static let benchLog = OSLog(subsystem: subsystem, category: "bench")
  static let renderLog = OSLog(subsystem: subsystem, category: "render")
  
  /// 간단 로그 헬퍼
  static func log(_ message: String, category: String = "bench") {
    switch category {
    case "render": render.info("\(message)")
    case "memory": memory.info("\(message)")
    case "graphics": graphics.info("\(message)")
    default: bench.info("\(message)")
    }
  }
  
  /// 에러 로그
  static func error(_ message: String, category: String = "bench") {
    switch category {
    case "render": render.error("\(message)")
    case "memory": memory.error("\(message)")
    case "graphics": graphics.error("\(message)")
    default: bench.error("\(message)")
    }
  }
  
  /// 디버그 로그 (개발 중에만)
  static func debug(_ message: String, category: String = "bench") {
#if DEBUG
    switch category {
    case "render": render.debug("\(message)")
    case "memory": memory.debug("\(message)")
    case "graphics": graphics.debug("\(message)")
    default: bench.debug("\(message)")
    }
#endif
  }
}

