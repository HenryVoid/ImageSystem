# Day 4: Image I/O로 EXIF 읽기

> EXIF 메타데이터를 효율적으로 읽고 활용하는 방법을 학습합니다

---

## 📚 학습 목표

### 핵심 목표
- **EXIF의 구조와 주요 항목을 이해**한다
- **Image I/O가 어떤 프레임워크인지 파악**한다
- GPS 태그를 활용하여 지도에 위치 표시하기

### 학습 포인트

#### EXIF란?
**Exchangeable Image File Format** - 이미지 메타데이터 표준
- 카메라 모델, GPS, 셔터속도, 조리개, ISO, 촬영일자 등 포함
- JPEG, HEIF, TIFF 등 다양한 포맷에서 지원

#### iOS에서 EXIF 접근 경로
- **ImageIO 프레임워크** (`CGImageSource`)
- **CoreLocation**과 함께 GPS 태그를 활용 가능
- UIImage보다 **수천 배 메모리 효율적**

---

## 🗂️ 파일 구조

```
day04/
├── IMAGE_IO_THEORY.md          # 이론 설명
├── EXIF_GUIDE.md               # EXIF 활용 가이드
├── PERFORMANCE_GUIDE.md        # 성능 최적화 가이드
├── README.md                   # 이 파일
│
└── day04/
    ├── ContentView.swift       # 메인 네비게이션
    │
    ├── Core/                   # 핵심 로직
    │   ├── EXIFReader.swift        # EXIF 읽기 메인
    │   └── MetadataParser.swift    # 통합 메타데이터 파서
    │
    ├── Views/                  # 학습 뷰
    │   ├── BasicEXIFView.swift     # 기본 EXIF 정보
    │   ├── DetailedEXIFView.swift  # 상세 메타데이터
    │   ├── PhotoLibraryView.swift  # 사진 라이브러리 연동
    │   ├── GPSLocationView.swift   # GPS 지도 표시
    │   └── BenchmarkView.swift     # 성능 벤치마크
    │
    ├── tool/                   # 성능 측정 도구
    │   ├── PerformanceLogger.swift
    │   ├── MemorySampler.swift
    │   └── SignpostHelper.swift
    │
    └── Assets.xcassets/
        └── sample-exif.imageset/   # EXIF 포함 샘플 이미지
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day04
open day04.xcodeproj
```

### 2. 샘플 이미지 추가
⚠️ **중요**: EXIF 데이터가 포함된 샘플 이미지가 필요합니다.

#### 방법 1: 직접 촬영한 사진 사용
1. iPhone 카메라 앱으로 사진 촬영 (위치 서비스 켜기)
2. 사진을 Mac으로 AirDrop
3. Xcode에서 `Assets.xcassets` 열기
4. `sample-exif.imageset` 생성
5. 사진을 드래그 앤 드롭

#### 방법 2: 테스트 이미지 생성
```swift
// EXIF가 없는 경우 앱이 정상 작동하지만
// GPS 기능은 테스트할 수 없습니다
```

### 3. 앱 실행
```
⌘R (Run)
```

---

## 📖 학습 순서

### 📚 1단계: 이론 학습
먼저 이론 문서를 읽어보세요:

1. **IMAGE_IO_THEORY.md** 읽기
   - EXIF 기초
   - Image I/O 프레임워크
   - 핵심 API

### 👨‍💻 2단계: 기본 실습

#### BasicEXIFView
- 샘플 이미지에서 EXIF 읽기
- 카메라 정보, 촬영 설정 표시
- `EXIFReader` 사용법 익히기

```swift
// 핵심 코드
let exifData = EXIFReader.loadEXIFData(from: url)
print(exifData?.cameraMake)        // "Apple"
print(exifData?.formattedISO)      // "ISO 200"
print(exifData?.formattedAperture) // "f/1.8"
```

#### DetailedEXIFView
- EXIF, TIFF, GPS 섹션별 탐색
- 모든 메타데이터 항목 확인
- 각 필드의 의미 이해

### 🚀 3단계: 실전 응용

#### PhotoLibraryView
- PhotosUI로 사진 선택
- 실제 기기 사진에서 EXIF 읽기
- 다양한 카메라 모델 데이터 확인

#### GPSLocationView
- GPS 태그 파싱
- MapKit으로 촬영 위치 표시
- CoreLocation 좌표 변환

```swift
// GPS 좌표 추출
if let coordinate = exifData?.coordinate {
    print("위도: \(coordinate.latitude)")
    print("경도: \(coordinate.longitude)")
}
```

### ⚡ 4단계: 성능 실험

#### BenchmarkView
- Image I/O vs UIImage 성능 비교
- 메모리 사용량 측정
- 썸네일 생성 효율성 확인

**예상 결과**:
- EXIF 읽기: ~1ms, ~10KB 메모리
- UIImage 로드: ~100ms, ~48MB 메모리
- 성능 차이: **100배 빠르고 4,800배 메모리 절약**

---

## 🔑 핵심 개념

### 1. CGImageSource
이미지 파일에서 데이터를 읽는 객체

```swift
// 생성
let source = CGImageSourceCreateWithURL(url as CFURL, nil)

// 메타데이터 추출
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)

// EXIF 딕셔너리
let exif = properties[kCGImagePropertyExifDictionary]
```

