# SwiftUI Canvas 완벽 가이드

> iOS 15+에서 사용 가능한 선언적 2D 그래픽 API

---

## 🎨 Canvas란?

**Canvas**는 SwiftUI에서 제공하는 즉시 모드(immediate mode) 2D 그래픽 API입니다. (iOS 15+)

```swift
Canvas { context, size in
    // 여기서 그리기!
}
```

### ✨ 주요 특징

| 특징 | 설명 |
|------|------|
| **선언적** | SwiftUI 스타일의 직관적 API |
| **GPU 가속** | 하드웨어 가속 지원 |
| **실시간** | TimelineView와 함께 애니메이션 |
| **통합성** | SwiftUI View와 완벽 통합 |
| **좌표계** | SwiftUI 스타일 (왼쪽 상단 원점) |

---

## 🚀 기본 사용법

### 1️⃣ 간단한 도형 그리기

```swift
Canvas { context, size in
    // 사각형
    let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
    context.fill(Path(rect), with: .color(.blue))
    
    // 원
    let circle = Path(ellipseIn: CGRect(x: 200, y: 50, width: 100, height: 100))
    context.fill(circle, with: .color(.red))
    
    // 선
    var line = Path()
    line.move(to: CGPoint(x: 50, y: 200))
    line.addLine(to: CGPoint(x: 300, y: 200))
    context.stroke(line, with: .color(.green), lineWidth: 3)
}
.frame(width: 400, height: 400)
```

### 2️⃣ 텍스트 그리기

```swift
Canvas { context, size in
    let text = Text("Hello, Canvas!")
        .font(.largeTitle)
        .foregroundColor(.white)
    
    context.draw(text, at: CGPoint(x: 200, y: 100), anchor: .center)
}
```

### 3️⃣ 이미지 그리기

```swift
Canvas { context, size in
    if let image = context.resolveSymbol(id: "myImage") {
        context.draw(image, at: CGPoint(x: 100, y: 100))
    }
} symbols: {
    Image(systemName: "star.fill")
        .resizable()
        .frame(width: 50, height: 50)
        .tag("myImage")
}
```

---

## 🎯 GraphicsContext API

### 도형 그리기

```swift
Canvas { context, size in
    // fill: 채우기
    context.fill(path, with: .color(.blue))
    
    // stroke: 테두리
    context.stroke(path, with: .color(.red), lineWidth: 2)
    
    // 스타일 옵션
    context.stroke(
        path,
        with: .color(.green),
        style: StrokeStyle(
            lineWidth: 3,
            lineCap: .round,
            lineJoin: .round,
            dash: [5, 3]  // 점선
        )
    )
}
```

### 그라디언트

```swift
Canvas { context, size in
    let gradient = Gradient(colors: [.blue, .purple, .pink])
    let rect = CGRect(origin: .zero, size: size)
    
    // 선형 그라디언트
    context.fill(
        Path(rect),
        with: .linearGradient(
            gradient,
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height)
        )
    )
    
    // 방사형 그라디언트
    context.fill(
        Path(rect),
        with: .radialGradient(
            gradient,
            center: CGPoint(x: size.width/2, y: size.height/2),
            startRadius: 0,
            endRadius: 100
        )
    )
}
```

### 변환 (Transform)

```swift
Canvas { context, size in
    // 이동
    context.translateBy(x: 100, y: 100)
    
    // 회전
    context.rotate(by: .degrees(45))
    
    // 확대/축소
    context.scaleBy(x: 1.5, y: 1.5)
    
    // 그리기...
    context.fill(Path(CGRect(x: 0, y: 0, width: 50, height: 50)), 
                 with: .color(.blue))
}
```

### 블렌드 모드 & 투명도

```swift
Canvas { context, size in
    // 투명도
    context.opacity = 0.5
    
    // 블렌드 모드
    context.blendMode = .multiply
    
    // 그리기...
}
```

### 필터 (iOS 15+)

```swift
Canvas { context, size in
    // 블러
    context.addFilter(.blur(radius: 5))
    
    // 색조 회전
    context.addFilter(.hueRotation(.degrees(90)))
    
    // 그림자
    context.addFilter(.shadow(
        color: .black.opacity(0.3),
        radius: 10,
        offset: CGSize(width: 5, height: 5)
    ))
}
```

