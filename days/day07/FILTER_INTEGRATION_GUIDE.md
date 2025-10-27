# Core Image 필터 통합 가이드

> 실시간 필터 적용 및 필터 체인 구축 완벽 가이드

---

## 📚 목차

1. [필터 엔진 아키텍처](#1-필터-엔진-아키텍처)
2. [필터 체인 구축](#2-필터-체인-구축)
3. [실시간 프리뷰 최적화](#3-실시간-프리뷰-최적화)
4. [GPU 가속 활용](#4-gpu-가속-활용)
5. [메모리 관리](#5-메모리-관리)

---

## 1. 필터 엔진 아키텍처

### 기본 구조

```swift
class FilterEngine {
    static let shared = FilterEngine()
    
    // CIContext 재사용 (중요!)
    private let context: CIContext
    
    private init() {
        self.context = CIContext(options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .cacheIntermediates: true,      // 중간 결과 캐싱
            .useSoftwareRenderer: false     // GPU 사용
        ])
    }
}
```

**핵심 원칙**:

1. **싱글톤 패턴**: `CIContext` 재사용
2. **GPU 가속**: `.useSoftwareRenderer: false`
3. **중간 캐싱**: `.cacheIntermediates: true`
4. **색공간 설정**: RGB 색공간 명시

### CIContext 재사용의 중요성

```swift
// ❌ 나쁜 예: 매번 생성
func applyFilter(_ image: CIImage) -> UIImage? {
    let context = CIContext()  // 비용 큼!
    let cgImage = context.createCGImage(image, from: image.extent)
    return UIImage(cgImage: cgImage!)
}

// ✅ 좋은 예: 재사용
class FilterEngine {
    private let context: CIContext  // 한 번만 생성
    
    func applyFilter(_ image: CIImage) -> UIImage? {
        let cgImage = context.createCGImage(image, from: image.extent)
        return UIImage(cgImage: cgImage!)
    }
}
```

**성능 차이**:
- CIContext 생성: ~100ms
- CIContext 재사용: ~0ms
- **100배 이상 빠름!**

---

## 2. 필터 체인 구축

### 기본 필터 적용

```swift
// 블러 필터
func applyBlur(to ciImage: CIImage, radius: Double = 10.0) -> CIImage? {
    let filter = CIFilter(name: "CIGaussianBlur")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    filter?.setValue(radius, forKey: kCIInputRadiusKey)
    return filter?.outputImage
}

// 세피아 필터
func applySepia(to ciImage: CIImage, intensity: Double = 0.8) -> CIImage? {
    let filter = CIFilter(name: "CISepiaTone")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    filter?.setValue(intensity, forKey: kCIInputIntensityKey)
    return filter?.outputImage
}

// 비네팅 필터
func applyVignette(to ciImage: CIImage, intensity: Double = 1.0) -> CIImage? {
    let filter = CIFilter(name: "CIVignette")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    filter?.setValue(intensity, forKey: kCIInputIntensityKey)
    return filter?.outputImage
}
```

### 필터 체인 구성

```swift
func applyFilterChain(_ filters: [FilterType], to ciImage: CIImage) -> CIImage? {
    var result = ciImage
    
    for filter in filters {
        guard let filtered = applyFilter(filter, to: result) else {
            continue
        }
        result = filtered
    }
    
    return result
}

// 사용 예
let filtered = FilterEngine.shared.applyFilterChain(
    [.sepia, .vignette, .sharpen],
    to: originalImage
)
```

**작동 원리**:

```
원본 CIImage
    ↓
세피아 필터 적용
    ↓
비네팅 필터 적용
    ↓
선명하게 필터 적용
    ↓
최종 CIImage
```

### 필터 타입 정의

```swift
enum FilterType: String, CaseIterable {
    case none = "원본"
    case blur = "블러"
    case sepia = "세피아"
    case vignette = "비네팅"
    case colorControls = "색상 조정"
    case sharpen = "선명하게"
    
    var filterName: String? {
        switch self {
        case .none: return nil
        case .blur: return "CIGaussianBlur"
        case .sepia: return "CISepiaTone"
        case .vignette: return "CIVignette"
        case .colorControls: return "CIColorControls"
        case .sharpen: return "CISharpenLuminance"
        }
    }
}
```

### 프리셋 구성

```swift
struct FilterPreset {
    let name: String
    let filters: [FilterType]
    
    static let presets: [FilterPreset] = [
        FilterPreset(name: "빈티지", filters: [.sepia, .vignette]),
        FilterPreset(name: "드라마틱", filters: [.colorControls, .sharpen]),
        FilterPreset(name: "소프트", filters: [.blur, .colorControls]),
        FilterPreset(name: "강렬", filters: [.sharpen, .colorControls, .vignette])
    ]
}

// 사용
let preset = FilterPreset.presets[0]  // 빈티지
let filtered = FilterEngine.shared.applyPreset(preset, to: image)
```

---

## 3. 실시간 프리뷰 최적화

### 지연 실행 (Debouncing)

```swift
class FilterTestView: View {
    @State private var selectedFilters: [FilterType] = []
    @State private var debounceWorkItem: DispatchWorkItem?
    
    private func applyFiltersWithDebounce() {
        // 이전 작업 취소
        debounceWorkItem?.cancel()
        
        // 새 작업 예약
        let workItem = DispatchWorkItem { [weak self] in
            self?.applyFilters()
        }
        
        debounceWorkItem = workItem
        
        // 0.3초 후 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
}
```

**효과**:
- 연속 입력 시 마지막만 처리
- 불필요한 계산 방지
- 응답성 향상

### 저해상도 프리뷰

```swift
func generatePreviewImage(_ original: UIImage, maxSize: CGFloat = 512) -> UIImage? {
    let scale = min(maxSize / original.size.width, maxSize / original.size.height)
    
    if scale >= 1.0 {
        return original
    }
    
    let newSize = CGSize(
        width: original.size.width * scale,
        height: original.size.height * scale
    )
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    original.draw(in: CGRect(origin: .zero, size: newSize))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resized
}

// 사용
let preview = generatePreviewImage(originalImage)  // 512px로 축소
let filtered = FilterEngine.shared.applyFilterChain(filters, to: CIImage(image: preview)!)
```

**성능 개선**:
- 2000x1500 → 512x384: **~15배 빠름**
- 메모리 사용: **~95% 감소**

### 비동기 처리

```swift
private func applyFilters() {
    guard !selectedFilters.isEmpty, let original = originalImage else { return }
    
    isProcessing = true
    
    DispatchQueue.global(qos: .userInitiated).async {
        let start = CFAbsoluteTimeGetCurrent()
        
        // 필터 적용
        let filtered = FilterEngine.shared.applyFilterChain(
            self.selectedFilters,
            to: original
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        DispatchQueue.main.async {
            self.filteredImage = filtered
            self.processingTime = duration
            self.isProcessing = false
        }
    }
}
```

**핵심**:
- 백그라운드 스레드에서 처리
- 메인 스레드 블로킹 방지
- UI 응답성 유지

---

## 4. GPU 가속 활용

### Metal 기반 렌더링

```swift
// CIContext 생성 시 Metal 활용
import Metal

let context: CIContext = {
    if let device = MTLCreateSystemDefaultDevice() {
        return CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .cacheIntermediates: true
        ])
    } else {
        // Metal 미지원 시 CPU 렌더러
        return CIContext(options: [
            .useSoftwareRenderer: true
        ])
    }
}()
```

**Metal 장점**:
- GPU 병렬 처리
- CPU 대비 10~100배 빠름
- 배터리 효율 좋음

### 필터 병합 최적화

```swift
// ❌ 비효율적: 각 필터마다 렌더링
let blurred = applyBlur(to: image)!
let uiImage1 = convertToUIImage(blurred)!  // 렌더링 1
let sepia = applySepia(to: CIImage(image: uiImage1)!)!
let uiImage2 = convertToUIImage(sepia)!  // 렌더링 2

// ✅ 효율적: 한 번에 렌더링
let blurred = applyBlur(to: image)!
let sepia = applySepia(to: blurred)!  // CIImage 체인
let uiImage = convertToUIImage(sepia)!  // 렌더링 1회만
```

**성능 차이**:
- 비효율적: 각 필터마다 GPU ↔ CPU 전송
- 효율적: 최종 결과만 전송
- **3~5배 빠름**

### Extent 최적화

```swift
func applyBlur(to ciImage: CIImage, radius: Double) -> CIImage? {
    let filter = CIFilter(name: "CIGaussianBlur")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(radius, forKey: kCIInputRadiusKey)
    
    guard let output = filter.outputImage else { return nil }
    
    // ⚠️ 블러는 extent가 확장됨
    // 원본 크기로 잘라내기
    return output.cropped(to: ciImage.extent)
}
```

**Extent란?**:
- 이미지가 정의된 좌표 공간
- 일부 필터는 extent 확장 (블러, 그림자 등)
- 원본 extent로 crop 필요

---

## 5. 메모리 관리

### CIImage는 레이지

```swift
// CIImage는 "레시피"일 뿐
let image = CIImage(image: uiImage)!
let blurred = applyBlur(to: image)!
// 여기까지는 메모리 거의 안씀

// 렌더링할 때 실제 메모리 사용
let cgImage = context.createCGImage(blurred, from: blurred.extent)
// 이제 메모리 사용
```

**레이지 평가**:
- `CIImage`: 계산 그래프만 저장
- `createCGImage`: 실제 픽셀 생성
- 불필요한 계산 스킵 가능

### 메모리 워닝 처리

```swift
class FilterEngine {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // CIContext 캐시 정리
        // 새 CIContext 생성은 비용 크므로 주의
        PerformanceLogger.log("메모리 워닝 - 캐시 정리", category: "memory")
    }
}
```

### 대용량 이미지 처리

```swift
func processLargeImage(_ image: UIImage) -> UIImage? {
    // 1. 적절한 크기로 리사이징
    let maxDimension: CGFloat = 2048
    let resized = resizeImage(image, maxDimension: maxDimension)
    
    // 2. 필터 적용
    guard let ciImage = CIImage(image: resized) else { return nil }
    let filtered = applyFilterChain(filters, to: ciImage)
    
    // 3. UIImage 변환
    return convertToUIImage(filtered)
}

private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
    let size = image.size
    let scale = min(maxDimension / size.width, maxDimension / size.height)
    
    if scale >= 1.0 {
        return image
    }
    
    let newSize = CGSize(
        width: size.width * scale,
        height: size.height * scale
    )
    
    // ImageIO 활용 (메모리 효율적)
    // ... (구현 생략)
    
    return image
}
```

**전략**:
1. 큰 이미지는 리사이징
2. 2048px 이하로 제한
3. ImageIO로 효율적 리사이징

### 필터 결과 캐싱

```swift
class FilterCache {
    private var cache: [CacheKey: UIImage] = [:]
    
    struct CacheKey: Hashable {
        let imageName: String
        let filters: [FilterType]
    }
    
    func getCachedResult(imageName: String, filters: [FilterType]) -> UIImage? {
        let key = CacheKey(imageName: imageName, filters: filters)
        return cache[key]
    }
    
    func cacheResult(_ image: UIImage, imageName: String, filters: [FilterType]) {
        let key = CacheKey(imageName: imageName, filters: filters)
        cache[key] = image
        
        // 캐시 크기 제한
        if cache.count > 10 {
            cache.removeAll()
        }
    }
}
```

---

## 📊 성능 측정

### 필터별 처리 시간

```swift
func measureFilterPerformance() {
    let image = CIImage(image: sampleImage)!
    
    let filters: [FilterType] = [.blur, .sepia, .vignette, .colorControls, .sharpen]
    
    for filter in filters {
        let start = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<10 {
            _ = FilterEngine.shared.applyFilter(filter, to: image)
        }
        
        let duration = (CFAbsoluteTimeGetCurrent() - start) / 10
        print("\(filter.rawValue): \(duration * 1000)ms")
    }
}
```

**예상 결과** (2000x1500 이미지):

```
블러: ~20ms
세피아: ~5ms
비네팅: ~8ms
색상 조정: ~6ms
선명하게: ~15ms
```

### 필터 체인 성능

```swift
// 단일 필터
블러: 20ms

// 필터 체인
블러 → 세피아: 25ms (20 + 5 = 25ms)
블러 → 세피아 → 비네팅: 33ms (20 + 5 + 8 = 33ms)
```

**핵심**: 필터는 거의 선형으로 증가

---

## 🎯 실전 팁

### 1. 필터 순서 최적화

```swift
// ✅ 빠른 필터를 먼저
[.sepia, .vignette, .blur]  // 빠름

// ❌ 느린 필터를 먼저
[.blur, .sepia, .vignette]  // 느림 (블러가 무거움)
```

### 2. 파라미터 조정

```swift
// 블러 반경
radius: 5.0   // 빠름, 약한 효과
radius: 10.0  // 보통, 적당한 효과
radius: 20.0  // 느림, 강한 효과
```

### 3. 조건부 적용

```swift
// 이미지 크기에 따라 조정
let effectiveRadius = image.extent.width < 1000 ? 5.0 : 10.0
```

### 4. 프로그레스 표시

```swift
private func applyFiltersWithProgress() {
    let total = selectedFilters.count
    
    for (index, filter) in selectedFilters.enumerated() {
        // 필터 적용
        result = applyFilter(filter, to: result)
        
        // 프로그레스 업데이트
        let progress = Double(index + 1) / Double(total)
        DispatchQueue.main.async {
            self.progress = progress
        }
    }
}
```

---

## 📚 참고 자료

- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/)
- [Core Image Filter Reference](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/)
- [Metal Performance Shaders](https://developer.apple.com/documentation/metalperformanceshaders)

---

**Core Image 필터 통합을 마스터하셨습니다! ✨**