### 2. 주요 딕셔너리

```swift
kCGImagePropertyExifDictionary   // 촬영 설정 (ISO, 조리개, 셔터)
kCGImagePropertyTIFFDictionary   // 카메라 정보 (제조사, 모델)
kCGImagePropertyGPSDictionary    // GPS 위치 (위도, 경도, 고도)
kCGImagePropertyIPTCDictionary   // 저작권, 키워드
```

### 3. 썸네일 생성

```swift
let options: [CFString: Any] = [
    kCGImageSourceThumbnailMaxPixelSize: 200,
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceCreateThumbnailWithTransform: true
]

let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
```

---

## 💡 실무 활용

### 갤러리 앱
- 썸네일 그리드 고속 생성
- EXIF 정보 표시
- 날짜/카메라별 정렬

### 사진 편집 앱
- 메타데이터 보존
- GPS 제거 (개인정보 보호)
- 저작권 추가

### 위치 기반 앱
- GPS 태그로 지도에 표시
- 촬영 위치 역지오코딩
- 여행 경로 추적

### 카메라 앱
- 커스텀 메타데이터 추가
- 촬영 설정 로그
- RAW + JPEG 동시 처리

---

## 📊 성능 비교

| 작업 | UIImage | Image I/O | 차이 |
|-----|---------|-----------|------|
| 메타데이터만 | 48MB | 10KB | 4,800배 |
| 썸네일 200px | 48MB | 150KB | 320배 |
| 시간 (EXIF) | ~100ms | ~1ms | 100배 빠름 |

**결론**: 메타데이터만 필요하면 **반드시 Image I/O 사용**

---

## 🔍 디버깅 팁

### EXIF가 없는 경우
```swift
// 원인:
// 1. 스크린샷 (EXIF 없음)
// 2. 편집된 이미지 (제거됨)
// 3. Assets에서 로드 (UIImage는 EXIF 손실)

// 해결:
// - 번들 URL 직접 사용
let url = Bundle.main.url(forResource: "photo", withExtension: "jpg")
let exif = EXIFReader.loadEXIFData(from: url!)
```

### GPS가 없는 경우
```swift
// 원인:
// 1. 위치 서비스 꺼짐
// 2. 카메라 앱에 위치 권한 없음
// 3. 개인정보 보호로 제거됨

// 테스트:
// - 기본 카메라로 촬영 (위치 서비스 켜기)
// - 사진 앱에서 "위치" 정보 확인
```

### Console.app으로 로그 확인
```bash
1. Console.app 실행
2. 시뮬레이터/기기 선택
3. "com.study.day04" 검색
4. PerformanceLogger 로그 확인
```

---

## 🎯 학습 체크리스트

### 기본
- [ ] EXIF가 무엇인지 설명할 수 있다
- [ ] Image I/O와 UIImage의 차이를 안다
- [ ] CGImageSource로 메타데이터를 읽을 수 있다
- [ ] 주요 EXIF 태그 10개를 안다

### 응용
- [ ] 사진 라이브러리에서 EXIF를 읽을 수 있다
- [ ] GPS 좌표를 지도에 표시할 수 있다
- [ ] 썸네일을 효율적으로 생성할 수 있다
- [ ] EXIF를 수정/제거할 수 있다

### 심화
- [ ] 성능 벤치마크를 이해한다
- [ ] Instruments로 성능을 측정할 수 있다
- [ ] 백그라운드 처리를 구현할 수 있다
- [ ] 메모리 최적화 기법을 적용할 수 있다

---

## 📚 참고 자료

### Apple 공식 문서
- [Image I/O Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/)
- [CGImageSource](https://developer.apple.com/documentation/imageio/cgimagesource)
- [CGImageProperties](https://developer.apple.com/documentation/imageio/cgimageproperties)

### EXIF 표준
- [EXIF 2.32 Specification](http://www.cipa.jp/std/documents/e/DC-008-Translation-2019-E.pdf)
- [Metadata Working Group Guidelines](http://www.metadataworkinggroup.org/pdf/mwg_guidance.pdf)

### 튜토리얼
- `IMAGE_IO_THEORY.md` - 이론 정리
- `EXIF_GUIDE.md` - 실무 활용 가이드
- `PERFORMANCE_GUIDE.md` - 성능 최적화

---

## 🐛 알려진 이슈

### iOS 시뮬레이터
- 카메라 앱이 없어 직접 촬영 불가
- AirDrop으로 실제 사진 전송 필요

### PhotosUI
- iOS 16+ 필요
- 이전 버전은 PHPickerViewController 사용

---

## 🎓 다음 단계

Image I/O를 마스터했다면:

1. **Day 5**: Metal로 이미지 처리
2. **Day 6**: Vision으로 객체 인식
3. **Day 7**: Core ML로 이미지 분류

---

## 💬 질문 & 피드백

학습 중 궁금한 점이 있다면:
- 각 View의 코드 주석 확인
- 가이드 문서 참고
- Apple 공식 문서 읽기

---

**Happy Learning! 📸**

*EXIF 메타데이터로 더 똑똑한 사진 앱을 만들어보세요!*


