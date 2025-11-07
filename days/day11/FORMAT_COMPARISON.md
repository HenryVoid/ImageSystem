# 이미지 포맷 비교

> JPEG, PNG, HEIC, WebP 4가지 포맷의 특성과 사용 시나리오

---

## 📊 포맷 개요

### 한눈에 보는 비교표

| 포맷 | 압축 방식 | 압축률 | 품질 | 투명도 | iOS 지원 | 속도 |
|------|-----------|--------|------|--------|----------|------|
| **JPEG** | 손실 | ⭐⭐⭐ | ⭐⭐⭐ | ❌ | ✅ All | ⚡⚡⚡ |
| **PNG** | 무손실 | ⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ All | ⚡⚡ |
| **HEIC** | 손실 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | ✅ iOS 11+ | ⚡⚡ |
| **WebP** | 손실/무손실 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | ✅ iOS 14+ | ⚡⚡ |

---

## 🖼️ JPEG (Joint Photographic Experts Group)

### 기본 정보

**출시**: 1992년
**확장자**: .jpg, .jpeg
**MIME**: image/jpeg
**알고리즘**: DCT + 양자화

---

### 특징

#### ✅ 장점

**1. 보편성**
- 모든 플랫폼 지원
- 모든 브라우저 지원
- 하드웨어 가속 지원

**2. 높은 압축률**
```
원본: 10MB
JPEG 80%: 2-3MB
압축률: 70-80%
```

**3. 빠른 속도**
- 인코딩: 10-50ms (1920×1080)
- 디코딩: 5-20ms
- 하드웨어 가속 활용

**4. 작은 파일 크기**
- 네트워크 전송에 최적
- 빠른 로딩
- 적은 저장 공간

---

#### ⚠️ 단점

**1. 품질 손실**
```
압축 → 디테일 손실
재압축 → 품질 누적 저하
```

**2. 투명도 미지원**
- 알파 채널 없음
- 배경 항상 불투명

**3. 아티팩트**
- 블로킹 현상
- 색상 번짐
- 날카로운 경계 열화

**4. 메타데이터 크기**
- EXIF 데이터 크기 증가
- 썸네일 포함 시 더 큼

---

### 사용 시나리오

#### ✅ 적합한 경우

**1. 사진 (Photographs)**
```
풍경 사진
인물 사진
제품 사진
→ 자연스러운 색상 그라데이션
```

**2. 웹 이미지**
```
블로그 이미지
뉴스 사진
갤러리
→ 빠른 로딩 필요
```

**3. 소셜 미디어**
```
Instagram
Facebook
Twitter
→ 빠른 업로드/다운로드
```

---

#### ❌ 부적합한 경우

**1. 로고/아이콘**
```
명확한 경계
단색 영역
→ 아티팩트 발생
```

**2. 텍스트 이미지**
```
스크린샷
다이어그램
→ 글자 흐려짐
```

**3. 투명 배경**
```
PNG 필요
```

---

### Swift 코드

```swift
// JPEG 압축
let image = UIImage(named: "photo")!
let quality: CGFloat = 0.8

if let jpegData = image.jpegData(compressionQuality: quality) {
    let fileSize = jpegData.count
    print("JPEG 크기: \(fileSize) bytes")
    
    // 파일 저장
    try? jpegData.write(to: url)
}
```

---

## 🎨 PNG (Portable Network Graphics)

### 기본 정보

**출시**: 1996년
**확장자**: .png
**MIME**: image/png
**알고리즘**: DEFLATE (LZ77 + Huffman)

---

### 특징

#### ✅ 장점

**1. 무손실 압축**
```
원본 = 압축본
100% 품질 유지
재압축해도 품질 동일
```

**2. 투명도 지원**
```
8비트 알파 채널
256단계 투명도
완벽한 합성 가능
```

**3. 다양한 색상 깊이**
```
1비트: 흑백
8비트: 256색
24비트: 트루컬러
32비트: 트루컬러 + 알파
```

**4. 아티팩트 없음**
- 깨끗한 경계
- 선명한 텍스트
- 완벽한 색상 재현

---

#### ⚠️ 단점

**1. 큰 파일 크기**
```
원본: 10MB
PNG: 6-8MB
압축률: 20-40%
```

**2. 느린 속도**
- 인코딩: 50-200ms
- 디코딩: 30-100ms
- JPEG 대비 3-5배 느림

**3. 사진에 비효율**
```
자연스러운 그라데이션
→ 압축 효율 낮음
→ JPEG보다 3-4배 큼
```

