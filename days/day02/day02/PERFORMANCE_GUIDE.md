# Core Graphics vs Canvas 성능 측정 가이드

> Day 2: 렌더링 성능 비교 및 측정 방법

---

## 🎯 목표

Core Graphics와 SwiftUI Canvas의 성능을 **정량적으로** 비교 측정합니다.

---

## 📊 측정 지표

### 1️⃣ 렌더링 시간
- **지표**: 이미지 생성/그리기에 걸리는 시간
- **도구**: `os_signpost` (Instruments)
- **목표**: 밀리초 단위 정확도

### 2️⃣ 메모리 사용량
- **지표**: 렌더링 중 메모리 증가량
- **도구**: `mach_task_basic_info`
- **목표**: MB 단위 추적

### 3️⃣ CPU 사용률
- **지표**: 렌더링 중 CPU 부하
- **도구**: Instruments Time Profiler
- **목표**: % 단위 측정

---

## 🛠️ 측정 도구

### PerformanceLogger.swift
```swift
// 기본 로깅
PerformanceLogger.log("렌더링 시작", category: "render")

// 에러 로깅
PerformanceLogger.error("렌더링 실패", category: "render")

// 디버그 로깅 (DEBUG 빌드만)
PerformanceLogger.debug("디버그 정보", category: "graphics")
```

**카테고리:**
- `bench`: 일반 벤치마크
- `render`: 렌더링 성능
- `memory`: 메모리 사용
- `graphics`: 그래픽 관련

### SignpostHelper.swift
```swift
// 방법 1: 수동 측정
let signpost = Signpost.coreGraphicsRender(label: "도형 100개")
signpost.begin()
// 렌더링 작업...
signpost.end()

// 방법 2: 클로저 자동 측정
let image = Signpost.coreGraphicsRender(label: "워터마크").measure {
    return addWatermark(to: originalImage)
}

// 방법 3: 비동기
let result = await Signpost.canvasRender(label: "애니메이션").measureAsync {
    await performHeavyRendering()
}
```

**Signpost 종류:**
- `coreGraphicsRender`: Core Graphics 렌더링
- `canvasRender`: SwiftUI Canvas 렌더링
- `textRender`: 텍스트 렌더링
- `imageComposite`: 이미지 합성

### MemorySampler.swift
```swift
// 현재 메모리 로그
MemorySampler.logCurrentMemory(label: "렌더링 전")

// 메모리 변화 측정
let delta = MemorySampler.measureMemoryDelta {
    let image = createComplexGraphics()
}
// 로그: "메모리 변화: +15.3 MB"

// SwiftUI에서 실시간 모니터링
Canvas { context, size in
    // 그리기...
}
.showMemory() // 좌측 상단에 메모리 표시
```

---

## 📈 Instruments 사용법

### 1. Time Profiler로 CPU 측정

```bash
# Xcode에서
Product > Profile (⌘I)
→ Time Profiler 선택
→ Record 버튼
```

**측정 순서:**
1. 앱 실행 후 Core Graphics 탭 선택
2. 렌더링 수행
3. SwiftUI Canvas 탭 선택
4. 동일한 렌더링 수행
5. Instruments에서 CPU 사용량 비교

### 2. Allocations로 메모리 측정

```bash
Product > Profile (⌘I)
→ Allocations 선택
→ Record 버튼
```

**측정 순서:**
1. Snapshot 생성 (기준점)
2. Core Graphics 렌더링 수행
3. Snapshot 생성 (비교)
4. 메모리 증가량 확인
5. Canvas 렌더링도 동일하게 측정

### 3. os_signpost로 타이밍 측정

```bash
Product > Profile (⌘I)
→ Instruments 선택
→ 우측 상단 + 버튼
→ os_signpost 추가
```

**필터 설정:**
```
Subsystem: com.study.day02
Category: render
```

**분석:**
- 파란색 막대: 렌더링 구간
- 길이: 소요 시간
- Core Graphics vs Canvas 비교

---

## 🧪 테스트 시나리오

### 시나리오 1: 기본 도형 그리기 (100개)

**Core Graphics:**
```swift
let signpost = Signpost.coreGraphicsRender(label: "도형 100개")
let image = signpost.measure {
    return UIGraphicsImageRenderer(size: size).image { context in
        for i in 0..<100 {
            // 도형 그리기
        }
    }
}
```

**SwiftUI Canvas:**
```swift
Canvas { context, size in
    let signpost = Signpost.canvasRender(label: "도형 100개")
    signpost.begin()
    
    for i in 0..<100 {
        // 도형 그리기
    }
    
    signpost.end()
}
```

**측정 항목:**
- ⏱️ 렌더링 시간 (ms)
- 🧠 메모리 사용량 (MB)
- 💻 CPU 사용률 (%)

### 시나리오 2: 텍스트 렌더링 (1000줄)

**Core Graphics:**
```swift
let delta = MemorySampler.measureMemoryDelta {
    let image = Signpost.textRender(label: "1000줄").measure {
        return drawThousandLines()
    }
}
```

