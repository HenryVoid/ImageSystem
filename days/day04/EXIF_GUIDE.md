# EXIF 활용 가이드

> EXIF 메타데이터를 실무에서 활용하는 방법

---

## 📋 목차

1. [주요 EXIF 태그 레퍼런스](#주요-exif-태그-레퍼런스)
2. [GPS 태그 상세 설명](#gps-태그-상세-설명)
3. [EXIF 수정/제거 방법](#exif-수정제거-방법)
4. [실무 활용 사례](#실무-활용-사례)

---

## 주요 EXIF 태그 레퍼런스

### 📷 카메라 정보 (TIFF)

| 태그 | 키 | 타입 | 예시 | 설명 |
|-----|-----|------|------|------|
| Make | `kCGImagePropertyTIFFMake` | String | "Apple" | 카메라 제조사 |
| Model | `kCGImagePropertyTIFFModel` | String | "iPhone 14 Pro" | 카메라 모델 |
| Software | `kCGImagePropertyTIFFSoftware` | String | "iOS 17.0" | 펌웨어/소프트웨어 버전 |
| DateTime | `kCGImagePropertyTIFFDateTime` | String | "2025:10:22 14:30:45" | 마지막 수정 일시 |
| XResolution | `kCGImagePropertyTIFFXResolution` | Double | 72.0 | 가로 해상도 (DPI) |
| YResolution | `kCGImagePropertyTIFFYResolution` | Double | 72.0 | 세로 해상도 (DPI) |
| Orientation | `kCGImagePropertyTIFFOrientation` | Int | 1 | 이미지 방향 (1-8) |

### 🎨 촬영 설정 (EXIF)

| 태그 | 키 | 타입 | 예시 | 설명 |
|-----|-----|------|------|------|
| ISO | `kCGImagePropertyExifISOSpeedRatings` | [Int] | [200] | ISO 감도 |
| FNumber | `kCGImagePropertyExifFNumber` | Double | 1.8 | 조리개 값 (f/1.8) |
| ExposureTime | `kCGImagePropertyExifExposureTime` | Double | 0.008333 | 셔터속도 (1/120s) |
| FocalLength | `kCGImagePropertyExifFocalLength` | Double | 5.7 | 초점거리 (mm) |
| LensModel | `kCGImagePropertyExifLensModel` | String | "iPhone 14 Pro..." | 렌즈 모델 |
| Flash | `kCGImagePropertyExifFlash` | Int | 0 | 플래시 (비트 플래그) |
| WhiteBalance | `kCGImagePropertyExifWhiteBalance` | Int | 0 | 화이트밸런스 (0=자동) |
| MeteringMode | `kCGImagePropertyExifMeteringMode` | Int | 5 | 측광 모드 |
| DateTimeOriginal | `kCGImagePropertyExifDateTimeOriginal` | String | "2025:10:22 14:30:45" | 원본 촬영 일시 |

### 📐 이미지 정보

| 태그 | 키 | 타입 | 예시 | 설명 |
|-----|-----|------|------|------|
| PixelWidth | `kCGImagePropertyPixelWidth` | Int | 4032 | 이미지 너비 (픽셀) |
| PixelHeight | `kCGImagePropertyPixelHeight` | Int | 3024 | 이미지 높이 (픽셀) |
| ColorModel | `kCGImagePropertyColorModel` | String | "RGB" | 색상 모델 |
| Depth | `kCGImagePropertyDepth` | Int | 8 | 색 깊이 (비트) |

---

## GPS 태그 상세 설명

### 🗺️ 위치 좌표

```swift
// GPS 딕셔너리 접근
if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
    // 위도 (Latitude)
    let latitude = gps[kCGImagePropertyGPSLatitude] as? Double  // 37.5665
    let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String  // "N" (북위) 또는 "S" (남위)
    
    // 경도 (Longitude)
    let longitude = gps[kCGImagePropertyGPSLongitude] as? Double  // 126.9780
    let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String  // "E" (동경) 또는 "W" (서경)
    
    // 실제 좌표 계산
    let lat = latitudeRef == "N" ? latitude : -latitude
    let lon = longitudeRef == "E" ? longitude : -longitude
}
```

### 📏 고도 및 방향

| 태그 | 키 | 타입 | 예시 | 설명 |
|-----|-----|------|------|------|
| Altitude | `kCGImagePropertyGPSAltitude` | Double | 38.5 | 고도 (미터) |
| AltitudeRef | `kCGImagePropertyGPSAltitudeRef` | Int | 0 | 0=해발, 1=해저 |
| Speed | `kCGImagePropertyGPSSpeed` | Double | 10.5 | 이동 속도 |
| SpeedRef | `kCGImagePropertyGPSSpeedRef` | String | "K" | K=km/h, M=mph, N=knots |
| ImgDirection | `kCGImagePropertyGPSImgDirection` | Double | 45.0 | 촬영 방향 (0-359.99도) |
| ImgDirectionRef | `kCGImagePropertyGPSImgDirectionRef` | String | "T" | T=진북, M=자북 |

### 🕐 시간 정보

```swift
// GPS 시간 (UTC)
let timeStamp = gps[kCGImagePropertyGPSTimeStamp] as? String  // "06:30:45.00"
let dateStamp = gps[kCGImagePropertyGPSDateStamp] as? String  // "2025:10:22"
```

---

## EXIF 수정/제거 방법

### 🔒 개인정보 보호를 위한 GPS 제거

```swift
import ImageIO
import UniformTypeIdentifiers

func removeGPS(from sourceURL: URL, to destinationURL: URL) -> Bool {
    // 1. ImageSource 생성
    guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
        return false
    }
    
    // 2. ImageDestination 생성
    guard let destination = CGImageDestinationCreateWithURL(
        destinationURL as CFURL,
        kUTTypeJPEG,
        1,
        nil
    ) else {
        return false
    }
    
    // 3. 원본 속성 복사
    guard var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
        return false
    }
    
    // 4. GPS 딕셔너리 제거
    properties.removeValue(forKey: kCGImagePropertyGPSDictionary)
    
    // 5. 이미지와 수정된 메타데이터 저장
    if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
    
    return false
}

// 사용 예시
let input = URL(fileURLWithPath: "/path/to/input.jpg")
let output = URL(fileURLWithPath: "/path/to/output.jpg")
let success = removeGPS(from: input, to: output)
```

### ✏️ EXIF 데이터 수정

```swift
func updateExifDateTime(from sourceURL: URL, to destinationURL: URL, newDate: Date) -> Bool {
    guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            kUTTypeJPEG,
            1,
            nil
          ),
          var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          var exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] else {
        return false
    }
    
    // 날짜 포맷 변환
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    let dateString = formatter.string(from: newDate)
    
    // EXIF 날짜 업데이트
    exif[kCGImagePropertyExifDateTimeOriginal] = dateString
    exif[kCGImagePropertyExifDateTimeDigitized] = dateString
    properties[kCGImagePropertyExifDictionary] = exif
    
    // 저장
    if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
    
    return false
}
```

### 🆕 EXIF 데이터 추가

```swift
func addCopyright(to sourceURL: URL, destinationURL: URL, copyright: String) -> Bool {
    guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            kUTTypeJPEG,
            1,
            nil
          ),
          var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
        return false
    }
    
    // TIFF 딕셔너리에 저작권 추가
    var tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
    tiff[kCGImagePropertyTIFFCopyright] = copyright
    properties[kCGImagePropertyTIFFDictionary] = tiff
    
    // 저장
    if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
    
    return false
}
```

---

## 실무 활용 사례

### 📱 1. 사진 갤러리 앱

**요구사항**: 수천 장의 사진을 빠르게 표시

```swift
// ✅ Image I/O로 효율적인 썸네일 생성
func generateThumbnail(from url: URL, size: CGFloat) -> UIImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }
    
    let options: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: size,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]
    
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }
    
    return UIImage(cgImage: thumbnail)
}

// 사용
let thumbnails = photoURLs.map { generateThumbnail(from: $0, size: 200) }
// 메모리 사용량: 원본의 1/300
```

### 🗺️ 2. 사진 지도 앱

**요구사항**: GPS 태그로 사진을 지도에 표시

```swift
import MapKit

struct PhotoAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let imageURL: URL
    let thumbnail: UIImage?
}

func extractPhotoLocations(from urls: [URL]) -> [PhotoAnnotation] {
    return urls.compactMap { url in
        guard let exif = EXIFReader.loadEXIFData(from: url),
              let coordinate = exif.coordinate else {
            return nil
        }
        
        let thumbnail = generateThumbnail(from: url, size: 100)
        
        return PhotoAnnotation(
            coordinate: coordinate,
            imageURL: url,
            thumbnail: thumbnail
        )
    }
}
```

### 📊 3. 사진 분석 앱

**요구사항**: 촬영 통계 분석

```swift
struct PhotoStats {
    var totalPhotos: Int = 0
    var cameraModels: [String: Int] = [:]
    var isoDistribution: [Int: Int] = [:]
    var averageFocalLength: Double = 0
    var photosWithGPS: Int = 0
}

func analyzePhotos(urls: [URL]) -> PhotoStats {
    var stats = PhotoStats()
    var focalLengths: [Double] = []
    
    for url in urls {
        guard let exif = EXIFReader.loadEXIFData(from: url) else { continue }
        
        stats.totalPhotos += 1
        
        // 카메라 모델
        if let model = exif.cameraModel {
            stats.cameraModels[model, default: 0] += 1
        }
        
        // ISO
        if let iso = exif.iso?.first {
            stats.isoDistribution[iso, default: 0] += 1
        }
        
        // 초점거리
        if let focal = exif.focalLength {
            focalLengths.append(focal)
        }
        
        // GPS
        if exif.coordinate != nil {
            stats.photosWithGPS += 1
        }
    }
    
    stats.averageFocalLength = focalLengths.isEmpty ? 0 : focalLengths.reduce(0, +) / Double(focalLengths.count)
    
    return stats
}
```

### 🔒 4. 개인정보 보호 앱

**요구사항**: SNS 업로드 전 GPS 제거

```swift
func prepareForSNS(originalURL: URL) -> URL? {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("jpg")
    
    guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil),
          let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, kUTTypeJPEG, 1, nil),
          var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
        return nil
    }
    
    // GPS 및 민감한 정보 제거
    properties.removeValue(forKey: kCGImagePropertyGPSDictionary)
    
    // 카메라 시리얼 번호 제거 (있다면)
    if var exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
        exif.removeValue(forKey: kCGImagePropertyExifBodySerialNumber)
        exif.removeValue(forKey: kCGImagePropertyExifLensSerialNumber)
        properties[kCGImagePropertyExifDictionary] = exif
    }
    
    if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        if CGImageDestinationFinalize(destination) {
            return tempURL
        }
    }
    
    return nil
}
```

### 📸 5. 카메라 앱

**요구사항**: 커스텀 메타데이터 추가

```swift
func saveCameraPhoto(_ image: UIImage, location: CLLocation?, customData: [String: Any]) {
    guard let data = image.jpegData(compressionQuality: 0.9) else { return }
    
    let source = CGImageSourceCreateWithData(data as CFData, nil)!
    var metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [CFString: Any]
    
    // GPS 추가
    if let location = location {
        var gps: [CFString: Any] = [:]
        gps[kCGImagePropertyGPSLatitude] = abs(location.coordinate.latitude)
        gps[kCGImagePropertyGPSLatitudeRef] = location.coordinate.latitude >= 0 ? "N" : "S"
        gps[kCGImagePropertyGPSLongitude] = abs(location.coordinate.longitude)
        gps[kCGImagePropertyGPSLongitudeRef] = location.coordinate.longitude >= 0 ? "E" : "W"
        gps[kCGImagePropertyGPSAltitude] = location.altitude
        
        metadata[kCGImagePropertyGPSDictionary] = gps
    }
    
    // 커스텀 데이터 (IPTC)
    var iptc: [CFString: Any] = [:]
    if let keywords = customData["keywords"] as? [String] {
        iptc[kCGImagePropertyIPTCKeywords] = keywords
    }
    if let caption = customData["caption"] as? String {
        iptc[kCGImagePropertyIPTCCaptionAbstract] = caption
    }
    metadata[kCGImagePropertyIPTCDictionary] = iptc
    
    // 저장
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).jpg")
    if let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeJPEG, 1, nil),
       let cgImage = image.cgImage {
        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        CGImageDestinationFinalize(destination)
    }
}
```

---

## 💡 베스트 프랙티스

### ✅ 권장 사항

1. **메타데이터만 필요하면 전체 이미지 로드 안함**
   ```swift
   // ✅ Good
   let exif = EXIFReader.loadEXIFData(from: url)
   
   // ❌ Bad
   let image = UIImage(contentsOfFile: url.path)
   ```

2. **백그라운드 스레드에서 처리**
   ```swift
   DispatchQueue.global(qos: .userInitiated).async {
       let exif = EXIFReader.loadEXIFData(from: url)
       DispatchQueue.main.async {
           // UI 업데이트
       }
   }
   ```

3. **에러 처리 철저히**
   ```swift
   guard let exif = EXIFReader.loadEXIFData(from: url) else {
       print("EXIF 읽기 실패")
       return
   }
   ```

4. **개인정보 주의**
   - GPS 태그는 민감한 정보
   - SNS 업로드 전 제거 고려
   - 사용자에게 GPS 포함 여부 알림

### ❌ 피해야 할 것

1. 메인 스레드에서 대량 이미지 처리
2. UIImage로 메타데이터 읽기 (EXIF 손실)
3. GPS 정보를 무단으로 공유
4. EXIF 수정 시 원본 백업 없이 덮어쓰기

---

## 🔗 참고 자료

- [EXIF 2.32 Specification (PDF)](http://www.cipa.jp/std/documents/e/DC-008-Translation-2019-E.pdf)
- [Apple Image I/O Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/)
- [CGImageProperties Reference](https://developer.apple.com/documentation/imageio/cgimageproperties)
- [Privacy Guidelines - Location Data](https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services)

---

*EXIF를 올바르게 활용하여 더 나은 사진 앱을 만들어보세요!*


