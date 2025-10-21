//
//  MemorySampler.swift
//  day01
//
//  5) 메모리 샘플링(간단·경량)
//

import Foundation
import os.log

/// 메모리 사용량 측정 유틸리티
enum MemorySampler {
  /// 현재 메모리 사용량 (바이트)
  static func currentMemoryUsage() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count
        )
      }
    }
    
    if kerr == KERN_SUCCESS {
      return info.resident_size
    } else {
      return 0
    }
  }
  
  /// 메모리를 읽기 쉬운 형식으로 변환
  static func formatBytes(_ bytes: UInt64) -> String {
    let kb = Double(bytes) / 1024.0
    let mb = kb / 1024.0
    let gb = mb / 1024.0
    
    if gb >= 1.0 {
      return String(format: "%.2f GB", gb)
    } else if mb >= 1.0 {
      return String(format: "%.2f MB", mb)
    } else {
      return String(format: "%.2f KB", kb)
    }
  }
  
  /// 메모리 사용량 로그
  static func logCurrentMemory(label: String = "") {
    let bytes = currentMemoryUsage()
    let formatted = formatBytes(bytes)
    let message = label.isEmpty ? "메모리: \(formatted)" : "\(label): \(formatted)"
    PerformanceLogger.log(message, category: "memory")
  }
  
  /// 메모리 차이 측정
  static func measureMemoryDelta(_ operation: () -> Void) -> Int64 {
    let before = currentMemoryUsage()
    operation()
    let after = currentMemoryUsage()
    let delta = Int64(after) - Int64(before)
    
    let formatted = formatBytes(UInt64(abs(delta)))
    let sign = delta >= 0 ? "+" : "-"
    PerformanceLogger.log("메모리 변화: \(sign)\(formatted)", category: "memory")
    
    return delta
  }
}

/// 주기적으로 메모리를 샘플링하는 모니터
class MemoryMonitor: ObservableObject {
  @Published var currentMemory: String = "0 MB"
  
  private var timer: Timer?
  private let interval: TimeInterval
  
  init(interval: TimeInterval = 1.0) {
    self.interval = interval
  }
  
  func startMonitoring() {
    stopMonitoring()
    
    timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      let bytes = MemorySampler.currentMemoryUsage()
      let formatted = MemorySampler.formatBytes(bytes)
      
      DispatchQueue.main.async {
        self.currentMemory = formatted
      }
    }
    
    // 즉시 한 번 실행
    timer?.fire()
  }
  
  func stopMonitoring() {
    timer?.invalidate()
    timer = nil
  }
  
  deinit {
    stopMonitoring()
  }
}

// MARK: - SwiftUI View Modifier

import SwiftUI

struct MemoryOverlayModifier: ViewModifier {
  @StateObject private var monitor = MemoryMonitor(interval: 1.0)
  
  func body(content: Content) -> some View {
    ZStack(alignment: .topLeading) {
      content
      
      Text("🧠 \(monitor.currentMemory)")
        .font(.system(.caption, design: .monospaced))
        .padding(8)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.purple.opacity(0.8))
            .shadow(radius: 2)
        )
        .foregroundColor(.white)
        .padding(8)
    }
    .onAppear {
      monitor.startMonitoring()
    }
    .onDisappear {
      monitor.stopMonitoring()
    }
  }
}

extension View {
  /// 메모리 사용량 오버레이 추가
  func showMemory() -> some View {
    self.modifier(MemoryOverlayModifier())
  }
}

// MARK: - 사용 예시
/*
 // 간단 로그
 MemorySampler.logCurrentMemory(label: "앱 시작")
 
 // 메모리 변화 측정
 let delta = MemorySampler.measureMemoryDelta {
 // 무거운 작업
 loadHundredImages()
 }
 
 // SwiftUI에서 실시간 모니터링
 struct MyView: View {
 var body: some View {
 ScrollView {
 // 내용...
 }
 .showMemory() // 🎯 메모리 오버레이
 }
 }
 */

