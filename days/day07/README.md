# Day 7: 미니 프로젝트 - 이미지 뷰어

> Day 1-6의 학습 내용을 통합한 종합 이미지 뷰어 미니 프로젝트

---

## 📚 학습 목표

### 핵심 목표
- **Day 1-6의 통합**: UIImage, Core Graphics, Core Image, ImageIO, SwiftUI 렌더링을 하나의 앱으로 구현
- **SwiftUI vs UIKit 비교**: 두 프레임워크의 이미지 렌더링 방식과 성능 차이를 직접 경험
- **Core Image 필터 체인**: 실시간 필터 적용 및 체인 구성
- **성능 측정**: Instruments와 os_signpost를 활용한 체계적인 성능 분석

### 학습 포인트

#### 이미지 로딩
- 다양한 포맷 지원 (JPEG, PNG, WebP)
- ImageIO를 활용한 메타데이터 추출
- 효율적인 썸네일 생성
- 메모리 캐싱 전략

#### 렌더링 비교
- SwiftUI: LazyVGrid, MagnificationGesture
- UIKit: UICollectionView, UIScrollView
- 각 프레임워크의 장단점 이해

#### 필터 처리
- Core Image 필터 체인 구성
- GPU 가속 활용
- 실시간 프리뷰 최적화

#### 성능 측정
- os_log와 os_signpost 활용
- 메모리 사용량 모니터링
- 벤치마크 자동화

---

## 🗂️ 파일 구조

```
day07/
├── README.md                           # 이 파일
├── IMAGE_VIEWER_GUIDE.md               # 뷰어 구현 가이드
├── FILTER_INTEGRATION_GUIDE.md         # 필터 통합 가이드
├── PERFORMANCE_ANALYSIS.md             # 성능 분석
├── 시작하기.md                          # 빠른 시작
│
└── day07/
    ├── ContentView.swift               # 메인 TabView
    │
    ├── Core/                           # 핵심 모듈
    │   ├── ImageLoader.swift          # 이미지 로딩 & 메타데이터
    │   ├── FilterEngine.swift         # Core Image 필터 엔진
    │   └── ImageCache.swift           # 메모리 캐시 관리
    │
    ├── Views/
    │   ├── SwiftUI/                   # SwiftUI 뷰어
    │   │   ├── GalleryGridView.swift      # 썸네일 그리드
    │   │   ├── ImageDetailView.swift      # 이미지 상세보기
    │   │   └── FilterTestView.swift       # 필터 테스트
    │   │
    │   ├── UIKit/                     # UIKit 뷰어
    │   │   ├── UIKitGalleryViewController.swift
    │   │   └── UIKitImageDetailViewController.swift
    │   │
    │   └── BenchmarkView.swift        # 성능 벤치마크
    │
    ├── tool/                          # 성능 측정 도구
    │   ├── PerformanceLogger.swift
    │   ├── MemorySampler.swift
    │   ├── SignpostHelper.swift
    │   └── BenchmarkRunner.swift
    │
    └── Assets.xcassets/
        ├── sample.imageset/           # PNG 샘플
        ├── sample2.imageset/          # PNG 샘플
        └── sample3.dataset/           # WebP 샘플 (선택)
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day07
open day07.xcodeproj
```

### 2. 샘플 이미지 준비
프로젝트에는 기본 샘플 이미지가 포함되어 있습니다. 추가 이미지를 테스트하려면:

1. Xcode에서 `Assets.xcassets` 열기
2. 새 Image Set 또는 Data Set 추가
3. 이미지 파일 드래그 & 드롭

상세한 방법은 `시작하기.md`를 참고하세요.

### 3. 앱 실행
```
⌘R (Run)
```

### 4. Instruments 연결 (성능 측정)
```
⌘I (Profile)
→ Time Profiler 또는 Logging 선택
→ 앱에서 벤치마크 실행
```

---

## 📖 사용 가이드

### Tab 1: SwiftUI 뷰어

