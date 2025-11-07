# 이미지 압축 이론

> 이미지 압축의 기본 원리와 알고리즘을 이해한다

---

## 📚 압축의 기본 개념

### 압축이란?

**압축(Compression)**: 데이터의 크기를 줄여 저장 공간과 전송 시간을 절약하는 기술

```
원본 이미지 (10MB)
    ↓ 압축
압축된 이미지 (2MB)
    ↓ 80% 절감
```

### 왜 압축이 필요한가?

#### 1. 저장 공간 절약
- iPhone 사진: 평균 3-5MB
- 100장 = 300-500MB
- 압축 시: 60-100MB (80% 절감)

#### 2. 네트워크 전송 속도
- 10MB 이미지: 4G에서 5-10초
- 2MB 이미지: 4G에서 1-2초
- **5배 빠른 로딩**

#### 3. 사용자 경험
- 빠른 페이지 로드
- 적은 데이터 사용량
- 배터리 절약

---

## 🔬 압축의 두 가지 방식

### 1. 손실 압축 (Lossy Compression)

**원리**: 사람이 인지하기 어려운 데이터를 제거

**특징**:
- ✅ 높은 압축률 (80-95%)
- ✅ 작은 파일 크기
- ⚠️ 품질 손실
- ⚠️ 복원 불가능

**대표 포맷**:
- JPEG
- HEIC
- WebP (손실 모드)

**사용 예**:
- 웹 이미지
- 소셜 미디어
- 일반 사진

---

### 2. 무손실 압축 (Lossless Compression)

**원리**: 데이터를 완벽하게 보존하면서 중복 제거

**특징**:
- ✅ 품질 손실 없음
- ✅ 완벽한 복원
- ⚠️ 낮은 압축률 (20-50%)
- ⚠️ 큰 파일 크기

**대표 포맷**:
- PNG
- WebP (무손실 모드)

**사용 예**:
- 로고, 아이콘
- 투명도가 필요한 이미지
- 의료 영상

---

## 🎨 손실 압축 알고리즘

### JPEG 압축 원리

#### 1. 색 공간 변환 (RGB → YCbCr)

```
RGB 색 공간
├─ R: Red (빨강)
├─ G: Green (초록)
└─ B: Blue (파랑)

YCbCr 색 공간
├─ Y: 밝기 (Luminance)
├─ Cb: 파랑-밝기 차이
└─ Cr: 빨강-밝기 차이
```

**왜?**: 인간의 눈은 색상보다 밝기에 민감
- Y는 높은 해상도 유지
- Cb, Cr은 낮은 해상도로 다운샘플링

---

#### 2. DCT (Discrete Cosine Transform)

**이산 코사인 변환**: 이미지를 주파수 영역으로 변환

```
8x8 픽셀 블록
    ↓ DCT
주파수 계수 행렬
    ↓
저주파 (중요)    고주파 (덜 중요)
   ↓                 ↓
  유지             제거/감소
```

**효과**:
- 저주파: 이미지의 전체적인 형태
- 고주파: 미세한 디테일 (제거해도 인지 어려움)

---

#### 3. 양자화 (Quantization)

**핵심 압축 단계**: 정밀도를 낮춰 데이터 크기 감소

```
원본 계수: 157.3, 142.8, 135.2
    ↓ 양자화 (품질 70)
양자화 계수: 157, 143, 135
    ↓ 더 높은 양자화 (품질 50)
양자화 계수: 160, 140, 140
```

**품질 계수**:
- 100: 최소 양자화 (최고 품질)
- 50: 중간 양자화 (균형)
- 10: 최대 양자화 (최저 품질)

---

#### 4. 허프만 인코딩 (Huffman Encoding)

**무손실 압축**: 빈번한 값을 짧은 비트로 표현

```
값      빈도    허프만 코드
0       많음    0
1       보통    10
2       적음    110
3       매우적음 111
```

---

### HEIC/HEVC 압축 원리

**H.265/HEVC 기반**: 비디오 압축 기술 응용

#### 주요 차이점

