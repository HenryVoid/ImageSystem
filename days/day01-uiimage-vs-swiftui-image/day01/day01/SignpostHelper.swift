//
//  SignpostHelper.swift
//  day01
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
  // SwiftUI 렌더링 측정용
  static func swiftUIRender(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.benchLog,
      name: "SwiftUI_Render",
      label: label
    )
  }
  
  // UIKit 렌더링 측정용
  static func uikitRender(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.benchLog,
      name: "UIKit_Render",
      label: label
    )
  }
  
  // 스크롤 성능 측정용
  static func scroll(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.scrollLog,
      name: "Scroll_Performance",
      label: label
    )
  }
  
  // 이미지 로딩 측정용
  static func imageLoad(label: String = "") -> SignpostHelper {
    SignpostHelper(
      log: PerformanceLogger.benchLog,
      name: "Image_Load",
      label: label
    )
  }
}

// MARK: - 사용 예시
/*
 // 간단 사용
 let helper = Signpost.swiftUIRender(label: "MyView")
 helper.begin()
 // ... 작업 ...
 helper.end()
 
 // 클로저로 감싸기
 let result = Signpost.imageLoad(label: "100장").measure {
 // 무거운 이미지 로딩 작업
 return heavyImageOperation()
 }
 
 // 비동기
 let data = await Signpost.imageLoad(label: "네트워크").measureAsync {
 await fetchImageData()
 }
 */