**갤러리 그리드**
- 3열 썸네일 그리드
- LazyVGrid로 효율적 렌더링
- 포맷별 색상 뱃지 표시

**이미지 상세보기**
- 핀치 줌 (0.5x ~ 5.0x)
- 드래그로 패닝
- 더블탭으로 리셋
- 메타데이터 오버레이

```swift
// 핵심 구현
MagnificationGesture()
    .onChanged { value in
        scale *= value / lastScale
        scale = min(max(scale, 0.5), 5.0)
    }
```

### Tab 2: UIKit 뷰어

**갤러리 (UICollectionView)**
- UICollectionViewFlowLayout 기반
- 3열 그리드 레이아웃
- 셀 재사용 최적화

**이미지 상세보기 (UIScrollView)**
- UIScrollViewDelegate 기반 줌
- 더블탭 줌 in/out
- 자동 중앙 정렬

```swift
// 핵심 구현
func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
}
```

### Tab 3: 필터 테스트

**필터 체인 구성**
- 최대 3개 필터 조합
- 실시간 프리뷰
- 처리 시간 측정

**프리셋**
- 빈티지: 세피아 + 비네팅
- 드라마틱: 색상 조정 + 선명하게
- 소프트: 블러 + 색상 조정
- 강렬: 선명하게 + 색상 조정 + 비네팅

```swift
// 필터 체인 적용
let filtered = FilterEngine.shared.applyFilterChain(
    [.sepia, .vignette],
    to: ciImage
)
```

### Tab 4: 성능 벤치마크

**테스트 항목**
1. **이미지 로딩**: 포맷별 로딩 시간
2. **필터 체인**: 필터 조합별 처리 시간
3. **썸네일 생성**: 크기별 생성 시간

**측정 항목**
- 평균/최소/최대 시간
- 메모리 사용량
- 반복 횟수

---

## 🔑 핵심 개념

### 1. 이미지 로딩 파이프라인

```
Asset/URL
    ↓
ImageLoader.loadUIImage()
    ↓
메타데이터 추출 (ImageIO)
    ↓
썸네일 생성 (선택)
    ↓
캐싱 (ImageCache)
    ↓
렌더링 (SwiftUI/UIKit)
```

### 2. 필터 체인 처리

```
원본 CIImage
    ↓
FilterEngine.applyFilterChain()
    ↓
필터 1 → 필터 2 → 필터 3
    ↓
CIContext.createCGImage()
    ↓
UIImage 변환
    ↓
화면 표시
```

### 3. 성능 측정 흐름

```
Signpost.begin()
    ↓
작업 수행
    ↓
Signpost.end()
    ↓
PerformanceLogger.log()
    ↓
Instruments/Console.app
```

---

## 💡 핵심 기법

### SwiftUI 줌/패닝

```swift
Image(uiImage: image)
    .scaleEffect(scale)
    .offset(offset)
    .gesture(MagnificationGesture()...)
    .gesture(DragGesture()...)
```

**장점**:
- 선언적 구문
- 애니메이션 쉬움
- 코드 간결

**단점**:
- 세밀한 제어 어려움
- 관성 스크롤 없음

### UIKit 줌/패닝

```swift
scrollView.minimumZoomScale = 0.5
scrollView.maximumZoomScale = 5.0

func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
}
```

**장점**:
- 네이티브 스크롤 동작
- 정교한 제어 가능
- 관성 스크롤 지원

**단점**:
- 코드 복잡
- 수동 레이아웃 관리

### 필터 체인 최적화

```swift
// CIContext 재사용 (중요!)
private let context: CIContext = {
    CIContext(options: [
        .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
        .cacheIntermediates: true,    // 중간 결과 캐싱
        .useSoftwareRenderer: false   // GPU 사용
    ])
}()
```

### 메모리 캐싱

```swift
// NSCache 활용
private let cache = NSCache<NSString, UIImage>()
cache.totalCostLimit = 100 * 1024 * 1024  // 100MB

// 비용 기반 캐싱
let cost = estimateImageSize(image)
cache.setObject(image, forKey: key, cost: cost)
```

