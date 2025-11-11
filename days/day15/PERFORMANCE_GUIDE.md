# 성능 최적화 가이드

> PHPhotoLibrary 이미지 로딩 성능 최적화 전략

---

## 🚀 핵심 최적화 전략

### 1. 썸네일 우선 로딩

**문제**: 풀사이즈 이미지는 메모리를 많이 사용 (예: 12MP = ~48MB)

**해결**: 썸네일 먼저 로드, 필요시 풀사이즈 로드

```swift
// 1단계: 썸네일 즉시 표시
let thumbnailSize = CGSize(width: 200, height: 200)
imageManager.requestImage(
    for: asset,
    targetSize: thumbnailSize,
    contentMode: .aspectFill,
    options: nil
) { thumbnail, _ in
    // 썸네일 표시 (빠름, 메모리 적음)
}

// 2단계: 사용자가 탭하면 풀사이즈 로드
func didSelectPhoto(asset: PHAsset) {
    let fullSizeOptions = PHImageRequestOptions()
    fullSizeOptions.deliveryMode = .highQualityFormat
    
    imageManager.requestImage(
        for: asset,
        targetSize: PHImageManagerMaximumSize,
        contentMode: .aspectFit,
        options: fullSizeOptions
    ) { fullImage, _ in
        // 풀사이즈 표시
    }
}
```

**성능 비교**:
- 썸네일: ~1-5ms, ~150KB 메모리
- 풀사이즈: ~50-200ms, ~48MB 메모리

---

### 2. Lazy 로딩 전략

**문제**: 갤러리 그리드에서 모든 썸네일을 한번에 로드하면 느림

**해결**: 보이는 셀만 로드, 스크롤 시 추가 로드

```swift
// LazyVGrid 사용
LazyVGrid(columns: columns, spacing: 4) {
    ForEach(visibleAssets) { asset in
        ThumbnailCell(asset: asset)
            .onAppear {
                // 셀이 보일 때만 로드
                loadThumbnail(for: asset)
            }
    }
}
```

**최적화 포인트**:
- `onAppear`에서 로드 시작
- `onDisappear`에서 취소 가능
- 스크롤 중에는 저품질 먼저

---

### 3. PHImageRequestOptions 최적화

### Delivery Mode 선택

```swift
let options = PHImageRequestOptions()

// .opportunistic (기본값)
// 빠른 저품질 먼저, 고품질는 나중에
options.deliveryMode = .opportunistic

// .highQualityFormat
// 고품질만 (느리지만 품질 보장)
options.deliveryMode = .highQualityFormat

// .fastFormat
// 빠른 저품질만 (빠르지만 품질 낮음)
options.deliveryMode = .fastFormat
```

**사용 시나리오**:
- 갤러리 그리드: `.opportunistic` 또는 `.fastFormat`
- 상세보기: `.highQualityFormat`

### Resize Mode 선택

```swift
let options = PHImageRequestOptions()

// .fast: 빠른 리사이즈 (품질 낮음)
options.resizeMode = .fast

// .exact: 정확한 크기 (느리지만 정확)
options.resizeMode = .exact

// .none: 리사이즈 안 함 (원본 크기)
options.resizeMode = .none
```

**권장**:
- 썸네일: `.fast`
- 정확한 크기 필요: `.exact`

---

### 4. 메모리 효율적인 로딩

### 이미지 크기 제한

```swift
// 화면 크기에 맞는 크기만 요청
let screenSize = UIScreen.main.bounds.size
let scale = UIScreen.main.scale
let targetSize = CGSize(
    width: screenSize.width * scale,
    height: screenSize.height * scale
)

imageManager.requestImage(
    for: asset,
    targetSize: targetSize,  // 화면 크기만큼만
    contentMode: .aspectFit,
    options: nil
)
```

### 요청 취소

```swift
var requestID: PHImageRequestID?

func loadThumbnail(for asset: PHAsset) {
    // 이전 요청 취소
    if let id = requestID {
        imageManager.cancelImageRequest(id)
    }
    
    // 새 요청
    requestID = imageManager.requestImage(
        for: asset,
        targetSize: thumbnailSize,
        contentMode: .aspectFill,
        options: nil
    ) { image, info in
        // 완료
    }
}

func cancelLoading() {
    if let id = requestID {
        imageManager.cancelImageRequest(id)
    }
}
```

---

### 5. 캐싱 활용

**PHImageManager 자동 캐싱**:
- 같은 크기 요청은 캐시에서 즉시 반환
- 메모리 효율적

