# Core Image 이론 정리

> Day 3 학습 자료 - GPU 기반 이미지 처리의 핵심

---

## 📚 목차

1. [Core Image 기초](#1-core-image-기초)
2. [핵심 구성요소 3가지](#2-핵심-구성요소-3가지)
3. [좌표계와 Extent](#3-좌표계와-extent)
4. [성능 최적화 핵심](#4-성능-최적화-핵심)
5. [Core Graphics vs Core Image](#5-core-graphics-vs-core-image)

---

## 1. Core Image 기초

### 🎯 Core Image란?

**Core Image**는 애플의 GPU 기반 고성능 이미지 처리 프레임워크입니다.

```
┌─────────────────────────────────────┐
│  SwiftUI / UIKit                    │  ← 화면 표시
├─────────────────────────────────────┤
│  Core Image ← 우리가 배울 것!        │  ← 필터 처리 (GPU)
├─────────────────────────────────────┤
│  Core Graphics                      │  ← 픽셀 그리기 (CPU)
├─────────────────────────────────────┤
│  Metal / GPU                        │  ← 하드웨어 가속
└─────────────────────────────────────┘
```

### ✨ 핵심 특징

| 특징 | 설명 |
|------|------|
| **GPU 가속** | Metal 기반 하드웨어 가속 |
| **80+ 내장 필터** | 블러, 색상 조정, 왜곡 등 |
| **필터 체인** | 여러 필터 연결하여 복잡한 효과 |
| **비파괴적** | 원본 이미지 변경 없음 |
| **레이지 평가** | 실제 필요할 때만 처리 |
| **실시간 처리** | 60fps 영상 필터링 가능 |

### ✅ 언제 사용할까?

```swift
// ✅ Core Image 사용
// - 실시간 카메라 필터
// - 사진 편집 (Instagram 스타일)
// - 블러, 색상 보정, 이미지 합성
// - 얼굴 인식 (CIDetector)

// ❌ Core Image 사용 안함
// - 단순 UI 표시 → SwiftUI/UIKit
// - 워터마크 추가 → Core Graphics
// - 3D 렌더링 → Metal/SceneKit
// - PDF 생성 → Core Graphics
```

---

## 2. 핵심 구성요소 3가지

Core Image는 **3가지 핵심 요소**로 구성됩니다:

### 🖼️ CIImage - 이미지 "레시피"

**"실제 픽셀 데이터가 아니라, 이미지를 어떻게 만들지에 대한 설명서"**

```swift
// 생성 방법
let ciImage = CIImage(image: uiImage)          // UIImage에서
let ciImage = CIImage(contentsOf: url)         // 파일에서
let ciImage = CIImage(color: .red)             // 단색에서
let ciImage = CIImage(cgImage: cgImage)        // CGImage에서
```

#### 핵심 특징

1. **불변(Immutable)**: 한번 만들면 변경 불가
2. **레이지(Lazy)**: 실제 렌더링 전까지는 처리 안됨
3. **무제한 크기**: extent로 좌표 공간 표현

```swift
// CIImage는 "레시피"일 뿐
let image = CIImage(image: photo)!
let blurred = image.applyingFilter("CIGaussianBlur", parameters: [
    kCIInputRadiusKey: 10
])

// 여기까지는 아무것도 실행 안됨!
print("필터 적용 완료? 아니요, 레시피만 작성했습니다.")

// CIContext에서 렌더링할 때 비로소 처리됨
let cgImage = context.createCGImage(blurred, from: blurred.extent)
print("이제 진짜 처리됨!")
```

#### extent (좌표 공간)

```swift
let image = CIImage(image: uiImage)!
print(image.extent)  // (0.0, 0.0, 1000.0, 1000.0)

// 블러는 이미지를 확장시킴!
let blur = CIFilter(name: "CIGaussianBlur")!
blur.setValue(image, forKey: kCIInputImageKey)
blur.setValue(20, forKey: kCIInputRadiusKey)

let blurred = blur.outputImage!
print(blurred.extent)  // (-60.0, -60.0, 1120.0, 1120.0) ← 확장됨!

// 원본 크기로 크롭
let cropped = blurred.cropped(to: image.extent)
```

---

### 🎨 CIFilter - 필터 "명령"

**"입력 이미지를 받아서 새로운 이미지를 출력하는 함수"**

```swift
// 필터 생성
let filter = CIFilter(name: "CIGaussianBlur")!

// 입력 설정
filter.setValue(inputImage, forKey: kCIInputImageKey)
filter.setValue(10, forKey: kCIInputRadiusKey)

// 출력 얻기
let outputImage = filter.outputImage  // 새로운 CIImage 반환
```

#### 주요 필터 카테고리

| 카테고리 | 예시 필터 |
|----------|-----------|
| **블러** | CIGaussianBlur, CIMotionBlur, CIBoxBlur |
| **색상 조정** | CIColorControls, CIExposureAdjust, CIWhitePointAdjust |
| **스타일화** | CISepiaTone, CIPixellate, CIComicEffect, CICrystallize |
| **왜곡** | CIBumpDistortion, CIPinchDistortion, CITwirlDistortion |
| **합성** | CISourceOverCompositing, CIMultiplyBlend, CIScreenBlend |
| **샤픈** | CISharpenLuminance, CIUnsharpMask |
| **비네팅** | CIVignette, CIVignetteEffect |

#### 필터 파라미터 확인

```swift
// 사용 가능한 필터 목록
let filterNames = CIFilter.filterNames(inCategory: kCICategoryBuiltIn)
print("총 \(filterNames.count)개 필터")

// 특정 필터의 파라미터
let filter = CIFilter(name: "CIGaussianBlur")!
print(filter.attributes)
// {
//   "CIAttributeFilterDisplayName": "Gaussian Blur",
//   "inputRadius": {
//     "CIAttributeClass": "NSNumber",
//     "CIAttributeDefault": 10,
//     "CIAttributeType": "CIAttributeTypeDistance"
//   },
//   ...
// }
```

---

### ⚙️ CIContext - 렌더링 "공장"

**"실제로 픽셀을 계산하는 엔진"**

CIImage는 "레시피"일 뿐, CIContext가 실제로 이미지를 만듭니다.

```swift
// Metal 기반 (GPU) - 권장!
let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)

// CPU 기반 (폴백)
let context = CIContext()

// 옵션 지정
let context = CIContext(options: [
    .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    .outputColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
    .useSoftwareRenderer: false  // GPU 강제
])
```

#### 렌더링 방법

```swift
// 1️⃣ CGImage로 변환 (가장 일반적)
let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
let uiImage = UIImage(cgImage: cgImage!)

// 2️⃣ 특정 영역만 렌더링
let rect = CGRect(x: 0, y: 0, width: 500, height: 500)
let cgImage = context.createCGImage(ciImage, from: rect)

// 3️⃣ CIImage를 다른 CIImage로 변환 (체인 연결용)
let outputImage = filter.outputImage
// 아직 렌더링 안됨, 다음 필터로 전달 가능
```

#### ⚠️ Context 생성 비용

```swift
// ❌ 나쁜 예: 매번 생성 (매우 느림!)
func applyFilter(image: CIImage) -> CGImage? {
    let context = CIContext()  // 100ms 이상!
    return context.createCGImage(image, from: image.extent)
}

// ✅ 좋은 예: 한번 생성 후 재사용
class ImageProcessor {
    private let context: CIContext = {
        let device = MTLCreateSystemDefaultDevice()!
        return CIContext(mtlDevice: device)
    }()
    
    func applyFilter(image: CIImage) -> CGImage? {
        return context.createCGImage(image, from: image.extent)
    }
}
```

**Context 생성 비용 측정:**
- Metal Context 생성: **~100-200ms**
- CPU Context 생성: **~50-100ms**
- 렌더링: **~10-50ms** (이미지 크기에 따라)

→ **Context는 반드시 재사용!**

---

## 3. 좌표계와 Extent

### 📐 좌표계

Core Image는 **Core Graphics와 동일한 좌표계**를 사용합니다.

```
┌─────────────────────────────────────┐
│  📱 UIKit / SwiftUI                 │
│                                     │
│  (0,0) ┌──────────┐                │
│        │          │                │
│        │    ↓ +Y  │                │
│        │  → +X    │                │
│        └──────────┘                │
│                                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  🎨 Core Image (& Core Graphics)    │
│                                     │
│        ┌──────────┐                │
│        │  → +X    │                │
│        │    ↑ +Y  │                │
│        │          │                │
│  (0,0) └──────────┘                │
│                                     │
└─────────────────────────────────────┘
```

**하지만!** SwiftUI에서 Image로 표시할 때는 자동으로 변환되므로 신경 쓸 필요 없습니다.

### 📏 Extent (범위)

**Extent**는 CIImage가 정의되는 좌표 공간입니다.

```swift
let image = CIImage(image: uiImage)!
print(image.extent)  // CGRect(x: 0, y: 0, width: 1000, height: 1000)
```

#### 무한 Extent

```swift
// 단색 이미지는 무한 extent!
let redImage = CIImage(color: .red)
print(redImage.extent)  // (-∞, -∞, ∞, ∞)

// 특정 영역으로 제한 필요
let croppedRed = redImage.cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
```

#### Extent 변화

```swift
let original = CIImage(image: uiImage)!
print("원본:", original.extent)  // (0, 0, 1000, 1000)

// 블러는 extent를 확장
let blur = CIFilter(name: "CIGaussianBlur", parameters: [
    kCIInputImageKey: original,
    kCIInputRadiusKey: 20
])!
print("블러:", blur.outputImage!.extent)  // (-60, -60, 1120, 1120)

// 픽셀레이트는 extent 유지
let pixellate = CIFilter(name: "CIPixellate", parameters: [
    kCIInputImageKey: original,
    kCIInputScaleKey: 20
])!
print("픽셀:", pixellate.outputImage!.extent)  // (0, 0, 1000, 1000)
```

---

## 4. 성능 최적화 핵심

### ⚡ 최적화 체크리스트

#### 1️⃣ CIContext 재사용 (최우선!)

```swift
// ❌ 나쁜 예
func processImages(_ images: [UIImage]) -> [UIImage] {
    return images.map { image in
        let context = CIContext()  // 매번 생성! (매우 느림)
        // ...
    }
}

// ✅ 좋은 예
class ImageProcessor {
    private let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    
    func processImages(_ images: [UIImage]) -> [UIImage] {
        return images.compactMap { image in
            // context 재사용
        }
    }
}
```

**성능 차이: 10배 이상**

#### 2️⃣ Metal 사용 (GPU 가속)

```swift
// ✅ Metal 기반 (빠름)
let metalDevice = MTLCreateSystemDefaultDevice()!
let context = CIContext(mtlDevice: metalDevice)

// ⚠️ CPU 기반 (느림)
let context = CIContext(options: [
    .useSoftwareRenderer: true
])
```

**성능 차이: 5배 이상**

#### 3️⃣ 필터 객체 재사용

```swift
// ❌ 나쁜 예
func applyBlur(to image: CIImage, radius: Double) -> CIImage {
    let filter = CIFilter(name: "CIGaussianBlur")!  // 매번 생성
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(radius, forKey: kCIInputRadiusKey)
    return filter.outputImage!
}

// ✅ 좋은 예
class ImageProcessor {
    private let blurFilter = CIFilter(name: "CIGaussianBlur")!
    
    func applyBlur(to image: CIImage, radius: Double) -> CIImage {
        blurFilter.setValue(image, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
        return blurFilter.outputImage!
    }
}
```

#### 4️⃣ Extent 명시

```swift
// ⚠️ extent 생략 (느릴 수 있음)
let cgImage = context.createCGImage(ciImage, from: ciImage.extent)

// ✅ extent 명시 (권장)
let rect = CGRect(x: 0, y: 0, width: 1000, height: 1000)
let cgImage = context.createCGImage(ciImage, from: rect)
```

#### 5️⃣ 비동기 처리

```swift
// ❌ 메인 스레드 블로킹
func applyFilter() {
    let result = heavyFilterOperation()  // UI 멈춤!
    imageView.image = result
}

// ✅ 백그라운드 처리
func applyFilter() {
    Task.detached {
        let result = heavyFilterOperation()
        await MainActor.run {
            imageView.image = result
        }
    }
}
```

#### 6️⃣ 필터 체인 사용 (핵심!)

```swift
// ❌ 매번 렌더링 (느림)
let blurred = renderFilter(blurFilter, on: image)      // 렌더링 1
let brightened = renderFilter(brightnessFilter, on: blurred)  // 렌더링 2
let result = renderFilter(saturationFilter, on: brightened)   // 렌더링 3

// ✅ 필터 체인 (빠름)
blurFilter.setValue(image, forKey: kCIInputImageKey)
brightnessFilter.setValue(blurFilter.outputImage, forKey: kCIInputImageKey)
saturationFilter.setValue(brightnessFilter.outputImage, forKey: kCIInputImageKey)
let result = render(saturationFilter.outputImage)  // 렌더링 1번만!
```

**성능 차이: 10배 이상** 

→ 자세한 내용은 [FILTER_CHAIN_GUIDE.md](./FILTER_CHAIN_GUIDE.md) 참고

---

## 5. Core Graphics vs Core Image

### 📊 비교표

| 특징 | Core Graphics | Core Image |
|------|---------------|------------|
| **목적** | 그리기 (Drawing) | 필터링 (Filtering) |
| **처리 방식** | CPU | GPU (Metal) |
| **속도** | 느림 | 빠름 (실시간 가능) |
| **API 스타일** | C 기반 (복잡) | Objective-C/Swift (현대적) |
| **필터 체인** | 불가능 | 핵심 기능 ✅ |
| **사용 사례** | 워터마크, 도형 그리기 | 블러, 색상 보정 |
| **이미지 저장** | 쉬움 | 쉬움 |
| **학습 곡선** | 높음 | 중간 |

### 🎯 선택 기준

```swift
// ✅ Core Image 사용
// - 기존 이미지에 필터 적용
// - 블러, 색상 조정, 왜곡
// - 실시간 카메라 필터
// - 여러 효과 조합 (필터 체인)
let filtered = applyFilters(image)

// ✅ Core Graphics 사용
// - 처음부터 그리기 (도형, 텍스트)
// - 워터마크, 스탬프 추가
// - PDF 생성
// - 정밀한 픽셀 제어
let drawn = drawCustomGraphics()

// ✅ 둘 다 사용
// 1. Core Image로 필터
// 2. Core Graphics로 워터마크
let filtered = applyFilters(image)
let final = addWatermark(filtered)
```

### 💡 실전 예제

```swift
// Core Image: 사진 편집
func editPhoto(_ image: UIImage) -> UIImage {
    let context = CIContext()
    guard let ciImage = CIImage(image: image) else { return image }
    
    // 필터 체인
    let sepia = CIFilter(name: "CISepiaTone")!
    sepia.setValue(ciImage, forKey: kCIInputImageKey)
    sepia.setValue(0.8, forKey: kCIInputIntensityKey)
    
    let vignette = CIFilter(name: "CIVignette")!
    vignette.setValue(sepia.outputImage, forKey: kCIInputImageKey)
    vignette.setValue(1.5, forKey: kCIInputIntensityKey)
    
    guard let output = vignette.outputImage,
          let cgImage = context.createCGImage(output, from: output.extent) else {
        return image
    }
    
    return UIImage(cgImage: cgImage)
}

// Core Graphics: 워터마크
func addWatermark(_ image: UIImage, text: String) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { context in
        image.draw(at: .zero)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 40),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        
        (text as NSString).draw(at: CGPoint(x: 20, y: 20), withAttributes: attributes)
    }
}

// 조합: 필터 + 워터마크
func processPhoto(_ image: UIImage) -> UIImage {
    let filtered = editPhoto(image)       // Core Image
    let final = addWatermark(filtered, text: "© 2025")  // Core Graphics
    return final
}
```

---

## 📚 참고 자료

### Apple 공식 문서

- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/)
- [CIFilter](https://developer.apple.com/documentation/coreimage/cifilter)
- [CIContext](https://developer.apple.com/documentation/coreimage/cicontext)
- [CIImage](https://developer.apple.com/documentation/coreimage/ciimage)

### WWDC 세션

- [Advances in Core Image (WWDC 2017)](https://developer.apple.com/videos/play/wwdc2017/510/)
- [Image and Graphics Best Practices (WWDC 2018)](https://developer.apple.com/videos/play/wwdc2018/219/)

### 프로젝트 문서

- [FILTER_CHAIN_GUIDE.md](./FILTER_CHAIN_GUIDE.md) - 필터 체인 완벽 가이드 ⭐
- [PERFORMANCE_GUIDE.md](./PERFORMANCE_GUIDE.md) - 성능 측정 가이드
- [README.md](./README.md) - 프로젝트 개요

---

**다음 단계**: [필터 체인 가이드](./FILTER_CHAIN_GUIDE.md)를 읽고 Core Image의 가장 강력한 기능을 마스터하세요! 🚀

