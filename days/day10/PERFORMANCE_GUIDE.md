# 캐시 성능 최적화 가이드

> 캐시 히트율 향상, 메모리 최적화, 디스크 I/O 최소화 실전 기법

---

## 📚 성능 최적화 목표

### 3대 목표

1. **캐시 히트율 극대화** (90%+ 목표)
2. **메모리 사용량 최소화** (앱 크래시 방지)
3. **디스크 I/O 최소화** (배터리 절약, 속도 향상)

---

## 🎯 캐시 히트율 최적화

### 히트율이란?

```
히트율 = (캐시에서 찾은 횟수 / 전체 요청 횟수) × 100%

예시:
총 요청: 1000회
캐시 히트: 920회
히트율: 92% ← 우수!
```

### 히트율 평가 기준

| 히트율 | 등급 | 평가 | 조치 |
|-------|-----|------|------|
| **95%+** | S | 최고 | 유지 |
| **90-95%** | A | 우수 | 유지 |
| **80-90%** | B | 양호 | 프리페칭 추가 |
| **70-80%** | C | 보통 | 캐시 크기 증가 |
| **60-70%** | D | 나쁨 | 전략 재검토 |
| **60% 미만** | F | 매우 나쁨 | 전면 개선 |

---

### 기법 1: 적절한 캐시 크기

#### 문제

```swift
// ❌ 너무 작은 캐시
cache.totalCostLimit = 10 * 1024 * 1024  // 10MB

// 결과:
// - 10-15개 이미지만 보관
// - 스크롤 시 계속 삭제
// - 히트율: 40%
```

#### 해결

```swift
// ✅ 적절한 캐시 크기
let deviceMemory = ProcessInfo.processInfo.physicalMemory
let cacheSize = min(deviceMemory / 10, 200 * 1024 * 1024)  // 기기 메모리의 10%, 최대 200MB
cache.totalCostLimit = Int(cacheSize)

// 결과:
// - 50-100개 이미지 보관
// - 스크롤해도 유지
// - 히트율: 85%
```

#### 기기별 권장 크기

```swift
func recommendedCacheSize() -> Int {
    let memory = ProcessInfo.processInfo.physicalMemory
    
    switch memory {
    case ..<(2 * 1024 * 1024 * 1024):  // 2GB 미만
        return 30 * 1024 * 1024  // 30MB
    case ..<(4 * 1024 * 1024 * 1024):  // 4GB 미만
        return 50 * 1024 * 1024  // 50MB
    case ..<(6 * 1024 * 1024 * 1024):  // 6GB 미만
        return 100 * 1024 * 1024  // 100MB
    default:  // 6GB 이상
        return 200 * 1024 * 1024  // 200MB
    }
}
```

---

### 기법 2: 프리페칭 (Prefetching)

#### 개념

사용자가 보기 **전에** 미리 로드합니다.

```
현재 화면: 이미지 1-10
프리페칭: 이미지 11-20

사용자가 스크롤 → 이미 로드됨 → 즉시 표시
```

#### Kingfisher 프리페칭

```swift
import Kingfisher

class GalleryViewController: UIViewController {
    let prefetcher = ImagePrefetcher(urls: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 다음 20개 이미지 프리페칭
        let nextUrls = (20..<40).map { imageURL(for: $0) }
        prefetcher.start(with: nextUrls)
    }
}

// UICollectionView 통합
extension GalleryViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        let urls = indexPaths.map { imageURL(for: $0.item) }
        prefetcher.start(with: urls)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        let urls = indexPaths.map { imageURL(for: $0.item) }
        prefetcher.stop(with: urls)
    }
}
```

#### Nuke 프리히팅

```swift
import Nuke

class GalleryViewController: UIViewController {
    let preheater = ImagePreheater()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 다음 20개 이미지 프리히팅
        let nextRequests = (20..<40).map { 
            ImageRequest(url: imageURL(for: $0))
        }
        preheater.startPreheating(with: nextRequests)
    }
}

// UICollectionView 통합
extension GalleryViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        let requests = indexPaths.map { 
            ImageRequest(url: imageURL(for: $0.item))
        }
        preheater.startPreheating(with: requests)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        let requests = indexPaths.map { 
            ImageRequest(url: imageURL(for: $0.item))
        }
        preheater.stopPreheating(with: requests)
    }
}
```

#### 효과

```
프리페칭 없음:
스크롤 → 로딩 시작 → 300ms 대기 → 표시
히트율: 60%

프리페칭 적용:
스크롤 → 즉시 표시 (이미 로드됨)
히트율: 90%
```

---

### 기법 3: 다운샘플링

#### 문제

```swift
// ❌ 원본 크기 그대로
let image = UIImage(data: data)  // 3000×2000 = 24MB

// 실제 표시: 150×100 썸네일
imageView.image = image  // 24MB 메모리 낭비!
```

