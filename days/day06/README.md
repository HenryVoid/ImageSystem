# Day 6: SwiftUI 이미지 렌더링 옵션

> SwiftUI Image의 다양한 렌더링 옵션을 실습하고 성능 특성을 이해합니다

---

## 📚 학습 목표

### 핵심 목표
- SwiftUI Image의 **렌더링 모드**를 정확히 이해한다
- **resizable()**, **aspectRatio()**, **interpolation()**, **renderingMode()** 등을 실습으로 익힌다
- 실제 기기에서 **Retina/Non-Retina** 해상도 차이와 interpolation 효과를 눈으로 확인한다
- 다양한 렌더링 옵션의 **성능 차이**를 측정한다

### 학습 포인트

#### 렌더링 옵션
- **resizable()**: 이미지 크기 조정 활성화
- **aspectRatio()**: 비율 유지 방법 (.fit vs .fill)
- **interpolation()**: 보간 품질 (.none, .low, .medium, .high)
- **renderingMode()**: 원본 색상 vs 템플릿
- **antialiased()**: 안티앨리어싱 제어

#### 성능 고려사항
- 각 옵션의 렌더링 비용
- Retina 디스플레이 최적화
- 스크롤 성능
- 메모리 효율

---

## 🗂️ 파일 구조

```
day06/
├── SWIFTUI_IMAGE_THEORY.md          # SwiftUI Image 기본 개념
├── RENDERING_MODE_GUIDE.md          # 렌더링 옵션 상세 가이드
├── PERFORMANCE_GUIDE.md             # 성능 최적화
├── README.md                        # 이 파일
├── 시작하기.md                      # 빠른 시작 가이드
│
└── day06/
    ├── ContentView.swift            # 메인 네비게이션
    │
    ├── Core/                        # 핵심 로직
    │   ├── RenderingModeHelper.swift      # 렌더링 모드 헬퍼
    │   ├── InterpolationHelper.swift      # 보간 품질 헬퍼
    │   └── ImageSizeCalculator.swift      # 크기 계산 유틸
    │
    ├── Views/                       # 학습 뷰
    │   ├── RenderingModeComparisonView.swift   # 렌더링 모드 비교
    │   ├── InterpolationQualityView.swift      # 보간 품질 비교
    │   ├── AspectRatioTestView.swift           # Aspect Ratio 테스트
    │   ├── ResizableOptionsView.swift          # Resizable 옵션
    │   └── PerformanceBenchmarkView.swift      # 성능 벤치마크
    │
    ├── tool/                        # 성능 측정 도구
    │   ├── PerformanceLogger.swift
    │   ├── MemorySampler.swift
    │   └── SignpostHelper.swift
    │
    └── Assets.xcassets/
        └── sample.imageset/         # 샘플 이미지
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day06
open day06.xcodeproj
```

### 2. 샘플 이미지 준비
⚠️ **중요**: 고해상도 이미지 필요 (2000 × 1500 이상)

상세한 준비 방법은 `시작하기.md`를 참고하세요.

### 3. 앱 실행
```
⌘R (Run)
```

---

## 📖 학습 순서

### 📚 1단계: 이론 학습 (약 30분)

#### SWIFTUI_IMAGE_THEORY.md 읽기
- SwiftUI Image vs UIImage 차이
- View 프로토콜로서의 Image
- 렌더링 파이프라인
- Lazy Loading 개념

**핵심 개념**:
```swift
// SwiftUI Image는 값 타입 (struct)
let image = Image("sample")  // View 프로토콜

// 선언적 API
Image("photo")
    .resizable()              // 크기 조정 가능
    .aspectRatio(contentMode: .fit)  // 비율 유지
    .frame(width: 300)        // 크기 지정
```

#### RENDERING_MODE_GUIDE.md 읽기
- resizable() 동작 원리
- aspectRatio() 사용법
- interpolation 품질 비교
- renderingMode 활용
- antialiased 효과

**핵심 개념**:
```swift
// 기본: 원본 크기 고정
Image("photo")  // resizable() 없음

// resizable() 후 크기 조정 가능
Image("photo")
    .resizable()
    .frame(width: 200, height: 200)
```

### 👨‍💻 2단계: 렌더링 모드 실습 (약 15분)

#### RenderingModeComparisonView
.original vs .template 시각적 비교:

```swift
// 원본 색상 유지
Image(systemName: "star.fill")
    .renderingMode(.original)

// 템플릿 모드 (틴트 적용)
Image(systemName: "star.fill")
    .renderingMode(.template)
    .foregroundStyle(.blue)
```

