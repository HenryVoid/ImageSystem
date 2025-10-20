//
//  ImageList.swift
//  day01
//
//  7) SwiftUI/UIViewController에 "케이블 연결" 예시
//  모든 성능 측정 도구를 실제로 적용
//  ✅ 메모리 누수 & UI Hangs 해결 버전
//

import SwiftUI
import UIKit
import os

// MARK: - SwiftUI 버전 (최적화 완료)
let maxCount: Int = 1000

struct SwiftUIImageList: View {
  // ✅ 이미지 캐시 관리
  @StateObject private var imageCache = ImageCacheManager.shared
  private let renderSignpost = Signpost.swiftUIRender(label: "ImageList")
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(0..<maxCount, id: \.self) { index in
          // ✅ 최적화된 이미지 뷰
          OptimizedSwiftUIImage()
            .frame(height: 120)
            .padding(.horizontal)
        }
      }
    }
    .coordinateSpace(name: "scroll")
    .detectScrollWithSignpost(name: "SwiftUI_ImageList")
    .showFPS()
    .showMemory()
    .onAppear {
      PerformanceLogger.log("✅ SwiftUI 이미지 리스트 시작")
      MemorySampler.logCurrentMemory(label: "SwiftUI onAppear")
      renderSignpost.begin()
    }
    .onDisappear {
      PerformanceLogger.log("❌ SwiftUI 이미지 리스트 종료")
      renderSignpost.end()
      
      // ✅ 메모리 정리
      imageCache.clearCache()
    }
  }
}

// MARK: - 최적화된 SwiftUI 이미지 뷰
private struct OptimizedSwiftUIImage: View {
  @State private var preparedImage: UIImage?
  
  var body: some View {
    Group {
      if let image = preparedImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      } else {
        ProgressView()
      }
    }
    .task {
      // ✅ 백그라운드에서 이미지 디코딩
      await loadAndPrepareImage()
    }
  }
  
  @MainActor
  private func loadAndPrepareImage() async {
    await Task.detached(priority: .userInitiated) {
      guard let image = UIImage(named: "sample") else { return }
      
      // ✅ iOS 15+ preparingForDisplay() 사용
      let prepared: UIImage
      if #available(iOS 15.0, *) {
        prepared = image.preparingForDisplay() ?? image
      } else {
        // iOS 15 미만은 수동 디코딩
        prepared = Self.decodeImage(image) ?? image
      }
      
      await MainActor.run {
        self.preparedImage = prepared
      }
    }.value
  }
  
  // iOS 15 미만을 위한 수동 이미지 디코딩
  private static func decodeImage(_ image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    guard let context = CGContext(
      data: nil,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: 8,
      bytesPerRow: cgImage.width * 4,
      space: colorSpace,
      bitmapInfo: bitmapInfo.rawValue
    ) else { return nil }
    
    let rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
    context.draw(cgImage, in: rect)
    
    guard let decodedImage = context.makeImage() else { return nil }
    return UIImage(cgImage: decodedImage)
  }
}

// MARK: - 이미지 캐시 매니저
class ImageCacheManager: ObservableObject {
  static let shared = ImageCacheManager()
  
  private var cache: [String: UIImage] = [:]
  private let queue = DispatchQueue(label: "com.day01.imageCache", attributes: .concurrent)
  
  private init() {
    // ✅ 메모리 워닝 감지
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveMemoryWarning),
      name: UIApplication.didReceiveMemoryWarningNotification,
      object: nil
    )
  }
  
  deinit {
    // ✅ Observer 제거
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc private func didReceiveMemoryWarning() {
    PerformanceLogger.log("⚠️ 메모리 워닝 - 캐시 정리")
    clearCache()
  }
  
  func clearCache() {
    queue.async(flags: .barrier) { [weak self] in
      self?.cache.removeAll()
    }
  }
}

// MARK: - UIKit 버전 (최적화 완료)

class UIKitImageListViewController: UIViewController {
  // ✅ UICollectionView로 변경 (재사용 가능)
  private var collectionView: UICollectionView!
  
  // ✅ 스크롤 감지 델리게이트
  private lazy var scrollDetector = ScrollDetectorDelegate(name: "UIKit_ImageList")
  
  // ✅ FPS/메모리 모니터
  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var frameCount: Int = 0
  private var memoryMonitor: MemoryMonitor?
  
  // ✅ 성능 측정
  private let renderSignpost = Signpost.uikitRender(label: "ImageList")
  
  // 오버레이 레이블들
  private let fpsLabel = UILabel()
  private let memoryLabel = UILabel()
  