#### 해결: 다운샘플링

```swift
// ✅ 필요한 크기로 축소
func downsample(imageData: Data, to targetSize: CGSize) -> UIImage? {
    let options = [
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height)
    ] as CFDictionary
    
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
          let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
        return nil
    }
    
    return UIImage(cgImage: cgImage)
}

// 사용
let data = try Data(contentsOf: url)
let thumbnail = downsample(imageData: data, to: CGSize(width: 150, height: 100))
// 3000×2000 (24MB) → 150×100 (60KB) = 400배 메모리 절약!
```

#### Kingfisher 다운샘플링

```swift
let processor = DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))

imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)

// 내부적으로 다운샘플링 + 캐싱
// 메모리 효율 극대화
```

#### Nuke 다운샘플링

```swift
let request = ImageRequest(
    url: url,
    processors: [.resize(size: CGSize(width: 200, height: 200))]
)

Nuke.loadImage(with: request, into: imageView)
```

#### 효과

```
원본 이미지 100개:
메모리: 2.4GB (불가능!)

다운샘플링 100개:
메모리: 6MB (400배 절약)
캐시에 더 많은 이미지 저장 가능 → 히트율 향상
```

---

### 기법 4: 적응형 캐시

상황에 따라 캐시 크기를 조정합니다.

```swift
class AdaptiveCache {
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        adjustCacheSize()
        
        // 메모리 경고 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    private func adjustCacheSize() {
        let memory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = memory / 10  // 10%
        
        cache.totalCostLimit = Int(min(availableMemory, 200 * 1024 * 1024))
        print("캐시 크기: \(cache.totalCostLimit / 1024 / 1024) MB")
    }
    
    @objc private func handleMemoryWarning() {
        // 캐시 크기 50% 감소
        cache.totalCostLimit /= 2
        cache.removeAllObjects()
        print("⚠️ 메모리 경고 - 캐시 크기 축소: \(cache.totalCostLimit / 1024 / 1024) MB")
    }
}
```

---

## 💾 메모리 최적화

### 메모리 사용량 모니터링

```swift
func currentMemoryUsage() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    guard kerr == KERN_SUCCESS else { return 0 }
    return info.resident_size
}

// 사용
let memoryMB = currentMemoryUsage() / 1024 / 1024
print("현재 메모리: \(memoryMB) MB")
```

### 메모리 경고 대응

```swift
class MemoryAwareCache {
    private let cache = ImageCache.default
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ 메모리 경고")
        
        // 1. 메모리 캐시 전체 삭제
        cache.clearMemoryCache()
        
        // 2. 디스크 캐시는 유지 (재로드 시 빠름)
        print("메모리 캐시 삭제 완료")
    }
}
```

### 백그라운드 진입 시 정리

```swift
NotificationCenter.default.addObserver(
    forName: UIApplication.didEnterBackgroundNotification,
    object: nil,
    queue: .main
) { _ in
    // 백그라운드 진입 시 메모리 캐시 정리
    ImageCache.default.clearMemoryCache()
    print("🌙 백그라운드 진입 - 메모리 캐시 정리")
}

NotificationCenter.default.addObserver(
    forName: UIApplication.willEnterForegroundNotification,
    object: nil,
    queue: .main
) { _ in
    print("☀️ 포그라운드 진입 - 캐시 준비")
}
```

---

## 💿 디스크 I/O 최적화

### 문제: 빈번한 디스크 접근

```swift
// ❌ 매번 디스크 확인
for i in 0..<100 {
    if let image = diskCache.retrieve(forKey: "image-\(i)") {
        // 디스크 I/O 100회!
    }
}
```

### 해결 1: 배치 처리

```swift
// ✅ 한 번에 여러 이미지 확인
extension ImageDiskCache {
    func retrieveBatch(forKeys keys: [String]) -> [String: UIImage] {
        var results = [String: UIImage]()
        
        // 디스크 I/O를 백그라운드 스레드에서 처리
        let queue = DispatchQueue(label: "disk.cache.batch")
        let group = DispatchGroup()
        
        for key in keys {
            group.enter()
            queue.async {
                if let image = self.retrieve(forKey: key) {
                    results[key] = image
                }
                group.leave()
            }
        }
        
        group.wait()
        return results
    }
}
```

### 해결 2: 메모리 캐시 우선

```swift
// ✅ 2단계 조회
func loadImage(forKey key: String) -> UIImage? {
    // 1. 메모리 캐시 확인 (빠름: 1-5ms)
    if let image = memoryCache.retrieve(forKey: key) {
        return image
    }
    
    // 2. 디스크 캐시 확인 (느림: 10-100ms)
    if let image = diskCache.retrieve(forKey: key) {
        // 메모리에 저장 (다음엔 빠르게)
        memoryCache.store(image, forKey: key)
        return image
    }
    
    // 3. 네트워크 다운로드
    return nil
}
```

