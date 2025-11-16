# GIF 성능 최적화 가이드

> iOS에서 GIF 애니메이션의 성능을 최적화하는 방법과 전략

---

## 📚 목차

1. [성능 문제 분석](#성능-문제-분석)
2. [메모리 최적화](#메모리-최적화)
3. [CPU 최적화](#cpu-최적화)
4. [렌더링 최적화](#렌더링-최적화)
5. [배터리 최적화](#배터리-최적화)
6. [실전 최적화 전략](#실전-최적화-전략)

---

## 성능 문제 분석

### 주요 성능 문제

#### 1. 메모리 사용량
- **문제**: 모든 프레임을 메모리에 로드
- **영향**: 메모리 부족, 앱 크래시
- **해결**: 지연 로딩, 프레임 캐싱

#### 2. CPU 사용량
- **문제**: 프레임 디코딩이 메인 스레드에서 실행
- **영향**: UI 프리징, 프레임 드롭
- **해결**: 백그라운드 디코딩, 비동기 처리

#### 3. 배터리 소모
- **문제**: 지속적인 애니메이션 재생
- **영향**: 배터리 수명 단축
- **해결**: 화면 가시성 감지, 백그라운드 일시정지

---

## 메모리 최적화

### 1. 지연 로딩 (Lazy Loading)

모든 프레임을 한 번에 로드하지 않고 필요한 시점에만 로드합니다.

```swift
class LazyGIFLoader {
    private let imageSource: CGImageSource
    private var frameCache: [Int: UIImage] = [:]
    private let maxCacheSize = 5  // 최대 캐시 프레임 수
    
    func getFrame(at index: Int) -> UIImage? {
        // 캐시 확인
        if let cached = frameCache[index] {
            return cached
        }
        
        // 프레임 디코딩
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            return nil
        }
        
        let image = UIImage(cgImage: cgImage)
        
        // 캐시 크기 제한
        if frameCache.count >= maxCacheSize {
            // 가장 오래된 프레임 제거
            let oldestKey = frameCache.keys.min()!
            frameCache.removeValue(forKey: oldestKey)
        }
        
        frameCache[index] = image
        return image
    }
}
```

**효과**:
- 메모리 사용량 80-90% 감소
- 큰 GIF 파일도 안정적으로 처리 가능

### 2. 프레임 캐싱 전략

#### LRU (Least Recently Used) 캐시

```swift
class LRUFrameCache {
    private var cache: [Int: UIImage] = [:]
    private var accessOrder: [Int] = []
    private let maxSize: Int
    
    init(maxSize: Int = 5) {
        self.maxSize = maxSize
    }
    
    func getFrame(at index: Int) -> UIImage? {
        // 캐시 히트
        if let image = cache[index] {
            // 접근 순서 업데이트
            accessOrder.removeAll { $0 == index }
            accessOrder.append(index)
            return image
        }
        
        // 캐시 미스 - 새 프레임 로드
        let image = loadFrame(at: index)
        
        // 캐시 크기 제한
        if cache.count >= maxSize {
            let oldest = accessOrder.removeFirst()
            cache.removeValue(forKey: oldest)
        }
        
        cache[index] = image
        accessOrder.append(index)
        return image
    }
}
```

#### 예측 프리로딩

다음에 재생될 프레임을 미리 로드합니다.

```swift
class PredictiveGIFLoader {
    private var currentIndex = 0
    private var preloadQueue: [Int] = []
    
    func preloadNextFrames() {
        // 다음 3개 프레임 미리 로드
        for offset in 1...3 {
            let nextIndex = (currentIndex + offset) % frameCount
            if !isFrameLoaded(at: nextIndex) {
                preloadQueue.append(nextIndex)
            }
        }
        
        // 백그라운드에서 프리로드
        Task.detached(priority: .utility) {
            for index in self.preloadQueue {
                _ = await self.loadFrame(at: index)
            }
        }
    }
}
```

### 3. 다운샘플링

큰 GIF를 작은 크기로 다운샘플링하여 메모리 사용량을 줄입니다.

```swift
func createThumbnail(from imageSource: CGImageSource, at index: Int, maxSize: CGFloat) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: maxSize,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]
    
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, index, options as CFDictionary),
          let cgImage = thumbnail else {
        return nil
    }
    
    return UIImage(cgImage: cgImage)
}
```

**효과**:
- 300x300으로 다운샘플링 시 메모리 사용량 약 75% 감소
- 화면 크기에 맞는 최적 해상도 사용

---

## CPU 최적화

### 1. 백그라운드 디코딩

프레임 디코딩을 메인 스레드가 아닌 백그라운드 스레드에서 수행합니다.

```swift
class AsyncGIFLoader {
    func loadFrame(at index: Int) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(self.imageSource, index, nil) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }.value
    }
}
```

**효과**:
- UI 프리징 방지
- 프레임 드롭 감소

### 2. 프레임 디코딩 최적화

불필요한 변환을 피하고 최적의 옵션을 사용합니다.

```swift
func optimizedDecodeFrame(at index: Int) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceShouldCache: false,  // 즉시 디코딩
        kCGImageSourceShouldCacheImmediately: false
    ]
    
    guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, options as CFDictionary) else {
        return nil
    }
    
    // iOS 15+ preparingForDisplay() 사용
    if #available(iOS 15.0, *) {
        let image = UIImage(cgImage: cgImage)
        return image.preparingForDisplay()
    }
    
    return UIImage(cgImage: cgImage)
}
```

### 3. 프레임 드롭 감지 및 대응

```swift
class FrameDropDetector {
    private var lastFrameTime: CFTimeInterval = 0
    private var droppedFrames = 0
    
    func checkFrameTiming(currentTime: CFTimeInterval, expectedInterval: TimeInterval) {
        let actualInterval = currentTime - lastFrameTime
        let expectedIntervalSeconds = expectedInterval
        
        // 프레임 드롭 감지 (20% 이상 지연)
        if actualInterval > expectedIntervalSeconds * 1.2 {
            droppedFrames += 1
            
            // 프레임 드롭이 많으면 품질 낮춤
            if droppedFrames > 5 {
                reduceQuality()
            }
        }
        
        lastFrameTime = currentTime
    }
    
    private func reduceQuality() {
        // 다운샘플링 또는 프레임 스킵
    }
}
```

---

## 렌더링 최적화

### 1. CADisplayLink 사용

Timer 대신 CADisplayLink를 사용하여 정확한 프레임 타이밍을 보장합니다.

```swift
class GIFAnimator {
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0
    private var accumulatedTime: TimeInterval = 0
    
    func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateFrame(_ displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        let deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        accumulatedTime += deltaTime
        
        // 프레임 딜레이 확인
        if accumulatedTime >= currentFrameDelay {
            showNextFrame()
            accumulatedTime = 0
        }
    }
}
```

**장점**:
- 화면 새로고침과 동기화
- 프레임 드롭 최소화
- 배터리 효율적

### 2. SwiftUI 최적화

```swift
struct OptimizedGIFView: View {
    @State private var currentFrame: UIImage?
    @State private var frameIndex = 0
    
    var body: some View {
        Group {
            if let frame = currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .scaledToFit()
                    .drawingGroup()  // 메탈 렌더링 최적화
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
}
```

**`.drawingGroup()` 효과**:
- 메탈 렌더링 파이프라인 사용
- 복잡한 뷰 계층 구조 최적화
- GPU 가속 활용

### 3. UIView 최적화

```swift
class OptimizedGIFImageView: UIView {
    private var imageLayer: CALayer?
    
    func updateFrame(_ image: UIImage) {
        // CALayer 직접 업데이트로 재렌더링 최소화
        if imageLayer == nil {
            let layer = CALayer()
            layer.contentsGravity = .resizeAspect
            self.layer.addSublayer(layer)
            imageLayer = layer
        }
        
        imageLayer?.contents = image.cgImage
    }
}
```

---

## 배터리 최적화

### 1. 화면 가시성 감지

화면에 보이지 않을 때 애니메이션을 일시정지합니다.

```swift
class BatteryOptimizedGIFAnimator {
    private var isVisible = true
    
    func viewDidAppear() {
        isVisible = true
        resumeAnimation()
    }
    
    func viewDidDisappear() {
        isVisible = false
        pauseAnimation()
    }
    
    func applicationWillResignActive() {
        pauseAnimation()
    }
    
    func applicationDidBecomeActive() {
        if isVisible {
            resumeAnimation()
        }
    }
}
```

### 2. 저전력 모드 감지

```swift
class LowPowerModeDetector {
    static var isLowPowerModeEnabled: Bool {
        if #available(iOS 9.0, *) {
            return ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        return false
    }
    
    func adjustAnimationForLowPowerMode() {
        if Self.isLowPowerModeEnabled {
            // 프레임 레이트 감소
            reduceFrameRate(to: 15)
            // 품질 낮춤
            enableDownsampling(maxSize: 200)
        }
    }
}
```

### 3. 백그라운드 일시정지

```swift
class BackgroundAwareGIFAnimator {
    private var notificationObservers: [NSObjectProtocol] = []
    
    func setupBackgroundNotifications() {
        let willResignActive = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseAnimation()
        }
        
        let didBecomeActive = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeAnimation()
        }
        
        notificationObservers = [willResignActive, didBecomeActive]
    }
}
```

---

## 실전 최적화 전략

### 전략 1: 작은 GIF (< 1MB)

**최적화**:
- 모든 프레임을 메모리에 로드 가능
- 프리로딩 활용
- 높은 프레임 레이트 유지

```swift
class SmallGIFStrategy {
    func loadAllFrames() {
        // 모든 프레임 미리 로드
        for i in 0..<frameCount {
            frames.append(loadFrame(at: i))
        }
    }
}
```

### 전략 2: 중간 GIF (1-5MB)

**최적화**:
- 지연 로딩 사용
- LRU 캐시 (5-10개 프레임)
- 예측 프리로딩

```swift
class MediumGIFStrategy {
    private let cache = LRUFrameCache(maxSize: 8)
    
    func getFrame(at index: Int) -> UIImage? {
        return cache.getFrame(at: index)
    }
    
    func preloadNextFrames(from currentIndex: Int) {
        // 다음 3개 프레임 프리로드
        for offset in 1...3 {
            let nextIndex = (currentIndex + offset) % frameCount
            _ = cache.getFrame(at: nextIndex)
        }
    }
}
```

### 전략 3: 큰 GIF (> 5MB)

**최적화**:
- 다운샘플링 필수
- 최소 캐시 (2-3개 프레임)
- 프레임 스킵 허용

```swift
class LargeGIFStrategy {
    private let maxSize: CGFloat = 300
    private var cache: [Int: UIImage] = [:]
    private let maxCacheSize = 2
    
    func getFrame(at index: Int) -> UIImage? {
        if let cached = cache[index] {
            return cached
        }
        
        // 다운샘플링하여 로드
        let frame = createThumbnail(at: index, maxSize: maxSize)
        
        // 최소 캐시만 유지
        if cache.count >= maxCacheSize {
            cache.removeAll()
        }
        
        cache[index] = frame
        return frame
    }
}
```

### 전략 4: 네트워크 GIF

**최적화**:
- 스트리밍 디코딩
- 점진적 로딩
- 캐싱 활용

```swift
class NetworkGIFStrategy {
    func loadFromNetwork(url: URL) async throws -> CGImageSource? {
        let (asyncBytes, _) = try await URLSession.shared.bytes(from: url)
        
        // 스트리밍으로 첫 프레임 먼저 표시
        var data = Data()
        for try await byte in asyncBytes {
            data.append(byte)
            
            // 첫 프레임 디코딩 가능한지 확인
            if let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
               CGImageSourceGetCount(imageSource) > 0 {
                // 첫 프레임 표시
                showFirstFrame(from: imageSource)
            }
        }
        
        return CGImageSourceCreateWithData(data as CFData, nil)
    }
}
```

---

## 성능 측정

### 메모리 사용량 측정

```swift
func measureMemoryUsage() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        let memoryUsage = Double(info.resident_size) / (1024 * 1024)
        print("메모리 사용량: \(memoryUsage) MB")
    }
}
```

### 프레임 레이트 측정

```swift
class FrameRateMonitor {
    private var frameCount = 0
    private var lastCheckTime = CFAbsoluteTimeGetCurrent()
    
    func recordFrame() {
        frameCount += 1
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsed = currentTime - lastCheckTime
        
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            print("FPS: \(fps)")
            
            frameCount = 0
            lastCheckTime = currentTime
        }
    }
}
```

---

## 체크리스트

### 메모리 최적화
- [ ] 지연 로딩 구현
- [ ] 프레임 캐싱 전략 적용
- [ ] 큰 GIF는 다운샘플링
- [ ] 메모리 사용량 모니터링

### CPU 최적화
- [ ] 백그라운드 디코딩
- [ ] 메인 스레드 블로킹 방지
- [ ] 프레임 드롭 감지 및 대응

### 렌더링 최적화
- [ ] CADisplayLink 사용
- [ ] SwiftUI drawingGroup() 활용
- [ ] 불필요한 재렌더링 방지

### 배터리 최적화
- [ ] 화면 가시성 감지
- [ ] 백그라운드 일시정지
- [ ] 저전력 모드 대응

---

**다음 단계**: 실제 코드에서 이러한 최적화 기법을 적용해보세요.

