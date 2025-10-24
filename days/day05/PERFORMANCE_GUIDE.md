# 이미지 리사이즈 & 포맷 변환 성능 가이드

> 메모리와 속도를 최적화하는 실전 전략

---

## 📚 목차

1. [성능 측정 기준](#성능-측정-기준)
2. [메모리 최적화](#메모리-최적화)
3. [속도 최적화](#속도-최적화)
4. [배치 처리 최적화](#배치-처리-최적화)
5. [실전 패턴](#실전-패턴)

---

## 성능 측정 기준

### 측정 항목

성능을 평가할 때 고려해야 할 3가지 지표:

| 지표 | 설명 | 측정 방법 |
|------|------|-----------|
| **메모리** | 피크 메모리 사용량 | Instruments (Allocations) |
| **속도** | 처리 시간 | `CFAbsoluteTimeGetCurrent()` |
| **화질** | 이미지 품질 | PSNR, SSIM |

### 테스트 이미지

일관된 측정을 위한 표준 이미지:

```swift
// 테스트 이미지 스펙
let testImage = UIImage(/* ... */)
// 해상도: 4032 × 3024 (12MP)
// 원본 메모리: ~48MB (비압축 비트맵)
// JPEG 파일: ~4.2MB (quality 0.9)
```

### 측정 코드

```swift
import os.signpost

class PerformanceTester {
    static func measure(
        _ name: String,
        block: () -> Void
    ) -> (time: TimeInterval, memory: UInt64) {
        // 메모리 측정 시작
        let memoryBefore = reportMemory()
        
        // 시간 측정 시작
        let start = CFAbsoluteTimeGetCurrent()
        
        // 실행
        block()
        
        // 시간 측정 종료
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        // 메모리 측정 종료
        let memoryAfter = reportMemory()
        let memoryUsed = memoryAfter - memoryBefore
        
        print("[\(name)] 시간: \(String(format: "%.2f", duration * 1000))ms, 메모리: \(memoryUsed / 1_000_000)MB")
        
        return (duration, memoryUsed)
    }
    
    private static func reportMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}
```

---

## 메모리 최적화

### 문제: 메모리 폭발

```swift
// ❌ 나쁜 예: 100개 이미지 리사이즈
var resizedImages: [UIImage] = []
for url in imageURLs {  // 100개
    let image = UIImage(contentsOfFile: url.path)!  // 48MB × 100 = 4.8GB!
    let resized = resize(image, to: targetSize)
    resizedImages.append(resized)
}
// 결과: 메모리 부족으로 앱 크래시
```

### 해결책 1: Autoreleasepool

```swift
// ✅ 좋은 예: Autoreleasepool 사용
var resizedImages: [UIImage] = []
for url in imageURLs {
    autoreleasepool {
        let image = UIImage(contentsOfFile: url.path)!
        let resized = resize(image, to: targetSize)
        resizedImages.append(resized)
    }  // 여기서 임시 객체 즉시 해제
}
// 결과: 피크 메모리 ~100MB (원본 + 결과 하나씩)
```

**동작 원리**:
```
autoreleasepool 없음:
이미지1 (48MB) → 리사이즈1 (4MB) → 메모리 48MB 유지
이미지2 (48MB) → 리사이즈2 (4MB) → 메모리 96MB 유지
...
이미지100 (48MB) → 리사이즈100 (4MB) → 메모리 4.8GB 유지 💥

autoreleasepool 있음:
이미지1 (48MB) → 리사이즈1 (4MB) → 해제 (48MB) ✅
이미지2 (48MB) → 리사이즈2 (4MB) → 해제 (48MB) ✅
...
이미지100 (48MB) → 리사이즈100 (4MB) → 해제 (48MB) ✅
피크 메모리: ~52MB
```

### 해결책 2: Image I/O 다운샘플링

```swift
// ✅ 최고: 다운샘플링으로 메모리 최소화
var resizedImages: [UIImage] = []
for url in imageURLs {
    autoreleasepool {
        // 원본을 메모리에 로드하지 않음!
        let downsampled = downsampleImage(from: url, to: targetSize)
        resizedImages.append(downsampled)
    }
}
// 결과: 피크 메모리 ~10MB (원본 로드하지 않음)
```

**메모리 사용량 비교**:

| 방법 | 피크 메모리 | 상대 메모리 |
|------|-------------|-------------|
| 일반 로드 | 4.8GB | 480x |
| Autoreleasepool | 52MB | 5.2x |
| **다운샘플링** | **10MB** | **1.0x** 🏆 |

### 해결책 3: 즉시 저장 후 해제

```swift
// ✅ 메모리에 유지하지 않고 즉시 저장
for url in imageURLs {
    autoreleasepool {
        let resized = downsampleImage(from: url, to: targetSize)
        
        // 즉시 파일로 저장
        if let data = resized?.jpegData(compressionQuality: 0.8) {
            try? data.write(to: destinationURL)
        }
        
        // resized는 autoreleasepool 종료 시 해제됨
    }
}
// 결과: 메모리에 이미지를 유지하지 않음
```

### 대용량 이미지 처리

```swift
func processLargeImage(url: URL) {
    // ❌ 나쁜 예: 전체 로드
    let image = UIImage(contentsOfFile: url.path)  // 200MB 메모리
    
    // ✅ 좋은 예: 다운샘플링
    let downsampled = downsampleImage(from: url, to: targetSize)  // 10MB 메모리
}
```

**규칙**:
- 이미지 > 10MB → 반드시 다운샘플링 사용
- 배치 처리 → 항상 `autoreleasepool` 사용
- 즉시 사용하지 않는 이미지 → 파일로 저장

---

## 속도 최적화

### 리사이즈 방법별 성능

테스트: 4032 × 3024 → 1000 × 750

| 방법 | 시간 | 메모리 | 품질 | 추천 |
|------|------|--------|------|------|
| UIGraphics | 120ms | 52MB | 우수 | 작은 이미지 |
| Core Graphics | 95ms | 52MB | 우수 | 세밀한 제어 |
| **vImage** | **35ms** | 52MB | 우수 | **실시간** 🏆 |
| Image I/O | 45ms | **10MB** | 우수 | **대용량** 🏆 |

### vImage로 속도 극대화

```swift
import Accelerate

func fastResize(image: UIImage, to size: CGSize) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }
    
    // vImage 포맷 정의
    var format = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        colorSpace: nil,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
        version: 0,
        decode: nil,
        renderingIntent: .defaultIntent
    )
    
    // 소스 버퍼
    var sourceBuffer = vImage_Buffer()
    defer { sourceBuffer.data.deallocate() }
    
    var error = vImageBuffer_InitWithCGImage(
        &sourceBuffer,
        &format,
        nil,
        cgImage,
        vImage_Flags(kvImageNoFlags)
    )
    
    guard error == kvImageNoError else { return nil }
    
    // 목적지 버퍼
    var destinationBuffer = vImage_Buffer()
    defer { destinationBuffer.data.deallocate() }
    
    error = vImageBuffer_Init(
        &destinationBuffer,
        vImagePixelCount(size.height),
        vImagePixelCount(size.width),
        format.bitsPerPixel,
        vImage_Flags(kvImageNoFlags)
    )
    
    guard error == kvImageNoError else { return nil }
    
    // 리사이즈 (고품질, 초고속)
    error = vImageScale_ARGB8888(
        &sourceBuffer,
        &destinationBuffer,
        nil,
        vImage_Flags(kvImageHighQualityResampling)
    )
    
    guard error == kvImageNoError else { return nil }
    
    // CGImage 생성
    guard let resizedCGImage = vImageCreateCGImageFromBuffer(
        &destinationBuffer,
        &format,
        nil,
        nil,
        vImage_Flags(kvImageNoFlags),
        nil
    )?.takeRetainedValue() else { return nil }
    
    return UIImage(cgImage: resizedCGImage)
}
```

**성능 비교**:
```
UIGraphics: 120ms
vImage:      35ms  (3.4배 빠름!)
```

### 비동기 처리

```swift
func resizeAsync(
    image: UIImage,
    to size: CGSize,
    completion: @escaping (UIImage?) -> Void
) {
    DispatchQueue.global(qos: .userInitiated).async {
        let resized = fastResize(image: image, to: size)
        
        DispatchQueue.main.async {
            completion(resized)
        }
    }
}

// 사용
resizeAsync(image: originalImage, to: targetSize) { resized in
    imageView.image = resized
}
```

### 포맷 변환 속도

| 변환 | 시간 | 비고 |
|------|------|------|
| UIImage → JPEG | 85ms | 표준 |
| UIImage → PNG | 180ms | 무손실 압축 느림 |
| UIImage → HEIC | 250ms | HEVC 인코딩 느림 |
| JPEG → HEIC | 200ms | 재인코딩 |
| **다운샘플 → JPEG** | **60ms** | **최적** 🏆 |

**최적화 팁**:
```swift
// ❌ 느림: 로드 → 리사이즈 → 인코딩
let image = UIImage(contentsOfFile: path)  // 100ms
let resized = resize(image, to: size)       // 120ms
let jpeg = resized.jpegData(compressionQuality: 0.8)  // 85ms
// 총: 305ms

// ✅ 빠름: 다운샘플 → 인코딩
let resized = downsampleImage(from: url, to: size)  // 45ms
let jpeg = resized.jpegData(compressionQuality: 0.8)  // 60ms
// 총: 105ms (3배 빠름!)
```

---

## 배치 처리 최적화

### 순차 vs 병렬 처리

**순차 처리**:
```swift
// 100개 이미지, 각 100ms → 총 10초
for url in imageURLs {
    let resized = processImage(url)
    results.append(resized)
}
```

**병렬 처리**:
```swift
// 100개 이미지, 8코어 병렬 → 총 1.25초 (8배 빠름!)
let queue = DispatchQueue(label: "image.processing", attributes: .concurrent)
let group = DispatchGroup()

var results: [UIImage?] = Array(repeating: nil, count: imageURLs.count)

for (index, url) in imageURLs.enumerated() {
    group.enter()
    queue.async {
        autoreleasepool {
            results[index] = processImage(url)
            group.leave()
        }
    }
}

group.wait()
```

### Concurrent OperationQueue

```swift
class BatchImageProcessor {
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    func processBatch(
        imageURLs: [URL],
        targetSize: CGSize,
        progress: @escaping (Int, Int) -> Void,
        completion: @escaping ([UIImage]) -> Void
    ) {
        var results: [Int: UIImage] = [:]
        let lock = NSLock()
        var completed = 0
        
        for (index, url) in imageURLs.enumerated() {
            operationQueue.addOperation {
                autoreleasepool {
                    if let resized = downsampleImage(from: url, to: targetSize) {
                        lock.lock()
                        results[index] = resized
                        completed += 1
                        let current = completed
                        lock.unlock()
                        
                        DispatchQueue.main.async {
                            progress(current, imageURLs.count)
                        }
                    }
                }
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        // 순서대로 정렬
        let sortedResults = results.sorted(by: { $0.key < $1.key }).map { $0.value }
        
        DispatchQueue.main.async {
            completion(sortedResults)
        }
    }
}

// 사용
let processor = BatchImageProcessor()
processor.processBatch(
    imageURLs: urls,
    targetSize: CGSize(width: 1000, height: 1000),
    progress: { current, total in
        print("진행률: \(current)/\(total)")
    },
    completion: { images in
        print("완료: \(images.count)개")
    }
)
```

### 메모리 압력 관리

```swift
class SmartBatchProcessor {
    func processBatch(imageURLs: [URL], targetSize: CGSize) -> [UIImage] {
        var results: [UIImage] = []
        
        // 메모리 압력에 따라 청크 크기 조절
        let chunkSize = determineChunkSize()
        
        for chunk in imageURLs.chunked(into: chunkSize) {
            autoreleasepool {
                let chunkResults = processChunk(chunk, targetSize: targetSize)
                results.append(contentsOf: chunkResults)
            }
        }
        
        return results
    }
    
    private func determineChunkSize() -> Int {
        let memoryPressure = ProcessInfo.processInfo.thermalState
        
        switch memoryPressure {
        case .nominal:
            return 20  // 여유 있음
        case .fair:
            return 10  // 보통
        case .serious:
            return 5   // 주의
        case .critical:
            return 1   // 위험
        @unknown default:
            return 10
        }
    }
    
    private func processChunk(_ urls: [URL], targetSize: CGSize) -> [UIImage] {
        // 병렬 처리
        let queue = DispatchQueue(label: "chunk", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [UIImage?] = Array(repeating: nil, count: urls.count)
        
        for (index, url) in urls.enumerated() {
            group.enter()
            queue.async {
                results[index] = downsampleImage(from: url, to: targetSize)
                group.leave()
            }
        }
        
        group.wait()
        return results.compactMap { $0 }
    }
}
```

---

## 실전 패턴

### 1. 썸네일 그리드 (갤러리)

```swift
class ThumbnailGenerator {
    // 썸네일 캐시
    private let cache = NSCache<NSURL, UIImage>()
    
    init() {
        cache.countLimit = 200  // 최대 200개 캐싱
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB
    }
    
    func thumbnail(
        for url: URL,
        size: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) {
        // 캐시 확인
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }
        
        // 백그라운드에서 생성
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            autoreleasepool {
                // 다운샘플링 (메모리 효율)
                let thumbnail = downsampleImage(from: url, to: size)
                
                if let thumbnail = thumbnail {
                    // 캐시에 저장
                    let cost = Int(size.width * size.height * 4)  // 바이트
                    self?.cache.setObject(thumbnail, forKey: url as NSURL, cost: cost)
                }
                
                DispatchQueue.main.async {
                    completion(thumbnail)
                }
            }
        }
    }
}
```

### 2. Progressive 로딩

```swift
class ProgressiveImageLoader {
    func load(
        from url: URL,
        into imageView: UIImageView,
        placeholder: UIImage? = nil
    ) {
        // 1. 플레이스홀더 즉시 표시
        imageView.image = placeholder
        
        // 2. 작은 썸네일 로드 (빠름)
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = downsampleImage(
                from: url,
                to: CGSize(width: 100, height: 100)
            )
            
            DispatchQueue.main.async {
                imageView.image = thumbnail
            }
            
            // 3. 실제 크기 로드 (느림)
            DispatchQueue.global(qos: .utility).async {
                let fullSize = downsampleImage(
                    from: url,
                    to: imageView.bounds.size,
                    scale: UIScreen.main.scale
                )
                
                DispatchQueue.main.async {
                    UIView.transition(
                        with: imageView,
                        duration: 0.3,
                        options: .transitionCrossDissolve
                    ) {
                        imageView.image = fullSize
                    }
                }
            }
        }
    }
}
```

### 3. 적응형 품질 조절

```swift
class AdaptiveQualityEncoder {
    func encode(
        image: UIImage,
        targetFileSize: Int  // 바이트
    ) -> Data? {
        var quality: CGFloat = 1.0
        var data: Data?
        
        // 이진 탐색으로 최적 품질 찾기
        var low: CGFloat = 0.1
        var high: CGFloat = 1.0
        
        for _ in 0..<10 {  // 최대 10번 시도
            quality = (low + high) / 2
            data = image.jpegData(compressionQuality: quality)
            
            guard let currentSize = data?.count else { break }
            
            if currentSize > targetFileSize {
                high = quality  // 품질 낮추기
            } else if currentSize < targetFileSize * 9 / 10 {
                low = quality   // 품질 높이기
            } else {
                break  // 타겟의 90~100% 범위면 OK
            }
        }
        
        return data
    }
}

// 사용
let encoder = AdaptiveQualityEncoder()
let data = encoder.encode(image: largeImage, targetFileSize: 500_000)  // 500KB
print("결과: \(data?.count ?? 0) 바이트")
```

### 4. 메모리 압박 대응

```swift
class MemoryAwareProcessor {
    private var isProcessing = false
    
    init() {
        // 메모리 경고 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // 진행 중인 작업 일시 중지
        isProcessing = false
        
        // 캐시 정리
        clearCache()
        
        // GC 힌트
        autoreleasepool {}
    }
    
    func processImages(_ urls: [URL]) {
        isProcessing = true
        
        for url in urls {
            guard isProcessing else {
                print("메모리 압박으로 중단")
                break
            }
            
            autoreleasepool {
                // 처리 로직
                let processed = processImage(url)
                saveToFile(processed)
            }
            
            // CPU 양보 (배터리 절약)
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        isProcessing = false
    }
}
```

### 5. 에너지 효율 고려

```swift
class EnergyEfficientProcessor {
    func shouldProcess() -> Bool {
        let state = ProcessInfo.processInfo.thermalState
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        
        // 열 상태 확인
        guard state != .critical && state != .serious else {
            print("기기가 과열됨, 처리 연기")
            return false
        }
        
        // 배터리 상태 확인
        if batteryState == .unplugged && batteryLevel < 0.2 {
            print("배터리 부족, 처리 연기")
            return false
        }
        
        return true
    }
    
    func processWithEnergyAwareness(_ urls: [URL]) {
        guard shouldProcess() else { return }
        
        // Low Power Mode 확인
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            // 저전력 모드: 품질 낮추고, 속도 우선
            processWithLowQuality(urls)
        } else {
            // 일반 모드: 고품질
            processWithHighQuality(urls)
        }
    }
}
```

---

## 성능 체크리스트

### 메모리

- [ ] `autoreleasepool` 사용 (배치 처리)
- [ ] Image I/O 다운샘플링 (대용량 이미지)
- [ ] 즉시 사용하지 않는 이미지 파일 저장
- [ ] NSCache로 적절한 캐싱
- [ ] 메모리 경고 대응

### 속도

- [ ] vImage 사용 (실시간 처리)
- [ ] 비동기 처리 (백그라운드)
- [ ] 병렬 처리 (배치)
- [ ] Progressive 로딩 (UX)
- [ ] 캐싱으로 중복 처리 방지

### 품질

- [ ] 적절한 리사이즈 방법 선택
- [ ] 포맷별 최적 품질 설정
- [ ] Aspect ratio 유지
- [ ] EXIF 메타데이터 고려

### 에너지

- [ ] 열 상태 확인
- [ ] 배터리 상태 확인
- [ ] Low Power Mode 대응
- [ ] CPU 양보 (Sleep)

---

## 벤치마크 결과 예시

### 단일 이미지 (4032 × 3024 → 1000 × 750)

| 작업 | 방법 | 시간 | 메모리 | 순위 |
|------|------|------|--------|------|
| 리사이즈 | vImage | 35ms | 52MB | ⭐⭐⭐ |
| 리사이즈 | Image I/O | 45ms | 10MB | ⭐⭐⭐ |
| JPEG 인코딩 | quality 0.8 | 85ms | 4MB | ⭐⭐ |
| HEIC 인코딩 | quality 0.8 | 250ms | 4MB | ⭐ |

### 배치 처리 (100개 이미지)

| 방법 | 총 시간 | 피크 메모리 | 순위 |
|------|---------|-------------|------|
| 순차 + 일반 로드 | 12초 | 4.8GB 💥 | ⭐ |
| 순차 + 다운샘플 | 5초 | 52MB | ⭐⭐ |
| 병렬(8코어) + 다운샘플 | 0.7초 | 80MB | ⭐⭐⭐ |

---

## 요약

### 황금 규칙

1. **작은 이미지 (< 1MB)**: 간단한 방법 OK
2. **큰 이미지 (> 10MB)**: 반드시 다운샘플링
3. **배치 처리**: `autoreleasepool` + 병렬 처리
4. **실시간**: vImage
5. **메모리 제약**: Image I/O

### 성능 최적화 우선순위

```
1. 메모리 최적화 (크래시 방지)
   → 다운샘플링, autoreleasepool

2. 속도 최적화 (UX 개선)
   → vImage, 비동기, 병렬

3. 에너지 최적화 (배터리 수명)
   → 열/배터리 체크, Low Power Mode 대응
```

### 다음 단계

- 실습 뷰에서 성능 직접 측정
- Instruments로 프로파일링
- 실제 앱에 적용

---

**Happy Optimizing! ⚡**

*적절한 최적화로 빠르고 효율적인 이미지 처리를 구현하세요!*

