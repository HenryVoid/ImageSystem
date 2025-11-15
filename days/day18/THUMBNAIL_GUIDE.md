# 썸네일 생성 구현 가이드

> AVAssetImageGenerator를 사용한 썸네일 생성의 단계별 구현 가이드

---

## 📚 목차

1. [기본 썸네일 생성](#기본-썸네일-생성)
2. [비동기 처리](#비동기-처리)
3. [배치 처리](#배치-처리)
4. [캐싱 활용](#캐싱-활용)
5. [에러 처리](#에러-처리)
6. [실전 예제](#실전-예제)

---

## 기본 썸네일 생성

### 1단계: AVAsset 생성

```swift
import AVFoundation

let videoURL = URL(fileURLWithPath: "/path/to/video.mp4")
let asset = AVAsset(url: videoURL)
```

### 2단계: AVAssetImageGenerator 생성

```swift
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.maximumSize = CGSize(width: 200, height: 200)
```

### 3단계: 시간 지정 및 이미지 생성

```swift
let time = CMTime(seconds: 5.0, preferredTimescale: 600)

do {
    let cgImage = try await generator.image(at: time).image
    let thumbnail = UIImage(cgImage: cgImage)
    // 썸네일 사용
} catch {
    print("에러: \(error)")
}
```

### 완전한 예제

```swift
func generateThumbnail(from videoURL: URL, at time: TimeInterval) async throws -> UIImage {
    // 1. Asset 생성
    let asset = AVAsset(url: videoURL)
    
    // 2. Generator 생성 및 설정
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 200, height: 200)
    
    // 3. CMTime 변환
    let cmTime = CMTime(seconds: time, preferredTimescale: 600)
    
    // 4. 이미지 생성
    let cgImage = try await generator.image(at: cmTime).image
    return UIImage(cgImage: cgImage)
}
```

---

## 비동기 처리

### SwiftUI에서 사용

```swift
struct ThumbnailView: View {
    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            }
        }
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        isLoading = true
        
        do {
            let image = try await ThumbnailGenerator.generateThumbnail(
                from: videoURL,
                at: 5.0
            )
            
            await MainActor.run {
                self.thumbnail = image
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("에러: \(error)")
        }
    }
}
```

### Task 사용

```swift
Button("썸네일 생성") {
    Task {
        do {
            let thumbnail = try await ThumbnailGenerator.generateThumbnail(
                from: videoURL,
                at: time
            )
            await MainActor.run {
                self.thumbnail = thumbnail
            }
        } catch {
            print("에러: \(error)")
        }
    }
}
```

### 백그라운드 처리

```swift
Task.detached(priority: .userInitiated) {
    let thumbnail = try await ThumbnailGenerator.generateThumbnail(
        from: videoURL,
        at: time
    )
    
    await MainActor.run {
        self.thumbnail = thumbnail
    }
}
```

---

## 배치 처리

### 여러 시간에서 썸네일 생성

```swift
func generateMultipleThumbnails(
    from videoURL: URL,
    at times: [TimeInterval]
) async throws -> [UIImage?] {
    let asset = AVAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 200, height: 200)
    
    let cmTimes = times.map { 
        CMTime(seconds: $0, preferredTimescale: 600) 
    }
    
    // 병렬 처리
    return try await withThrowingTaskGroup(of: UIImage?.self) { group in
        for cmTime in cmTimes {
            group.addTask {
                try? await generator.image(at: cmTime).image
            }
        }
        
        var results: [UIImage?] = []
        for try await thumbnail in group {
            results.append(thumbnail)
        }
        return results
    }
}
```

### 진행률 표시

```swift
func generateThumbnailsWithProgress(
    from videoURL: URL,
    at times: [TimeInterval],
    progressHandler: @escaping (Double) -> Void
) async throws -> [UIImage?] {
    // ... generator 설정 ...
    
    var results: [UIImage?] = []
    var completedCount = 0
    
    try await withThrowingTaskGroup(of: (Int, UIImage?).self) { group in
        for (index, cmTime) in cmTimes.enumerated() {
            group.addTask {
                let thumbnail = try? await generator.image(at: cmTime).image
                return (index, thumbnail)
            }
        }
        
        results = Array(repeating: nil, count: cmTimes.count)
        
        for try await (index, thumbnail) in group {
            results[index] = thumbnail
            completedCount += 1
            
            let progress = Double(completedCount) / Double(cmTimes.count)
            progressHandler(progress)
        }
    }
    
    return results
}
```

### SwiftUI에서 진행률 표시

```swift
@State private var progress: Double = 0.0

Task {
    let thumbnails = try await ThumbnailGenerator.generateThumbnails(
        from: videoURL,
        at: times,
        progressHandler: { progressValue in
            Task { @MainActor in
                progress = progressValue
            }
        }
    )
    // 결과 처리
}

ProgressView(value: progress)
```

---

## 캐싱 활용

### 캐시 확인 및 저장

```swift
func getThumbnailWithCache(
    from videoURL: URL,
    at time: TimeInterval
) async throws -> UIImage {
    let cacheKey = ThumbnailCacheKey(videoURL: videoURL, time: time)
    
    // 캐시 확인
    if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
        return cached
    }
    
    // 캐시에 없으면 생성
    let thumbnail = try await ThumbnailGenerator.generateThumbnail(
        from: videoURL,
        at: time
    )
    
    // 캐시에 저장
    ThumbnailCache.shared.storeThumbnail(thumbnail, for: cacheKey)
    
    return thumbnail
}
```

### SwiftUI에서 캐싱 활용

```swift
struct CachedThumbnailView: View {
    let videoURL: URL
    let time: TimeInterval
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        let cacheKey = ThumbnailCacheKey(videoURL: videoURL, time: time)
        
        // 캐시 확인
        if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
            await MainActor.run {
                thumbnail = cached
            }
            return
        }
        
        // 생성
        do {
            let image = try await ThumbnailGenerator.generateThumbnail(
                from: videoURL,
                at: time
            )
            
            ThumbnailCache.shared.storeThumbnail(image, for: cacheKey)
            
            await MainActor.run {
                thumbnail = image
            }
        } catch {
            print("에러: \(error)")
        }
    }
}
```

---

## 에러 처리

### 기본 에러 처리

```swift
do {
    let thumbnail = try await ThumbnailGenerator.generateThumbnail(
        from: videoURL,
        at: time
    )
    // 성공 처리
} catch ThumbnailError.invalidAsset {
    // 동영상 파일 문제
    showError("유효하지 않은 동영상 파일입니다.")
} catch ThumbnailError.invalidTime {
    // 시간 범위 초과
    showError("유효하지 않은 시간입니다.")
} catch ThumbnailError.imageGenerationFailed {
    // 이미지 생성 실패
    showError("이미지 생성에 실패했습니다.")
} catch {
    // 기타 에러
    showError("예상치 못한 에러: \(error.localizedDescription)")
}
```

### Result 타입 사용

```swift
func generateThumbnailSafely(
    from videoURL: URL,
    at time: TimeInterval
) async -> Result<UIImage, Error> {
    do {
        let thumbnail = try await ThumbnailGenerator.generateThumbnail(
            from: videoURL,
            at: time
        )
        return .success(thumbnail)
    } catch {
        return .failure(error)
    }
}

// 사용
let result = await generateThumbnailSafely(from: url, at: 5.0)
switch result {
case .success(let thumbnail):
    // 성공 처리
case .failure(let error):
    // 에러 처리
}
```

---

## 실전 예제

### 예제 1: 동영상 갤러리

```swift
struct VideoGalleryView: View {
    let videoURLs: [URL]
    @State private var thumbnails: [URL: UIImage] = [:]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(videoURLs, id: \.self) { url in
                    VideoThumbnailCell(
                        videoURL: url,
                        thumbnail: thumbnails[url]
                    )
                }
            }
        }
        .task {
            await loadAllThumbnails()
        }
    }
    
    private func loadAllThumbnails() async {
        for url in videoURLs {
            // 캐시 확인
            let cacheKey = ThumbnailCacheKey(videoURL: url, time: 1.0)
            if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
                await MainActor.run {
                    thumbnails[url] = cached
                }
                continue
            }
            
            // 생성
            if let thumbnail = try? await ThumbnailGenerator.generateThumbnail(
                from: url,
                at: 1.0
            ) {
                ThumbnailCache.shared.storeThumbnail(thumbnail, for: cacheKey)
                await MainActor.run {
                    thumbnails[url] = thumbnail
                }
            }
        }
    }
}
```

### 예제 2: 타임라인 썸네일

```swift
struct TimelineThumbnailView: View {
    let videoURL: URL
    let thumbnailCount: Int
    @State private var thumbnails: [UIImage?] = []
    @State private var videoDuration: TimeInterval?
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(Array(thumbnails.enumerated()), id: \.offset) { index, thumbnail in
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                    }
                }
            }
        }
        .task {
            await loadTimelineThumbnails()
        }
    }
    
    private func loadTimelineThumbnails() async {
        // 동영상 길이 가져오기
        guard let duration = try? await ThumbnailGenerator.getDuration(from: videoURL) else {
            return
        }
        
        await MainActor.run {
            videoDuration = duration
        }
        
        // 균등하게 나눠서 썸네일 생성
        let times = (0..<thumbnailCount).map { index in
            duration * Double(index) / Double(thumbnailCount - 1)
        }
        
        let results = try? await ThumbnailGenerator.generateThumbnails(
            from: videoURL,
            at: times
        )
        
        await MainActor.run {
            thumbnails = results ?? []
        }
    }
}
```

### 예제 3: 썸네일 선택기

```swift
struct ThumbnailPickerView: View {
    let videoURL: URL
    @State private var selectedTime: TimeInterval = 0
    @State private var thumbnail: UIImage?
    @State private var videoDuration: TimeInterval?
    
    var body: some View {
        VStack {
            // 썸네일 표시
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            }
            
            // 시간 슬라이더
            if let duration = videoDuration {
                Slider(
                    value: Binding(
                        get: { selectedTime },
                        set: { newValue in
                            selectedTime = newValue
                            generateThumbnail(at: newValue)
                        }
                    ),
                    in: 0...duration
                )
                
                Text("\(Int(selectedTime))초 / \(Int(duration))초")
            }
        }
        .task {
            await loadVideoInfo()
        }
    }
    
    private func loadVideoInfo() async {
        videoDuration = try? await ThumbnailGenerator.getDuration(from: videoURL)
        await generateThumbnail(at: selectedTime)
    }
    
    private func generateThumbnail(at time: TimeInterval) {
        Task {
            if let image = try? await ThumbnailGenerator.generateThumbnail(
                from: videoURL,
                at: time
            ) {
                await MainActor.run {
                    thumbnail = image
                }
            }
        }
    }
}
```

---

## 성능 최적화 팁

### 1. 크기 제한

```swift
// 항상 적절한 크기로 제한
generator.maximumSize = CGSize(width: 200, height: 200)
```

### 2. 시간 허용 오차

```swift
// 성능과 정확도의 균형
generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
```

### 3. 캐싱

```swift
// 항상 캐시 확인 후 생성
if let cached = cache.getThumbnail(for: key) {
    return cached
}
```

### 4. 병렬 처리

```swift
// 여러 썸네일은 병렬로 생성
try await withThrowingTaskGroup(of: UIImage?.self) { group in
    // ...
}
```

---

## 요약

1. **기본 생성**: AVAsset → Generator → 이미지 생성
2. **비동기 처리**: async/await와 MainActor 활용
3. **배치 처리**: TaskGroup을 사용한 병렬 처리
4. **캐싱**: 메모리와 디스크 캐시 활용
5. **에러 처리**: 적절한 에러 타입과 처리 로직

---

## 다음 단계

- [PERFORMANCE_GUIDE.md](./PERFORMANCE_GUIDE.md): 성능 최적화 상세 가이드
- [AVASSET_THEORY.md](./AVASSET_THEORY.md): 이론 설명

---

**실습**: 프로젝트의 각 View를 실행해보고 코드를 수정해보세요!

