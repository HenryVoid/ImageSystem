//
//  ImageList.swift
//  day01
//
//  7) SwiftUI/UIViewController에 "케이블 연결" 예시
//  모든 성능 측정 도구를 실제로 적용
//

import SwiftUI
import UIKit
import os

// MARK: - SwiftUI 버전 (모든 도구 적용)
let maxCount: Int = 1000

struct SwiftUIImageList: View {
  let image = UIImage(named: "sample")!
  private let renderSignpost = Signpost.swiftUIRender(label: "ImageList")
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(0..<maxCount, id: \.self) { index in
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: 120)
            .padding(.horizontal)
        }
      }
    }
    .coordinateSpace(name: "scroll") // 🎯 스크롤 감지를 위한 좌표 공간
    .detectScrollWithSignpost(name: "SwiftUI_ImageList") // 🎯 스크롤 자동 감지
    .showFPS() // 🎯 FPS 오버레이
    .showMemory() // 🎯 메모리 오버레이
    .onAppear {
      PerformanceLogger.log("✅ SwiftUI 이미지 리스트 시작")
      MemorySampler.logCurrentMemory(label: "SwiftUI onAppear")
      
      // 렌더링 측정
      renderSignpost.begin()
    }
    .onDisappear {
      PerformanceLogger.log("❌ SwiftUI 이미지 리스트 종료")
      renderSignpost.end()
    }
  }
}

// MARK: - UIKit 버전 (모든 도구 적용)

class UIKitImageListViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  
  // 🎯 스크롤 감지 델리게이트
  private lazy var scrollDetector = ScrollDetectorDelegate(name: "UIKit_ImageList")
  
  // 🎯 FPS/메모리 모니터
  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var frameCount: Int = 0
  private let memoryMonitor = MemoryMonitor(interval: 2.0)
  
  // 🎯 성능 측정
  private let renderSignpost = Signpost.uikitRender(label: "ImageList")
  
  // 오버레이 레이블들
  private let fpsLabel = UILabel()
  private let memoryLabel = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    PerformanceLogger.log("✅ UIKit 이미지 리스트 시작")
    MemorySampler.logCurrentMemory(label: "UIKit viewDidLoad")
    
    setupUI()
    loadImages()
    setupOverlays()
    
    renderSignpost.begin()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // 🎯 FPS 모니터링 시작
    startFPSMonitoring()
    memoryMonitor.startMonitoring()
    
    // 렌더링 완료
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.renderSignpost.end()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    PerformanceLogger.log("❌ UIKit 이미지 리스트 종료")
    stopFPSMonitoring()
    memoryMonitor.stopMonitoring()
  }
  
  deinit {
    stopFPSMonitoring()
  }
  
  private func setupUI() {
    view.backgroundColor = .systemBackground
    
    // ScrollView 설정
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.delegate = scrollDetector // 🎯 스크롤 감지 연결
    view.addSubview(scrollView)
    
    // StackView 설정
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)
    
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      
      stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
    ])
  }
  
  private func loadImages() {
    guard let image = UIImage(named: "sample") else { return }
    
    // 100장의 이미지 추가
    (0..<maxCount).forEach { _ in
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFit
      imageView.heightAnchor.constraint(equalToConstant: 120).isActive = true
      stackView.addArrangedSubview(imageView)
    }
  }
  
  // MARK: - 🎯 FPS 오버레이
  
  private func setupOverlays() {
    // FPS 레이블
    fpsLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    fpsLabel.textColor = .white
    fpsLabel.backgroundColor = UIColor.green.withAlphaComponent(0.8)
    fpsLabel.textAlignment = .center
    fpsLabel.layer.cornerRadius = 8
    fpsLabel.clipsToBounds = true
    fpsLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(fpsLabel)
    
    // 메모리 레이블
    memoryLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    memoryLabel.textColor = .white
    memoryLabel.backgroundColor = UIColor.purple.withAlphaComponent(0.8)
    memoryLabel.textAlignment = .center
    memoryLabel.layer.cornerRadius = 8
    memoryLabel.clipsToBounds = true
    memoryLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(memoryLabel)
    
    NSLayoutConstraint.activate([
      fpsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      fpsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
      fpsLabel.widthAnchor.constraint(equalToConstant: 80),
      fpsLabel.heightAnchor.constraint(equalToConstant: 32),
      
      memoryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      memoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      memoryLabel.widthAnchor.constraint(equalToConstant: 100),
      memoryLabel.heightAnchor.constraint(equalToConstant: 32)
    ])
  }
  
  private func startFPSMonitoring() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
    displayLink?.add(to: .main, forMode: .common)
  }
  
  private func stopFPSMonitoring() {
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
    
    if elapsed >= 1.0 {
      let fps = Double(frameCount) / elapsed
      let fpsInt = Int(fps.rounded())
      
      fpsLabel.text = "\(fpsInt) FPS"
      fpsLabel.backgroundColor = fpsColor(for: fpsInt)
      
      PerformanceLogger.log("FPS: \(fpsInt)", category: "fps")
      
      frameCount = 0
      lastTimestamp = displayLink.timestamp
    }
    
    // 메모리 업데이트
    let bytes = MemorySampler.currentMemoryUsage()
    memoryLabel.text = "🧠 " + MemorySampler.formatBytes(bytes)
  }
  
  private func fpsColor(for fps: Int) -> UIColor {
    switch fps {
    case 55...Int.max: return UIColor.green.withAlphaComponent(0.8)
    case 40..<55: return UIColor.yellow.withAlphaComponent(0.8)
    case 30..<40: return UIColor.orange.withAlphaComponent(0.8)
    default: return UIColor.red.withAlphaComponent(0.8)
    }
  }
}

// MARK: - SwiftUI Representable Wrapper

struct UIKitListRepresentable: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIViewController {
    return UIKitImageListViewController()
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // 업데이트 없음
  }
}