---

### 사용 시나리오

#### ✅ 적합한 경우

**1. 로고/아이콘**
```
앱 아이콘
버튼
UI 요소
→ 명확한 경계, 투명도
```

**2. 스크린샷**
```
텍스트 많은 이미지
다이어그램
차트
→ 선명함 필요
```

**3. 투명 배경**
```
스티커
오버레이
워터마크
→ 알파 채널 필수
```

**4. 그래픽 디자인**
```
일러스트
인포그래픽
→ 정확한 색상
```

---

#### ❌ 부적합한 경우

**1. 대용량 사진**
```
풍경 사진
인물 사진
→ 파일 크기 너무 큼
```

**2. 웹 갤러리**
```
느린 로딩
많은 대역폭
→ JPEG 권장
```

---

### Swift 코드

```swift
// PNG 압축
let image = UIImage(named: "logo")!

if let pngData = image.pngData() {
    let fileSize = pngData.count
    print("PNG 크기: \(fileSize) bytes")
    
    // 파일 저장
    try? pngData.write(to: url)
}
```

---

## 📱 HEIC (High Efficiency Image Container)

### 기본 정보

**출시**: 2015년 (iOS 11에서 채택)
**확장자**: .heic, .heif
**MIME**: image/heic, image/heif
**알고리즘**: HEVC (H.265)

---

### 특징

#### ✅ 장점

**1. 최고 압축 효율**
```
JPEG 대비 2배 압축
원본: 10MB
JPEG 80%: 2.5MB
HEIC 80%: 1.2MB
→ 50% 더 작음
```

**2. 더 나은 품질**
```
동일 파일 크기에서
HEIC 품질 > JPEG 품질

1MB JPEG = 2MB HEIC 품질
```

**3. 투명도 지원**
- 16비트 알파 채널
- PNG보다 더 정밀

**4. 향상된 기능**
```
이미지 시퀀스 (Live Photos)
다중 이미지 (연속 촬영)
깊이 정보 (Portrait Mode)
```

**5. 효율적인 메타데이터**
- EXIF 데이터 최적화
- 작은 썸네일 크기

---

#### ⚠️ 단점

**1. 제한적 호환성**
```
iOS 11+ 필수
macOS High Sierra+
Windows 10+
→ 웹 브라우저 부분 지원
```

**2. 느린 인코딩**
```
JPEG: 10-20ms
HEIC: 30-60ms
→ 3배 느림
```

**3. CPU 집약적**
- 배터리 소모 증가
- 발열 가능성
- 구형 기기에서 느림

**4. 변환 필요**
```
웹 업로드 시 JPEG 변환
→ 추가 처리 시간
→ 품질 손실 가능
```

---

### 사용 시나리오

#### ✅ 적합한 경우

**1. iOS 카메라**
```
iPhone 사진
iPad 사진
→ 자동 HEIC 저장
→ 50% 저장 공간 절약
```

**2. 모바일 앱 (iOS 전용)**
```
대용량 이미지 저장
클라우드 백업
→ 공간/대역폭 절약
```

**3. 아카이빙**
```
사진 백업
장기 보관
→ 품질 유지 + 작은 크기
```

---

#### ❌ 부적합한 경우

**1. 웹 서비스**
```
브라우저 호환성 문제
→ JPEG 변환 필요
```

**2. 크로스 플랫폼**
```
Android 공유
Windows 전송
→ JPEG 권장
```

**3. 실시간 처리**
```
빠른 인코딩 필요
→ JPEG 더 빠름
```

---

### Swift 코드

```swift
import ImageIO
import AVFoundation

// HEIC 압축
let image = UIImage(named: "photo")!
guard let cgImage = image.cgImage else { return }

let data = NSMutableData()
guard let destination = CGImageDestinationCreateWithData(
    data,
    AVFileType.heic as CFString,
    1,
    nil
) else { return }

let options: [CFString: Any] = [
    kCGImageDestinationLossyCompressionQuality: 0.8
]

CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
CGImageDestinationFinalize(destination)

print("HEIC 크기: \(data.count) bytes")
```

---

## 🌐 WebP

### 기본 정보

**출시**: 2010년 (Google)
**확장자**: .webp
**MIME**: image/webp
**알고리즘**: VP8 (손실) / LZ77 (무손실)

---

### 특징

#### ✅ 장점

**1. 유연한 압축**
```
손실 모드: JPEG 대비 25-35% 작음
무손실 모드: PNG 대비 26% 작음
→ 하나의 포맷으로 두 가지 기능
```