---

## 🔧 Core Graphics 통합

Canvas 안에서 Core Graphics를 직접 사용할 수 있습니다!

```swift
Canvas { context, size in
    context.withCGContext { cgContext in
        // 이제 CGContext 메서드 사용 가능
        
        // 복잡한 그라디언트
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [UIColor.red.cgColor, UIColor.blue.cgColor] as CFArray
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: nil
        )!
        
        cgContext.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: 0, y: size.height),
            options: []
        )
        
        // 섀도우
        cgContext.setShadow(
            offset: CGSize(width: 3, height: 3),
            blur: 5,
            color: UIColor.black.cgColor
        )
        
        // 클리핑
        let clipPath = CGPath(
            ellipseIn: CGRect(x: 50, y: 50, width: 200, height: 200),
            transform: nil
        )
        cgContext.addPath(clipPath)
        cgContext.clip()
    }
}
```

---

## ⚡ 실시간 애니메이션

### TimelineView와 함께 사용

```swift
struct AnimatedCanvasView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let angle = Angle.radians(time.remainder(dividingBy: 2 * .pi))
                
                context.rotate(by: angle)
                
                let rect = CGRect(
                    x: size.width/2 - 50,
                    y: size.height/2 - 50,
                    width: 100,
                    height: 100
                )
                context.fill(Path(rect), with: .color(.blue))
            }
        }
        .frame(width: 300, height: 300)
    }
}
```

### 인터랙티브 드로잉

```swift
struct DrawingCanvasView: View {
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    
    var body: some View {
        Canvas { context, size in
            // 완성된 선들
            for line in lines {
                var path = Path()
                if let first = line.first {
                    path.move(to: first)
                    for point in line.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                context.stroke(path, with: .color(.blue), lineWidth: 3)
            }
            
            // 현재 그리는 선
            if !currentLine.isEmpty {
                var path = Path()
                path.move(to: currentLine[0])
                for point in currentLine.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(path, with: .color(.blue), lineWidth: 3)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentLine.append(value.location)
                }
                .onEnded { _ in
                    lines.append(currentLine)
                    currentLine = []
                }
        )
        .background(Color.white)
    }
}
```

---

## 💾 이미지로 저장 (iOS 16+)

```swift
@MainActor
func captureCanvasAsImage() -> UIImage? {
    let view = Canvas { context, size in
        // 그리기...
    }
    .frame(width: 400, height: 400)
    
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3.0  // @3x
    return renderer.uiImage
}
```

---

## 🆚 Canvas vs Core Graphics

| | Canvas | Core Graphics |
|---|---|---|
| **사용 시기** | 화면 표시, 실시간 | 이미지 저장, 오프스크린 |
| **API 스타일** | 선언적 (SwiftUI) | 명령형 (C API) |
| **좌표계** | 왼쪽 상단 원점 | 왼쪽 하단 원점 |
| **성능** | GPU 가속 가능 | CPU 기반 |
| **애니메이션** | ✅ TimelineView | ❌ 부적합 |
| **이미지 저장** | ⚠️ iOS 16+ | ✅ 간단 |
| **학습 곡선** | 낮음 | 높음 |

---

## 🎯 실전 예제

### 1. 차트 그리기

```swift
struct BarChartView: View {
    let data: [Double]
    
    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(data.count)
            let maxValue = data.max() ?? 1
            
            for (index, value) in data.enumerated() {
                let height = (value / maxValue) * size.height * 0.8
                let x = CGFloat(index) * barWidth
                let y = size.height - height
                
                let rect = CGRect(
                    x: x + 5,
                    y: y,
                    width: barWidth - 10,
                    height: height
                )
                
                context.fill(
                    Path(rect),
                    with: .color(.blue.opacity(0.7))
                )
            }
        }
    }
}
```

### 2. 별점 표시

