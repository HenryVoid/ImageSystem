# Core Graphics 이론 정리

> Day 2 학습 자료 - 2D 그래픽 렌더링의 기초

---

## 📚 목차

1. [Core Graphics란?](#1-core-graphics란)
2. [좌표계 (Coordinate System)](#2-좌표계-coordinate-system)
3. [Graphics Context](#3-graphics-context)
4. [UIGraphicsImageRenderer](#4-uigraphicsimagerenderer)
5. [Drawing Primitives](#5-drawing-primitives)
6. [Context State 관리](#6-context-state-관리)
7. [성능 특성](#7-성능-특성)
8. [실무 사용 예시](#8-실무-사용-예시)

---

## 1. Core Graphics란?

**Core Graphics** (Quartz 2D)는 애플의 저수준 2D 그래픽 렌더링 엔진입니다.

### 🎯 핵심 특징

```
┌─────────────────────────────────────┐
│  App Layer (SwiftUI/UIKit)          │
├─────────────────────────────────────┤
│  Core Graphics (Quartz 2D) ← 여기!  │
├─────────────────────────────────────┤
│  Core Animation (CALayer)           │
├─────────────────────────────────────┤
│  Metal / OpenGL                     │
└─────────────────────────────────────┘
```

- **저수준 API**: UIKit, SwiftUI보다 더 세밀한 제어
- **벡터 기반**: 해상도에 독립적인 그래픽
- **CPU 기반**: GPU가 아닌 CPU에서 렌더링
- **C 기반 API**: Swift에서 래핑하여 사용

### ✅ 언제 사용할까?

| 사용해야 할 때 | 사용하지 말아야 할 때 |
|----------------|---------------------|
| 📄 PDF 생성 | 🎨 단순 UI 구성 → SwiftUI |
| 🖼️ 이미지 합성/편집 | 🎮 3D 그래픽 → Metal |
| 💧 워터마크 추가 | ⚡ 고성능 애니메이션 → CALayer |
| 📐 커스텀 도형 | 📊 차트 → Charts 라이브러리 |
| 🎨 정밀한 그리기 | 🏃 실시간 렌더링 → Canvas |

---

## 2. 좌표계 (Coordinate System)

### 🔄 UIKit vs Core Graphics

가장 혼란스러운 부분! Y축이 반대입니다.

```
┌────────────────────────────────────────────────────┐
│                                                    │
│  📱 UIKit (UIView, SwiftUI)                        │
│                                                    │
│  ┌─────────────┐                                  │
│  │ (0,0)       │  ← 원점: 왼쪽 상단               │
│  │      ↓ +Y   │                                  │
│  │             │                                  │
│  │  → +X       │                                  │
│  └─────────────┘                                  │
│                                                    │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│                                                    │
│  🎨 Core Graphics (기본)                           │
│                                                    │
│  ┌─────────────┐                                  │
│  │  → +X       │                                  │
│  │             │                                  │
│  │      ↑ +Y   │  ← 수학 좌표계                   │
│  │ (0,0)       │  ← 원점: 왼쪽 하단               │
│  └─────────────┘                                  │
│                                                    │
└────────────────────────────────────────────────────┘
```

### ⚡ Y축 반전 해결법

```swift
// 방법 1: Context 변환 (가장 일반적)
context.translateBy(x: 0, y: height)  // 아래로 이동
context.scaleBy(x: 1, y: -1)          // Y축 뒤집기

// 방법 2: 좌표 직접 계산
let flippedY = height - y
```

### 💡 왜 이렇게 설계되었나?

- **Core Graphics**: 수학 좌표계 전통 (PostScript 유래)
- **UIKit**: 화면 렌더링에 자연스러운 방식 (위→아래)

---

## 3. Graphics Context

**Context**는 "그림을 그릴 수 있는 캔버스"입니다.

### 🎨 Context의 구성 요소

```swift
Context = {
    1. Destination (어디에?)
       - Bitmap (이미지)
       - PDF
       - 화면 (CALayer)
       - 프린터
    
    2. Drawing State (어떻게?)
       - 색상 (stroke/fill)
       - 선 굵기, 스타일
       - 투명도, 블렌드 모드
       - 폰트, 텍스트 속성
    
    3. Transform Matrix (변환)
       - 이동 (translate)
       - 회전 (rotate)
       - 확대/축소 (scale)
    
    4. Clipping Path (제한 영역)
       - 그릴 수 있는 영역 제한
}
```

### 📦 Context 종류

| 타입 | 생성 방법 | 용도 |
|------|-----------|------|
| **Bitmap Context** | `UIGraphicsImageRenderer` | 이미지 생성 |
| **PDF Context** | `UIGraphicsPDFRenderer` | PDF 문서 |
| **Layer Context** | `layer.draw(in:)` | CALayer 그리기 |
| **Print Context** | `UIPrintPageRenderer` | 프린트 |

---

## 4. UIGraphicsImageRenderer

### 🚀 현대적 이미지 렌더링 (iOS 10+)

iOS 15를 지원하는 현대 앱에서는 **UIGraphicsImageRenderer**가 표준입니다.

```swift
// ✅ UIGraphicsImageRenderer (권장)
let renderer = UIGraphicsImageRenderer(size: size)
let image = renderer.image { context in
    let ctx = context.cgContext
    
    // Core Graphics 명령으로 그리기
    ctx.setFillColor(UIColor.blue.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
}  // 자동으로 정리됨
```

**장점:**
- ✅ 자동 스케일 처리 (@2x, @3x Retina 완벽 대응)
- ✅ 자동 메모리 관리 (ARC 친화적)
- ✅ Wide Color(P3) 자동 지원
- ✅ 안전한 API (강제 언래핑 불필요)
- ✅ 클로저 기반 (Swift 친화적)

### 🔍 스케일 처리 예시

```swift
// iPhone 15 Pro는 @3x
let size = CGSize(width: 100, height: 100)
let renderer = UIGraphicsImageRenderer(size: size)

// 실제로는 300x300 픽셀 이미지 생성됨!
// → 화면에 그리면 선명함
```

### 🎨 Format 커스터마이징

```swift
let format = UIGraphicsImageRendererFormat()
format.scale = 3.0              // 강제 3배 스케일
format.opaque = false           // 투명 배경
format.preferredRange = .extended  // Wide Color

let renderer = UIGraphicsImageRenderer(size: size, format: format)
```

---

## 4.5. SwiftUI Canvas vs Core Graphics

### 📊 SwiftUI의 Canvas (iOS 15+)

**SwiftUI Canvas**는 선언적 방식의 2D 그리기를 제공합니다.

```swift
import SwiftUI

Canvas { context, size in
    // SwiftUI의 GraphicsContext 사용
    var path = Path()
    path.addEllipse(in: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    context.fill(path, with: .color(.blue))
    context.stroke(path, with: .color(.red), lineWidth: 3)
}
.frame(width: 200, height: 200)
```

### 🔄 Core Graphics vs SwiftUI Canvas 비교

| 특징 | Core Graphics (UIGraphicsImageRenderer) | SwiftUI Canvas |
|------|----------------------------------------|----------------|
| **API 스타일** | 명령형 (imperative) | 선언적 (declarative) |
| **좌표계** | 왼쪽 하단 원점 | 왼쪽 상단 원점 (SwiftUI 스타일) |
| **이미지 저장** | ✅ 매우 쉬움 (UIImage 직접 생성) | ⚠️ 번거로움 (ImageRenderer 필요) |
| **성능** | CPU 기반, 한 번 렌더링 | GPU 가속 가능, 실시간 |
| **애니메이션** | ❌ 부적합 | ✅ 적합 (TimelineView 연동) |
| **학습 곡선** | 가파름 (C API 래핑) | 완만 (Swift/SwiftUI 친화적) |
| **사용 시기** | 오프스크린 렌더링, 이미지 저장 | 화면 표시, 실시간 그리기 |

### 🎨 SwiftUI Canvas의 GraphicsContext

SwiftUI의 `GraphicsContext`는 Core Graphics보다 고수준 API입니다.

```swift
Canvas { context, size in
    // 1️⃣ 도형 그리기
    let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
    context.fill(Path(rect), with: .color(.blue))
    
    // 2️⃣ 텍스트 (Core Graphics보다 쉬움)
    let text = Text("Hello, Canvas!")
        .font(.title)
    context.draw(text, at: CGPoint(x: 100, y: 200))
    
    // 3️⃣ 이미지
    if let image = context.resolveSymbol(id: "myImage") {
        context.draw(image, at: CGPoint(x: 150, y: 150))
    }
    
    // 4️⃣ 블렌드 모드
    context.blendMode = .multiply
    
    // 5️⃣ 투명도
    context.opacity = 0.5
    
    // 6️⃣ 필터 (Core Graphics에 없음!)
    context.addFilter(.blur(radius: 5))
}
```

### 🔧 Canvas에서 Core Graphics 사용하기

Canvas 안에서도 Core Graphics를 사용할 수 있습니다!

```swift
Canvas { context, size in
    // CoreGraphics Context 얻기
    context.withCGContext { cgContext in
        // 이제 Core Graphics 명령 사용 가능
        cgContext.setFillColor(UIColor.red.cgColor)
        cgContext.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        
        // 복잡한 그라디언트나 패턴도 가능
        let gradient = CGGradient(...)
        cgContext.drawLinearGradient(gradient, ...)
    }
}
```

### 💡 언제 무엇을 사용할까?

```swift
// ✅ Core Graphics 사용
// - 이미지 파일로 저장 필요
// - 워터마크, 썸네일 생성
// - PDF 생성
// - 백그라운드에서 렌더링
let image = UIGraphicsImageRenderer(size: size).image { ctx in
    // 그리기...
}

// ✅ SwiftUI Canvas 사용
// - 화면에 직접 표시
// - 실시간 애니메이션
// - 사용자 인터랙션
// - SwiftUI와 통합
Canvas { context, size in
    // 그리기...
}
```

### 📱 SwiftUI에서 이미지 저장 (iOS 16+)

```swift
// ImageRenderer로 Canvas를 이미지로 변환
@MainActor
func captureCanvas() -> UIImage? {
    let renderer = ImageRenderer(content: myCanvasView)
    return renderer.uiImage
}
```

---

## 5. Drawing Primitives

기본 그리기 요소들입니다.

### 1️⃣ 선 (Line)

```swift
let context = ctx.cgContext

// 스타일 설정
context.setStrokeColor(UIColor.red.cgColor)
context.setLineWidth(3)
context.setLineCap(.round)     // 선 끝 스타일
context.setLineJoin(.round)    // 선 연결 스타일

// 경로 그리기
context.move(to: CGPoint(x: 10, y: 10))      // 시작점
context.addLine(to: CGPoint(x: 100, y: 100)) // 끝점
context.strokePath()                          // 실행
```

### 2️⃣ 사각형 (Rectangle)

```swift
let rect = CGRect(x: 50, y: 50, width: 100, height: 100)

// 방법 1: 간단
context.setFillColor(UIColor.yellow.cgColor)
context.fill(rect)

// 방법 2: 테두리 + 채우기
context.setFillColor(UIColor.yellow.cgColor)
context.setStrokeColor(UIColor.blue.cgColor)
context.setLineWidth(3)
context.fill(rect)
context.stroke(rect)
```

### 3️⃣ 원 (Circle / Ellipse)

```swift
// 타원
let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
context.fillEllipse(in: rect)

// 정원 (정사각형 안의 타원)
let circle = CGRect(x: 50, y: 50, width: 100, height: 100)
context.fillEllipse(in: circle)
```

### 4️⃣ 복잡한 경로 (Path)

```swift
context.beginPath()
context.move(to: CGPoint(x: 50, y: 100))
context.addLine(to: CGPoint(x: 100, y: 50))
context.addLine(to: CGPoint(x: 150, y: 100))
context.closePath()  // 시작점으로 닫기
context.fillPath()   // 삼각형 완성
```

### 5️⃣ 텍스트

```swift
let text = "Hello, Core Graphics!"
let attributes: [NSAttributedString.Key: Any] = [
    .font: UIFont.systemFont(ofSize: 20),
    .foregroundColor: UIColor.black
]

// NSString으로 변환하여 그리기
(text as NSString).draw(at: CGPoint(x: 10, y: 10), 
                        withAttributes: attributes)
```

### 6️⃣ 이미지

```swift
let image = UIImage(named: "sample")!
let rect = CGRect(x: 0, y: 0, width: 200, height: 200)

// Y축 반전 필요!
context.translateBy(x: 0, y: rect.height)
context.scaleBy(x: 1, y: -1)

image.draw(in: rect)
```

---

## 6. Context State 관리

Context는 **스택 기반 상태 관리**를 사용합니다.

### 📚 State Stack 개념

```swift
// 현재 상태: 검은색, 선 굵기 1

context.saveGState()           // [상태1] 저장
  context.setFillColor(.red)   // 빨간색
  context.fill(rect1)
  
  context.saveGState()         // [상태1, 상태2] 저장
    context.rotate(by: .pi/4)  // 45도 회전
    context.fill(rect2)
  context.restoreGState()      // [상태1] 복원 → 회전 취소
  
  context.fill(rect3)          // 빨간색, 회전 없음
context.restoreGState()        // [] 복원 → 검은색

context.fill(rect4)            // 검은색, 회전 없음
```

### 💾 저장되는 것들

| 카테고리 | 속성 |
|----------|------|
| **그리기 속성** | 색상, 선 굵기, 스타일 |
| **변환** | translate, rotate, scale |
| **클리핑** | 클리핑 영역 |
| **합성** | 블렌드 모드, 투명도 |
| **텍스트** | 폰트, 텍스트 행렬 |

### ⚡ 베스트 프랙티스

```swift
// ❌ 나쁜 예: 수동 복원
let oldColor = context.fillColor
context.setFillColor(.red)
// 그리기...
context.setFillColor(oldColor)  // 실수하기 쉬움

// ✅ 좋은 예: 자동 복원
context.saveGState()
context.setFillColor(.red)
// 그리기...
context.restoreGState()  // 완벽하게 복원
```

---

## 7. 성능 특성

### ⚖️ Core Graphics의 장단점

#### ✅ 장점

1. **정밀한 제어**
   ```
   픽셀 단위 정밀도
   모든 그리기 속성 제어 가능
   ```

2. **해상도 독립적**
   ```
   벡터 기반 → 확대/축소해도 선명
   PDF 생성 가능
   ```

3. **오프스크린 렌더링**
   ```
   이미지로 저장 가능
   배경에서 처리 가능
   ```

4. **성숙한 API**
   ```
   20년 이상의 최적화
   안정적이고 예측 가능
   ```

#### ❌ 단점

1. **CPU 집약적**
   ```
   GPU를 활용하지 않음
   배터리 소모 증가
   ```

2. **복잡한 API**
   ```
   C 기반 API (포인터, 수동 관리)
   학습 곡선 가파름
   ```

3. **동기적 실행**
   ```
   메인 스레드 블로킹 가능
   긴 작업은 백그라운드 필요
   ```

4. **실시간 애니메이션 부적합**
   ```
   60fps 유지 어려움
   CALayer/Metal이 더 적합
   ```

### 📊 성능 비교 (iOS 15+ 기준)

| | Core Graphics | SwiftUI Canvas | CALayer | Metal |
|---|---|---|---|---|
| **렌더링 속도** | 느림 (CPU) | 보통 (GPU 가속 가능) | 빠름 (GPU) | 매우 빠름 (GPU) |
| **정밀도** | 최고 | 높음 | 보통 | 낮음 |
| **배터리** | 많이 소모 | 보통 | 적게 소모 | 보통 |
| **난이도** | 높음 | 낮음 | 보통 | 매우 높음 |
| **이미지 저장** | ✅ 쉬움 | ⚠️ iOS 16+ (ImageRenderer) | ❌ 어려움 | ❌ 매우 어려움 |
| **SwiftUI 통합** | ⚠️ UIViewRepresentable | ✅ 네이티브 | ⚠️ UIViewRepresentable | ❌ 복잡 |
| **애니메이션** | ❌ 부적합 | ✅ TimelineView | ✅ 최적 | ✅ 고성능 |

### 🎯 iOS 15+ 앱에서의 선택 기준

```swift
// 🎨 화면 표시용 → SwiftUI Canvas
Canvas { context, size in
    // GPU 가속, 실시간 렌더링
    // SwiftUI와 완벽 통합
}

// 💾 이미지 저장용 → Core Graphics
let image = UIGraphicsImageRenderer(size: size).image { ctx in
    // 정밀한 이미지 생성
    // 워터마크, 썸네일, PDF
}

// ⚡ 고성능 애니메이션 → CALayer
layer.contents = image.cgImage
layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)

// 🎮 복잡한 3D/고성능 → Metal
// 게임, AR, 복잡한 시각 효과
```

---

## 8. 실무 사용 예시

### 🏷️ 예시 1: 워터마크 추가

#### Core Graphics 방식 (이미지 저장)

```swift
func addWatermark(to image: UIImage, text: String) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { context in
        // 1. 원본 이미지
        image.draw(at: .zero)
        
        // 2. 워터마크 텍스트
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 40),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: image.size.width - textSize.width - 20,
            y: image.size.height - textSize.height - 20,
            width: textSize.width,
            height: textSize.height
        )
        
        (text as NSString).draw(in: textRect, withAttributes: attributes)
    }
}
```

#### SwiftUI Canvas 방식 (화면 표시)

```swift
struct WatermarkedImageView: View {
    let image: Image
    let watermarkText: String
    
    var body: some View {
        Canvas { context, size in
            // 1. 배경 이미지
            context.draw(image, in: CGRect(origin: .zero, size: size))
            
            // 2. 워터마크 텍스트
            let text = Text(watermarkText)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            
            context.draw(text, at: CGPoint(
                x: size.width - 20,
                y: size.height - 20
            ), anchor: .bottomTrailing)
        }
    }
}
```

### 📐 예시 2: 리사이징 (고품질)

```swift
func resize(image: UIImage, to size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        // 고품질 보간
        context.cgContext.interpolationQuality = .high
        image.draw(in: CGRect(origin: .zero, size: size))
    }
}
```

### 🖼️ 예시 3: 썸네일 (크롭)

```swift
func createThumbnail(image: UIImage, size: CGSize) -> UIImage {
    let aspectRatio = image.size.width / image.size.height
    let targetRatio = size.width / size.height
    
    var drawRect = CGRect.zero
    
    if aspectRatio > targetRatio {
        // 너비 크롭
        let scaledHeight = size.height
        let scaledWidth = scaledHeight * aspectRatio
        let xOffset = (scaledWidth - size.width) / 2
        drawRect = CGRect(x: -xOffset, y: 0, 
                         width: scaledWidth, height: scaledHeight)
    } else {
        // 높이 크롭
        let scaledWidth = size.width
        let scaledHeight = scaledWidth / aspectRatio
        let yOffset = (scaledHeight - size.height) / 2
        drawRect = CGRect(x: 0, y: -yOffset, 
                         width: scaledWidth, height: scaledHeight)
    }
    
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        image.draw(in: drawRect)
    }
}
```

### 🎨 예시 4: 그라디언트 배경

#### Core Graphics 방식

```swift
func createGradient(size: CGSize, colors: [UIColor]) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        let cgContext = context.cgContext
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let cgColors = colors.map { $0.cgColor } as CFArray
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: cgColors,
            locations: nil
        )!
        
        cgContext.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: size.height),
            options: []
        )
    }
}
```

#### SwiftUI Canvas 방식 (iOS 15+)

```swift
struct GradientCanvasView: View {
    let colors: [Color]
    
    var body: some View {
        Canvas { context, size in
            // SwiftUI의 Gradient 사용
            let gradient = Gradient(colors: colors)
            let rect = CGRect(origin: .zero, size: size)
            
            context.fill(
                Path(rect),
                with: .linearGradient(
                    gradient,
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
        }
    }
}

// 또는 더 간단하게 (Core Graphics 없이)
struct SimpleGradientView: View {
    var body: some View {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
```

### 🌟 예시 5: SwiftUI Canvas로 실시간 그리기

```swift
struct InteractiveDrawingView: View {
    @State private var points: [CGPoint] = []
    
    var body: some View {
        Canvas { context, size in
            // 모든 점을 연결하여 그리기
            if points.count > 1 {
                var path = Path()
                path.move(to: points[0])
                
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                
                context.stroke(
                    path,
                    with: .color(.blue),
                    lineWidth: 3
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    points.append(value.location)
                }
                .onEnded { _ in
                    points = []
                }
        )
    }
}
```

### 🎯 예시 6: Canvas에서 Core Graphics 고급 기능 사용

```swift
struct AdvancedCanvasView: View {
    var body: some View {
        Canvas { context, size in
            context.withCGContext { cgContext in
                // 섀도우 (Core Graphics만 가능)
                cgContext.setShadow(
                    offset: CGSize(width: 5, height: 5),
                    blur: 10,
                    color: UIColor.black.withAlphaComponent(0.5).cgColor
                )
                
                // 복잡한 패턴
                let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
                cgContext.setFillColor(UIColor.blue.cgColor)
                cgContext.fill(rect)
                
                // 클리핑 경로 (Core Graphics의 강력한 기능)
                cgContext.saveGState()
                
                let clipPath = CGPath(
                    ellipseIn: CGRect(x: 100, y: 100, width: 200, height: 200),
                    transform: nil
                )
                cgContext.addPath(clipPath)
                cgContext.clip()
                
                // 클리핑 영역 안에만 그려짐
                cgContext.setFillColor(UIColor.red.cgColor)
                cgContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
                
                cgContext.restoreGState()
            }
        }
    }
}
```

---

## 🎯 학습 체크리스트

### Core Graphics 기초
- [ ] Core Graphics가 무엇인지 설명할 수 있다
- [ ] UIKit과 Core Graphics의 좌표계 차이를 이해했다
- [ ] Graphics Context의 역할을 설명할 수 있다
- [ ] UIGraphicsImageRenderer를 사용할 수 있다
- [ ] 기본 도형(선, 사각형, 원)을 그릴 수 있다
- [ ] Context State를 save/restore로 관리할 수 있다
- [ ] Core Graphics의 성능 특성을 이해했다

### SwiftUI 통합
- [ ] SwiftUI Canvas를 사용할 수 있다
- [ ] GraphicsContext API를 이해했다
- [ ] Core Graphics vs SwiftUI Canvas 차이를 설명할 수 있다
- [ ] Canvas에서 withCGContext를 사용할 수 있다
- [ ] 언제 Core Graphics를, 언제 Canvas를 사용할지 판단할 수 있다

### 실무 응용
- [ ] 이미지에 워터마크를 추가할 수 있다
- [ ] 고품질 이미지 리사이징을 구현할 수 있다
- [ ] 그라디언트 배경을 만들 수 있다
- [ ] 실시간 그리기 인터랙션을 구현할 수 있다

---

## 📚 참고 자료

### Apple 공식 문서

#### Core Graphics
- [Quartz 2D Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/)
- [UIGraphicsImageRenderer](https://developer.apple.com/documentation/uikit/uigraphicsimagerenderer)
- [CGContext](https://developer.apple.com/documentation/coregraphics/cgcontext)

#### SwiftUI
- [Canvas](https://developer.apple.com/documentation/swiftui/canvas) - iOS 15+
- [GraphicsContext](https://developer.apple.com/documentation/swiftui/graphicscontext)
- [ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer) - iOS 16+
- [Path](https://developer.apple.com/documentation/swiftui/path)

### WWDC 세션

#### Core Graphics
- [What's New in Cocoa Touch (WWDC 2016)](https://developer.apple.com/videos/play/wwdc2016/205/) - UIGraphicsImageRenderer 소개
- [Image and Graphics Best Practices (WWDC 2018)](https://developer.apple.com/videos/play/wwdc2018/219/)

#### SwiftUI
- [Add rich graphics to your SwiftUI app (WWDC 2021)](https://developer.apple.com/videos/play/wwdc2021/10021/) - Canvas 소개
- [SwiftUI on iPad: Add toolbars, titles, and more (WWDC 2022)](https://developer.apple.com/videos/play/wwdc2022/10058/)
- [Demystify SwiftUI performance (WWDC 2023)](https://developer.apple.com/videos/play/wwdc2023/10160/)

### 추가 학습
- [Hacking with Swift - Core Graphics](https://www.hackingwithswift.com/read/27/overview)
- [Hacking with Swift - SwiftUI Canvas](https://www.hackingwithswift.com/books/ios-swiftui/drawing-custom-paths-with-swiftui)
- [Swift by Sundell - Canvas in SwiftUI](https://www.swiftbysundell.com/)

---

**다음 단계**: 이제 이론을 배웠으니 직접 코드로 구현해봅시다! 🚀

