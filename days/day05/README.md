# Day 5: 이미지 리사이즈 & 포맷 변환

> iOS에서 이미지를 효율적으로 리사이즈하고 포맷 변환하는 방법을 학습합니다

---

## 📚 학습 목표

### 핵심 목표
- **4가지 리사이즈 방법**을 이해하고 상황에 맞게 선택한다
- **JPEG/PNG/HEIC 포맷**의 특징과 차이를 파악한다
- **성능과 품질의 균형**을 체험적으로 학습한다

### 학습 포인트

#### 리사이즈 방법
- **UIGraphicsImageRenderer**: 간편하지만 느림
- **Core Graphics**: 세밀한 제어 가능
- **vImage**: 초고속 (SIMD 최적화)
- **Image I/O**: 메모리 효율 (다운샘플링)

#### 포맷 특징
- **JPEG**: 손실 압축, 사진에 최적
- **PNG**: 무손실, 투명도 지원
- **HEIC**: 고효율 (JPEG 대비 40~50% 작음)

---

## 🗂️ 파일 구조

```
day05/
├── IMAGE_RESIZE_THEORY.md          # 리사이즈 이론
├── FORMAT_CONVERSION_GUIDE.md      # 포맷 변환 가이드
├── PERFORMANCE_GUIDE.md            # 성능 최적화
├── README.md                       # 이 파일
├── 시작하기.md                     # 빠른 시작 가이드
│
└── day05/
    ├── ContentView.swift           # 메인 네비게이션
    │
    ├── Core/                       # 핵심 로직
    │   ├── ImageResizer.swift          # 4가지 리사이즈 방법
    │   ├── FormatConverter.swift       # 포맷 변환 (JPEG/PNG/HEIC)
    │   └── CompressionManager.swift    # 압축 옵션 관리
    │
    ├── Views/                      # 학습 뷰
    │   ├── ResizeMethodsView.swift        # 리사이즈 방법 비교
    │   ├── FormatComparisonView.swift     # 포맷 비교
    │   ├── QualityBenchmarkView.swift     # 품질 vs 크기
    │   └── BatchProcessingView.swift      # 배치 처리
    │
    ├── tool/                       # 성능 측정 도구
    │   ├── MemorySampler.swift
    │   └── PerformanceLogger.swift
    │
    └── Assets.xcassets/
        └── sample.imageset/        # 고해상도 샘플 이미지
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day05
open day05.xcodeproj
```

### 2. 샘플 이미지 준비
⚠️ **중요**: 고해상도 이미지 (4000 × 3000 이상) 필요

#### 방법 1: iPhone으로 촬영
1. iPhone 카메라로 사진 촬영
2. Mac으로 AirDrop 전송
3. Xcode에서 `Assets.xcassets/sample.imageset`에 추가

#### 방법 2: 웹에서 다운로드
```bash
# Unsplash에서 고해상도 이미지 다운로드
# https://unsplash.com
# 검색: "landscape" 또는 "nature"
# "Download free" 클릭 (Large 또는 Original)
```

### 3. 앱 실행
```
⌘R (Run)
```

---

## 📖 학습 순서

### 📚 1단계: 이론 학습 (약 30분)

먼저 이론 문서를 읽어보세요:

#### IMAGE_RESIZE_THEORY.md 읽기
- 4가지 리사이즈 방법 비교
- Aspect Ratio 유지 방법
- 다운샘플링 개념
- 성능 비교표

#### FORMAT_CONVERSION_GUIDE.md 읽기
- JPEG vs PNG vs HEIC 특징
- 압축 원리
- 포맷 선택 가이드
- 변환 방법

**핵심 개념**:
```
다운샘플링이란?
→ 큰 이미지를 메모리에 모두 로드하지 않고 축소

일반 리사이즈:  48MB (원본) + 4MB (결과) = 52MB
다운샘플링:     5MB (필요한 만큼만) = 5MB
→ 10배 메모리 절약!
```

### 👨‍💻 2단계: 리사이즈 실습 (약 30분)

