//
//  FPSOverlay.swift
//  day01
//
//  3) FPS 오버레이(시각 피드백, 즉시 감 잡기)
//

import SwiftUI
import QuartzCore

/// FPS 측정 및 표시를 위한 오버레이
class FPSCounter: ObservableObject {
  @Published var currentFPS: Int = 60
  
  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var frameCount: Int = 0
  
  init() {
    startMonitoring()
  }
  
  deinit {
    stopMonitoring()
  }
  
  private func startMonitoring() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
    displayLink?.add(to: .main, forMode: .common)
  }
  
  private func stopMonitoring() {
    displayLink?.invalidate()
    displayLink = nil
  }
  
  @objc private func displayLinkTick(displayLink: CADisplayLink) {
    if lastTimestamp == 0 {
      lastTimestamp = displayLink.timestamp
      return
    }
    
    frameCount += 1
    let elapsed = displayLink.timestamp - lastTimestamp
    
    // 0.5초마다 FPS 계산
    if elapsed >= 0.5 {
      let fps = Double(frameCount) / elapsed
      DispatchQueue.main.async { [weak self] in
        self?.currentFPS = Int(fps.rounded())
      }
      
      // 로그 출력
      PerformanceLogger.log("FPS: \(Int(fps))", category: "fps")
      
      frameCount = 0
      lastTimestamp = displayLink.timestamp
    }
  }
}

/// SwiftUI View Modifier
struct FPSOverlayModifier: ViewModifier {
  @StateObject private var fpsCounter = FPSCounter()
  
  func body(content: Content) -> some View {
    ZStack(alignment: .topTrailing) {
      content
      
      // FPS 표시
      Text("\(fpsCounter.currentFPS) FPS")
        .font(.system(.caption, design: .monospaced))
        .padding(8)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor(for: fpsCounter.currentFPS))
            .shadow(radius: 2)
        )
        .foregroundColor(.white)
        .padding(8)
    }
  }
  
  private func backgroundColor(for fps: Int) -> Color {
    switch fps {
    case 55...Int.max: return .green.opacity(0.8)
    case 40..<55: return .yellow.opacity(0.8)
    case 30..<40: return .orange.opacity(0.8)
    default: return .red.opacity(0.8)
    }
  }
}

extension View {
  /// FPS 오버레이를 추가
  func showFPS() -> some View {
    self.modifier(FPSOverlayModifier())
  }
}

// MARK: - 사용 예시
/*
 struct MyView: View {
 var body: some View {
 ScrollView {
 // 내용...
 }
 .showFPS() // 🎯 FPS 오버레이 추가
 }
 }
 */

