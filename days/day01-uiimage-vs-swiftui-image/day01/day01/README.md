# Day 01: UIImage vs SwiftUI Image 성능 비교

## 📋 프로젝트 개요

SwiftUI의 `Image`와 UIKit의 `UIImageView` 중 어느 것이 더 성능이 좋은지 **과학적으로** 측정하는 프로젝트입니다.

---

## 🛠️ 구현된 도구들

### 1️⃣ PerformanceLogger.swift
- **목적**: 통합 로깅 시스템
- **특징**: 
  - Console.app에서 확인 가능
  - Instruments와 연동
  - 카테고리별 로그 분리 (bench, scroll, fps, memory)

```swift
PerformanceLogger.log("앱 시작")
PerformanceLogger.error("에러 발생", category: "bench")
```

---

### 2️⃣ SignpostHelper.swift
- **목적**: 구간 타이밍 측정의 핵심
- **특징**:
  - `os_signpost` 래핑
  - Instruments에서 그래프로 확인
  - 클로저 자동 측정 지원

```swift
// 간단 사용
Signpost.swiftUIRender.begin()
// 작업...
Signpost.swiftUIRender.end()

// 클로저 사용
let result = Signpost.imageLoad.measure {
    return heavyOperation()
}
```

---

### 3️⃣ FPSOverlay.swift
- **목적**: 실시간 FPS 시각 피드백
- **특징**:
  - 오버레이로 화면에 표시
  - CADisplayLink 사용
  - 색상으로 성능 상태 표시 (녹/황/적)

```swift
ScrollView {
    // 내용...
}
.showFPS() // 🎯 이거 하나면 끝
```

---

### 4️⃣ ScrollDetector.swift
- **목적**: 스크롤 시작/종료 자동 감지
- **특징**:
  - **SwiftUI**: PreferenceKey 기반 (간단)
  - **UIKit**: Delegate 패턴 (정확)
  - 자동으로 signpost 연동

```swift
// SwiftUI
ScrollView {
    // ...
}
.detectScrollWithSignpost(name: "ImageList")

// UIKit
scrollView.delegate = scrollDetector
```

---

### 5️⃣ MemorySampler.swift
- **목적**: 메모리 사용량 측정
- **특징**:
  - `mach_task_basic_info` 사용
  - 실시간 모니터링
  - 오버레이 표시 지원

```swift
// 간단 로그
MemorySampler.logCurrentMemory(label: "앱 시작")

// 메모리 변화 측정
let delta = MemorySampler.measureMemoryDelta {
    loadImages()
}

// SwiftUI 오버레이
ScrollView {
    // ...
}
.showMemory()
```

---

## 🧪 테스트 방법

### 📱 사전 준비

1. **실기기 연결** (시뮬레이터 금지!)
2. **Release 모드**: 
   ```
   Xcode > Product > Scheme > Edit Scheme...
   Run > Build Configuration > Release
   ```
3. **다른 앱 종료**
4. **충전 상태 확인**

### 📊 측정 절차

#### 방법 1: 앱에서 직접 확인
```
1. 앱 실행
2. SwiftUI 탭 → 스크롤
   - 화면 우측 상단: FPS 확인
   - 화면 좌측 상단: 메모리 확인
3. UIKit 탭 → 스크롤
   - 동일하게 FPS, 메모리 확인
4. 비교!
```

#### 방법 2: Console.app으로 로그 확인
```
1. Console.app 실행
2. 필터: subsystem:com.study.day01
3. 앱에서 테스트
4. 로그 저장 → 분석
```
👉 상세 가이드: [CONSOLE_APP_GUIDE.md](./CONSOLE_APP_GUIDE.md)

#### 방법 3: Instruments로 정밀 측정
```
1. Xcode > Product > Profile (⌘I)
2. Time Profiler 선택
3. 테스트 실행
4. 결과 분석
```
👉 상세 가이드: [INSTRUMENTS_GUIDE.md](./INSTRUMENTS_GUIDE.md)

---

## 📁 파일 구조

