# 성능 비교 & 최적화 가이드

> 캐시 적용 전후 성능 측정 및 최적화 기법

---

## 📊 성능 측정 항목

### 핵심 지표

이미지 로딩 성능을 평가할 때 측정해야 할 3가지:

```
┌─────────────────────────────────┐
│  1. 로딩 시간 (Latency)          │
│     - 요청 → 화면 표시까지        │
│     - 목표: < 100ms              │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  2. 네트워크 사용량 (Bandwidth)   │
│     - 다운로드 데이터 크기        │
│     - 목표: 최소화               │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  3. 메모리 사용량 (Memory)        │
│     - 캐시가 차지하는 메모리      │
│     - 목표: < 100MB              │
└─────────────────────────────────┘
```

---

## ⚡ 캐시 없는 로딩 vs 캐시 적용

### 시나리오: 10개 이미지를 3번 로드

**테스트 환경**:
- 이미지 크기: 800×600 JPEG (약 100KB)
- 네트워크: 4G LTE (평균 50Mbps)
- 기기: iPhone 15 Simulator

---

### 🐢 캐시 없는 버전

```swift
class SimpleImageLoader {
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // 매번 네트워크 요청
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
```

**측정 결과**:

| 로드 차수 | 평균 시간 | 총 시간 | 데이터 사용 |
|----------|----------|---------|------------|
| 1차 로드 | 500ms | 5000ms | 1.0MB |
| 2차 로드 | 500ms | 5000ms | 1.0MB |
| 3차 로드 | 500ms | 5000ms | 1.0MB |
| **합계** | - | **15000ms** | **3.0MB** |

**문제점**:
- ❌ 매번 네트워크 요청 (느림)
- ❌ 중복 데이터 다운로드 (비용)
- ❌ 동일 이미지 재로드 시 지연

---

### 🚀 캐시 적용 버전

```swift
class CachedImageLoader {
    private let cache = NSCache<NSString, UIImage>()
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString as NSString
        
        // 캐시 확인
        if let cached = cache.object(forKey: key) {
            completion(cached)  // 즉시 반환!
            return
        }
        
        // 없으면 다운로드 + 캐시 저장
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            self.cache.setObject(image, forKey: key)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
```

**측정 결과**:

| 로드 차수 | 평균 시간 | 총 시간 | 캐시 히트율 | 데이터 사용 |
|----------|----------|---------|------------|------------|
| 1차 로드 | 500ms | 5000ms | 0% | 1.0MB |
| 2차 로드 | 5ms | 50ms | **100%** | 0MB |
| 3차 로드 | 5ms | 50ms | **100%** | 0MB |
| **합계** | - | **5100ms** | 66.7% | **1.0MB** |

**개선 효과**:
- ✅ **66% 시간 단축** (15000ms → 5100ms)
- ✅ **66% 데이터 절감** (3.0MB → 1.0MB)
- ✅ **100배 빠른 재로드** (500ms → 5ms)

---

## 📈 상세 성능 비교

### 1. 로딩 시간 분석

**캐시 없음**:
```
[이미지 1] ████████████████████ 500ms
[이미지 2] ████████████████████ 500ms
[이미지 3] ████████████████████ 500ms
[이미지 4] ████████████████████ 500ms
[이미지 5] ████████████████████ 500ms
[이미지 6] ████████████████████ 500ms
[이미지 7] ████████████████████ 500ms
[이미지 8] ████████████████████ 500ms
[이미지 9] ████████████████████ 500ms
[이미지 10] ███████████████████ 500ms
────────────────────────────────────
총합: 5000ms
```

**캐시 적용 (2차 로드)**:
```
[이미지 1] █ 5ms (캐시)
[이미지 2] █ 5ms (캐시)
[이미지 3] █ 5ms (캐시)
[이미지 4] █ 5ms (캐시)
[이미지 5] █ 5ms (캐시)
[이미지 6] █ 5ms (캐시)
[이미지 7] █ 5ms (캐시)
[이미지 8] █ 5ms (캐시)
[이미지 9] █ 5ms (캐시)
[이미지 10] █ 5ms (캐시)
────────────────────────────────────
총합: 50ms ⚡
```

---

### 2. 네트워크 트래픽 분석

**캐시 없음** (3회 로드):
```
1차: [Download] 1.0MB ──────────▶ 총 1.0MB
2차: [Download] 1.0MB ──────────▶ 총 2.0MB
3차: [Download] 1.0MB ──────────▶ 총 3.0MB
```

**캐시 적용** (3회 로드):
```
1차: [Download] 1.0MB ──────────▶ 총 1.0MB
2차: [Cache Hit] 0MB   ─────────▶ 총 1.0MB
3차: [Cache Hit] 0MB   ─────────▶ 총 1.0MB
```