**학습 포인트**:
- SF Symbols 활용
- Tint color 적용
- 다크 모드 대응

### 🎨 3단계: 보간 품질 실습 (약 15분)

#### InterpolationQualityView
작은 이미지를 크게 확대하여 보간 품질 비교:

```swift
// .none - 픽셀 아트 스타일
Image("small-icon")
    .resizable()
    .interpolation(.none)
    .frame(width: 200, height: 200)

// .high - 최고 품질
Image("small-icon")
    .resizable()
    .interpolation(.high)
    .frame(width: 200, height: 200)
```

**측정 항목**:
- 시각적 품질 차이
- 렌더링 시간
- 적합한 사용 사례

### 📐 4단계: Aspect Ratio 실습 (약 15분)

#### AspectRatioTestView
.fit vs .fill 비교:

```swift
// .fit - 이미지 전체가 보임
Image("landscape")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 300, height: 200)

// .fill - 영역을 꽉 채움
Image("landscape")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 300, height: 200)
    .clipped()  // 넘친 부분 자르기
```

**학습 포인트**:
- 비율 유지 방법
- clipped() 필요성
- frame과의 관계

### 🔧 5단계: Resizable 옵션 실습 (약 15분)

#### ResizableOptionsView
resizable() 유무 및 capInsets 활용:

```swift
// 기본 (resizable 없음)
Image("button-bg")
    .frame(width: 300, height: 60)
// 원본 크기 유지

// resizable + capInsets (9-patch)
Image("button-bg")
    .resizable(capInsets: EdgeInsets(
        top: 10, leading: 10, bottom: 10, trailing: 10
    ))
    .frame(width: 300, height: 60)
// 가장자리는 고정, 중앙만 늘어남
```

**학습 포인트**:
- resizable() 필요성
- capInsets를 활용한 9-patch
- resizingMode (.stretch, .tile)

### ⚡ 6단계: 성능 벤치마크 (약 20분)

#### PerformanceBenchmarkView
다양한 옵션 조합의 렌더링 성능 측정:

```swift
// 성능 비교
let options: [(String, Image.Interpolation)] = [
    ("None", .none),
    ("Low", .low),
    ("Medium", .medium),
    ("High", .high)
]

for (name, interpolation) in options {
    let time = measure {
        renderImage(with: interpolation)
    }
    print("\(name): \(time)ms")
}
```

**측정 항목**:
- 렌더링 시간
- 메모리 사용량
- FPS (스크롤 테스트)

**예상 결과**:
```
None:   15ms  ⚡ 가장 빠름
Low:    25ms  ⚡ 빠름
Medium: 45ms  🔶 기본
High:   120ms 🔴 느림
```

### 📘 7단계: 성능 가이드 읽기 (약 15분)

#### PERFORMANCE_GUIDE.md 읽기
- 성능 측정 기초
- 메모리 최적화
- 렌더링 속도 최적화
- 실기기 테스트 방법

**핵심 패턴**:
```swift
// ✅ 고성능 이미지 그리드
ScrollView {
    LazyVStack {  // Lazy 사용
        ForEach(images) { img in
            Image(img)
                .resizable()
                .interpolation(.medium)  // 균형
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
        }
    }
}
```

---

## 🔑 핵심 개념

### 1. resizable()

기본적으로 Image는 **원본 크기 고정**:

```swift
// ❌ 원본 크기 유지
Image("photo")
    .frame(width: 200, height: 200)

// ✅ 크기 조정 가능
Image("photo")
    .resizable()
    .frame(width: 200, height: 200)
```

### 2. aspectRatio()

비율 유지 방법:

```swift
// .fit - 내부에 맞춤 (여백 생김)
.aspectRatio(contentMode: .fit)

// .fill - 꽉 채움 (잘림)
.aspectRatio(contentMode: .fill)
    .clipped()  // 필수!
```

### 3. interpolation()

보간 품질:

```swift
// 픽셀 아트
.interpolation(.none)

// 일반 사진
.interpolation(.medium)  // 기본값

// 고품질 필요 시
.interpolation(.high)
```

### 4. renderingMode()

색상 모드:

```swift
// 원본 색상
.renderingMode(.original)

// 템플릿 (틴트 적용)
.renderingMode(.template)
    .foregroundStyle(.blue)
```

---

## 💡 실무 활용

### 프로필 이미지

```swift
struct ProfileImage: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
    }
}
```

### 썸네일 그리드