#### ResizeMethodsView
4가지 방법으로 동일 이미지 리사이즈 후 비교:

```swift
// 핵심 코드
let methods: [ResizeMethod] = [.uiGraphics, .coreGraphics, .vImage, .imageIO]

for method in methods {
    let (image, time, memory) = benchmark {
        return ImageResizer.resize(originalImage, to: targetSize, method: method)
    }
    
    print("\(method): \(time)ms, \(memory)MB")
}
```

**측정 항목**:
- ⏱️ 처리 시간
- 📊 메모리 사용량
- 🎨 결과 이미지

**예상 결과**:
| 방법 | 시간 | 메모리 | 용도 |
|------|------|--------|------|
| UIGraphics | 120ms | 52MB | 간단한 작업 |
| Core Graphics | 95ms | 52MB | 세밀한 제어 |
| **vImage** | **35ms** | 52MB | **최고 속도** 🏆 |
| **Image I/O** | 45ms | **10MB** | **메모리 효율** 🏆 |

### 🎨 3단계: 포맷 변환 실습 (약 30분)

#### FormatComparisonView
JPEG, PNG, HEIC 포맷 비교:

```swift
// 동일 이미지를 여러 포맷으로 저장
let formats: [ImageFormat] = [
    .jpeg(quality: 0.9),
    .jpeg(quality: 0.7),
    .png,
    .heic(quality: 0.9),
    .heic(quality: 0.7)
]

for format in formats {
    let data = FormatConverter.convert(image, to: format)
    print("\(format): \(data.count / 1024)KB")
}
```

**비교 항목**:
- 파일 크기
- 화질 (시각적 비교)
- 인코딩 시간

**예상 결과**:
```
JPEG 0.9: 1.8MB   (기준)
JPEG 0.7: 620KB   (1/3 크기)
PNG:      5.2MB   (3배 크김)
HEIC 0.9: 950KB   (53% 절감!) 🏆
HEIC 0.7: 350KB   (43% 절감!)
```

#### QualityBenchmarkView
JPEG quality 10%~100% 단계별 측정:

```swift
for quality in stride(from: 0.1, through: 1.0, by: 0.1) {
    let jpeg = image.jpegData(compressionQuality: quality)
    let size = jpeg?.count ?? 0
    
    print("Quality \(Int(quality * 100))%: \(size / 1024)KB")
}
```

**그래프로 시각화**:
- X축: Quality (0.1 ~ 1.0)
- Y축: 파일 크기 (KB)
- 최적 포인트 찾기 (예: 0.8 = 크기/품질 균형)

### ⚡ 4단계: 배치 처리 실습 (약 30분)

#### BatchProcessingView
여러 이미지 일괄 변환:

```swift
// 100개 이미지를 썸네일로 변환
let processor = BatchImageProcessor()

processor.processBatch(
    imageURLs: imageURLs,
    targetSize: CGSize(width: 300, height: 300),
    progress: { current, total in
        print("진행률: \(current)/\(total)")
    },
    completion: { thumbnails in
        print("완료: \(thumbnails.count)개")
    }
)
```

**최적화 비교**:
| 방법 | 시간 | 메모리 | 순위 |
|------|------|--------|------|
| 순차 + 일반 로드 | 12초 | 4.8GB 💥 | ⭐ |
| 순차 + 다운샘플 | 5초 | 52MB | ⭐⭐ |
| **병렬 + 다운샘플** | **0.7초** | **80MB** | **⭐⭐⭐** |

### 📘 5단계: 성능 가이드 읽기 (약 20분)

#### PERFORMANCE_GUIDE.md 읽기
- 메모리 최적화 전략
- 속도 최적화 기법
- 배치 처리 패턴
- 실전 활용 예제

