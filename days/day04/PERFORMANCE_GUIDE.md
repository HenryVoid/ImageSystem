# 성능 최적화 가이드

> Image I/O를 사용한 효율적인 이미지 메타데이터 처리

---

## 📋 목차

1. [성능 비교](#성능-비교)
2. [메타데이터 읽기 최적화](#메타데이터-읽기-최적화)
3. [썸네일 생성 최적화](#썸네일-생성-최적화)
4. [메모리 관리](#메모리-관리)
5. [백그라운드 처리](#백그라운드-처리)

---

## 성능 비교

### ⚡ UIImage vs Image I/O

| 작업 | UIImage | Image I/O | 메모리 절약 | 속도 |
|-----|---------|-----------|-----------|------|
| 메타데이터만 읽기 | 48MB | 10KB | **4,800배** | 100배 빠름 |
| 200px 썸네일 생성 | 48MB | 150KB | 320배 | 50배 빠름 |
| 4K 이미지 전체 로드 | 48MB | 48MB | 동일 | 비슷함 |
| RAW 파일 (50MB) | 300MB+ | 100KB | **3,000배** | 200배 빠름 |

### 📊 실제 측정 결과

4032×3024 JPEG 이미지 기준:

```swift
// ❌ UIImage - 전체 로드
let start = CFAbsoluteTimeGetCurrent()
let image = UIImage(contentsOfFile: url.path)
let duration = CFAbsoluteTimeGetCurrent() - start
// 시간: ~100ms
// 메모리: ~48MB

// ✅ Image I/O - 메타데이터만
let start = CFAbsoluteTimeGetCurrent()
let exif = EXIFReader.loadEXIFData(from: url)
let duration = CFAbsoluteTimeGetCurrent() - start
// 시간: ~1ms (100배 빠름!)
// 메모리: ~10KB (4,800배 절약!)
```

---

## 메타데이터 읽기 최적화

### 1️⃣ 필요한 것만 읽기

```swift
// ❌ Bad - 전체 딕셔너리 파싱
func loadAllMetadata(from url: URL) -> [String: Any]? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
        return nil
    }
    
    // 모든 메타데이터를 파싱 (느림)
    return convertAllProperties(properties)
}

// ✅ Good - 필요한 필드만 추출
func loadCameraInfo(from url: URL) -> (make: String?, model: String?) {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] else {
        return (nil, nil)
    }
    
    // TIFF에서 카메라 정보만 추출
    let make = tiff[kCGImagePropertyTIFFMake] as? String
    let model = tiff[kCGImagePropertyTIFFModel] as? String
    
    return (make, model)
}
```

### 2️⃣ 캐싱 비활성화

대량 이미지 처리 시 캐싱을 비활성화하여 메모리 절약:

```swift
func loadEXIFWithoutCache(from url: URL) -> EXIFData? {
    let options: [CFString: Any] = [
        kCGImageSourceShouldCache: false  // 캐싱 비활성화
    ]
    
    guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
        return nil
    }
    
    return parseEXIF(properties)
}
```

### 3️⃣ 조건부 읽기

```swift
// GPS가 있는 사진만 처리
func loadPhotosWithGPS(urls: [URL]) -> [(URL, CLLocationCoordinate2D)] {
    return urls.compactMap { url in
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let coord = extractCoordinate(from: gps) else {
            return nil  // GPS 없으면 스킵
        }
        
        return (url, coord)
    }
}
```

---

## 썸네일 생성 최적화

### 🎯 베스트 프랙티스

```swift
func generateOptimizedThumbnail(from url: URL, maxSize: CGFloat) -> UIImage? {
    let options: [CFString: Any] = [
        // 1. 최대 크기 지정 (긴 쪽 기준)
        kCGImageSourceThumbnailMaxPixelSize: maxSize,
        
        // 2. 썸네일이 없어도 생성
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        
        // 3. 방향 자동 적용
        kCGImageSourceCreateThumbnailWithTransform: true,
        
        // 4. 캐싱 비활성화 (대량 처리 시)
        kCGImageSourceShouldCache: false
    ]
    
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }
    
    return UIImage(cgImage: thumbnail)
}
```

### 📐 크기별 용도

| 크기 | 용도 | 메모리 (RGB) | 예시 |
|-----|------|-------------|------|
| 50px | 아주 작은 아이콘 | ~10KB | 알림 |
| 100px | 작은 썸네일 | ~40KB | 리스트 뷰 |
| 200px | 중간 썸네일 | ~150KB | 그리드 뷰 |
| 400px | 큰 썸네일 | ~600KB | 프리뷰 |
| 800px | 미리보기 | ~2.4MB | 전체 화면 |

### 🚀 성능 팁

```swift
// ✅ 효율적인 그리드 뷰
struct PhotoGridView: View {
    let urls: [URL]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
            ForEach(urls, id: \.self) { url in
                ThumbnailView(url: url, size: 100)  // 100px 썸네일
                    .aspectRatio(1, contentMode: .fill)
            }
        }
    }
}

struct ThumbnailView: View {
    let url: URL
    let size: CGFloat
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
            } else {
                ProgressView()
            }
        }
        .task {
            // 백그라운드에서 썸네일 생성
            thumbnail = await Task.detached(priority: .userInitiated) {
                generateOptimizedThumbnail(from: url, maxSize: size)
            }.value
        }
    }
}
```

---

## 메모리 관리

### 💾 메모리 사용량 모니터링

```swift
class MemoryMonitor {
    static func currentUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    static func formattedUsage() -> String {
        let bytes = currentUsage()
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory)
    }
}

// 사용 예시
let before = MemoryMonitor.currentUsage()
let exif = loadEXIFData(from: url)
let after = MemoryMonitor.currentUsage()
print("메모리 사용: \(ByteCountFormatter.string(fromByteCount: after - before, countStyle: .memory))")
```

### 🔄 메모리 압박 대응

```swift
class PhotoLoader {
    private var thumbnailCache: [URL: UIImage] = [:]
    
    init() {
        // 메모리 경고 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc func clearCache() {
        print("⚠️ 메모리 경고 - 캐시 정리")
        thumbnailCache.removeAll()
    }
    
    func loadThumbnail(url: URL, size: CGFloat) -> UIImage? {
        // 캐시 확인
        if let cached = thumbnailCache[url] {
            return cached
        }
        
        // 썸네일 생성
        guard let thumbnail = generateOptimizedThumbnail(from: url, maxSize: size) else {
            return nil
        }
        
        // 캐시 크기 제한 (최대 100개)
        if thumbnailCache.count > 100 {
            let oldest = thumbnailCache.keys.first!
            thumbnailCache.removeValue(forKey: oldest)
        }
        
        thumbnailCache[url] = thumbnail
        return thumbnail
    }
}
```

### 🗑️ Autoreleasepool 활용

대량 이미지 처리 시 메모리 정리:

```swift
func processManyPhotos(urls: [URL]) {
    for url in urls {
        autoreleasepool {
            // 썸네일 생성
            if let thumbnail = generateOptimizedThumbnail(from: url, maxSize: 200) {
                saveThumbnail(thumbnail, for: url)
            }
            
            // 이 블록이 끝나면 자동으로 메모리 해제
        }
    }
}
```

---

## 백그라운드 처리

### 🔀 비동기 처리

```swift
// ✅ 단일 이미지 - async/await
func loadEXIFAsync(from url: URL) async -> EXIFData? {
    return await Task.detached(priority: .userInitiated) {
        EXIFReader.loadEXIFData(from: url)
    }.value
}

// 사용
Task {
    if let exif = await loadEXIFAsync(from: url) {
        await MainActor.run {
            self.exifData = exif
        }
    }
}
```

### 🚄 병렬 처리

```swift
// ✅ 여러 이미지 - TaskGroup
func loadMultipleEXIF(urls: [URL]) async -> [URL: EXIFData] {
    await withTaskGroup(of: (URL, EXIFData?).self) { group in
        var results: [URL: EXIFData] = [:]
        
        for url in urls {
            group.addTask {
                let exif = EXIFReader.loadEXIFData(from: url)
                return (url, exif)
            }
        }
        
        for await (url, exif) in group {
            if let exif = exif {
                results[url] = exif
            }
        }
        
        return results
    }
}

// 사용 (100개 이미지 동시 처리)
let exifData = await loadMultipleEXIF(urls: photoURLs)
```

### ⏸️ 진행률 표시

```swift
actor ProgressTracker {
    private var completed: Int = 0
    private let total: Int
    
    init(total: Int) {
        self.total = total
    }
    
    func increment() -> Double {
        completed += 1
        return Double(completed) / Double(total)
    }
}

func loadWithProgress(urls: [URL]) async -> [EXIFData] {
    let tracker = ProgressTracker(total: urls.count)
    
    return await withTaskGroup(of: EXIFData?.self) { group in
        var results: [EXIFData] = []
        
        for url in urls {
            group.addTask {
                let exif = EXIFReader.loadEXIFData(from: url)
                let progress = await tracker.increment()
                
                await MainActor.run {
                    print("진행률: \(Int(progress * 100))%")
                }
                
                return exif
            }
        }
        
        for await exif in group {
            if let exif = exif {
                results.append(exif)
            }
        }
        
        return results
    }
}
```

---

## 실전 최적화 예시

### 📱 갤러리 앱 최적화

```swift
class PhotoGalleryViewModel: ObservableObject {
    @Published var thumbnails: [URL: UIImage] = [:]
    @Published var exifData: [URL: EXIFData] = [:]
    
    private let thumbnailQueue = DispatchQueue(label: "thumbnail", qos: .userInitiated, attributes: .concurrent)
    private let exifQueue = DispatchQueue(label: "exif", qos: .utility, attributes: .concurrent)
    
    func loadGallery(urls: [URL]) {
        // 1단계: 썸네일 우선 로드 (빠른 UI)
        thumbnailQueue.async {
            let group = DispatchGroup()
            
            for url in urls {
                group.enter()
                self.loadThumbnail(url: url) {
                    group.leave()
                }
            }
            
            group.wait()
            print("✅ 썸네일 로드 완료")
        }
        
        // 2단계: EXIF 백그라운드 로드 (느림)
        exifQueue.async {
            for url in urls {
                autoreleasepool {
                    if let exif = EXIFReader.loadEXIFData(from: url) {
                        DispatchQueue.main.async {
                            self.exifData[url] = exif
                        }
                    }
                }
            }
            
            print("✅ EXIF 로드 완료")
        }
    }
    
    private func loadThumbnail(url: URL, completion: @escaping () -> Void) {
        guard let thumbnail = generateOptimizedThumbnail(from: url, maxSize: 200) else {
            completion()
            return
        }
        
        DispatchQueue.main.async {
            self.thumbnails[url] = thumbnail
            completion()
        }
    }
}
```

### 🗺️ 지도 앱 최적화

```swift
// GPS가 있는 사진만 효율적으로 필터링
func loadPhotosForMap(urls: [URL]) async -> [PhotoAnnotation] {
    await withTaskGroup(of: PhotoAnnotation?.self) { group in
        var annotations: [PhotoAnnotation] = []
        
        for url in urls {
            group.addTask {
                // EXIF만 빠르게 읽기
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                      let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
                      let coord = extractCoordinate(from: gps) else {
                    return nil  // GPS 없으면 즉시 스킵
                }
                
                // GPS 있는 것만 썸네일 생성
                let thumbnail = generateOptimizedThumbnail(from: url, maxSize: 100)
                
                return PhotoAnnotation(coordinate: coord, thumbnail: thumbnail)
            }
        }
        
        for await annotation in group {
            if let annotation = annotation {
                annotations.append(annotation)
            }
        }
        
        return annotations
    }
}
```

---

## 📊 성능 측정

### Instruments 사용

```swift
import os.signpost

let log = OSLog(subsystem: "com.app.photos", category: "performance")

func loadWithSignpost(url: URL) -> EXIFData? {
    let signpostID = OSSignpostID(log: log)
    
    os_signpost(.begin, log: log, name: "EXIF Load", signpostID: signpostID)
    let exif = EXIFReader.loadEXIFData(from: url)
    os_signpost(.end, log: log, name: "EXIF Load", signpostID: signpostID)
    
    return exif
}
```

Instruments에서 확인:
1. Xcode → Product → Profile (⌘I)
2. "os_signpost" 템플릿 선택
3. 앱 실행 후 타임라인 확인

---

## 💡 핵심 요약

### ✅ 해야 할 것

1. **메타데이터만 필요하면 Image I/O 사용**
2. **썸네일은 적절한 크기로 생성** (100-200px)
3. **백그라운드 스레드에서 처리**
4. **대량 처리 시 autoreleasepool 사용**
5. **캐시 크기 제한**
6. **메모리 경고 대응**

### ❌ 피해야 할 것

1. UIImage로 메타데이터 읽기
2. 메인 스레드에서 대량 이미지 처리
3. 필요 이상으로 큰 썸네일 생성
4. 무제한 캐싱
5. 메모리 모니터링 없이 대량 처리

### 📈 성능 목표

| 작업 | 목표 시간 | 메모리 |
|-----|----------|--------|
| EXIF 읽기 | < 1ms | < 50KB |
| 썸네일 생성 (200px) | < 10ms | < 200KB |
| 1000장 갤러리 로드 | < 3s | < 50MB |

---

*올바른 최적화로 빠르고 효율적인 사진 앱을 만들어보세요!*