```swift
// 첫 요청: 실제 로드
imageManager.requestImage(for: asset, targetSize: size, ...) { image, _ in
    // 로드 완료
}

// 두 번째 요청: 캐시에서 반환 (즉시)
imageManager.requestImage(for: asset, targetSize: size, ...) { image, _ in
    // 즉시 반환됨
}
```

**캐시 무효화**:
```swift
// 필요시 캐시 클리어
PHImageManager.default().stopCachingImagesForAllAssets()
```

---

## 📊 성능 측정

### 로딩 시간 측정

```swift
let startTime = CFAbsoluteTimeGetCurrent()

imageManager.requestImage(...) { image, info in
    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("로딩 시간: \(elapsed * 1000)ms")
}
```

### 메모리 사용량 측정

```swift
func getMemoryUsage() -> Int64 {
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
        return Int64(info.resident_size)
    }
    return 0
}
```

---

## 🎯 실전 최적화 예제

### 갤러리 그리드 최적화

```swift
struct OptimizedGalleryView: View {
    @State private var assets: [PHAsset] = []
    @State private var thumbnails: [String: UIImage] = [:]
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 4)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(assets.indices, id: \.self) { index in
                    let asset = assets[index]
                    ThumbnailView(asset: asset)
                        .onAppear {
                            loadThumbnail(for: asset, at: index)
                        }
                }
            }
        }
    }
    
    func loadThumbnail(for asset: PHAsset, at index: Int) {
        let key = asset.localIdentifier
        
        // 이미 로드됨
        if thumbnails[key] != nil { return }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        
        let size = CGSize(width: 200, height: 200)
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            if let image = image {
                thumbnails[key] = image
            }
        }
    }
}
```

### 스크롤 성능 최적화

```swift
// 스크롤 중에는 저품질, 멈추면 고품질
@State private var isScrolling = false

func handleScroll() {
    isScrolling = true
    
    // 스크롤 멈춤 감지
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        isScrolling = false
        // 고품질 로드
        upgradeThumbnails()
    }
}

func loadThumbnail(for asset: PHAsset) {
    let options = PHImageRequestOptions()
    
    if isScrolling {
        // 스크롤 중: 빠른 저품질
        options.deliveryMode = .fastFormat
    } else {
        // 멈춤: 고품질
        options.deliveryMode = .highQualityFormat
    }
    
    // ...
}
```

---

## ⚠️ 주의사항

### 메모리 누수 방지

```swift
// ❌ 나쁜 예: 강한 참조 순환
class ViewController {
    func loadImage() {
        imageManager.requestImage(...) { [self] image, _ in
            self.imageView.image = image  // self 강한 참조
        }
    }
}

// ✅ 좋은 예: 약한 참조
class ViewController {
    func loadImage() {
        imageManager.requestImage(...) { [weak self] image, _ in
            self?.imageView.image = image
        }
    }
}
```

### 동시 요청 제한

```swift
// 너무 많은 동시 요청은 성능 저하
// 최대 10개 정도로 제한
let maxConcurrentRequests = 10
var activeRequests = 0

func loadThumbnail(for asset: PHAsset) {
    guard activeRequests < maxConcurrentRequests else {
        // 대기열에 추가
        return
    }
    
    activeRequests += 1
    imageManager.requestImage(...) { image, _ in
        activeRequests -= 1
        // 다음 요청 처리
    }
}
```

---

## 📈 성능 벤치마크

### 예상 성능 (iPhone 14 Pro)

| 작업 | 시간 | 메모리 |
|-----|------|--------|
| 썸네일 로드 (200x200) | 1-5ms | ~150KB |
| 풀사이즈 로드 (12MP) | 50-200ms | ~48MB |
| EXIF 읽기 | <1ms | ~10KB |
| 갤러리 그리드 (100개) | 100-500ms | ~15MB |

---

## 🔍 Instruments 프로파일링

### Time Profiler

1. ⌘I → Time Profiler 선택
2. Record 시작
3. 갤러리 스크롤
4. Stop 후 분석

**확인 포인트**:
- `requestImage` 호출 시간
- 메인 스레드 블로킹 여부

### Allocations

1. ⌘I → Allocations 선택
2. Record 시작
3. 이미지 로드
4. Stop 후 분석

**확인 포인트**:
- UIImage 메모리 사용량
- 캐시 효과

---

## 📚 참고 자료

- [Apple: PHImageManager Performance](https://developer.apple.com/documentation/photos/phimagemanager)
- [WWDC: Optimize App Performance](https://developer.apple.com/videos/play/wwdc2020/10048/)

---

**다음**: Core 모듈 구현으로 넘어가세요.