```swift
struct ThumbnailGrid: View {
    let images: [String]
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(images, id: \.self) { img in
                    Image(img)
                        .resizable()
                        .interpolation(.medium)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}
```

### 아이콘 버튼

```swift
struct IconButton: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Button {
            // action
        } label: {
            Image(systemName: systemName)
                .renderingMode(.template)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())
        }
    }
}
```

### 픽셀 아트

```swift
struct PixelArt: View {
    let spriteName: String
    
    var body: some View {
        Image(spriteName)
            .resizable()
            .interpolation(.none)      // 픽셀 보존
            .antialiased(false)        // 선명함
            .frame(width: 128, height: 128)
    }
}
```

---

## 📊 성능 비교

### Interpolation 성능

| 품질 | 렌더링 시간 | 사용 사례 |
|------|------------|----------|
| `.none` | 15ms ⚡ | 픽셀 아트, 작은 아이콘 확대 |
| `.low` | 25ms ⚡ | 실시간 애니메이션 |
| `.medium` | 45ms 🔶 | 일반 사진 (권장) |
| `.high` | 120ms 🔴 | 고품질 갤러리 |

### 렌더링 모드 비교

| 모드 | 성능 | 사용 사례 |
|------|------|----------|
| `.original` | 빠름 | 컬러 이미지, SF Symbols 원색 |
| `.template` | 빠름 | 아이콘, 다크 모드 대응 |

---

## 🔍 디버깅 팁

### 이미지가 늘어나지 않음

```swift
// ❌ resizable() 없음
Image("photo")
    .frame(width: 200, height: 200)

// ✅ resizable() 추가
Image("photo")
    .resizable()
    .frame(width: 200, height: 200)
```

### 이미지가 잘림

```swift
// ❌ clipped() 없음
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 200, height: 200)

// ✅ clipped() 추가
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 200, height: 200)
    .clipped()
```

### 픽셀이 흐림

```swift
// ❌ 기본 보간
Image("pixel-art")
    .resizable()
    .frame(width: 200, height: 200)

// ✅ 보간 없음
Image("pixel-art")
    .resizable()
    .interpolation(.none)
    .antialiased(false)
    .frame(width: 200, height: 200)
```

---

## 🎯 학습 체크리스트

### 기본
- [ ] resizable()의 역할을 안다
- [ ] .fit과 .fill의 차이를 안다
- [ ] interpolation 품질을 설명할 수 있다
- [ ] renderingMode를 활용할 수 있다

### 응용
- [ ] capInsets를 사용할 수 있다
- [ ] 상황에 맞는 interpolation을 선택한다
- [ ] clipped()를 적절히 사용한다
- [ ] SF Symbols를 효과적으로 활용한다

### 심화
- [ ] 성능을 측정하고 비교할 수 있다
- [ ] Retina 디스플레이를 고려한다
- [ ] 스크롤 성능을 최적화할 수 있다
- [ ] 실무 패턴을 적용할 수 있다

---

## 📚 참고 자료

### Apple 공식 문서
- [Image - SwiftUI](https://developer.apple.com/documentation/swiftui/image)
- [Displaying and Manipulating Images](https://developer.apple.com/documentation/swiftui/displaying-and-manipulating-images)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

### WWDC 세션
- [What's new in SwiftUI (WWDC 2023)](https://developer.apple.com/videos/play/wwdc2023/10148/)
- [Demystify SwiftUI performance (WWDC 2023)](https://developer.apple.com/videos/play/wwdc2023/10160/)

### 튜토리얼
- `SWIFTUI_IMAGE_THEORY.md` - 기본 개념
- `RENDERING_MODE_GUIDE.md` - 렌더링 옵션
- `PERFORMANCE_GUIDE.md` - 성능 최적화

---

## 🐛 알려진 이슈

### iOS 시뮬레이터
- interpolation 품질 차이가 실기기보다 작음
- 실제 기기 테스트 권장

### Retina 디스플레이
- 논리적 픽셀 vs 실제 픽셀
- Asset Catalog @2x, @3x 활용

---

## 🎓 다음 단계

Day 6를 마스터했다면:

1. **Day 7**: 이미지 필터링 (Core Image)
2. **Day 8**: 이미지 분석 (Vision Framework)
3. **Day 9**: Metal을 활용한 GPU 가속

---

## 💬 질문 & 피드백

학습 중 궁금한 점이 있다면:
- 각 View의 코드 주석 확인
- 가이드 문서 참고
- Apple 공식 문서 읽기

---

**Happy Learning! 🎨**

*SwiftUI Image의 강력한 렌더링 옵션을 마스터하세요!*