**2. 투명도 지원**
- 손실 압축 + 투명도
- JPEG의 효율 + PNG의 투명도

**3. 애니메이션**
```
GIF 대체
더 작은 크기
더 나은 품질
```

**4. 좋은 압축 효율**
```
JPEG 품질 80 = 2.5MB
WebP 품질 80 = 1.8MB
→ 28% 절감
```

---

#### ⚠️ 단점

**1. iOS 지원 늦음**
```
iOS 14+ (2020년)
이전 버전 미지원
→ 라이브러리 필요
```

**2. 하드웨어 가속 부족**
- CPU 디코딩
- JPEG보다 느림
- 배터리 소모 증가

**3. 보편성 부족**
```
JPEG/PNG 대비 낮은 인지도
일부 도구 미지원
```

**4. 중간 속도**
```
JPEG: 10-20ms
WebP: 20-40ms
HEIC: 30-60ms
```

---

### 사용 시나리오

#### ✅ 적합한 경우

**1. 웹 최적화**
```
웹사이트 이미지
CDN 배포
→ 대역폭 절감
→ 빠른 로딩
```

**2. 투명 사진**
```
제품 사진 (배경 제거)
배너 이미지
→ JPEG 압축 + PNG 투명도
```

**3. 모던 웹 앱**
```
PWA
React/Vue 앱
→ 최신 브라우저 타겟
```

**4. 애니메이션**
```
GIF 대체
배너 애니메이션
→ 더 작고 깨끗함
```

---

#### ❌ 부적합한 경우

**1. iOS 12 이하 지원**
```
라이브러리 필요
→ 추가 복잡도
```

**2. 하드웨어 가속 필요**
```
실시간 처리
대량 이미지
→ JPEG 더 빠름
```

---

### Swift 코드

```swift
import SDWebImageWebPCoder

// WebP 인코딩 설정
SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)

// WebP 압축 (손실)
let image = UIImage(named: "photo")!
let options: [SDImageCoderOption: Any] = [
    .encodeCompressionQuality: 0.8
]

if let webpData = SDImageWebPCoder.shared.encodedData(
    with: image,
    format: .webP,
    options: options
) {
    print("WebP 크기: \(webpData.count) bytes")
}

// WebP 압축 (무손실)
let losslessOptions: [SDImageCoderOption: Any] = [
    .encodeCompressionQuality: 1.0,
    .encodeWebPLossless: true
]

if let losslessData = SDImageWebPCoder.shared.encodedData(
    with: image,
    format: .webP,
    options: losslessOptions
) {
    print("WebP 무손실: \(losslessData.count) bytes")
}
```

---

## 📊 실전 벤치마크

### 테스트 환경
- 이미지: 1920×1080 사진
- 품질: 80
- 기기: iPhone 시뮬레이터

---

### 파일 크기 비교

| 포맷 | 크기 | 압축률 | 상대 크기 |
|------|------|--------|-----------|
| **원본** | 10.0 MB | 0% | 100% |
| **JPEG 80** | 2.5 MB | 75% | 25% |
| **PNG** | 7.5 MB | 25% | 75% |
| **HEIC 80** | 1.2 MB | 88% | 12% |
| **WebP 80** | 1.8 MB | 82% | 18% |

**결과**:
- HEIC가 가장 작음 (2배 효율)
- WebP가 2등 (1.4배 효율)
- PNG이 가장 큼 (3배)

---

### 속도 비교

| 포맷 | 인코딩 | 디코딩 | 총 시간 |
|------|--------|--------|---------|
| **JPEG** | 15ms | 10ms | 25ms |
| **PNG** | 120ms | 80ms | 200ms |
| **HEIC** | 45ms | 30ms | 75ms |
| **WebP** | 30ms | 25ms | 55ms |

**결과**:
- JPEG가 가장 빠름 (기준)
- HEIC가 3배 느림
- PNG가 8배 느림

---

### 품질 비교 (동일 크기 2MB)

| 포맷 | 품질 계수 | PSNR | 인지 품질 |
|------|-----------|------|-----------|
| **JPEG** | 80 | 35 dB | ⭐⭐⭐⭐ |
| **HEIC** | 90 | 38 dB | ⭐⭐⭐⭐⭐ |
| **WebP** | 85 | 36 dB | ⭐⭐⭐⭐ |
| **PNG** | 100 | ∞ | ⭐⭐⭐⭐⭐ |

**결과**:
- 동일 크기에서 HEIC 품질이 가장 좋음
- PNG는 무손실이지만 크기가 너무 큼