```
day01/
├── day01App.swift              # 앱 진입점
├── BenchRootView.swift         # 메인 화면 (SwiftUI/UIKit 전환)
├── ImageList.swift             # 실제 테스트 구현체
│
├── 성능 측정 도구들
├── PerformanceLogger.swift     # 1) 통합 로거
├── SignpostHelper.swift        # 2) 사인포스트 헬퍼
├── FPSOverlay.swift           # 3) FPS 오버레이
├── ScrollDetector.swift       # 4) 스크롤 감지
├── MemorySampler.swift        # 5) 메모리 측정
│
├── 가이드 문서
├── INSTRUMENTS_GUIDE.md       # 6) Instruments 사용법
├── CONSOLE_APP_GUIDE.md       # 8) Console.app 사용법
└── README.md                  # 이 파일
```

---

## 🎯 측정 항목

| 항목 | SwiftUI | UIKit | 비고 |
|------|---------|-------|------|
| **FPS** | ? | ? | 60 fps가 목표 |
| **평균 메모리** | ? | ? | 낮을수록 좋음 |
| **최대 메모리** | ? | ? | 피크 메모리 |
| **스크롤 반응 시간** | ? | ? | Signpost로 측정 |
| **CPU 사용률** | ? | ? | Instruments 필요 |

---

## 💡 핵심 발견 (테스트 후 작성)

### 예상 결과
- **SwiftUI**: 
  - 장점: 코드 간결, 선언적
  - 단점: ?
  
- **UIKit**: 
  - 장점: 성숙한 최적화
  - 단점: 코드 복잡

### 실제 결과
```
TODO: 실기기에서 측정 후 작성
```

---

## 🚀 빠른 시작

### 1. 프로젝트 열기
```bash
open day01.xcodeproj
```

### 2. 실기기 선택
```
상단 바 > 타겟 디바이스 > 내 iPhone
```

### 3. Release 모드 설정
```
Product > Scheme > Edit Scheme... > Run > Release
```

### 4. 실행
```
⌘R 또는 Play 버튼
```

### 5. 측정 시작!
```
1. SwiftUI 탭 클릭
2. 스크롤하며 FPS 확인
3. UIKit 탭 클릭
4. 스크롤하며 FPS 확인
5. 비교!
```

---

## 🔧 커스터마이징

### 이미지 개수 변경
```swift:ImageList.swift
ForEach(0..<100, id: \.self) { // 100 → 500으로 변경
```

### FPS 업데이트 주기 변경
```swift:FPSOverlay.swift
if elapsed >= 1.0 { // 1초 → 0.5초로 변경
```

### 메모리 샘플링 주기 변경
```swift:ImageList.swift
MemoryMonitor(interval: 1.0) // 1초 → 2초로 변경
```

---

## 📚 참고 자료

### Apple 공식 문서
- [Measuring Performance](https://developer.apple.com/documentation/xcode/measuring-performance)
- [Using Signposts](https://developer.apple.com/documentation/os/logging/recording_performance_data)
- [Instruments Help](https://help.apple.com/instruments/)

### WWDC 세션
- [Explore UI animation hitches and the render loop](https://developer.apple.com/videos/play/wwdc2020/10077/)
- [Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/)

---

## ⚠️ 주의사항

1. **반드시 실기기에서 테스트**: 시뮬레이터는 Mac의 성능을 사용하므로 부정확
2. **Release 모드 필수**: Debug는 최적화가 꺼져있음
3. **첫 실행 제외**: 캐시가 없어서 느림
4. **배터리 충전 상태 확인**: 저전력 모드는 성능 제한
5. **과열 주의**: 기기가 뜨거우면 쓰로틀링 발생

---

## 🎓 학습 목표

이 프로젝트를 통해 배울 수 있는 것:

- ✅ SwiftUI와 UIKit의 성능 차이
- ✅ os_signpost를 활용한 프로파일링
- ✅ Instruments 사용법
- ✅ Console.app 활용
- ✅ CADisplayLink로 FPS 측정
- ✅ mach_task_basic_info로 메모리 측정
- ✅ 실무에서 사용 가능한 성능 측정 패턴

---

## 🤝 기여

이 프로젝트는 학습 목적으로 만들어졌습니다. 개선 사항이 있다면:

1. 더 정확한 측정 방법
2. 추가 성능 지표
3. 문서 개선
4. 버그 수정

---

**Happy Benchmarking! 🚀**

