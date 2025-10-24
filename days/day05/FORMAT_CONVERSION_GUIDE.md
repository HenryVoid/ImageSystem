# 이미지 포맷 변환 가이드

> JPEG, PNG, HEIC 포맷의 특징과 변환 방법을 학습합니다

---

## 📚 목차

1. [이미지 포맷 기초](#이미지-포맷-기초)
2. [JPEG](#jpeg)
3. [PNG](#png)
4. [HEIC](#heic)
5. [포맷 변환](#포맷-변환)
6. [실전 활용](#실전-활용)

---

## 이미지 포맷 기초

### 포맷이란?

이미지 데이터를 파일로 저장하는 방식입니다.

```
픽셀 데이터 (메모리)
    ↓ 인코딩
파일 (디스크)
    ↓ 디코딩
픽셀 데이터 (메모리)
```

### 주요 특성

| 특성 | 설명 |
|------|------|
| **압축 방식** | 손실 vs 무손실 |
| **파일 크기** | 작을수록 좋음 (네트워크/저장) |
| **화질** | 높을수록 좋음 |
| **투명도** | 알파 채널 지원 여부 |
| **호환성** | 브라우저/플랫폼 지원 |

### iOS에서 지원하는 포맷

| 포맷 | 압축 | 투명도 | iOS 버전 | 용도 |
|------|------|--------|----------|------|
| **JPEG** | 손실 | ❌ | 모든 버전 | 사진 |
| **PNG** | 무손실 | ✅ | 모든 버전 | 아이콘, UI |
| **HEIC** | 손실 | ✅ | iOS 11+ | 사진 (기본) |
| **WebP** | 손실/무손실 | ✅ | iOS 14+ (제한적) | 웹 |
| **GIF** | 무손실 | ✅ | 모든 버전 | 애니메이션 |
| **TIFF** | 무손실 | ✅ | 모든 버전 | 전문가 |

**이 가이드에서는 가장 많이 사용하는 JPEG, PNG, HEIC를 다룹니다.**

---

## JPEG

> Joint Photographic Experts Group

### 특징

**장점**:
- ✅ 작은 파일 크기
- ✅ 모든 플랫폼 지원
- ✅ 사진에 최적화
- ✅ 압축률 조절 가능

**단점**:
- ❌ 손실 압축 (반복 저장 시 화질 저하)
- ❌ 투명도 미지원
- ❌ 텍스트/선명한 경계에 부적합

### 압축 원리

JPEG는 **DCT(이산 코사인 변환)**를 사용합니다:

```
1. 이미지를 8×8 블록으로 분할
2. 각 블록을 주파수 영역으로 변환 (DCT)
3. 사람이 덜 민감한 고주파 성분 제거
4. 허프만 코딩으로 압축
```

**핵심**: 사람 눈이 인지하기 어려운 디테일을 버림

### Quality 설정

iOS에서 JPEG 압축:

```swift
let jpegData = image.jpegData(compressionQuality: 0.8)
```

**compressionQuality**: 0.0 ~ 1.0

| Quality | 파일 크기 | 화질 | 용도 |
|---------|-----------|------|------|
| 1.0 | 4.2 MB | 최상 | 원본 보존 |
| 0.9 | 1.8 MB | 우수 | **고품질** (권장) |
| 0.8 | 980 KB | 좋음 | **일반** (권장) |
| 0.7 | 620 KB | 양호 | 웹 업로드 |
| 0.5 | 350 KB | 보통 | 썸네일 |
| 0.3 | 180 KB | 낮음 | 저용량 |
| 0.1 | 80 KB | 나쁨 | 미리보기 |

**권장값**:
- 원본 저장: 0.9~1.0
- SNS 업로드: 0.8
- 썸네일: 0.6~0.7
- 미리보기: 0.3~0.5

### JPEG 최적화 팁

#### 1. 리사이즈 후 압축

```swift
// ❌ 나쁜 예: 큰 이미지를 고품질로 압축
let largeJPEG = largeImage.jpegData(compressionQuality: 1.0)  // 15MB

// ✅ 좋은 예: 리사이즈 후 적절한 품질로 압축
let resized = resize(largeImage, to: 1920)
let optimizedJPEG = resized.jpegData(compressionQuality: 0.8)  // 800KB
```

#### 2. Progressive JPEG

```swift
// UIImage는 progressive JPEG를 지원하지 않음
// Image I/O를 사용해야 함
func saveProgressiveJPEG(image: UIImage, to url: URL, quality: CGFloat) {
    guard let cgImage = image.cgImage else { return }
    
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        kUTTypeJPEG,
        1,
        nil
    ) else { return }
    
    let options: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: quality,
        kCGImagePropertyOrientation: image.imageOrientation.cgImagePropertyOrientation
    ]
    
    CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
    CGImageDestinationFinalize(destination)
}
```

#### 3. EXIF 메타데이터 보존

```swift
// UIImage.jpegData()는 EXIF를 제거함
// Image I/O로 보존 가능
func preserveMetadata(image: UIImage, originalURL: URL, to destination: URL) {
    guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil),
          let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil),
          let cgImage = image.cgImage else { return }
    
    guard let dest = CGImageDestinationCreateWithURL(
        destination as CFURL,
        kUTTypeJPEG,
        1,
        nil
    ) else { return }
    
    CGImageDestinationAddImage(dest, cgImage, metadata)
    CGImageDestinationFinalize(dest)
}
```

### 언제 JPEG를 사용할까?

✅ **사용**:
- 사진 (풍경, 인물)
- 웹 이미지
- SNS 업로드
- 이메일 첨부

❌ **비권장**:
- 투명 배경 필요
- 텍스트 위주
- 로고/아이콘
- 선명한 경계

---

## PNG

> Portable Network Graphics

### 특징

**장점**:
- ✅ 무손실 압축 (화질 저하 없음)
- ✅ 투명도 지원 (알파 채널)
- ✅ 텍스트/선명한 경계에 적합
- ✅ 반복 저장해도 화질 유지

**단점**:
- ❌ 파일 크기가 큼 (JPEG 대비 3~5배)
- ❌ 사진에는 비효율적

### 압축 원리

PNG는 **Deflate 알고리즘**을 사용합니다:

```
1. 필터링 (인접 픽셀의 유사성 활용)
2. LZ77 압축 (반복 패턴 찾기)
3. 허프만 코딩
```

**핵심**: 픽셀 데이터를 하나도 버리지 않음

### iOS에서 PNG 생성

```swift
let pngData = image.pngData()
```

**주의**: PNG는 압축 품질 옵션이 없습니다 (무손실이므로).

### PNG 최적화

#### 1. 색상 깊이 감소

```swift
// 24-bit RGB → 8-bit Indexed (256 색상)
func reduce256Colors(image: UIImage) -> Data? {
    guard let cgImage = image.cgImage else { return nil }
    
    // Core Image 필터 사용
    let ciImage = CIImage(cgImage: cgImage)
    let filter = CIFilter(name: "CIColorMonochrome")
    // ... 색상 감소 로직
    
    // PNG로 저장
    return resultImage.pngData()
}
```

#### 2. 외부 도구 활용

iOS에서는 PNG 최적화가 제한적입니다. 서버에서 처리 권장:

```bash
# ImageOptim, pngquant 등
pngquant --quality=65-80 input.png
```

#### 3. 알파 채널 제거

투명도가 필요 없다면:

```swift
func removePNGAlpha(image: UIImage) -> UIImage? {
    let format = UIGraphicsImageRendererFormat()
    format.opaque = true  // 투명도 제거
    
    let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
    return renderer.image { context in
        image.draw(in: CGRect(origin: .zero, size: image.size))
    }
}

let opaqueImage = removePNGAlpha(transparentImage)
let pngData = opaqueImage.pngData()  // 파일 크기 감소
```

### 언제 PNG를 사용할까?

✅ **사용**:
- UI 아이콘
- 로고 (투명 배경)
- 텍스트 이미지
- 스크린샷
- 그래픽 디자인
- 선명한 경계가 중요한 경우

❌ **비권장**:
- 사진 (JPEG 또는 HEIC 사용)
- 큰 배경 이미지 (용량 문제)

---

## HEIC

> High Efficiency Image Container (HEIF 기반)

### 특징

**장점**:
- ✅ **작은 파일 크기** (JPEG 대비 40~50% 절감)
- ✅ 높은 화질
- ✅ 투명도 지원
- ✅ 16-bit 색상 지원
- ✅ 라이브 포토, 버스트 지원

**단점**:
- ❌ iOS 11+ / macOS 10.13+ 필요
- ❌ 일부 웹 브라우저 미지원
- ❌ 인코딩이 느림 (JPEG 대비 3~5배)

### 압축 원리

HEIC는 **HEVC(H.265) 비디오 코덱**을 사용합니다:

```
1. 이미지를 타일로 분할
2. 각 타일을 HEVC로 압축
3. 메타데이터와 함께 컨테이너에 저장
```

**핵심**: 최신 비디오 압축 기술을 이미지에 적용

### iOS에서 HEIC 생성

iOS 11+에서 기본 포맷이지만, 직접 생성하려면:

```swift
import UniformTypeIdentifiers

func convertToHEIC(image: UIImage, quality: CGFloat) -> Data? {
    guard let cgImage = image.cgImage else { return nil }
    
    let data = NSMutableData()
    
    guard let destination = CGImageDestinationCreateWithData(
        data,
        AVFileType.heic as CFString,  // iOS 11+
        1,
        nil
    ) else { return nil }
    
    let options: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: quality
    ]
    
    CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
    
    guard CGImageDestinationFinalize(destination) else {
        return nil
    }
    
    return data as Data
}
```

**iOS 11+ 확인**:
```swift
if #available(iOS 11.0, *) {
    let heicData = convertToHEIC(image, quality: 0.8)
} else {
    // 폴백: JPEG 사용
    let jpegData = image.jpegData(compressionQuality: 0.8)
}
```

### HEIC vs JPEG 비교

동일한 사진 (4032 × 3024):

| 포맷 | Quality | 파일 크기 | 상대 크기 | 화질 (PSNR) |
|------|---------|-----------|-----------|-------------|
| JPEG | 0.9 | 1.8 MB | 100% | 42.3 dB |
| **HEIC** | **0.9** | **950 KB** | **53%** | **42.5 dB** |
| JPEG | 0.8 | 980 KB | 100% | 40.8 dB |
| **HEIC** | **0.8** | **520 KB** | **53%** | **41.2 dB** |
| JPEG | 0.7 | 620 KB | 100% | 38.9 dB |
| **HEIC** | **0.7** | **350 KB** | **56%** | **39.5 dB** |

**결론**: HEIC가 JPEG 대비 **40~50% 작으면서 화질은 더 좋음**

### 호환성 문제 해결

HEIC는 일부 플랫폼에서 미지원됩니다:

```swift
func saveImageCompatible(image: UIImage, for purpose: ImagePurpose) -> Data? {
    switch purpose {
    case .localStorage:
        // iOS 11+: HEIC 사용 (공간 절약)
        if #available(iOS 11.0, *) {
            return convertToHEIC(image, quality: 0.8)
        } else {
            return image.jpegData(compressionQuality: 0.8)
        }
        
    case .webUpload:
        // 웹 호환성: JPEG 사용
        return image.jpegData(compressionQuality: 0.8)
        
    case .share:
        // iOS 기기끼리: HEIC
        // 기타: JPEG
        if isIOSDevice() {
            return convertToHEIC(image, quality: 0.9)
        } else {
            return image.jpegData(compressionQuality: 0.9)
        }
    }
}
```

### 언제 HEIC를 사용할까?

✅ **사용**:
- iOS/macOS 전용 앱
- iCloud 사진 보관
- 로컬 저장소 절약
- 고품질 유지하면서 용량 줄이기
- 최신 기기 간 공유

❌ **비권장**:
- 웹 업로드 (호환성)
- 구형 기기 지원
- 크로스 플랫폼 (Android, Windows)

---

## 포맷 변환

### JPEG ↔ PNG

#### JPEG → PNG

```swift
// UIImage를 거쳐 변환
let jpegImage = UIImage(data: jpegData)
let pngData = jpegImage?.pngData()
```

**주의**: 손실된 화질은 복원되지 않음

#### PNG → JPEG

```swift
let pngImage = UIImage(data: pngData)
let jpegData = pngImage?.jpegData(compressionQuality: 0.8)
```

**주의**: 투명 배경이 검은색이 됨

**투명 배경 처리**:
```swift
func pngToJPEG(pngImage: UIImage, backgroundColor: UIColor = .white) -> Data? {
    let format = UIGraphicsImageRendererFormat()
    format.opaque = true
    
    let renderer = UIGraphicsImageRenderer(size: pngImage.size, format: format)
    let jpegImage = renderer.image { context in
        // 배경 색 채우기
        backgroundColor.setFill()
        context.fill(CGRect(origin: .zero, size: pngImage.size))
        
        // PNG 그리기
        pngImage.draw(in: CGRect(origin: .zero, size: pngImage.size))
    }
    
    return jpegImage.jpegData(compressionQuality: 0.8)
}
```

### HEIC ↔ JPEG

#### HEIC → JPEG

```swift
let heicImage = UIImage(data: heicData)
let jpegData = heicImage?.jpegData(compressionQuality: 0.8)
```

#### JPEG → HEIC

```swift
let jpegImage = UIImage(data: jpegData)
let heicData = convertToHEIC(jpegImage, quality: 0.8)
```

### 포맷 감지

```swift
enum ImageFormat {
    case jpeg
    case png
    case heic
    case unknown
}

func detectImageFormat(data: Data) -> ImageFormat {
    guard data.count > 12 else { return .unknown }
    
    // Magic number 체크
    let bytes = [UInt8](data.prefix(12))
    
    // JPEG: FF D8 FF
    if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
        return .jpeg
    }
    
    // PNG: 89 50 4E 47
    if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
        return .png
    }
    
    // HEIC: 'ftyp' at offset 4
    if bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
        // 추가 확인: heic, heix, hevc, hevx
        return .heic
    }
    
    return .unknown
}
```

### 일괄 변환

```swift
func batchConvert(
    imageURLs: [URL],
    to format: ImageFormat,
    quality: CGFloat = 0.8,
    progress: @escaping (Int, Int) -> Void
) -> [Data] {
    var results: [Data] = []
    
    for (index, url) in imageURLs.enumerated() {
        autoreleasepool {
            guard let image = UIImage(contentsOfFile: url.path) else { return }
            
            let data: Data?
            switch format {
            case .jpeg:
                data = image.jpegData(compressionQuality: quality)
            case .png:
                data = image.pngData()
            case .heic:
                data = convertToHEIC(image, quality: quality)
            case .unknown:
                data = nil
            }
            
            if let data = data {
                results.append(data)
            }
            
            progress(index + 1, imageURLs.count)
        }
    }
    
    return results
}

// 사용
batchConvert(imageURLs: urls, to: .jpeg, quality: 0.8) { current, total in
    print("진행률: \(current)/\(total)")
}
```

---

## 실전 활용

### 1. SNS 업로드 최적화

```swift
func optimizeForSNS(image: UIImage) -> Data? {
    // 1. 리사이즈 (Instagram: 1080px)
    let targetSize = CGSize(width: 1080, height: 1080)
    let resized = resize(image, to: targetSize, mode: .aspectFit)
    
    // 2. JPEG로 변환 (호환성)
    return resized.jpegData(compressionQuality: 0.85)
}
```

### 2. 프로필 사진 최적화

```swift
func optimizeProfilePhoto(image: UIImage) -> Data? {
    // 1. 정사각형 크롭
    let cropped = cropToSquare(image)
    
    // 2. 적절한 크기로 리사이즈
    let resized = resize(cropped, to: CGSize(width: 512, height: 512))
    
    // 3. 적절한 포맷 선택
    if #available(iOS 11.0, *) {
        return convertToHEIC(resized, quality: 0.9)  // 고품질, 작은 용량
    } else {
        return resized.jpegData(compressionQuality: 0.9)
    }
}
```

### 3. 썸네일 생성

```swift
func generateThumbnail(from url: URL, size: CGSize) -> UIImage? {
    // Image I/O 다운샘플링 (메모리 효율)
    let downsampled = downsampleImage(from: url, to: size)
    
    // 메모리 최소화를 위해 JPEG로 저장 후 재로드
    if let jpeg = downsampled?.jpegData(compressionQuality: 0.7) {
        return UIImage(data: jpeg)
    }
    
    return downsampled
}
```

### 4. 포맷별 사용 전략

```swift
class ImageManager {
    enum ImagePurpose {
        case original       // 원본 보관
        case display        // 화면 표시
        case thumbnail      // 썸네일
        case webUpload      // 웹 업로드
        case archive        // 장기 보관
    }
    
    func processImage(_ image: UIImage, for purpose: ImagePurpose) -> Data? {
        switch purpose {
        case .original:
            // HEIC (iOS 11+) 또는 PNG (무손실)
            if #available(iOS 11.0, *) {
                return convertToHEIC(image, quality: 1.0)
            } else {
                return image.pngData()
            }
            
        case .display:
            // 화면 크기로 리사이즈 + JPEG
            let resized = resize(image, to: UIScreen.main.bounds.size)
            return resized.jpegData(compressionQuality: 0.8)
            
        case .thumbnail:
            // 작은 크기 + 낮은 품질
            let resized = resize(image, to: CGSize(width: 200, height: 200))
            return resized.jpegData(compressionQuality: 0.6)
            
        case .webUpload:
            // 중간 크기 + JPEG (호환성)
            let resized = resize(image, to: CGSize(width: 1920, height: 1920))
            return resized.jpegData(compressionQuality: 0.85)
            
        case .archive:
            // HEIC (공간 절약, 고품질)
            if #available(iOS 11.0, *) {
                return convertToHEIC(image, quality: 0.95)
            } else {
                return image.jpegData(compressionQuality: 0.95)
            }
        }
    }
}
```

### 5. 자동 포맷 선택

```swift
func smartFormatSelection(image: UIImage, targetSize: Int) -> Data? {
    // 여러 포맷으로 인코딩하고 가장 작은 것 선택
    var bestData: Data?
    var bestSize = Int.max
    
    // JPEG 시도
    if let jpeg = image.jpegData(compressionQuality: 0.8) {
        if jpeg.count < bestSize {
            bestData = jpeg
            bestSize = jpeg.count
        }
    }
    
    // PNG 시도 (작은 이미지나 단순한 이미지는 PNG가 더 작을 수 있음)
    if let png = image.pngData() {
        if png.count < bestSize {
            bestData = png
            bestSize = png.count
        }
    }
    
    // HEIC 시도
    if #available(iOS 11.0, *) {
        if let heic = convertToHEIC(image, quality: 0.8) {
            if heic.count < bestSize {
                bestData = heic
                bestSize = heic.count
            }
        }
    }
    
    return bestData
}
```

---

## 요약

### 포맷 선택 차트

```
사진인가?
 ├─ YES → HEIC (iOS 11+) 또는 JPEG
 │         크기 중요? → HEIC
 │         호환성 중요? → JPEG
 │
 └─ NO → 투명 배경 필요?
           ├─ YES → PNG
           └─ NO → 단순한 그래픽?
                    ├─ YES → PNG (더 작을 수 있음)
                    └─ NO → JPEG
```

### 핵심 원칙

1. **사진**: HEIC (iOS 11+) > JPEG
2. **투명도**: PNG > HEIC
3. **호환성**: JPEG
4. **용량**: HEIC > JPEG > PNG
5. **화질**: PNG > HEIC > JPEG

### 실무 권장사항

| 상황 | 포맷 | 설정 |
|------|------|------|
| 카메라 촬영 저장 | HEIC | quality 0.9 |
| SNS 업로드 | JPEG | quality 0.85, 1080px |
| 프로필 사진 | HEIC/JPEG | quality 0.9, 512px |
| 썸네일 | JPEG | quality 0.6-0.7, 200px |
| UI 아이콘 | PNG | 원본 크기 |
| 로고 (투명) | PNG | 원본 크기 |

### 다음 단계

- PERFORMANCE_GUIDE.md에서 최적화 전략 학습
- 실습 뷰에서 포맷별 차이 직접 비교
- 벤치마크로 성능 측정

---

**Happy Converting! 🎨**

*적절한 포맷 선택으로 용량과 품질을 최적화하세요!*

