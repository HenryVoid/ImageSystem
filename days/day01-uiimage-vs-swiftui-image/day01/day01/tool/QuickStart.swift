//
//  QuickStart.swift
//  day01
//
//  빠른 시작 가이드 - 복사해서 바로 사용하세요!
//

import SwiftUI

// MARK: - 🚀 가장 간단한 사용 예시

/// 1️⃣ FPS + 메모리 오버레이만 추가하고 싶다면
struct SimpleExample: View {
  var body: some View {
    ScrollView {
      ForEach(0..<100, id: \.self) { i in
        Text("Item \(i)")
          .frame(height: 60)
      }
    }
    .showFPS()      // ← FPS 표시
    .showMemory()   // ← 메모리 표시
  }
}

// MARK: - 🎯 스크롤 감지까지 추가

/// 2️⃣ 스크롤 성능 측정도 하고 싶다면
struct ScrollExample: View {
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(0..<100, id: \.self) { i in
          Text("Item \(i)")
            .frame(height: 60)
        }
      }
    }
    .coordinateSpace(name: "scroll")  // ← 필수!
    .detectScrollWithSignpost(name: "MyList")  // ← 스크롤 감지
    .showFPS()
    .showMemory()
  }
}

// MARK: - 📊 완전체 (모든 기능 활용)

/// 3️⃣ 프로덕션 레벨 성능 측정
struct FullExample: View {
  private let renderSignpost = Signpost.swiftUIRender(label: "FullExample")
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(0..<100, id: \.self) { i in
          Text("Item \(i)")
            .frame(height: 60)
        }
      }
    }
    .coordinateSpace(name: "scroll")
    .detectScrollWithSignpost(name: "FullList")
    .showFPS()
    .showMemory()
    .onAppear {
      PerformanceLogger.log("화면 시작")
      MemorySampler.logCurrentMemory(label: "onAppear")
      renderSignpost.begin()
    }
    .onDisappear {
      PerformanceLogger.log("화면 종료")
      renderSignpost.end()
    }
  }
}

// MARK: - 🔥 무거운 작업 측정하기

/// 4️⃣ 특정 작업의 성능 측정
struct HeavyOperationExample: View {
  @State private var images: [UIImage] = []
  
  var body: some View {
    VStack {
      Button("이미지 로드") {
        loadImages()
      }
      
      ScrollView {
        LazyVStack {
          ForEach(images.indices, id: \.self) { index in
            Image(uiImage: images[index])
              .resizable()
              .frame(height: 100)
          }
        }
      }
    }
    .showFPS()
    .showMemory()
  }
  
  private func loadImages() {
    // 메모리 변화 측정
    let delta = MemorySampler.measureMemoryDelta {
      // 구간 측정
      let signpost = Signpost.imageLoad(label: "50장 로드")
      signpost.measure {
        // 무거운 작업
        images = (0..<50).compactMap { _ in
          UIImage(named: "sample")
        }
        
        PerformanceLogger.log("이미지 \(images.count)장 로드 완료")
      }
    }
    
    print("메모리 변화: \(delta) bytes")
  }
}

// MARK: - 🎨 UIKit과 비교하기

/// 5️⃣ UIKit 버전 (델리게이트 패턴)
class MyUIKitViewController: UIViewController {
  private let scrollView = UIScrollView()
  private lazy var scrollDetector = ScrollDetectorDelegate(name: "MyUIKitList")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 스크롤 감지 연결
    scrollView.delegate = scrollDetector
    
    // FPS 모니터링 추가 (원한다면)
    // setupFPSMonitoring() 
    
    PerformanceLogger.log("UIKit 화면 시작")
    MemorySampler.logCurrentMemory(label: "UIKit viewDidLoad")
  }
}

// MARK: - 📱 Console.app에서 확인하는 법

/*
 
 1️⃣ Console.app 실행
 /Applications/Utilities/Console.app
 
 2️⃣ 필터 설정
 subsystem:com.study.day01
 
 3️⃣ 카테고리별 확인
 subsystem:com.study.day01 category:fps
 subsystem:com.study.day01 category:scroll
 subsystem:com.study.day01 category:memory
 
 4️⃣ 로그 저장
 ⌘S로 텍스트 파일로 저장 가능
 
 */

// MARK: - 🔬 Instruments에서 확인하는 법

/*
 
 1️⃣ Release 모드로 변경
 Product > Scheme > Edit Scheme > Release
 
 2️⃣ Profile 실행
 Product > Profile (⌘I)
 
 3️⃣ 템플릿 선택
 - Time Profiler: CPU 사용률
 - Allocations: 메모리 사용량
 - os_signpost: 우리가 심은 마커들!
 
 4️⃣ 녹화 → 테스트 → 분석
 좌측에서 "com.study.day01" 찾기
 SwiftUI_Scroll, UIKit_Scroll 등의 구간 확인!
 
 */

// MARK: - 🎯 실전 팁

/*
 
 ✅ 해야 할 것:
 - 반드시 실기기에서 테스트
 - Release 모드 사용
 - 다른 앱 종료
 - 충전 상태 확인
 - 여러 번 측정 후 평균내기
 
 ❌ 하지 말아야 할 것:
 - 시뮬레이터에서 테스트
 - Debug 모드로 성능 측정
 - 첫 실행 결과만 보기
 - 기기 과열 상태에서 측정
 
 */

// MARK: - Preview

#Preview("Simple") {
  SimpleExample()
}

#Preview("Scroll") {
  ScrollExample()
}

#Preview("Full") {
  FullExample()
}

#Preview("Heavy") {
  HeavyOperationExample()
}

