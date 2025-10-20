//
//  SignpostHelper.swift
//  day02
//
//  2) 사인포스트(os_signpost) 헬퍼 (구간 타이밍 측정의 핵심)
//

import Foundation
import os.signpost

/// 사인포스트로 구간 측정을 쉽게 하기 위한 헬퍼
class SignpostHelper {
  private let log: OSLog
  private let name: StaticString
  private let label: String
  private var signpostID: OSSignpostID
  
  init(log: OSLog, name: StaticString, label: String = "") {
    self.log = log
    self.name = name
    self.label = label
    self.signpostID = OSSignpostID(log: log)
  }
  
  /// 측정 시작
  func begin() {
    signpostID = OSSignpostID(log: log)
    if label.isEmpty {
      os_signpost(.begin, log: log, name: name, signpostID: signpostID)
    } else {
      os_signpost(.begin, log: log, name: name, signpostID: signpostID, "%{public}s", label)
    }
  }
  
  /// 측정 종료
  func end() {
    if label.isEmpty {
      os_signpost(.end, log: log, name: name, signpostID: signpostID)
    } else {
      os_signpost(.end, log: log, name: name, signpostID: signpostID, "%{public}s", label)
    }
  }
  
  /// 이벤트 마킹 (순간 측정)
  func event(_ message: String = "") {
    os_signpost(.event, log: log, name: name, signpostID: signpostID, "%{public}s", message)
  }
  
  /// 클로저를 감싸서 자동 측정
  func measure<T>(_ closure: () throws -> T) rethrows -> T {
    begin()
    defer { end() }
    return try closure()
  }
  
  /// 비동기 작업도 지원
  func measureAsync<T>(_ closure: () async throws -> T) async rethrows -> T {
    begin()
    defer { end() }
    return try await closure()
  }
}

/// 간편 사용을 위한 전역 헬퍼들
enum Signpost {
  // Core Graphics 렌더링 측정용
  static func coreGraphicsRender(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.renderLog,
      name: "CoreGraphics_Render",
      label: label
    )
  }
  
  // SwiftUI Canvas 렌더링 측정용
  static func canvasRender(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.renderLog,
      name: "Canvas_Render",
      label: label
    )
  }
  
  // 텍스트 렌더링 측정용
  static func textRender(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.renderLog,
      name: "Text_Render",
      label: label
    )
  }
  
  // 이미지 합성 측정용
  static func imageComposite(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.benchLog,
      name: "Image_Composite",
      label: label
    )
  }
}

// MARK: - 사용 예시
/*
 // 간단 사용
 let helper = Signpost.coreGraphicsRender(label: "도형 그리기")
 helper.begin()
 // ... 작업 ...
 helper.end()
 
 // 클로저로 감싸기
 let image = Signpost.imageComposite(label: "워터마크").measure {
   return addWatermark(to: originalImage)
 }
 
 // 비동기
 let result = await Signpost.canvasRender(label: "애니메이션").measureAsync {
   await heavyCanvasRendering()
 }
 */