**핵심 패턴**:
```swift
// ✅ 메모리 최적화
for url in imageURLs {
    autoreleasepool {
        let thumbnail = downsampleImage(from: url, to: size)
        saveThumbnail(thumbnail)
    }  // 여기서 메모리 즉시 해제
}

// ✅ 속도 최적화
DispatchQueue.global().async {
    let resized = fastResize(image, using: .vImage)
    DispatchQueue.main.async {
        imageView.image = resized
    }
}
```

---

## 🔑 핵심 개념

### 1. 다운샘플링

큰 이미지를 메모리에 모두 로드하지 않고 축소:

```swift
func downsampleImage(from url: URL, to targetSize: CGSize) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height),
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true
    ]
    
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        return nil
    }
    
    return UIImage(cgImage: image)
}
```

**장점**:
- 원본을 메모리에 로드하지 않음
- 메모리 사용량 **10배 절감**
- 대용량 이미지 처리에 필수

### 2. vImage (Accelerate)

SIMD 명령어로 초고속 처리:

```swift
import Accelerate

// vImageScale_ARGB8888으로 3~5배 빠른 리사이즈
vImageScale_ARGB8888(
    &sourceBuffer,
    &destinationBuffer,
    nil,
    vImage_Flags(kvImageHighQualityResampling)
)
```

**장점**:
- 가장 빠른 속도 (SIMD 최적화)
- 멀티코어 자동 활용
- 실시간 처리 가능

### 3. HEIC 포맷

HEVC 비디오 코덱 기반의 고효율 압축:

```swift
func convertToHEIC(image: UIImage, quality: CGFloat) -> Data? {
    guard let cgImage = image.cgImage,
          let destination = CGImageDestinationCreateWithData(
              NSMutableData(),
              AVFileType.heic as CFString,
              1,
              nil
          ) else { return nil }
    
    let options: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: quality
    ]
    
    CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
    CGImageDestinationFinalize(destination)
    
    // ...
}
```

**장점**:
- JPEG 대비 **40~50% 작음**
- 더 높은 화질
- iOS 11+ 기본 포맷

### 4. Autoreleasepool

배치 처리 시 메모리 즉시 해제:

```swift
for url in imageURLs {
    autoreleasepool {
        let image = processImage(url)
        saveImage(image)
    }  // 여기서 임시 객체 해제
}
```

---

## 💡 실무 활용

### 갤러리 앱
- 썸네일 그리드: 다운샘플링
- 이미지 뷰어: Progressive 로딩
- 편집: vImage로 실시간 처리

### 카메라 앱
- 촬영 저장: HEIC (공간 절약)
- 공유: JPEG (호환성)
- 썸네일: 다운샘플링

### SNS 앱
- 업로드: 리사이즈 + JPEG 0.85
- 프로필 사진: 512px + JPEG 0.9
- 피드: 다양한 크기 캐싱

### 이커머스 앱
- 상품 썸네일: 200px + JPEG 0.7
- 상품 상세: 1000px + JPEG 0.85
- 배치 업로드: 병렬 처리 + 진행률

---

## 📊 성능 비교

### 단일 이미지 (4032 × 3024 → 1000 × 750)

| 작업 | 방법 | 시간 | 메모리 | 추천 |
|------|------|------|--------|------|
| 리사이즈 | UIGraphics | 120ms | 52MB | 작은 이미지 |
| 리사이즈 | Core Graphics | 95ms | 52MB | 세밀한 제어 |
| 리사이즈 | **vImage** | **35ms** | 52MB | **실시간** 🏆 |
| 리사이즈 | **Image I/O** | 45ms | **10MB** | **대용량** 🏆 |
| JPEG 인코딩 | quality 0.8 | 85ms | 4MB | 표준 |
| HEIC 인코딩 | quality 0.8 | 250ms | 4MB | 공간 절약 |

### 배치 처리 (100개 이미지)

| 최적화 | 총 시간 | 피크 메모리 | 비고 |
|--------|---------|-------------|------|
| 기본 | 12초 | 4.8GB | 💥 크래시 위험 |
| + autoreleasepool | 12초 | 52MB | ✅ 안정 |
| + 다운샘플링 | 5초 | 52MB | ✅✅ 빠름 |
| + 병렬 처리 | **0.7초** | 80MB | ✅✅✅ **최적** 🏆 |