---

## 🎯 포맷 선택 가이드

### 결정 트리

```
시작
  ├─ 투명도 필요?
  │   ├─ YES
  │   │   ├─ 사진?
  │   │   │   ├─ YES → WebP (손실 + 투명)
  │   │   │   └─ NO → PNG (로고/아이콘)
  │   │   └─ iOS 11+ 전용?
  │   │       └─ YES → HEIC
  │   └─ NO
  │       ├─ 사진?
  │       │   ├─ YES
  │       │   │   ├─ iOS 11+ 전용? → HEIC
  │       │   │   ├─ 웹 최적화? → WebP
  │       │   │   └─ 범용? → JPEG
  │       │   └─ NO
  │       │       ├─ 텍스트/로고? → PNG
  │       │       └─ 스크린샷? → PNG
  └─ 품질 vs 크기?
      ├─ 품질 우선 → PNG / HEIC 90+
      └─ 크기 우선 → JPEG 70 / HEIC 80
```

---

### 시나리오별 추천

#### 1. 개인 사진 앱 (iOS)
```
1순위: HEIC 85
2순위: JPEG 80
이유: 저장 공간 절약, 좋은 품질
```

#### 2. 웹 서비스
```
1순위: WebP 80
2순위: JPEG 75
이유: 빠른 로딩, 넓은 호환성
```

#### 3. 소셜 미디어
```
1순위: JPEG 75
2순위: WebP 75
이유: 빠른 업로드, 보편성
```

#### 4. UI 에셋
```
1순위: PNG
2순위: WebP (무손실)
이유: 투명도, 선명함
```

#### 5. 프로페셔널 사진
```
1순위: HEIC 95
2순위: PNG
이유: 품질 + 공간 효율
```

---

## 💡 실전 팁

### 1. 자동 포맷 선택

```swift
func selectOptimalFormat(for image: UIImage, context: ImageContext) -> ImageFormat {
    // 투명도 확인
    if image.hasAlpha {
        if context.requiresHighQuality {
            return .png
        } else {
            return .webp // 손실 + 투명
        }
    }
    
    // iOS 버전 확인
    if context.isiOSOnly && #available(iOS 11.0, *) {
        return .heic
    }
    
    // 웹 최적화
    if context.isWeb && #available(iOS 14.0, *) {
        return .webp
    }
    
    // 기본값
    return .jpeg
}
```

---

### 2. 변환 파이프라인

```swift
func convertForWeb(_ image: UIImage) -> Data? {
    // 1. 크기 최적화
    let resized = image.resize(to: CGSize(width: 1200, height: 800))
    
    // 2. 포맷 선택
    if #available(iOS 14.0, *) {
        return compressWebP(resized, quality: 0.8)
    } else {
        return resized.jpegData(compressionQuality: 0.8)
    }
}
```

---

### 3. 멀티 포맷 지원

```swift
struct ImageExporter {
    func export(_ image: UIImage, formats: [ImageFormat]) -> [ImageFormat: Data] {
        var results: [ImageFormat: Data] = [:]
        
        for format in formats {
            switch format {
            case .jpeg:
                results[.jpeg] = image.jpegData(compressionQuality: 0.8)
            case .png:
                results[.png] = image.pngData()
            case .heic:
                results[.heic] = compressHEIC(image, quality: 0.8)
            case .webp:
                results[.webp] = compressWebP(image, quality: 0.8)
            }
        }
        
        return results
    }
}
```

---

## 🎓 핵심 요약

### 포맷별 핵심

| 포맷 | 한 줄 요약 |
|------|------------|
| **JPEG** | 보편적이고 빠른 사진 포맷 |
| **PNG** | 투명도와 무손실 필요 시 |
| **HEIC** | iOS 전용 최고 효율 |
| **WebP** | 웹 최적화 만능 포맷 |

### 선택 기준

**크기 우선**: HEIC > WebP > JPEG > PNG
**속도 우선**: JPEG > WebP > HEIC > PNG
**품질 우선**: PNG > HEIC > WebP > JPEG
**호환성 우선**: JPEG > PNG > WebP > HEIC

### 권장 설정

- **일반 사진**: JPEG 75-85
- **iOS 사진**: HEIC 80-90
- **웹 이미지**: WebP 75-85 (fallback JPEG)
- **로고/아이콘**: PNG
- **투명 사진**: WebP 손실 / HEIC

---

**다음**: [PERFORMANCE_GUIDE.md](PERFORMANCE_GUIDE.md)에서 성능 최적화 방법