  // ✅ 준비된 이미지 캐시
  private var preparedImage: UIImage?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    PerformanceLogger.log("✅ UIKit 이미지 리스트 시작")
    MemorySampler.logCurrentMemory(label: "UIKit viewDidLoad")
    
    setupCollectionView()
    setupOverlays()
    prepareImage()
    
    renderSignpost.begin()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // ✅ FPS 모니터링 시작
    startFPSMonitoring()
    
    // ✅ 메모리 모니터링 시작
    memoryMonitor = MemoryMonitor(interval: 2.0)
    memoryMonitor?.startMonitoring()
    
    // 렌더링 완료
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.renderSignpost.end()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    PerformanceLogger.log("❌ UIKit 이미지 리스트 종료")
    stopFPSMonitoring()
    memoryMonitor?.stopMonitoring()
  }
  
  deinit {
    // ✅ 리소스 정리
    PerformanceLogger.log("🗑️ UIKit 이미지 리스트 deinit")
    stopFPSMonitoring()
    memoryMonitor?.stopMonitoring()
    memoryMonitor = nil
    preparedImage = nil
    collectionView = nil
  }
  
  // ✅ 이미지 사전 디코딩
  private func prepareImage() {
    Task.detached(priority: .userInitiated) { [weak self] in
      guard let image = UIImage(named: "sample") else { return }
      
      // iOS 15+ preparingForDisplay() 사용
      let prepared: UIImage
      if #available(iOS 15.0, *) {
        prepared = image.preparingForDisplay() ?? image
      } else {
        // 수동 디코딩
        prepared = self?.decodeImage(image) ?? image
      }
      
      await MainActor.run { [weak self] in
        self?.preparedImage = prepared
        self?.collectionView.reloadData()
      }
    }
  }
  
  // 수동 이미지 디코딩 (iOS 15 미만)
  private func decodeImage(_ image: UIImage) -> UIImage {
    guard let cgImage = image.cgImage else { return image }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    guard let context = CGContext(
      data: nil,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: 8,
      bytesPerRow: cgImage.width * 4,
      space: colorSpace,
      bitmapInfo: bitmapInfo.rawValue
    ) else { return image }
    
    let rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
    context.draw(cgImage, in: rect)
    
    guard let decodedImage = context.makeImage() else { return image }
    return UIImage(cgImage: decodedImage)
  }
  
  private func setupCollectionView() {
    view.backgroundColor = .systemBackground
    
    // ✅ UICollectionViewFlowLayout 설정
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 8
    layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 120)
    
    // ✅ UICollectionView 생성
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .systemBackground
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.delegate = self
    collectionView.dataSource = self
    
    // ✅ 셀 등록
    collectionView.register(
      OptimizedImageCell.self,
      forCellWithReuseIdentifier: OptimizedImageCell.identifier
    )
    
    view.addSubview(collectionView)
    
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
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
    // ✅ weak self로 순환 참조 방지
    displayLink = CADisplayLink(target: WeakDisplayLinkTarget(target: self), selector: #selector(WeakDisplayLinkTarget.tick(_:)))
    displayLink?.add(to: .main, forMode: .common)
  }
  
  private func stopFPSMonitoring() {
    displayLink?.invalidate()
    displayLink = nil
  }
  
  @objc func displayLinkTick(displayLink: CADisplayLink) {
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

// MARK: - UICollectionView DataSource & Delegate

extension UIKitImageListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return maxCount
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: OptimizedImageCell.identifier,
      for: indexPath
    ) as? OptimizedImageCell else {
      return UICollectionViewCell()
    }
    
    // ✅ 준비된 이미지 사용
    cell.configure(with: preparedImage)
    return cell
  }
}

// MARK: - 최적화된 이미지 셀

class OptimizedImageCell: UICollectionViewCell {
  static let identifier = "OptimizedImageCell"
  
  private let imageView = UIImageView()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupImageView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupImageView() {
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)
    
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    ])
  }
  
  func configure(with image: UIImage?) {
    imageView.image = image
  }
  
  // ✅ 셀 재사용 시 이미지 정리
  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
  }
  
  deinit {
    // ✅ 메모리 정리
    imageView.image = nil
  }
}

// MARK: - Weak DisplayLink Target (순환 참조 방지)

class WeakDisplayLinkTarget {
  private weak var target: UIKitImageListViewController?
  
  init(target: UIKitImageListViewController) {
    self.target = target
  }
  
  @objc func tick(_ displayLink: CADisplayLink) {
    target?.displayLinkTick(displayLink: displayLink)
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