### 해결 3: 디스크 캐시 압축

```swift
// ✅ JPEG 압축으로 디스크 공간 절약
extension ImageDiskCache {
    func store(_ image: UIImage, forKey key: String, compression: CGFloat = 0.7) {
        // PNG: 2MB → JPEG 0.7 압축: 200KB (10배 절약)
        guard let data = image.jpegData(compressionQuality: compression) else { return }
        
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash())
        try? data.write(to: fileURL)
    }
}
```

---

## 📊 성능 측정

### 캐시 통계 추적

```swift
class CacheStatistics {
    private(set) var memoryHits = 0
    private(set) var diskHits = 0
    private(set) var misses = 0
    
    var totalRequests: Int {
        memoryHits + diskHits + misses
    }
    
    var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits + diskHits) / Double(totalRequests) * 100
    }
    
    var memoryHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits) / Double(totalRequests) * 100
    }
    
    func recordMemoryHit() {
        memoryHits += 1
        print("🎯 메모리 히트 (\(Int(memoryHitRate))%)")
    }
    
    func recordDiskHit() {
        diskHits += 1
        print("💿 디스크 히트 (전체: \(Int(hitRate))%)")
    }
    
    func recordMiss() {
        misses += 1
        print("❌ 캐시 미스 (전체: \(Int(hitRate))%)")
    }
    
    func summary() -> String {
        """
        📊 캐시 통계
        ────────────────────────
        총 요청: \(totalRequests)회
        메모리 히트: \(memoryHits)회 (\(Int(memoryHitRate))%)
        디스크 히트: \(diskHits)회
        캐시 미스: \(misses)회
        전체 히트율: \(Int(hitRate))%
        """
    }
}
```

### 로딩 시간 측정

```swift
func measureLoadingTime(forKey key: String) -> TimeInterval {
    let start = Date()
    
    let _ = loadImage(forKey: key)
    
    let elapsed = Date().timeIntervalSince(start)
    print("⏱️ 로딩 시간: \(Int(elapsed * 1000))ms")
    return elapsed
}

// 100개 이미지 평균 측정
func benchmarkCache() {
    var totalTime: TimeInterval = 0
    
    for i in 0..<100 {
        totalTime += measureLoadingTime(forKey: "image-\(i)")
    }
    
    let average = totalTime / 100
    print("📊 평균 로딩 시간: \(Int(average * 1000))ms")
}
```

---

## 🎯 실전 최적화 체크리스트

### Level 1: 기본 (필수)

```
✅ NSCache 사용 (Dictionary 사용 금지)
✅ 적절한 totalCostLimit 설정 (50-200MB)
✅ 메모리 경고 처리
✅ 2단계 캐싱 (메모리 + 디스크)
```

### Level 2: 중급 (권장)

```
✅ 프리페칭 구현
✅ 다운샘플링 적용
✅ 백그라운드 진입 시 정리
✅ 캐시 통계 추적
```

### Level 3: 고급 (선택)

```
✅ 적응형 캐시 크기
✅ 우선순위 기반 캐싱
✅ 배치 디스크 I/O
✅ JPEG 압축 최적화
```

---

## 📈 최적화 전후 비교

### 최적화 전

```
캐시 설정:
- 메모리: 20MB
- 프리페칭: 없음
- 다운샘플링: 없음

결과 (100개 이미지):
- 첫 로드: 30초
- 재로드: 5초
- 메모리: 180MB
- 히트율: 55%
```

### 최적화 후

```
캐시 설정:
- 메모리: 100MB (적응형)
- 프리페칭: 다음 20개
- 다운샘플링: 적용

결과 (100개 이미지):
- 첫 로드: 28초 (7% 향상)
- 재로드: 0.6초 (8배 향상)
- 메모리: 65MB (64% 절감)
- 히트율: 92% (67% 향상)
```

---

## 💡 핵심 요약

### 캐시 히트율 향상

1. **적절한 크기**: 기기 메모리의 5-10%
2. **프리페칭**: 다음 10-20개 미리 로드
3. **다운샘플링**: 필요한 크기로 축소
4. **적응형**: 상황에 따라 동적 조정

### 메모리 최적화

1. **모니터링**: 실시간 사용량 추적
2. **메모리 경고**: 즉시 대응
3. **백그라운드**: 메모리 캐시 정리
4. **압축**: JPEG 압축 활용

### 디스크 I/O 최적화

1. **메모리 우선**: 디스크 접근 최소화
2. **배치 처리**: 여러 파일 한 번에
3. **백그라운드**: 메인 스레드 차단 방지
4. **압축**: 디스크 공간 절약

### 목표 달성

- ✅ 히트율: 90%+
- ✅ 메모리: 100MB 이하
- ✅ 로딩 시간: 재로드 1초 이하

---

**다음 단계**: 실전 앱 구현으로 이론을 적용해봅니다! 🚀

