```swift
struct StarRatingView: View {
    let rating: Double  // 0.0 ~ 5.0
    
    var body: some View {
        Canvas { context, size in
            let starSize: CGFloat = size.width / 5
            
            for i in 0..<5 {
                let x = CGFloat(i) * starSize + starSize / 2
                let y = size.height / 2
                
                let isFilled = Double(i) < rating
                let isPartial = Double(i) < rating && Double(i + 1) > rating
                
                drawStar(
                    context: context,
                    center: CGPoint(x: x, y: y),
                    size: starSize * 0.8,
                    filled: isFilled,
                    partialFill: isPartial ? rating - Double(i) : 1.0
                )
            }
        }
    }
    
    private func drawStar(context: GraphicsContext, center: CGPoint, 
                         size: CGFloat, filled: Bool, partialFill: Double) {
        var path = Path()
        let points = 5
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4
        
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        let color: Color = filled ? .yellow : .gray.opacity(0.3)
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(.orange), lineWidth: 1)
    }
}
```

### 3. 프로그레스 링

```swift
struct ProgressRingView: View {
    let progress: Double  // 0.0 ~ 1.0
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 10
            
            // 배경 링
            let backgroundPath = Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270),
                    clockwise: false
                )
            }
            context.stroke(
                backgroundPath,
                with: .color(.gray.opacity(0.2)),
                lineWidth: 10
            )
            
            // 프로그레스 링
            let progressAngle = 360 * progress
            let progressPath = Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + progressAngle),
                    clockwise: false
                )
            }
            context.stroke(
                progressPath,
                with: .linearGradient(
                    Gradient(colors: [.blue, .purple]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                ),
                style: StrokeStyle(lineWidth: 10, lineCap: .round)
            )
            
            // 퍼센트 텍스트
            let percentText = Text("\(Int(progress * 100))%")
                .font(.system(size: 40, weight: .bold))
            context.draw(percentText, at: center, anchor: .center)
        }
    }
}
```

---

## 📚 베스트 프랙티스

### 1. 성능 최적화

```swift
// ✅ 좋은 예: 변하지 않는 부분은 캐시
struct OptimizedCanvasView: View {
    @State private var cachedBackground: GraphicsContext.ResolvedImage?
    
    var body: some View {
        Canvas { context, size in
            // 배경은 한 번만 그리기
            if cachedBackground == nil {
                var backgroundContext = context
                // 배경 그리기...
                // cachedBackground = ...
            }
            
            // 변하는 부분만 매번 그리기
            // ...
        }
    }
}
```

### 2. 복잡한 경로는 재사용

```swift
// ✅ 계산된 경로 재사용
let starPath = createStarPath()

Canvas { context, size in
    for position in positions {
        var path = starPath
        path = path.offsetBy(dx: position.x, dy: position.y)
        context.fill(path, with: .color(.yellow))
    }
}
```

### 3. Core Graphics는 필요할 때만

```swift
// ✅ SwiftUI API로 충분하면 사용
Canvas { context, size in
    context.fill(path, with: .color(.blue))  // 간단!
}

// ⚠️ 복잡한 기능만 Core Graphics
Canvas { context, size in
    context.withCGContext { cgContext in
        // 특별한 기능만 여기서
    }
}
```

---

## 🎓 학습 순서

1. **기본 도형** → `fill()`, `stroke()` 익히기
2. **Path 다루기** → 선, 곡선, 도형 그리기
3. **텍스트/이미지** → `draw()` 메서드
4. **변환** → translate, rotate, scale
5. **그라디언트** → linearGradient, radialGradient
6. **애니메이션** → TimelineView 연동
7. **인터랙션** → Gesture와 결합
8. **Core Graphics** → withCGContext 고급 기능

---

## 🔗 관련 문서

- [CORE_GRAPHICS_THEORY.md](./CORE_GRAPHICS_THEORY.md) - Core Graphics 기초
- [Apple - Canvas](https://developer.apple.com/documentation/swiftui/canvas)
- [Apple - GraphicsContext](https://developer.apple.com/documentation/swiftui/graphicscontext)
- [WWDC21 - Add rich graphics to your SwiftUI app](https://developer.apple.com/videos/play/wwdc2021/10021/)

---

**Happy Drawing with SwiftUI! 🎨**

