# 성능 최적화 가이드

> AVAsset 썸네일 생성의 성능 최적화 방법과 측정 기법

---

## 📚 목차

1. [성능 측정](#성능-측정)
2. [최적화 전략](#최적화-전략)
3. [메모리 관리](#메모리-관리)
4. [캐싱 전략](#캐싱-전략)
5. [병렬 처리](#병렬-처리)
6. [실전 최적화](#실전-최적화)

---

## 성능 측정

### 생성 시간 측정

```swift
let (thumbnail, duration) = await PerformanceMeasurer.measureTime {
    try await ThumbnailGenerator.generateThumbnail(from: url, at: 5.0)
}

print("생성 시간: \(duration)초")
```

### 메모리 사용량 측정

```swift
let beforeMemory = PerformanceMeasurer.getMemoryUsage()

let thumbnail = try await ThumbnailGenerator.generateThumbnail(...)

let afterMemory = PerformanceMeasurer.getMemoryUsage()
let usedMemory = afterMemory - beforeMemory

print("사용된 메모리: \(PerformanceMeasurer.formatMemoryUsage(usedMemory))")
```

### 성능 로깅

```swift
PerformanceLogger.log("썸네일 생성 시작", category: "benchmark")

let thumbnail = try await ThumbnailGenerator.generateThumbnail(...)

PerformanceLogger.log("썸네일 생성 완료: \(duration)초", category: "benchmark")
```

---

## 최적화 전략

### 1. 썸네일 크기 제한

가장 효과적인 최적화 방법입니다.

```swift
// ❌ 나쁜 예: 원본 크기
generator.maximumSize = CGSize(width: 1920, height: 1080)
// 메모리: ~8MB, 시간: ~500ms

// ✅ 좋은 예: 적절한 크기
generator.maximumSize = CGSize(width: 200, height: 200)
// 메모리: ~160KB, 시간: ~50ms
```

**권장 크기**:
- 썸네일용: 200x200 (가장 빠름)
- 중간 크기: 400x400 (균형)
- 고화질: 800x800 (느리지만 고품질)

### 2. 시간 허용 오차 설정

정확도와 성능의 균형을 맞춥니다.

```swift
// 정확도 우선 (느림)
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
// 시간: ~100ms

// 성능 우선 (빠름, 충분히 정확)
generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
// 시간: ~30ms
```

### 3. 트랙 변환 최적화

회전이 필요 없는 경우 비활성화합니다.

```swift
// 회전이 필요한 경우만 활성화
generator.appliesPreferredTrackTransform = true  // 기본값

// 회전이 필요 없는 경우 비활성화 (약간 빠름)
generator.appliesPreferredTrackTransform = false
```

---

## 메모리 관리

### 메모리 사용량 분석

```swift
func analyzeMemoryUsage() {
    let initialMemory = PerformanceMeasurer.getMemoryUsage()
    
    Task {
        // 썸네일 생성
        let thumbnail = try await ThumbnailGenerator.generateThumbnail(...)
        
        let afterMemory = PerformanceMeasurer.getMemoryUsage()
        let usedMemory = afterMemory - initialMemory
        
        print("썸네일 메모리: \(PerformanceMeasurer.formatMemoryUsage(usedMemory))")
        
        // 썸네일 해제
        thumbnail = nil
        
        // 메모리 정리 대기
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let finalMemory = PerformanceMeasurer.getMemoryUsage()
        print("정리 후 메모리: \(PerformanceMeasurer.formatMemoryUsage(finalMemory - initialMemory))")
    }
}
```

### 메모리 누수 방지

```swift
// ✅ 좋은 예: 약한 참조 사용
class ThumbnailManager {
    weak var delegate: ThumbnailDelegate?
    
    func generateThumbnail() {
        Task { [weak self] in
            guard let self = self else { return }
            // 처리
        }
    }
}

// ❌ 나쁜 예: 강한 참조 순환
class ThumbnailManager {
    var delegate: ThumbnailDelegate?  // 강한 참조
    
    func generateThumbnail() {
        Task {
            // delegate가 self를 강하게 참조하면 순환 참조 발생
        }
    }
}
```

### 메모리 캐시 크기 제한

```swift
let cache = ThumbnailCache.shared

// 최대 개수 제한
cache.maxMemoryCacheCount = 100

// 최대 비용 제한 (50MB)
cache.maxMemoryCacheCost = 50 * 1024 * 1024
```

---

## 캐싱 전략

### 캐시 히트율 측정

```swift
class CacheAnalyzer {
    var hits = 0
    var misses = 0
    
    func getThumbnailWithTracking(for key: ThumbnailCacheKey) -> UIImage? {
        if let cached = ThumbnailCache.shared.getThumbnail(for: key) {
            hits += 1
            return cached
        } else {
            misses += 1
            return nil
        }
    }
    
    var hitRate: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total)
    }
}
```

### 캐시 전략 비교

#### 전략 1: 메모리만 사용

```swift
// 빠르지만 제한적
let cache = NSCache<NSString, UIImage>()
cache.countLimit = 50
```

**장점**:
- 매우 빠름
- 구현 간단

**단점**:
- 앱 종료 시 사라짐
- 메모리 제한

#### 전략 2: 메모리 + 디스크

```swift
// 메모리 캐시 확인 → 디스크 캐시 확인 → 생성
if let memory = memoryCache.get(key) {
    return memory
}
if let disk = diskCache.get(key) {
    memoryCache.set(disk, for: key)
    return disk
}
// 생성 후 둘 다 저장
```

**장점**:
- 앱 재시작 후에도 유지
- 메모리 효율적

**단점**:
- 디스크 I/O 오버헤드
- 구현 복잡

### 캐시 키 최적화

```swift
// ✅ 좋은 예: 적절한 키 구성
struct ThumbnailCacheKey: Hashable {
    let videoURL: URL
    let time: TimeInterval
    let maximumSize: CGSize  // 크기별로 다른 캐시
}

// ❌ 나쁜 예: 너무 세밀한 키
struct ThumbnailCacheKey: Hashable {
    let videoURL: URL
    let time: TimeInterval
    let maximumSize: CGSize
    let tolerance: CMTime  // 불필요하게 세밀함
}
```

---

## 병렬 처리

### 순차 처리 vs 병렬 처리

```swift
// ❌ 순차 처리 (느림)
var thumbnails: [UIImage] = []
for time in times {
    let thumbnail = try await generator.image(at: time).image
    thumbnails.append(UIImage(cgImage: thumbnail))
}
// 시간: N × 단일 시간

// ✅ 병렬 처리 (빠름)
let thumbnails = try await withThrowingTaskGroup(of: UIImage?.self) { group in
    for time in times {
        group.addTask {
            let cgImage = try? await generator.image(at: time).image
            return cgImage.map { UIImage(cgImage: $0) }
        }
    }
    // 결과 수집
}
// 시간: 약 단일 시간 (CPU 코어 수에 따라)
```

### 병렬 처리 최적화

```swift
// 적절한 동시성 제한
let semaphore = DispatchSemaphore(value: 4)  // 최대 4개 동시 실행

try await withThrowingTaskGroup(of: UIImage?.self) { group in
    for time in times {
        group.addTask {
            await semaphore.wait()
            defer { semaphore.signal() }
            
            return try? await generator.image(at: time).image
        }
    }
    // 결과 수집
}
```

---

## 실전 최적화

### 최적화된 썸네일 생성기

```swift
class OptimizedThumbnailGenerator {
    private let cache = ThumbnailCache.shared
    
    func generateThumbnail(
        from videoURL: URL,
        at time: TimeInterval,
        size: CGSize = CGSize(width: 200, height: 200)
    ) async throws -> UIImage {
        let cacheKey = ThumbnailCacheKey(videoURL: videoURL, time: time, maximumSize: size)
        
        // 1. 캐시 확인
        if let cached = cache.getThumbnail(for: cacheKey) {
            PerformanceLogger.debug("캐시 히트", category: "cache")
            return cached
        }
        
        // 2. 생성 (최적화된 설정)
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = size  // 크기 제한
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        let cgImage = try await generator.image(at: cmTime).image
        let thumbnail = UIImage(cgImage: cgImage)
        
        // 3. 캐시 저장
        cache.storeThumbnail(thumbnail, for: cacheKey)
        
        return thumbnail
    }
}
```

### 배치 처리 최적화

```swift
func generateBatchThumbnailsOptimized(
    from videoURL: URL,
    at times: [TimeInterval],
    size: CGSize = CGSize(width: 200, height: 200)
) async throws -> [UIImage?] {
    let asset = AVAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = size
    generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
    generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
    
    // 캐시 확인 및 병렬 생성
    return try await withThrowingTaskGroup(of: (Int, UIImage?).self) { group in
        for (index, time) in times.enumerated() {
            group.addTask { [index] in
                let cacheKey = ThumbnailCacheKey(videoURL: videoURL, time: time, maximumSize: size)
                
                // 캐시 확인
                if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
                    return (index, cached)
                }
                
                // 생성
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                if let cgImage = try? await generator.image(at: cmTime).image {
                    let thumbnail = UIImage(cgImage: cgImage)
                    ThumbnailCache.shared.storeThumbnail(thumbnail, for: cacheKey)
                    return (index, thumbnail)
                }
                
                return (index, nil)
            }
        }
        
        // 결과 수집
        var results = Array(repeating: UIImage?.none, count: times.count)
        for try await (index, thumbnail) in group {
            results[index] = thumbnail
        }
        return results
    }
}
```

---

## 성능 벤치마크

### 측정 예제

```swift
func benchmarkThumbnailGeneration() async {
    let videoURL = // 동영상 URL
    let times = [1.0, 5.0, 10.0, 15.0, 20.0]
    
    // 순차 처리
    let sequentialTime = await measureSequential(videoURL: videoURL, times: times)
    print("순차 처리: \(sequentialTime)초")
    
    // 병렬 처리
    let parallelTime = await measureParallel(videoURL: videoURL, times: times)
    print("병렬 처리: \(parallelTime)초")
    
    // 캐시 활용
    let cachedTime = await measureCached(videoURL: videoURL, times: times)
    print("캐시 활용: \(cachedTime)초")
}

func measureSequential(videoURL: URL, times: [TimeInterval]) async -> TimeInterval {
    let (_, duration) = await PerformanceMeasurer.measureTime {
        for time in times {
            _ = try? await ThumbnailGenerator.generateThumbnail(from: videoURL, at: time)
        }
    }
    return duration
}

func measureParallel(videoURL: URL, times: [TimeInterval]) async -> TimeInterval {
    let (_, duration) = await PerformanceMeasurer.measureTime {
        _ = try? await ThumbnailGenerator.generateThumbnails(from: videoURL, at: times)
    }
    return duration
}

func measureCached(videoURL: URL, times: [TimeInterval]) async -> TimeInterval {
    // 첫 번째는 생성, 두 번째는 캐시에서 가져오기
    _ = try? await ThumbnailGenerator.generateThumbnails(from: videoURL, at: times)
    
    let (_, duration) = await PerformanceMeasurer.measureTime {
        _ = try? await ThumbnailGenerator.generateThumbnails(from: videoURL, at: times)
    }
    return duration
}
```

---

## 성능 체크리스트

### 기본 최적화

- [ ] `maximumSize` 설정으로 크기 제한
- [ ] `requestedTimeTolerance` 설정으로 성능 향상
- [ ] 캐싱 시스템 구현
- [ ] 비동기 처리 (async/await)

### 고급 최적화

- [ ] 병렬 처리 (TaskGroup)
- [ ] 메모리 캐시 크기 제한
- [ ] 디스크 캐시 활용
- [ ] 메모리 누수 방지

### 모니터링

- [ ] 생성 시간 측정
- [ ] 메모리 사용량 추적
- [ ] 캐시 히트율 측정
- [ ] 성능 로깅

---

## 요약

1. **크기 제한**: 가장 효과적인 최적화
2. **시간 허용 오차**: 성능과 정확도의 균형
3. **캐싱**: 반복 생성 방지
4. **병렬 처리**: 여러 썸네일 동시 생성
5. **메모리 관리**: 적절한 크기 제한과 정리

---

## 참고 자료

- [Apple: Performance Best Practices](https://developer.apple.com/documentation/avfoundation/avassetimagegenerator)
- [WWDC: Optimize App Performance](https://developer.apple.com/videos/play/wwdc2021/10247/)

---

**다음 단계**: 실제 프로젝트에서 성능을 측정하고 최적화를 적용해보세요!