| 특징 | JPEG | HEIC |
|------|------|------|
| 블록 크기 | 8x8 고정 | 4x4 ~ 64x64 가변 |
| 예측 | 없음 | 33가지 방향 예측 |
| 압축률 | 기준 | 2배 개선 |
| 품질 | 기준 | 더 좋음 |

#### 핵심 기술

**1. 더 큰 블록 크기**
```
JPEG: 8x8
HEIC: 최대 64x64
→ 더 효율적인 압축
```

**2. 인트라 예측**
```
현재 블록을 주변 블록으로 예측
→ 차이만 저장
→ 데이터 양 감소
```

**3. 향상된 변환**
```
DCT 대신 여러 변환 사용
→ 각 블록에 최적 변환 선택
```

---

## 📦 무손실 압축 알고리즘

### PNG 압축 원리

#### 1. 필터링

**5가지 필터**:

```
None:    원본 그대로
Sub:     왼쪽 픽셀과의 차이
Up:      위 픽셀과의 차이
Average: 왼쪽+위 평균과의 차이
Paeth:   복잡한 예측
```

**목적**: 중복 데이터를 더 압축하기 쉽게 변환

---

#### 2. DEFLATE 압축

**LZ77 + 허프만 조합**:

```
원본: AAAAABBBBB
    ↓ LZ77 (반복 찾기)
압축: A(5)B(5)
    ↓ 허프만 (빈도 기반)
최종: 0101 1010
```

---

### WebP 압축 원리

**유연한 압축**: 손실/무손실 모두 지원

#### 손실 모드
```
VP8 비디오 코덱 기반
→ JPEG와 유사하지만 더 효율적
→ 25-35% 작은 파일 크기
```

#### 무손실 모드
```
예측 변환 + LZ77
→ PNG보다 26% 작은 파일
```

---

## 📊 압축률과 품질의 관계

### 품질 곡선

```
파일 크기
  ↑
  |     ●  품질 100 (10MB)
  |    ●   품질 90 (5MB)
  |   ●    품질 80 (3MB)  ← 최적점
  | ●      품질 70 (2MB)
  |●       품질 50 (1MB)
  +------------------→ 품질
                인지 품질 →
```

### Sweet Spot (최적점)

**품질 75-85**:
- 압축률: 60-70%
- 인지 품질: 거의 동일
- **권장 설정**

---

## 🔢 압축 수치 이해

### 압축률 (Compression Ratio)

```
압축률 = (1 - 압축후 / 원본) × 100%

예시:
원본: 10MB
압축: 2MB
압축률 = (1 - 2/10) × 100% = 80%
```

### PSNR (Peak Signal-to-Noise Ratio)

**품질 측정 지표**: 원본과 압축본의 차이

```
PSNR (dB)    품질
> 40         거의 인지 불가
30-40        약간 인지 가능
< 30         명확한 품질 저하
```

---

## 🎯 iOS 압축 API

### UIImage 압축

#### JPEG 압축

```swift
let image = UIImage(named: "photo")!
let quality: CGFloat = 0.8 // 80%

if let jpegData = image.jpegData(compressionQuality: quality) {
    print("압축 후: \(jpegData.count) bytes")
}
```

**품질 계수**:
- `1.0`: 최고 품질 (최소 압축)
- `0.8`: 권장 (균형)
- `0.5`: 낮은 품질 (높은 압축)

---

#### PNG 압축

```swift
let image = UIImage(named: "logo")!

if let pngData = image.pngData() {
    print("PNG 크기: \(pngData.count) bytes")
}
```

**특징**:
- 품질 옵션 없음 (무손실)
- 자동 최적 압축

---

### ImageIO 압축

#### HEIC 압축