**SwiftUI Canvas:**
```swift
Canvas { context, size in
    let signpost = Signpost.textRender(label: "1000줄")
    signpost.begin()
    
    for i in 0..<1000 {
        let text = Text("Line \(i)")
        context.draw(text, at: CGPoint(x: 0, y: CGFloat(i * 20)))
    }
    
    signpost.end()
}
.showMemory()
```

### 시나리오 3: 이미지 합성 (50장)

**Core Graphics:**
```swift
let signpost = Signpost.imageComposite(label: "50장 합성")
let result = signpost.measure {
    return UIGraphicsImageRenderer(size: size).image { context in
        for i in 0..<50 {
            // 이미지 합성
        }
    }
}
```

**SwiftUI Canvas:**
```swift
Canvas { context, size in
    let signpost = Signpost.imageComposite(label: "50장 합성")
    signpost.begin()
    
    for i in 0..<50 {
        // 이미지 합성
    }
    
    signpost.end()
}
```

---

## 📊 결과 분석 템플릿

### Core Graphics vs SwiftUI Canvas

| 시나리오 | 지표 | Core Graphics | SwiftUI Canvas | 승자 |
|----------|------|---------------|----------------|------|
| 도형 100개 | 시간 | ? ms | ? ms | ? |
| | 메모리 | ? MB | ? MB | ? |
| | CPU | ? % | ? % | ? |
| 텍스트 1000줄 | 시간 | ? ms | ? ms | ? |
| | 메모리 | ? MB | ? MB | ? |
| | CPU | ? % | ? % | ? |
| 이미지 50장 | 시간 | ? ms | ? ms | ? |
| | 메모리 | ? MB | ? MB | ? |
| | CPU | ? % | ? % | ? |

### 예상 결과

**Core Graphics:**
- ✅ 이미지 저장 시 빠름
- ✅ 메모리 사용량 예측 가능
- ❌ CPU 사용량 높음
- ❌ 복잡한 렌더링은 느림

**SwiftUI Canvas:**
- ✅ 화면 렌더링 빠름
- ✅ GPU 가속 가능
- ❌ 이미지 저장 어려움
- ❌ 메모리 사용량 가변적

---

## 🔧 측정 환경 설정

### 1. Release 빌드 설정
```
Xcode > Product > Scheme > Edit Scheme...
Run > Build Configuration > Release
```

**이유:** Debug 빌드는 최적화가 꺼져있어 부정확함

### 2. 실기기 테스트
```
시뮬레이터 ❌ → Mac의 성능 사용
실기기 ✅ → 실제 성능 측정
```

### 3. 환경 통제
- ✅ 다른 앱 종료
- ✅ 충전 상태
- ✅ 저전력 모드 끄기
- ✅ 여러 번 측정 후 평균

### 4. Console.app 필터링
```
Subsystem: com.study.day02
Category: render, memory, graphics
```

---

## 💡 최적화 팁

### Core Graphics 최적화
```swift
// ✅ 좋은 예: format 재사용
let format = UIGraphicsImageRendererFormat()
format.scale = UIScreen.main.scale
format.opaque = true  // 불투명 배경이면 더 빠름

let renderer = UIGraphicsImageRenderer(size: size, format: format)

// ❌ 나쁜 예: 매번 새로 생성
for i in 0..<100 {
    let renderer = UIGraphicsImageRenderer(size: size)  // 비효율
}
```

### SwiftUI Canvas 최적화
```swift
// ✅ 좋은 예: 레이어 분리
Canvas { context, size in
    // 정적 배경 (변하지 않음)
    context.drawLayer { layerContext in
        drawStaticBackground(layerContext, size)
    }
    
    // 동적 요소만 매번 그리기
    drawDynamicElements(context, size)
}

// ❌ 나쁜 예: 모든 것을 매번 그리기
Canvas { context, size in
    drawEverythingEveryFrame(context, size)
}
```

---

## 📚 참고 자료

### Apple 문서
- [Measuring Performance](https://developer.apple.com/documentation/xcode/measuring-performance)
- [Using Signposts](https://developer.apple.com/documentation/os/logging/recording_performance_data)
- [Instruments Help](https://help.apple.com/instruments/)

### WWDC
- [Explore UI animation hitches and the render loop (2020)](https://developer.apple.com/videos/play/wwdc2020/10077/)
- [Demystify SwiftUI performance (2023)](https://developer.apple.com/videos/play/wwdc2023/10160/)

---

## ✅ 체크리스트

측정 전:
- [ ] Release 빌드로 변경
- [ ] 실기기 연결
- [ ] 다른 앱 종료
- [ ] 충전 상태 확인
- [ ] Instruments 준비

측정 중:
- [ ] PerformanceLogger로 로그 기록
- [ ] SignpostHelper로 타이밍 측정
- [ ] MemorySampler로 메모리 추적
- [ ] Instruments로 CPU/메모리 프로파일링

측정 후:
- [ ] Console.app에서 로그 확인
- [ ] Instruments 결과 분석
- [ ] 결과 표 작성
- [ ] 최적화 포인트 도출

---

**Happy Benchmarking! 📊**