---

## 📊 성능 비교 (예상치)

### 로딩 시간

| 포맷 | 크기 | 로딩 시간 | 메모리 |
|------|------|----------|--------|
| PNG | 2000x1500 | ~15ms | ~11MB |
| JPEG | 2000x1500 | ~8ms | ~11MB |
| WebP | 2000x1500 | ~12ms | ~11MB |

### 렌더링 성능

| 구현 | 스크롤 FPS | 줌 FPS | 메모리 |
|------|-----------|--------|--------|
| SwiftUI | 60fps | 60fps | ~15MB |
| UIKit | 60fps | 60fps | ~12MB |

### 필터 처리 시간

| 필터 조합 | 처리 시간 | GPU 사용 |
|----------|----------|---------|
| 블러 | ~20ms | ✅ |
| 세피아 | ~5ms | ✅ |
| 세피아 + 비네팅 | ~12ms | ✅ |
| 색상 + 선명 + 비네팅 | ~25ms | ✅ |

*실제 성능은 기기와 이미지 크기에 따라 다를 수 있습니다.*

---

## 🎯 학습 체크리스트

### 기본
- [ ] SwiftUI 갤러리 구현 이해
- [ ] UIKit 갤러리 구현 이해
- [ ] 줌/패닝 제스처 구현
- [ ] Core Image 필터 적용

### 응용
- [ ] 필터 체인 구성
- [ ] 메타데이터 추출 및 표시
- [ ] 썸네일 캐싱
- [ ] UIViewControllerRepresentable 활용

### 심화
- [ ] os_signpost 활용
- [ ] 메모리 프로파일링
- [ ] SwiftUI vs UIKit 성능 비교
- [ ] 필터 체인 최적화

---

## 🔍 Instruments 활용

### Time Profiler
1. ⌘I로 Profiling 시작
2. Time Profiler 선택
3. 앱에서 스크롤/줌 수행
4. Call Tree에서 핫스팟 확인

### Logging (os_signpost)
1. ⌘I로 Profiling 시작
2. Logging 템플릿 선택
3. 앱에서 벤치마크 실행
4. Points of Interest 확인

**주요 signpost**:
- `Image_Load`: 이미지 로딩
- `Image_Render`: 렌더링
- `Filter_Apply`: 필터 적용
- `Thumbnail_Generate`: 썸네일 생성

---

## 📚 참고 자료

### 이전 학습 내용
- **Day 1**: UIImage vs SwiftUI Image
- **Day 2**: Core Graphics 렌더링
- **Day 3**: Core Image 필터링
- **Day 4**: ImageIO & EXIF
- **Day 5**: 포맷 변환 & 리사이징
- **Day 6**: SwiftUI 렌더링 옵션

### Apple 문서
- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html)
- [UIScrollView](https://developer.apple.com/documentation/uikit/uiscrollview)
- [Using Signposts](https://developer.apple.com/documentation/os/logging/recording_performance_data)

---

## 🐛 문제 해결

### WebP 이미지가 로드되지 않음
- iOS 14+ 기본 지원 확인
- 또는 SDWebImage 라이브러리 추가 필요

### 필터 적용이 느림
- CIContext 재사용 확인
- GPU 렌더러 활성화 확인
- 이미지 크기 확인 (너무 크면 리사이징)

### 메모리 부족
- 캐시 크기 제한 확인
- 썸네일 사이즈 조정
- 메모리 워닝 시 캐시 정리

---

## 🎓 다음 단계

Day 7을 완료했다면:

1. **실제 프로젝트 적용**: 학습한 내용을 자신의 앱에 적용
2. **추가 기능 구현**: 
   - 사진 라이브러리 통합
   - 커스텀 필터 제작
   - 비디오 필터링
3. **성능 극한 최적화**: Metal 직접 활용

---

**Happy Coding! 🎨**

*이미지 처리의 전체 파이프라인을 마스터하셨습니다!*