```swift
import ImageIO
import AVFoundation

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

## 🧪 압축 효율 비교

### 동일 품질 기준

| 포맷 | 파일 크기 | 압축률 | 속도 |
|------|-----------|--------|------|
| **JPEG** | 2.0 MB | 기준 | 빠름 ⚡⚡⚡ |
| **HEIC** | 1.0 MB | 2배 | 보통 ⚡⚡ |
| **WebP** | 1.6 MB | 1.25배 | 보통 ⚡⚡ |
| **PNG** | 8.0 MB | 0.25배 | 느림 ⚡ |

---

### 품질별 크기 변화 (JPEG 기준)

| 품질 | 파일 크기 | 압축률 | 인지 품질 |
|------|-----------|--------|-----------|
| 100 | 10.0 MB | 0% | ★★★★★ |
| 90 | 4.5 MB | 55% | ★★★★★ |
| 80 | 2.8 MB | 72% | ★★★★☆ |
| 70 | 2.0 MB | 80% | ★★★★☆ |
| 50 | 1.2 MB | 88% | ★★★☆☆ |
| 30 | 0.8 MB | 92% | ★★☆☆☆ |

---

## 💡 실전 압축 전략

### 용도별 권장 설정

#### 1. 웹 이미지
```
포맷: JPEG / WebP
품질: 75-85
목표: 빠른 로딩
```

#### 2. 모바일 앱
```
포맷: HEIC (iOS 11+)
품질: 80-90
목표: 저장 공간 절약
```

#### 3. 소셜 미디어
```
포맷: JPEG
품질: 70-80
목표: 빠른 업로드
```

#### 4. 프로페셔널 사진
```
포맷: HEIC / PNG
품질: 90-100
목표: 품질 유지
```

---

## 🔍 압축 아티팩트

### JPEG 아티팩트

#### 1. 블로킹 (Blocking)
```
8x8 블록 경계가 보임
원인: 과도한 양자화
해결: 품질 70 이상 사용
```

#### 2. 링잉 (Ringing)
```
날카로운 경계 주변 번짐
원인: 고주파 정보 손실
해결: 품질 80 이상
```

#### 3. 색상 번짐
```
색상 경계가 부드럽게 번짐
원인: 크로마 서브샘플링
해결: 고품질 설정
```

---

## 📈 최적화 팁

### 1. 다운샘플링 + 압축

```swift
// 먼저 크기 줄이기
let targetSize = CGSize(width: 1920, height: 1080)
UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
image.draw(in: CGRect(origin: .zero, size: targetSize))
let resized = UIGraphicsGetImageFromCurrentImageContext()
UIGraphicsEndImageContext()

// 그 다음 압축
let jpegData = resized?.jpegData(compressionQuality: 0.8)
```

**효과**: 크기와 품질 모두 최적화

---

### 2. 포맷 자동 선택

```swift
func optimizeImage(_ image: UIImage) -> Data? {
    // 투명도 확인
    if image.hasAlpha {
        return image.pngData() // PNG
    }
    
    // iOS 버전 확인
    if #available(iOS 11.0, *) {
        return compressHEIC(image, quality: 0.8)
    } else {
        return image.jpegData(compressionQuality: 0.8)
    }
}
```

---

### 3. 배치 처리

```swift
func compressImages(_ images: [UIImage]) async -> [Data] {
    await withTaskGroup(of: Data?.self) { group in
        for image in images {
            group.addTask {
                return image.jpegData(compressionQuality: 0.8)
            }
        }
        
        var results: [Data] = []
        for await data in group {
            if let data = data {
                results.append(data)
            }
        }
        return results
    }
}
```

---

## 🎓 핵심 요약

### 압축 방식
- **손실**: 높은 압축률, 품질 손실 (JPEG, HEIC, WebP)
- **무손실**: 낮은 압축률, 품질 유지 (PNG)

### 알고리즘
- **JPEG**: DCT + 양자화 (가장 보편적)
- **HEIC**: HEVC 기반 (2배 효율)
- **PNG**: DEFLATE (무손실)
- **WebP**: 유연함 (손실/무손실)

### 권장 설정
- **일반 사진**: JPEG 품질 75-85
- **iOS 전용**: HEIC 품질 80-90
- **로고/아이콘**: PNG
- **웹 최적화**: WebP

### 최적화
1. 다운샘플링 먼저
2. 적절한 품질 선택 (80 권장)
3. 용도에 맞는 포맷 선택
4. 배치 처리로 성능 향상

---

**다음**: [FORMAT_COMPARISON.md](FORMAT_COMPARISON.md)에서 포맷별 상세 비교


