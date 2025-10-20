# Day 2: Core Graphics로 이미지 그리기

> 저수준 2D 그래픽 API를 마스터하는 여정 🎨

---

## 🎯 학습 목표

- [x] Core Graphics의 좌표계와 context 개념을 이해한다
- [ ] UIGraphicsImageRenderer로 고해상도 안전한 이미지 렌더링을 수행한다
- [ ] 텍스트·도형·이미지를 직접 Core Graphics로 그린다
- [ ] SwiftUI/UIImage 렌더링 차이를 체감한다
- [ ] Instruments로 렌더링 성능 차이를 정량 측정한다

---

## 📚 학습 자료

### 📖 이론 문서
- [CORE_GRAPHICS_THEORY.md](./CORE_GRAPHICS_THEORY.md) - Core Graphics 핵심 개념 총정리
- [SWIFTUI_CANVAS_GUIDE.md](./SWIFTUI_CANVAS_GUIDE.md) - SwiftUI Canvas 완벽 가이드 (iOS 15+)

### 🎓 학습 순서
```
1. 이론 학습
   📖 CORE_GRAPHICS_THEORY.md - Core Graphics 기초
   🎨 SWIFTUI_CANVAS_GUIDE.md - SwiftUI Canvas
   ↓
2. 기본 도형 그리기 (CGContextView)
   ✅ Core Graphics로 직접 그리기
   ↓
3. SwiftUI Canvas 실습
   🎨 Canvas API로 선언적 그리기
   ↓
4. 텍스트 렌더링 (TextRenderingView)
   ↓
5. 이미지 합성 (ImageCompositionView)
   ↓
6. 성능 비교 (BenchmarkView)
   ⚖️ Core Graphics vs SwiftUI Canvas
   ↓
7. 실전 예제 (워터마크, 썸네일 등)
```

---

## 📁 파일 구조

```
day02/
├── day02App.swift                      # 앱 진입점
├── ContentView.swift                   # 메인 네비게이션
│
├── 📖 이론 문서
├── CORE_GRAPHICS_THEORY.md            # Core Graphics 개념 정리
├── SWIFTUI_CANVAS_GUIDE.md            # SwiftUI Canvas 가이드
├── PERFORMANCE_GUIDE.md                # 성능 측정 가이드
├── README.md                           # 이 파일
│
├── 🎨 Phase 2: 기본 구현
├── CGContextView.swift                 # 기본 도형 그리기 ✅
├── TextRenderingView.swift             # 텍스트 렌더링 ✅
├── ImageCompositionView.swift          # 이미지 합성 ✅
│
├── 📊 Phase 3: 성능 측정 도구
└── tool/
    ├── PerformanceLogger.swift         # 로깅 시스템 ✅
    ├── SignpostHelper.swift            # 타이밍 측정 ✅
    └── MemorySampler.swift             # 메모리 측정 ✅
```

---

## 🛠️ 구현 예제

### 1️⃣ 기본 도형 그리기 (Phase 2)

```swift
// CGContextView.swift
let renderer = UIGraphicsImageRenderer(size: size)
let image = renderer.image { context in
    let ctx = context.cgContext
    
    // 사각형
    ctx.setFillColor(UIColor.blue.cgColor)
    ctx.fill(CGRect(x: 50, y: 50, width: 100, height: 100))
    
    // 원
    ctx.setFillColor(UIColor.red.cgColor)
    ctx.fillEllipse(in: CGRect(x: 200, y: 50, width: 100, height: 100))
    
    // 선
    ctx.setStrokeColor(UIColor.green.cgColor)
    ctx.setLineWidth(5)
    ctx.move(to: CGPoint(x: 50, y: 200))
    ctx.addLine(to: CGPoint(x: 300, y: 200))
    ctx.strokePath()
}
```

### 2️⃣ 텍스트 렌더링

```swift
// TextRenderingView.swift
let attributes: [NSAttributedString.Key: Any] = [
    .font: UIFont.boldSystemFont(ofSize: 24),
    .foregroundColor: UIColor.black
]

"Hello, Core Graphics!".draw(
    at: CGPoint(x: 50, y: 50),
    withAttributes: attributes
)
```

### 3️⃣ 이미지 합성

```swift
// ImageCompositionView.swift
let background = UIImage(named: "background")!
let overlay = UIImage(named: "overlay")!

let renderer = UIGraphicsImageRenderer(size: background.size)
let result = renderer.image { _ in
    background.draw(at: .zero)
    overlay.draw(at: CGPoint(x: 50, y: 50))
}
```

---

## 🧪 실행 방법

### 1. 프로젝트 열기
```bash
cd day02
open day02.xcodeproj
```

### 2. 실행
```
⌘R 또는 Play 버튼
```

### 3. 각 예제 확인
```
- 기본 도형: CGContextView 탭
- 텍스트: TextRenderingView 탭
- 이미지 합성: ImageCompositionView 탭
- 성능 비교: BenchmarkView 탭
```

---

## 📊 학습 진행 상황

### Phase 1: 개념 이해 ✅
- [x] Core Graphics 이론 문서 작성
- [x] SwiftUI Canvas 가이드 작성
- [x] 좌표계 이해
- [x] Context 개념 학습
- [x] UIGraphicsImageRenderer 학습
- [x] iOS 15+ 환경 최적화