---

## 🔍 디버깅 팁

### 메모리 부족 크래시

**증상**:
```
EXC_RESOURCE RESOURCE_TYPE_MEMORY
```

**원인**:
- 큰 이미지를 메모리에 모두 로드

**해결**:
```swift
// ❌ 나쁜 예
let image = UIImage(contentsOfFile: path)  // 48MB

// ✅ 좋은 예
let image = downsampleImage(from: url, to: targetSize)  // 5MB
```

### 느린 UI

**증상**:
- 스크롤 끊김
- 이미지 로딩 느림

**원인**:
- 메인 스레드에서 이미지 처리

**해결**:
```swift
// ❌ 나쁜 예
imageView.image = resize(largeImage, to: size)  // UI 멈춤

// ✅ 좋은 예
DispatchQueue.global().async {
    let resized = resize(largeImage, to: size)
    DispatchQueue.main.async {
        imageView.image = resized
    }
}
```

### Instruments 프로파일링

```bash
1. Xcode → Product → Profile (⌘I)
2. Allocations 선택
3. 앱 실행 및 이미지 처리
4. Memory 그래프 확인
   - 급격한 상승: 메모리 누수
   - 해제 안됨: autoreleasepool 필요
```

---

## 🎯 학습 체크리스트

### 기본
- [ ] 4가지 리사이즈 방법을 설명할 수 있다
- [ ] 다운샘플링이 무엇인지 안다
- [ ] JPEG/PNG/HEIC 차이를 안다
- [ ] Aspect ratio를 유지하는 방법을 안다

### 응용
- [ ] vImage를 사용할 수 있다
- [ ] HEIC로 변환할 수 있다
- [ ] 배치 처리를 최적화할 수 있다
- [ ] autoreleasepool을 적절히 사용한다

### 심화
- [ ] 성능을 측정하고 비교할 수 있다
- [ ] 메모리 압박 상황에 대응할 수 있다
- [ ] 상황에 맞는 최적의 방법을 선택한다
- [ ] 실무 앱에 적용할 수 있다

---

## 📚 참고 자료

### Apple 공식 문서
- [Image I/O Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/)
- [vImage Programming Guide](https://developer.apple.com/documentation/accelerate/vimage)
- [UIGraphicsImageRenderer](https://developer.apple.com/documentation/uikit/uigraphicsimagerenderer)

### WWDC 세션
- [Image and Graphics Best Practices (WWDC 2018)](https://developer.apple.com/videos/play/wwdc2018/219/)
- [iOS Memory Deep Dive (WWDC 2018)](https://developer.apple.com/videos/play/wwdc2018/416/)

### 튜토리얼
- `IMAGE_RESIZE_THEORY.md` - 리사이즈 이론
- `FORMAT_CONVERSION_GUIDE.md` - 포맷 변환
- `PERFORMANCE_GUIDE.md` - 성능 최적화

---

## 🐛 알려진 이슈

### iOS 시뮬레이터
- vImage가 Mac CPU 사용 (실기기와 성능 다름)
- 실제 기기 테스트 권장

### HEIC 지원
- iOS 11+ 필요
- 일부 웹 브라우저 미지원
- 호환성 고려 필요

### 메모리 압력
- 시뮬레이터는 메모리 제약 느슨
- 실기기에서 테스트 필수

---

## 🎓 다음 단계

Day 5를 마스터했다면:

1. **Day 6**: Metal로 GPU 가속 이미지 처리
2. **Day 7**: Vision으로 이미지 분석
3. **Day 8**: Core ML로 이미지 분류

---

## 💬 질문 & 피드백

학습 중 궁금한 점이 있다면:
- 각 View의 코드 주석 확인
- 가이드 문서 참고
- Apple 공식 문서 읽기

---

**Happy Learning! 🖼️**

*효율적인 이미지 처리로 성능을 최적화하세요!*

