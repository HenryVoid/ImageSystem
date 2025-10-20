//
//  ScrollDetector.swift
//  day01
//
//  4) 스크롤 시작/종료 자동 감지(사인포스트에 쓰기)
//  4-1) SwiftUI 쪽(간단 실용 버전)
//  4-2) UIKit 쪽(정석)
//

import SwiftUI
import UIKit
import os.signpost

// MARK: - 4-1) SwiftUI 스크롤 감지 (간단 실용 버전)

/// SwiftUI에서 스크롤 이벤트 감지를 위한 PreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

/// SwiftUI 스크롤 감지 View Modifier
struct ScrollDetectorModifier: ViewModifier {
  let onScrollStart: () -> Void
  let onScrollEnd: () -> Void
  
  @State private var isScrolling = false
  @State private var workItem: DispatchWorkItem?
  
  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { geometry in
          Color.clear
            .preference(
              key: ScrollOffsetPreferenceKey.self,
              value: geometry.frame(in: .named("scroll")).minY
            )
        }
      )
      .onPreferenceChange(ScrollOffsetPreferenceKey.self) { _ in
        handleScrollEvent()
      }
  }
  
  private func handleScrollEvent() {
    // 스크롤 시작 감지
    if !isScrolling {
      isScrolling = true
      onScrollStart()
    }
    
    // 기존 타이머 취소
    workItem?.cancel()
    
    // 0.3초 후 스크롤 종료로 간주
    let newWorkItem = DispatchWorkItem { [isScrolling] in
      if isScrolling {
        self.isScrolling = false
        onScrollEnd()
      }
    }
    workItem = newWorkItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: newWorkItem)
  }
}

extension View {
  /// SwiftUI 스크롤 감지 추가
  func detectScroll(
    onStart: @escaping () -> Void = {},
    onEnd: @escaping () -> Void = {}
  ) -> some View {
    self.modifier(ScrollDetectorModifier(
      onScrollStart: onStart,
      onScrollEnd: onEnd
    ))
  }
  
  /// 자동으로 signpost와 연결된 스크롤 감지
  func detectScrollWithSignpost(name: String = "Scroll") -> some View {
    let signpost = SignpostHelper(
      log: PerformanceLogger.scrollLog,
      name: "SwiftUI_Scroll",
      label: name
    )
    
    return self.detectScroll(
      onStart: {
        signpost.begin()
        PerformanceLogger.log("스크롤 시작: \(name)", category: "scroll")
      },
      onEnd: {
        signpost.end()
        PerformanceLogger.log("스크롤 종료: \(name)", category: "scroll")
      }
    )
  }
}

// MARK: - 4-2) UIKit 스크롤 감지 (정석)

/// UIScrollView 델리게이트를 사용한 정확한 스크롤 감지
class ScrollDetectorDelegate: NSObject, UIScrollViewDelegate {
  private let signpost: SignpostHelper
  private let name: String
  
  init(name: String = "Scroll") {
    self.name = name
    self.signpost = SignpostHelper(
      log: PerformanceLogger.scrollLog,
      name: "UIKit_Scroll",
      label: name
    )
    super.init()
  }
  
  // 스크롤 시작
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    signpost.begin()
    PerformanceLogger.log("스크롤 시작 (드래그): \(name)", category: "scroll")
  }
  
  // 스크롤 종료 (손가락 뗌)
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      // 감속 없이 바로 멈춤
      signpost.end()
      PerformanceLogger.log("스크롤 종료 (즉시): \(name)", category: "scroll")
    }
  }
  
  // 감속 종료
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    signpost.end()
    PerformanceLogger.log("스크롤 종료 (감속): \(name)", category: "scroll")
  }
  
  // 프로그래밍 방식 스크롤 종료
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    signpost.end()
    PerformanceLogger.log("스크롤 종료 (애니메이션): \(name)", category: "scroll")
  }
  
  // 스크롤 중 (선택적)
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // 너무 자주 호출되므로 필요시에만 로그
    // PerformanceLogger.debug("스크롤 중: \(scrollView.contentOffset.y)", category: "scroll")
  }
}

// MARK: - 사용 예시
/*
 // SwiftUI
 ScrollView {
 LazyVStack {
 // 내용...
 }
 }
 .coordinateSpace(name: "scroll")
 .detectScrollWithSignpost(name: "ImageList")
 
 // UIKit
 class MyViewController: UIViewController {
 let scrollView = UIScrollView()
 let scrollDetector = ScrollDetectorDelegate(name: "ImageList")
 
 override func viewDidLoad() {
 super.viewDidLoad()
 scrollView.delegate = scrollDetector
 }
 }
 */