### Phase 2: 기본 구현 ✅
- [x] CGContextView (도형, 경로, 그라디언트, 변환)
- [x] TextRenderingView (텍스트 스타일, 멀티라인, 배경)
- [x] ImageCompositionView (오버레이, 블렌드, 마스킹)
- [x] Core Graphics vs Canvas 비교 예제

### Phase 3: 성능 측정 환경 ✅
- [x] PerformanceLogger (로깅 시스템)
- [x] SignpostHelper (타이밍 측정)
- [x] MemorySampler (메모리 추적)
- [x] PERFORMANCE_GUIDE.md 작성

### Phase 4: 실전 예제 ✅
- [x] 워터마크 추가 (예제 코드)
- [x] 프로필 아바타 (원형 + 테두리)
- [x] 알림 배지 (숫자 오버레이)
- [x] 카드 디자인 (그라디언트 + 텍스트)

### Phase 5: 성능 측정 가이드 ✅
- [x] Instruments 사용법 문서화
- [x] 테스트 시나리오 작성
- [x] 측정 환경 설정 가이드
- [x] 최적화 팁 정리

---

## 🎯 핵심 개념 요약

| 개념 | 설명 |
|------|------|
| **Core Graphics** | 저수준 2D 그래픽 렌더링 API |
| **좌표계** | 왼쪽 하단이 원점 (UIKit과 반대!) |
| **Context** | 그림을 그릴 캔버스 + 상태 관리 |
| **Renderer** | UIGraphicsImageRenderer로 안전하게 |
| **State** | save/restore로 상태 스택 관리 |
| **성능** | CPU 기반, 정밀 제어 가능 |

---

## 💡 배운 것들

### Core Graphics (UIGraphicsImageRenderer)
**장점:**
- ✅ 픽셀 단위 정밀 제어
- ✅ 해상도 독립적 렌더링
- ✅ PDF 생성 가능
- ✅ 이미지 파일로 직접 저장

**단점:**
- ❌ CPU 집약적 (배터리 소모)
- ❌ C 기반 API (복잡)
- ❌ 실시간 애니메이션 부적합

**사용 시기:**
```swift
// 이미지로 저장 필요
let image = UIGraphicsImageRenderer(size: size).image { ctx in
    // 워터마크, 썸네일, PDF 등
}
```

### SwiftUI Canvas (iOS 15+)
**장점:**
- ✅ 선언적 API (SwiftUI 스타일)
- ✅ GPU 가속 가능
- ✅ 실시간 애니메이션 (TimelineView)
- ✅ SwiftUI와 완벽 통합

**단점:**
- ❌ 이미지 저장이 번거로움 (iOS 16+ ImageRenderer)
- ❌ Core Graphics보다 제한적

**사용 시기:**
```swift
// 화면에 직접 표시
Canvas { context, size in
    // 실시간 그리기, 차트, 애니메이션
}
```

### 선택 기준 (iOS 15+)
| 요구사항 | 선택 |
|----------|------|
| 이미지 파일 저장 | Core Graphics ✅ |
| 화면 표시 | SwiftUI Canvas ✅ |
| 실시간 애니메이션 | SwiftUI Canvas ✅ |
| 정밀한 픽셀 제어 | Core Graphics ✅ |
| PDF 생성 | Core Graphics ✅ |
| 빠른 개발 | SwiftUI Canvas ✅ |

---

## 📚 참고 자료

### 이 프로젝트 문서
- [CORE_GRAPHICS_THEORY.md](./CORE_GRAPHICS_THEORY.md) - 이론 총정리
- [SWIFTUI_CANVAS_GUIDE.md](./SWIFTUI_CANVAS_GUIDE.md) - Canvas 가이드

### Apple 공식 문서
**Core Graphics:**
- [Quartz 2D Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/)
- [UIGraphicsImageRenderer](https://developer.apple.com/documentation/uikit/uigraphicsimagerenderer)
- [CGContext](https://developer.apple.com/documentation/coregraphics/cgcontext)

**SwiftUI:**
- [Canvas](https://developer.apple.com/documentation/swiftui/canvas)
- [GraphicsContext](https://developer.apple.com/documentation/swiftui/graphicscontext)
- [ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer) (iOS 16+)

### WWDC 세션
- [Add rich graphics to your SwiftUI app (2021)](https://developer.apple.com/videos/play/wwdc2021/10021/) - Canvas 소개
- [What's New in Cocoa Touch (2016)](https://developer.apple.com/videos/play/wwdc2016/205/) - UIGraphicsImageRenderer
- [Image and Graphics Best Practices (2018)](https://developer.apple.com/videos/play/wwdc2018/219/)

### Day 1 참고
- [../day01/README.md](../day01-uiimage-vs-swiftui-image/day01/day01/README.md)
- [../day01/tool/](../day01-uiimage-vs-swiftui-image/day01/day01/tool/)

---

## 🚀 다음 단계

1. **이론 복습**: [CORE_GRAPHICS_THEORY.md](./CORE_GRAPHICS_THEORY.md) 다시 읽기
2. **코드 실습**: 각 View 파일 직접 구현해보기
3. **성능 측정**: Day 1 도구로 비교하기
4. **실전 적용**: 워터마크, 썸네일 만들기

---

**Happy Drawing! 🎨**

