# Image I/O 이론 정리

> Day 4 학습 자료 - EXIF 메타데이터와 Image I/O 프레임워크

---

## 📚 목차

1. [EXIF 기초](#1-exif-기초)
2. [Image I/O 프레임워크](#2-image-io-프레임워크)
3. [핵심 구성요소](#3-핵심-구성요소)
4. [GPS 메타데이터](#4-gps-메타데이터)
5. [성능 최적화](#5-성능-최적화)

---

## 1. EXIF 기초

### 🎯 EXIF란?

**EXIF (Exchangeable Image File Format)**는 디지털 카메라와 스캐너가 생성한 이미지 파일에 포함되는 메타데이터 표준입니다.

```
┌─────────────────────────────────────┐
│  이미지 파일 (JPEG, HEIF 등)         │
├─────────────────────────────────────┤
│  픽셀 데이터 (실제 사진)              │  ← 우리가 보는 이미지
├─────────────────────────────────────┤
│  EXIF 메타데이터                     │  ← 촬영 정보
│  - 카메라: iPhone 14 Pro            │
│  - 날짜: 2025-10-22 14:30:45        │
│  - GPS: 37.5665° N, 126.9780° E     │
│  - ISO: 200                         │
│  - 조리개: f/1.8                     │
│  - 셔터: 1/120초                     │
└─────────────────────────────────────┘
```

### ✨ 주요 메타데이터 항목

| 카테고리 | 주요 정보 | 예시 |
|---------|----------|------|
| **기본 정보** | 이미지 크기, 파일 형식 | 4032×3024, JPEG |
| **카메라** | 제조사, 모델, 렌즈 | Apple, iPhone 14 Pro |
| **촬영 설정** | ISO, 조리개, 셔터속도, 초점거리 | ISO 200, f/1.8, 1/120s, 26mm |
| **날짜/시간** | 촬영 일시, 수정 일시 | 2025:10:22 14:30:45 |
| **GPS** | 위도, 경도, 고도, 방향 | 37.5665°N, 126.9780°E |
| **기타** | 플래시, 화이트밸런스, 측광 모드 | Auto, Daylight, Pattern |

### 📊 EXIF vs IPTC vs XMP 비교

```swift
// EXIF - 카메라가 자동으로 기록
{
  "ISO": 400,
  "ShutterSpeed": "1/250",
  "GPSLatitude": 37.5665
}

// IPTC - 사진 편집 시 수동으로 추가 (저작권, 키워드)
{
  "Creator": "John Doe",
  "Copyright": "© 2025",
  "Keywords": ["여행", "서울"]
}

// XMP - Adobe의 확장 가능한 메타데이터 (최신 표준)
{
  "Rating": 5,
  "Label": "Red",
  "Collections": ["Best Photos"]
}
```

| 포맷 | 용도 | 생성 시점 | 확장성 |
|-----|------|----------|-------|
| **EXIF** | 촬영 정보 | 카메라 자동 | 제한적 |
| **IPTC** | 저작권, 설명 | 수동 추가 | 중간 |
| **XMP** | 모든 메타데이터 | 수동/자동 | 높음 |

---

## 2. Image I/O 프레임워크

### 🎯 Image I/O란?

**Image I/O**는 이미지를 읽고 쓰는 애플의 저수준 프레임워크입니다. 다양한 이미지 포맷을 지원하며, **메타데이터 접근**과 **효율적인 썸네일 생성**에 최적화되어 있습니다.

```
┌─────────────────────────────────────┐
│  SwiftUI / UIKit                    │  ← UI 표시
├─────────────────────────────────────┤
│  Core Image                         │  ← 필터 처리
├─────────────────────────────────────┤
│  Image I/O ← 오늘 배울 것!           │  ← 파일 I/O, 메타데이터
├─────────────────────────────────────┤
│  Core Graphics                      │  ← 픽셀 처리
├─────────────────────────────────────┤
│  Metal                              │  ← GPU
└─────────────────────────────────────┘
```

### ✅ UIImage vs Image I/O 비교

```swift
// ❌ UIImage - 전체 이미지를 메모리에 로드
let uiImage = UIImage(named: "photo")
// 단점: 4032×3024 이미지 = 약 48MB 메모리 사용
// EXIF 접근 불가능

// ✅ Image I/O - 필요한 만큼만 로드
let source = CGImageSourceCreateWithURL(url, nil)
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
// 장점: 메타데이터만 읽으면 수 KB 메모리
// EXIF 접근 가능

// ✅ 썸네일만 생성
let options: [CFString: Any] = [
    kCGImageSourceThumbnailMaxPixelSize: 200,
    kCGImageSourceCreateThumbnailFromImageAlways: true
]
let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
// 200×200 썸네일 = 약 150KB (원본의 1/300)
```

### ✨ Image I/O의 장점

| 특징 | 설명 | 활용 |
|-----|------|------|
| **메모리 효율** | 전체 이미지를 로드하지 않음 | 갤러리 앱 |
| **메타데이터 접근** | EXIF, IPTC, XMP 읽기/쓰기 | 사진 정보 표시 |
| **썸네일 생성** | 고품질 썸네일 빠르게 생성 | 그리드 뷰 |
| **다양한 포맷** | JPEG, PNG, HEIF, RAW 등 | 범용 뷰어 |
| **점진적 로딩** | 네트워크 이미지 스트리밍 | 웹 이미지 |

---

## 3. 핵심 구성요소

### 📖 CGImageSource - 이미지 읽기

**"이미지 파일로부터 데이터를 읽는 객체"**

```swift
// 1) 파일에서 생성
if let url = Bundle.main.url(forResource: "photo", withExtension: "jpg") {
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)
}

// 2) Data에서 생성
if let data = try? Data(contentsOf: url) {
    let source = CGImageSourceCreateWithData(data as CFData, nil)
}

// 3) 이미지 개수 확인 (애니메이션 GIF는 여러 프레임)
let count = CGImageSourceGetCount(source)  // 보통 1

// 4) 이미지 타입 확인
let type = CGImageSourceGetType(source)  // "public.jpeg"
```

### 🔍 메타데이터 읽기

```swift
// 전체 속성 가져오기
guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] 
else { return }

// 기본 정보
let pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int  // 4032
let pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int  // 3024
let dpiWidth = properties[kCGImagePropertyDPIWidth] as? Int  // 72
let orientation = properties[kCGImagePropertyOrientation] as? Int  // 1

// EXIF 딕셔너리
if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
    let iso = exif[kCGImagePropertyExifISOSpeedRatings] as? [Int]  // [200]
    let fNumber = exif[kCGImagePropertyExifFNumber] as? Double  // 1.8
    let exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double  // 0.008333 (1/120)
    let focalLength = exif[kCGImagePropertyExifFocalLength] as? Double  // 5.7
    let dateTime = exif[kCGImagePropertyExifDateTimeOriginal] as? String  // "2025:10:22 14:30:45"
    let lensModel = exif[kCGImagePropertyExifLensModel] as? String  // "iPhone 14 Pro back triple camera 5.7mm f/1.78"
}

// TIFF 딕셔너리 (카메라 정보)
if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
    let make = tiff[kCGImagePropertyTIFFMake] as? String  // "Apple"
    let model = tiff[kCGImagePropertyTIFFModel] as? String  // "iPhone 14 Pro"
    let software = tiff[kCGImagePropertyTIFFSoftware] as? String  // "iOS 17.0"
}

// GPS 딕셔너리
if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
    let latitude = gps[kCGImagePropertyGPSLatitude] as? Double  // 37.5665
    let longitude = gps[kCGImagePropertyGPSLongitude] as? Double  // 126.9780
    let altitude = gps[kCGImagePropertyGPSAltitude] as? Double  // 38.5
}
```

### 🎨 주요 Property 키

#### 기본 속성
```swift
kCGImagePropertyPixelWidth           // 이미지 너비 (픽셀)
kCGImagePropertyPixelHeight          // 이미지 높이 (픽셀)
kCGImagePropertyDPIWidth             // 가로 해상도 (DPI)
kCGImagePropertyDPIHeight            // 세로 해상도 (DPI)
kCGImagePropertyOrientation          // 방향 (1-8)
kCGImagePropertyColorModel           // 색상 모델 (RGB, CMYK 등)
kCGImagePropertyDepth                // 색 깊이 (8, 16 등)
```

#### EXIF 딕셔너리 키
```swift
kCGImagePropertyExifDictionary       // EXIF 딕셔너리
kCGImagePropertyExifISOSpeedRatings  // ISO [100, 200, 400...]
kCGImagePropertyExifFNumber          // 조리개 값 (1.8 = f/1.8)
kCGImagePropertyExifExposureTime     // 셔터속도 (0.01 = 1/100s)
kCGImagePropertyExifFocalLength      // 초점거리 (mm)
kCGImagePropertyExifDateTimeOriginal // 촬영 일시
kCGImagePropertyExifLensModel        // 렌즈 모델
kCGImagePropertyExifFlash            // 플래시 사용 여부
kCGImagePropertyExifWhiteBalance     // 화이트밸런스
```

#### GPS 딕셔너리 키
```swift
kCGImagePropertyGPSDictionary        // GPS 딕셔너리
kCGImagePropertyGPSLatitude          // 위도 (도)
kCGImagePropertyGPSLatitudeRef       // 위도 방향 (N/S)
kCGImagePropertyGPSLongitude         // 경도 (도)
kCGImagePropertyGPSLongitudeRef      // 경도 방향 (E/W)
kCGImagePropertyGPSAltitude          // 고도 (미터)
kCGImagePropertyGPSTimeStamp         // GPS 시간
kCGImagePropertyGPSSpeed             // 속도
kCGImagePropertyGPSImgDirection      // 촬영 방향 (도)
```

### 🖼️ 썸네일 생성

```swift
// 효율적인 썸네일 생성
let options: [CFString: Any] = [
    // 최대 크기 지정 (긴 쪽 기준)
    kCGImageSourceThumbnailMaxPixelSize: 200,
    
    // 이미지에 썸네일이 없어도 생성
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    
    // 이미지 방향 자동 적용
    kCGImageSourceCreateThumbnailWithTransform: true
]

if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
   let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
    let thumbnailImage = UIImage(cgImage: thumbnail)
}

// 💡 메모리 비교
// 원본 4032×3024 = 약 48MB
// 썸네일 200×150 = 약 120KB (400배 절약!)
```

---

## 4. GPS 메타데이터

### 🗺️ GPS 태그 구조

GPS 정보는 EXIF의 하위 딕셔너리로 저장됩니다.

```swift
// GPS 딕셔너리 파싱
if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
    // 위도 (Latitude)
    let lat = gps[kCGImagePropertyGPSLatitude] as? Double  // 37.5665
    let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String  // "N" (북위)
    
    // 경도 (Longitude)
    let lon = gps[kCGImagePropertyGPSLongitude] as? Double  // 126.9780
    let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String  // "E" (동경)
    
    // 고도 (Altitude)
    let alt = gps[kCGImagePropertyGPSAltitude] as? Double  // 38.5 (미터)
    let altRef = gps[kCGImagePropertyGPSAltitudeRef] as? Int  // 0 (해발), 1 (해저)
    
    // 촬영 방향
    let direction = gps[kCGImagePropertyGPSImgDirection] as? Double  // 45.0 (도)
    
    // GPS 시간
    let timestamp = gps[kCGImagePropertyGPSTimeStamp] as? String  // "06:30:45.00"
    let datestamp = gps[kCGImagePropertyGPSDateStamp] as? String  // "2025:10:22"
}
```

### 🧭 CoreLocation 좌표 변환

```swift
import CoreLocation

func extractCoordinate(from gps: [CFString: Any]) -> CLLocationCoordinate2D? {
    guard let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
          let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
          let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
          let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String else {
        return nil
    }
    
    // 방향에 따라 부호 결정
    let latitude = latRef == "N" ? lat : -lat
    let longitude = lonRef == "E" ? lon : -lon
    
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
}

// MapKit에서 사용
import MapKit

let coordinate = extractCoordinate(from: gpsDict)
let region = MKCoordinateRegion(
    center: coordinate,
    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
)
```

### 🔒 개인정보 보호

**주의**: GPS 정보는 민감한 개인정보입니다!

```swift
// GPS 제거하여 이미지 저장
if let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
   let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, kUTTypeJPEG, 1, nil) {
    
    // 원본 속성 복사
    var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [CFString: Any]
    
    // GPS 딕셔너리 제거
    properties.removeValue(forKey: kCGImagePropertyGPSDictionary)
    
    // 이미지 저장
    if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
    }
}
```

---

## 5. 성능 최적화

### ⚡ 메타데이터만 읽기

```swift
// ✅ 빠른 방법 - 메타데이터만
let source = CGImageSourceCreateWithURL(url as CFURL, nil)
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
// 시간: ~1ms, 메모리: ~10KB

// ❌ 느린 방법 - 전체 이미지 로드
let image = UIImage(contentsOfFile: url.path)
// 시간: ~100ms, 메모리: ~48MB
```

### 🔄 백그라운드 처리

```swift
// 대량 이미지 처리는 백그라운드에서
DispatchQueue.global(qos: .userInitiated).async {
    let properties = loadEXIFData(from: url)
    
    DispatchQueue.main.async {
        // UI 업데이트
        self.exifData = properties
    }
}
```

### 🎯 필요한 것만 파싱

```swift
// ❌ 전체 딕셔너리 파싱
let allProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)

// ✅ 필요한 것만 선택적으로
let options: [CFString: Any] = [
    kCGImageSourceShouldCache: false  // 캐싱 비활성화로 메모리 절약
]
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options as CFDictionary)

// EXIF만 필요하면 EXIF만 접근
if let exif = properties?[kCGImagePropertyExifDictionary] {
    // 필요한 필드만 추출
    let iso = exif[kCGImagePropertyExifISOSpeedRatings]
    let shutterSpeed = exif[kCGImagePropertyExifExposureTime]
}
```

### 📊 성능 비교

| 작업 | UIImage | Image I/O | 메모리 절약 |
|-----|---------|-----------|-----------|
| 메타데이터 읽기 | 48MB | 10KB | 4,800배 |
| 썸네일 생성 | 48MB | 150KB | 320배 |
| 대용량 RAW (50MB) | 300MB+ | 100KB | 3,000배 |

---

## 💡 실무 활용 사례

### 1. 갤러리 앱
- 썸네일 그리드: Image I/O로 고속 썸네일 생성
- 상세 정보: EXIF 데이터 표시
- 지도 뷰: GPS 태그로 촬영 위치 표시

### 2. 사진 편집 앱
- 메타데이터 보존: 편집 후에도 EXIF 유지
- GPS 제거: 개인정보 보호 모드
- 워터마크: IPTC에 저작권 추가

### 3. 카메라 앱
- 커스텀 메타데이터 추가
- 촬영 설정 로그 저장
- RAW + JPEG 동시 처리

---

## 🔗 참고 자료

- [Apple Documentation - Image I/O](https://developer.apple.com/documentation/imageio)
- [EXIF 2.32 Specification](http://www.cipa.jp/std/documents/e/DC-008-Translation-2019-E.pdf)
- [CGImageSource Reference](https://developer.apple.com/documentation/imageio/cgimagesource)
- [CGImageDestination Reference](https://developer.apple.com/documentation/imageio/cgimagedestination)

---

## ✅ 핵심 요약

1. **EXIF**는 이미지 파일에 포함된 촬영 정보 메타데이터
2. **Image I/O**는 메타데이터 접근과 효율적인 썸네일 생성에 최적화
3. **CGImageSource**로 이미지를 읽고 메타데이터 추출
4. **GPS 태그**는 CoreLocation, MapKit과 연동 가능
5. **메모리 효율**: 전체 이미지 로드 없이 메타데이터만 접근 (최대 수천 배 절약)

---

*다음 단계: 실습 코드로 직접 EXIF 읽기를 구현해봅시다!*


