# SwiftUI Image 렌더링 옵션 가이드

> SwiftUI Image의 다양한 렌더링 옵션을 마스터하여 원하는 시각적 효과를 구현하세요.

---

## 📚 목차

1. [resizable()](#resizable)
2. [aspectRatio()](#aspectratio)
3. [interpolation()](#interpolation)
4. [renderingMode()](#renderingmode)
5. [antialiased()](#antialiased)
6. [resizingMode()](#resizingmode)
7. [조합 패턴](#조합-패턴)

---

## resizable()

### 개념

기본적으로 SwiftUI `Image`는 **원본 크기로 고정**되어 있습니다. `resizable()`을 호출해야 크기 조정이 가능합니다.

### 기본 사용법

```swift
// ❌ resizable() 없음 - 원본 크기
Image("sample")
    .frame(width: 200, height: 200)
// 결과: 이미지는 원본 크기 유지, frame은 클리핑 영역만

// ✅ resizable() 있음 - 크기 조정 가능
Image("sample")
    .resizable()
    .frame(width: 200, height: 200)
// 결과: 이미지가 200×200으로 늘어남
```

### 동작 원리

```swift
// 내부 구조 (개념적)
struct Image {
    var isResizable: Bool = false  // 기본값: false
    
    func resizable() -> Image {
        var copy = self
        copy.isResizable = true
        return copy
    }
}
```

### capInsets를 활용한 9-Patch

```swift
Image("button-background")
    .resizable(capInsets: EdgeInsets(
        top: 10,
        leading: 10,
        bottom: 10,
        trailing: 10
    ))
    .frame(width: 300, height: 60)
```

**동작**:
- 가장자리 10pt는 늘어나지 않음
- 중앙 부분만 늘어남
- 둥근 모서리 유지

**사용 예**: 버튼 배경, 말풍선, 패널

### resizingMode

```swift
// 늘리기 (기본값)
Image("pattern")
    .resizable(resizingMode: .stretch)
    .frame(width: 300, height: 300)

// 타일링
Image("pattern")
    .resizable(resizingMode: .tile)
    .frame(width: 300, height: 300)
```

**차이점**:
- `.stretch`: 이미지를 늘림
- `.tile`: 이미지를 반복

---

## aspectRatio()

### 개념

이미지의 **가로세로 비율**을 제어합니다.

### contentMode

```swift
public enum ContentMode {
    case fit   // 내부에 맞춤 (여백 생김)
    case fill  // 꽉 채움 (잘림)
}
```

### .fit vs .fill

```swift
// .fit - 이미지 전체가 보임
Image("landscape")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 300, height: 200)
// 결과: 이미지가 300×200 안에 들어감, 위아래 여백 생길 수 있음

// .fill - 영역을 꽉 채움
Image("landscape")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 300, height: 200)
// 결과: 300×200을 완전히 채움, 좌우가 잘릴 수 있음
    .clipped()  // ⚠️ 잘린 부분 숨기기 (필수!)
```

### 시각적 비교

```
원본: 1600 × 900 (16:9)
프레임: 300 × 200 (3:2)

┌─────────────────┐
│  .fit           │
│ ┌─────────────┐ │ ← 위아래 여백
│ │             │ │
│ │   이미지    │ │
│ │             │ │
│ └─────────────┘ │
└─────────────────┘

┌─────────────────┐
│ .fill           │
├─┬─────────────┬─┤ ← 좌우 잘림
│ │   이미지    │ │
├─┴─────────────┴─┤
└─────────────────┘
```

### 특정 비율 지정

```swift
// 1:1 정사각형
Image("photo")
    .resizable()
    .aspectRatio(1.0, contentMode: .fill)
    .frame(width: 200, height: 200)
    .clipped()

// 16:9 비율
Image("video-thumbnail")
    .resizable()
    .aspectRatio(16/9, contentMode: .fit)
    .frame(width: 320)  // 높이는 자동 계산 (180)

// 원본 비율 유지
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(maxWidth: 300)  // 최대 너비만 제한
```

### scaledToFit / scaledToFill

```swift
// 축약 문법
Image("photo")
    .resizable()
    .scaledToFit()  // == .aspectRatio(contentMode: .fit)
    .frame(width: 300)

Image("photo")
    .resizable()
    .scaledToFill()  // == .aspectRatio(contentMode: .fill)
    .frame(width: 300, height: 200)
    .clipped()
```

---

## interpolation()

### 개념

이미지를 확대/축소할 때 **픽셀 사이를 채우는 방법**(보간)을 지정합니다.

### 보간 품질

```swift
public enum Interpolation {
    case none    // 보간 없음 (nearest neighbor)
    case low     // 낮은 품질 (빠름)
    case medium  // 중간 품질 (기본값)
    case high    // 높은 품질 (느림)
}
```

### 품질 비교

```swift
// 작은 이미지를 크게 확대
let smallIcon = Image("16x16-icon")

// .none - 픽셀 아트 스타일
smallIcon
    .resizable()
    .interpolation(.none)
    .frame(width: 200, height: 200)
// 결과: 계단 현상, 픽셀이 보임 🟦🟦

// .low - 빠르지만 품질 낮음
smallIcon
    .resizable()
    .interpolation(.low)
    .frame(width: 200, height: 200)
// 결과: 약간 흐림

// .medium - 균형 (기본값)
smallIcon
    .resizable()
    .interpolation(.medium)
    .frame(width: 200, height: 200)
// 결과: 적당한 품질

// .high - 최고 품질
smallIcon
    .resizable()
    .interpolation(.high)
    .frame(width: 200, height: 200)
// 결과: 부드러움, 디테일 보존
```

### 언제 어떤 품질을 사용할까?

| 상황 | 추천 | 이유 |
|------|------|------|
| 픽셀 아트 게임 | `.none` | 픽셀 경계 보존 |
| 작은 아이콘 확대 | `.none` | 선명함 유지 |
| 일반 사진 축소 | `.medium` | 성능/품질 균형 |
| 고품질 갤러리 | `.high` | 최상의 품질 |
| 실시간 애니메이션 | `.low` | 빠른 렌더링 |
| 썸네일 그리드 | `.medium` | 적당한 품질 |

### 성능 영향

```swift
// 성능 테스트 (100개 이미지 렌더링)
.interpolation(.none)   // 15ms  ⚡ 가장 빠름
.interpolation(.low)    // 25ms  ⚡ 빠름
.interpolation(.medium) // 45ms  🔶 기본
.interpolation(.high)   // 120ms 🔴 느림
```

**추천**:
- 스크롤 뷰: `.medium` 또는 `.low`
- 정적 화면: `.high`
- 픽셀 아트: `.none`

### 실무 예제

```swift
// 프로필 사진 (고품질)
struct ProfileImage: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(.high)  // 최고 품질
            .aspectRatio(contentMode: .fill)
            .frame(width: 120, height: 120)
            .clipShape(Circle())
    }
}

// 썸네일 그리드 (균형)
struct ThumbnailGrid: View {
    let images: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
            ForEach(images, id: \.self) { img in
                Image(img)
                    .resizable()
                    .interpolation(.medium)  // 균형
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            }
        }
    }
}

// 픽셀 아트 게임
struct PixelArtSprite: View {
    let spriteName: String
    
    var body: some View {
        Image(spriteName)
            .resizable()
            .interpolation(.none)  // 픽셀 보존
            .frame(width: 64, height: 64)
    }
}
```

---

## renderingMode()

### 개념

이미지를 **원본 색상** 또는 **템플릿**(단색)으로 렌더링합니다.

### 렌더링 모드

```swift
public enum RenderingMode {
    case original  // 원본 색상 유지
    case template  // 단색 템플릿 (tint 적용)
}
```

### 사용 예제

```swift
// .original - 원본 색상
Image(systemName: "star.fill")
    .renderingMode(.original)
// 결과: SF Symbol의 원래 색상 (노란색)

// .template - 틴트 적용
Image(systemName: "star.fill")
    .renderingMode(.template)
    .foregroundStyle(.blue)
// 결과: 파란색으로 표시

// Asset 이미지도 가능
Image("logo")
    .renderingMode(.template)
    .foregroundStyle(.red)
// 결과: 로고가 빨간색 실루엣으로
```

### SF Symbols와 함께 사용

```swift
// 다크 모드 대응 아이콘
struct AdaptiveIcon: View {
    let systemName: String
    
    var body: some View {
        Image(systemName: systemName)
            .renderingMode(.template)
            .foregroundStyle(.primary)  // 자동으로 밝기 조정
    }
}

// 버튼 아이콘
Button(action: { /* ... */ }) {
    Image(systemName: "heart.fill")
        .renderingMode(.template)
        .foregroundStyle(.red)
}

// 탭 아이콘
TabView {
    HomeView()
        .tabItem {
            Image(systemName: "house")
                .renderingMode(.template)  // 선택 시 틴트 적용
            Text("Home")
        }
}
```

### 실무 패턴

```swift
// 다크 모드 로고
struct Logo: View {
    var body: some View {
        Image("app-logo")
            .renderingMode(.template)
            .foregroundStyle(.primary)  // 라이트: 검정, 다크: 흰색
    }
}

// 상태 표시 아이콘
struct StatusIcon: View {
    let isActive: Bool
    
    var body: some View {
        Image(systemName: "circle.fill")
            .renderingMode(.template)
            .foregroundStyle(isActive ? .green : .gray)
    }
}

// 커스텀 버튼
struct IconButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .renderingMode(.template)
                .font(.title)
                .foregroundStyle(color)
                .padding()
                .background(color.opacity(0.2))
                .clipShape(Circle())
        }
    }
}
```

---

## antialiased()

### 개념

이미지의 **계단 현상(aliasing)**을 줄여 부드럽게 표시합니다.

### 사용법

```swift
// 안티앨리어싱 활성화 (기본값)
Image("photo")
    .resizable()
    .antialiased(true)
    .frame(width: 200)

// 안티앨리어싱 비활성화
Image("photo")
    .resizable()
    .antialiased(false)
    .frame(width: 200)
```

### 효과

```
antialiased(true):   antialiased(false):
   ╱╲                   ╱╲
  ╱  ╲                 ╱  ╲
 ╱    ╲               ╱    ╲
        (부드러움)           (계단 현상)
```

### 언제 사용할까?

| 상황 | 설정 | 이유 |
|------|------|------|
| 일반 사진 | `true` (기본) | 부드러운 외곽선 |
| 회전된 이미지 | `true` | 계단 현상 감소 |
| 픽셀 아트 | `false` | 선명함 유지 |
| 작은 아이콘 | `false` | 디테일 보존 |

### 실무 예제

```swift
// 회전 애니메이션
struct RotatingImage: View {
    @State private var rotation = 0.0
    
    var body: some View {
        Image("logo")
            .resizable()
            .antialiased(true)  // 회전 시 부드러움
            .frame(width: 100, height: 100)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// 픽셀 아트
struct PixelArt: View {
    var body: some View {
        Image("pixel-character")
            .resizable()
            .interpolation(.none)
            .antialiased(false)  // 픽셀 보존
            .frame(width: 128, height: 128)
    }
}
```

---

## resizingMode()

### 개념

`resizable()`에 전달하는 옵션으로, 이미지를 **늘릴지** 또는 **반복**할지 결정합니다.

### 모드

```swift
public enum ResizingMode {
    case stretch  // 늘리기 (기본값)
    case tile     // 타일링 (반복)
}
```

### 사용 예제

```swift
// 늘리기
Image("gradient")
    .resizable(resizingMode: .stretch)
    .frame(width: 300, height: 200)

// 타일링
Image("pattern")
    .resizable(resizingMode: .tile)
    .frame(width: 300, height: 200)
```

### 실무 패턴

```swift
// 패턴 배경
struct PatternBackground: View {
    var body: some View {
        ZStack {
            Image("tile-pattern")
                .resizable(resizingMode: .tile)
                .ignoresSafeArea()
            
            ContentView()
        }
    }
}

// 늘어나는 버튼 배경
struct StretchableButton: View {
    var body: some View {
        Button("Click Me") {
            // action
        }
        .padding()
        .background(
            Image("button-bg")
                .resizable(capInsets: EdgeInsets(
                    top: 5, leading: 5, bottom: 5, trailing: 5
                ), resizingMode: .stretch)
        )
    }
}
```

---

## 조합 패턴

### 일반 사진 표시

```swift
Image("photo")
    .resizable()                          // 크기 조정 가능
    .interpolation(.high)                 // 고품질
    .aspectRatio(contentMode: .fill)      // 꽉 채움
    .frame(width: 300, height: 200)       // 크기 지정
    .clipped()                            // 넘친 부분 자르기
```

### 프로필 이미지

```swift
struct ProfileImageView: View {
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
                ForEach(images, id: \.self) { imageName in
                    Image(imageName)
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

### 커버 이미지

```swift
struct CoverImage: View {
    let imageName: String
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: 300)
                .clipped()
        }
        .frame(height: 300)
    }
}
```

### 아이콘 버튼

```swift
struct IconButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
struct PixelArtView: View {
    let spriteName: String
    let scale: CGFloat
    
    var body: some View {
        Image(spriteName)
            .resizable()
            .interpolation(.none)      // 픽셀 보존
            .antialiased(false)        // 선명함
            .aspectRatio(contentMode: .fit)
            .frame(width: 32 * scale, height: 32 * scale)
    }
}
```

---

## 성능 최적화 팁

### 1. resizable()를 적절히 사용

```swift
// ❌ 불필요한 resizable()
Image(systemName: "star")  // 이미 벡터
    .resizable()
    .frame(width: 20, height: 20)

// ✅ font()로 크기 조절
Image(systemName: "star")
    .font(.system(size: 20))
```

### 2. interpolation 최소화

```swift
// ❌ 모든 썸네일에 .high
LazyVGrid(columns: columns) {
    ForEach(images) { img in
        Image(img)
            .resizable()
            .interpolation(.high)  // 느림
            .frame(width: 100)
    }
}

// ✅ .medium으로 충분
LazyVGrid(columns: columns) {
    ForEach(images) { img in
        Image(img)
            .resizable()
            .interpolation(.medium)
            .frame(width: 100)
    }
}
```

### 3. clipped() 꼭 추가

```swift
// ❌ 잘린 부분도 렌더링됨
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 200, height: 200)

// ✅ 보이는 부분만 렌더링
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 200, height: 200)
    .clipped()
```

---

## 핵심 정리

### 필수 modifier

| Modifier | 역할 | 기본값 |
|----------|------|--------|
| `resizable()` | 크기 조정 활성화 | false |
| `aspectRatio()` | 비율 유지 방법 | 원본 비율 |
| `interpolation()` | 보간 품질 | `.medium` |
| `renderingMode()` | 색상/템플릿 | `.original` |
| `antialiased()` | 안티앨리어싱 | true |

### 호출 순서

```swift
Image("photo")
    .resizable()              // 1️⃣ 먼저
    .interpolation(.high)     // 2️⃣ 품질 설정
    .aspectRatio(contentMode: .fill)  // 3️⃣ 비율
    .frame(width: 200)        // 4️⃣ 크기
    .clipped()                // 5️⃣ 자르기
```

### 일반적인 조합

```swift
// 사진 표시
.resizable()
.interpolation(.high)
.aspectRatio(contentMode: .fit)

// 썸네일
.resizable()
.interpolation(.medium)
.aspectRatio(contentMode: .fill)
.clipped()

// 아이콘
.renderingMode(.template)
.foregroundStyle(color)

// 픽셀 아트
.resizable()
.interpolation(.none)
.antialiased(false)
```

---

**다음 단계**: PERFORMANCE_GUIDE.md에서 성능 최적화 기법을 학습하세요!