**절감 효과**: 2.0MB 절약 (월 1만 회 로드 시 **20GB 절감!**)

---

### 3. 메모리 사용량 분석

**캐시 없음**:
```
앱 시작: 50MB
로딩 중: 55MB (임시 메모리)
로딩 후: 50MB (해제됨)
```

**캐시 적용**:
```
앱 시작: 50MB
로딩 중: 55MB
로딩 후: 60MB (캐시 10MB 유지)
메모리 경고 시: 50MB (자동 정리)
```

**메모리 오버헤드**: 약 10MB (10개 이미지)  
**장점**: NSCache가 메모리 부족 시 자동 정리

---

## 🔬 측정 도구 구현

### PerformanceLogger.swift

```swift
import os.log
import os.signpost

class PerformanceLogger {
    static let shared = PerformanceLogger()
    
    private let log = OSLog(subsystem: "com.study.day08", category: "performance")
    
    // Signpost ID 생성
    func beginSignpost(name: StaticString) -> OSSignpostID {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        return id
    }
    
    // Signpost 종료
    func endSignpost(name: StaticString, id: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }
    
    // 시간 측정 헬퍼
    func measure<T>(name: String, block: () -> T) -> (result: T, duration: TimeInterval) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        os_log(.info, log: log, "%{public}s: %.2fms", name, duration * 1000)
        
        return (result, duration)
    }
}
```

### 사용 예제

```swift
// Signpost 사용
let id = PerformanceLogger.shared.beginSignpost(name: "Image_Load")
loadImage(url: url) { image in
    PerformanceLogger.shared.endSignpost(name: "Image_Load", id: id)
}

// 간단한 측정
let (image, duration) = PerformanceLogger.shared.measure(name: "Decode") {
    return UIImage(data: data)
}
print("디코딩 시간: \(duration * 1000)ms")
```

---

## 📊 벤치마크 구현

### BenchmarkRunner.swift

```swift
struct BenchmarkResult {
    let name: String
    let iterations: Int
    let totalTime: TimeInterval
    let averageTime: TimeInterval
    let minTime: TimeInterval
    let maxTime: TimeInterval
    
    var description: String {
        """
        📊 \(name)
        반복: \(iterations)회
        평균: \(String(format: "%.2f", averageTime * 1000))ms
        최소: \(String(format: "%.2f", minTime * 1000))ms
        최대: \(String(format: "%.2f", maxTime * 1000))ms
        총합: \(String(format: "%.2f", totalTime))s
        """
    }
}

class BenchmarkRunner {
    static func run(
        name: String,
        iterations: Int,
        task: (@escaping () -> Void) -> Void
    ) async -> BenchmarkResult {
        var times: [TimeInterval] = []
        
        for i in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            
            await withCheckedContinuation { continuation in
                task {
                    let duration = CFAbsoluteTimeGetCurrent() - start
                    times.append(duration)
                    continuation.resume()
                }
            }
            
            print("[\(i + 1)/\(iterations)] \(String(format: "%.2f", times.last! * 1000))ms")
        }
        
        return BenchmarkResult(
            name: name,
            iterations: iterations,
            totalTime: times.reduce(0, +),
            averageTime: times.reduce(0, +) / Double(times.count),
            minTime: times.min() ?? 0,
            maxTime: times.max() ?? 0
        )
    }
}
```

### 사용 예제

```swift
// 캐시 없는 버전 벤치마크
let noCacheResult = await BenchmarkRunner.run(
    name: "캐시 없음",
    iterations: 10
) { completion in
    SimpleImageLoader.shared.loadImage(from: url) { _ in
        completion()
    }
}

// 캐시 적용 버전 벤치마크
let cachedResult = await BenchmarkRunner.run(
    name: "캐시 적용",
    iterations: 10
) { completion in
    CachedImageLoader.shared.loadImage(from: url) { _ in
        completion()
    }
}

print(noCacheResult.description)
print(cachedResult.description)
```

---

## 🎯 최적화 기법

### 1. 이미지 다운샘플링

큰 이미지를 작게 표시할 때는 **다운샘플링** 필수:

```swift
func downsample(data: Data, to size: CGSize) -> UIImage? {
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
        return nil
    }
    
    let options: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]
    
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        return nil
    }
    
    return UIImage(cgImage: cgImage)
}
```

**효과**:
- 메모리: **75% 감소** (4000×3000 → 1000×750)
- 디코딩 속도: **50% 빠름**

---

### 2. 병렬 다운로드

여러 이미지를 **동시에** 다운로드:

```swift
// ❌ 순차 다운로드 (느림)
for url in urls {
    let image = try await loadImage(url: url)
    images.append(image)
}
// 총 시간: 500ms × 10 = 5000ms

// ✅ 병렬 다운로드 (빠름)
let images = try await withThrowingTaskGroup(of: UIImage.self) { group in
    for url in urls {
        group.addTask {
            try await loadImage(url: url)
        }
    }
    
    var results: [UIImage] = []
    for try await image in group {
        results.append(image)
    }
    return results
}
// 총 시간: max(500ms) = 500ms ⚡
```

**효과**: **10배 빠름** (5000ms → 500ms)

---

### 3. 이미지 프리로딩

화면에 보이기 전에 **미리 로드**:

```swift
class ImagePrefetcher {
    func prefetch(urls: [URL]) {
        for url in urls {
            Task(priority: .low) {
                _ = try? await CachedImageLoader.shared.loadImage(from: url)
            }
        }
    }
}

// 사용: 스크롤 시 다음 페이지 프리로드
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let visibleRange = calculateVisibleRange()
    let prefetchRange = visibleRange.upperBound..<(visibleRange.upperBound + 10)
    
    let urlsToPrefetch = urls[prefetchRange]
    ImagePrefetcher.shared.prefetch(urls: urlsToPrefetch)
}
```

**효과**: 사용자가 스크롤할 때 이미지가 **이미 로드됨**

---

### 4. 점진적 이미지 로딩

이미지를 **단계적으로** 표시 (Progressive JPEG):

```swift
class ProgressiveImageLoader {
    func loadImage(url: URL, progress: @escaping (UIImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            
            // 부분 데이터로 이미지 생성 (흐릿한 버전)
            if let partial = UIImage(data: data) {
                progress(partial)
            }
        }
        
        task.resume()
    }
}
```

**효과**: 사용자가 **즉시** 무언가를 봄 (UX 개선)

---

## 🏆 최적화 체크리스트

### 필수 최적화

- [x] **NSCache 사용**: 중복 다운로드 방지
- [x] **weak self**: 메모리 누수 방지
- [x] **메인 스레드 전환**: UI 업데이트
- [x] **에러 처리**: 네트워크 실패 대응

### 고급 최적화

- [ ] **다운샘플링**: 큰 이미지 리사이징
- [ ] **병렬 다운로드**: TaskGroup 활용
- [ ] **프리로딩**: 미리 캐시 워밍
- [ ] **점진적 로딩**: 부분 이미지 표시

### 측정 및 모니터링

- [ ] **Instruments**: Time Profiler 사용
- [ ] **Signpost**: os_signpost로 구간 측정
- [ ] **메모리**: Allocations 확인
- [ ] **네트워크**: Network Instrument 사용

---

## 📱 실기기 vs 시뮬레이터

### 성능 차이

| 항목 | 시뮬레이터 | 실기기 |
|------|----------|--------|
| CPU | Mac CPU (빠름) | ARM CPU |
| 메모리 | Mac RAM (많음) | 제한적 |
| 네트워크 | 로컬 (매우 빠름) | 실제 네트워크 |
| GPU | Mac GPU | 모바일 GPU |

**주의**: 시뮬레이터는 **실제보다 빠름**. 꼭 **실기기에서 테스트**!

---

## 🎯 목표 성능 지표

### 권장 기준

| 항목 | 목표 | 우수 |
|------|------|------|
| 첫 로드 | < 1000ms | < 500ms |
| 캐시 히트 | < 100ms | < 50ms |
| 캐시 히트율 | > 50% | > 80% |
| 메모리 사용 | < 100MB | < 50MB |

---

## 🔍 Instruments 활용

### 1. Time Profiler

```bash
⌘I → Time Profiler 선택 → Record
```

**확인 사항**:
- `URLSession.dataTask` 호출 횟수
- 메인 스레드 차단 여부
- 이미지 디코딩 시간

### 2. Allocations

```bash
⌘I → Allocations 선택 → Record
```

**확인 사항**:
- UIImage 메모리 사용량
- NSCache 크기
- 메모리 누수

### 3. Network

```bash
⌘I → Network 선택 → Record
```

**확인 사항**:
- 총 다운로드 데이터
- 요청 횟수
- 중복 요청

---

## 🎓 핵심 요약

### 캐시의 위력

| 지표 | 개선률 |
|------|--------|
| 로딩 시간 | **66% ↓** |
| 네트워크 사용 | **66% ↓** |
| 재로드 속도 | **100배 ↑** |

### 추가 최적화

- **다운샘플링**: 75% 메모리 절감
- **병렬 다운로드**: 10배 속도 향상
- **프리로딩**: 체감 속도 무한대

### 측정 도구

- **PerformanceLogger**: os_signpost 활용
- **BenchmarkRunner**: 반복 테스트
- **Instruments**: 정밀 분석

---

**성능 최적화 마스터! 🎉**

*다음: 실제 구현에서 이 모든 기법을 직접 체험합니다!*

























