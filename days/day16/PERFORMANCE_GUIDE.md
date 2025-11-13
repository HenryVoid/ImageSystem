# 성능 측정 가이드

> 카메라 세션의 성능을 측정하고 최적화하는 방법

---

## 🎯 목표

- FPS (프레임률) 측정
- 메모리 사용량 모니터링
- 성능 병목 지점 파악
- 최적화 기법 적용

---

## 📊 성능 측정 도구

### 1. PerformanceMonitor

실시간 FPS 및 메모리 사용량을 측정합니다.

```swift
@StateObject private var performanceMonitor = PerformanceMonitor()

// 모니터링 시작
performanceMonitor.startMonitoring()

// 모니터링 중지
performanceMonitor.stopMonitoring()
```

**측정 항목**:
- **FPS**: 초당 프레임 수 (목표: 60 fps)
- **메모리**: 현재 메모리 사용량 (MB/GB)

### 2. MemorySampler

메모리 사용량을 샘플링하고 측정합니다.

```swift
// 현재 메모리 사용량
let usage = MemorySampler.currentUsage()

// 포맷된 메모리 사용량
let formatted = MemorySampler.formattedUsage()  // "150 MB"

// 메모리 차이 측정
let (result, memoryUsed) = MemorySampler.measure("캡처") {
    sessionManager.capturePhoto()
}
```

### 3. PerformanceLogger

성능 로그를 기록합니다.

```swift
PerformanceLogger.log("세션 시작", category: "camera")
PerformanceLogger.error("세션 실패", category: "camera")
PerformanceLogger.debug("디버그 정보", category: "camera")
```

---

## 🔍 성능 측정 방법

### 방법 1: 앱 화면에서 직접 확인 (가장 쉬움)

**장점**: 즉시 확인 가능, 시각적
**단점**: 정밀하지 않음

**사용법**:
1. CameraFlowView 실행
2. 우측 상단 성능 모니터 확인
   - FPS: 초록색 (60 fps 이상) / 빨간색 (60 fps 미만)
   - 메모리: 현재 사용량 표시
3. 카메라 조작하며 성능 변화 관찰

### 방법 2: Console.app으로 로그 분석 (실용적)

**장점**: 상세한 로그, 저장 가능
**단점**: 추가 앱 필요

**사용법**:
1. Console.app 실행
2. 필터: `subsystem:com.study.day16`
3. 앱에서 테스트
4. 로그 저장 (⌘S)
5. 분석

**확인 내용**:
- 세션 시작/종료 타이밍
- FPS 추이 (1초마다)
- 메모리 변화량
- 캡처 시 메모리 증가량

### 방법 3: Instruments로 정밀 측정 (전문가용)

**장점**: 가장 정확, 그래프, CPU/GPU/메모리 모두
**단점**: 학습 필요, 시간 소요

**사용법**:
1. Xcode > Product > Profile (⌘I)
2. 템플릿 선택:
   - **Time Profiler**: CPU 사용률
   - **Allocations**: 메모리 할당
   - **System Trace**: 전체 시스템 추적
3. 녹화 → 테스트 → 분석

**확인 내용**:
- CPU 시간 비교
- 메모리 피크 비교
- 프레임 드롭 구간
- 메모리 누수 여부

---

## 📈 성능 지표

### FPS (프레임률)

**목표**: 60 fps

**측정**:
```swift
let monitor = PerformanceMonitor()
monitor.startMonitoring()
// FPS는 monitor.fps로 접근
```

**최적화 팁**:
- 세션 preset 조정 (`.photo` → `.medium`)
- 미리보기 해상도 낮추기
- 불필요한 UI 업데이트 줄이기

### 메모리 사용량

**목표**: 안정적인 사용량 유지

**측정**:
```swift
let usage = MemorySampler.currentUsage()
let formatted = MemorySampler.formattedUsage()
```

**최적화 팁**:
- 세션 생명주기 관리
- 이미지 메모리 해제
- 백그라운드 전환 시 세션 중지

---

## ⚡ 최적화 기법

### 1. 세션 Preset 조정

```swift
// 고품질 (메모리 많이 사용)
session.sessionPreset = .photo

// 중간 품질 (균형)
session.sessionPreset = .high

// 낮은 품질 (메모리 적게 사용)
session.sessionPreset = .medium
```

### 2. 세션 생명주기 관리

```swift
// 뷰가 나타날 때만 세션 시작
.onAppear {
    sessionManager.startSession()
}

// 뷰가 사라질 때 세션 중지
.onDisappear {
    sessionManager.stopSession()
}
```

### 3. 백그라운드 전환 처리

```swift
// 앱이 백그라운드로 갈 때 세션 중지
NotificationCenter.default.addObserver(
    forName: UIApplication.willResignActiveNotification,
    object: nil,
    queue: .main
) { _ in
    sessionManager.stopSession()
}

// 앱이 포그라운드로 돌아올 때 세션 재시작
NotificationCenter.default.addObserver(
    forName: UIApplication.didBecomeActiveNotification,
    object: nil,
    queue: .main
) { _ in
    sessionManager.startSession()
}
```

### 4. 메모리 효율적인 이미지 처리

```swift
// 큰 이미지는 즉시 해제
func photoOutput(_ output: AVCapturePhotoOutput,
                 didFinishProcessingPhoto photo: AVCapturePhoto,
                 error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else { return }
    
    // 이미지 처리 후 메모리 해제
    DispatchQueue.main.async {
        self.handleImage(image)
        // image는 자동으로 해제됨
    }
}
```

### 5. 세션 큐 사용

```swift
// 세션 작업은 백그라운드 큐에서 수행
private let sessionQueue = DispatchQueue(label: "camera.session.queue")

sessionQueue.async {
    session.beginConfiguration()
    // 설정 변경
    session.commitConfiguration()
    session.startRunning()
}
```

---

## 🐛 성능 문제 해결

### FPS가 낮습니다 (60 fps 미만)

**원인**:
- 세션 preset이 너무 높음
- UI 업데이트가 너무 많음
- 메인 스레드 블로킹

**해결**:
1. 세션 preset을 `.medium`으로 낮추기
2. UI 업데이트 최소화
3. 무거운 작업을 백그라운드 큐로 이동

### 메모리 사용량이 계속 증가합니다

**원인**:
- 이미지 메모리 누수
- 세션이 제대로 중지되지 않음
- 순환 참조

**해결**:
1. Instruments로 메모리 누수 확인
2. 세션 생명주기 확인
3. weak self 사용 확인

### 세션 시작이 느립니다

**원인**:
- 세션 설정이 메인 스레드에서 수행됨
- 동기 작업이 많음

**해결**:
1. 세션 설정을 백그라운드 큐로 이동
2. 비동기 작업 사용

---

## 📊 벤치마크 예시

### 기본 세션 구성

```
세션 생성: ~50ms
입력 추가: ~30ms
출력 추가: ~20ms
세션 시작: ~100ms
총 시간: ~200ms
```

### 사진 캡처

```
캡처 요청: ~10ms
이미지 처리: ~100-500ms (이미지 크기에 따라)
총 시간: ~110-510ms
```

### 메모리 사용량

```
기본 세션: ~50-100 MB
미리보기: +20-30 MB
사진 캡처: +10-50 MB (이미지 크기에 따라)
```

---

## 🎯 실전 팁

### 1. 성능 모니터 표시

```swift
VStack {
    HStack {
        Spacer()
        PerformanceStatsView(monitor: performanceMonitor)
            .padding()
    }
    Spacer()
}
```

### 2. 성능 로그 기록

```swift
PerformanceLogger.log("세션 시작", category: "camera")
PerformanceLogger.log("FPS: \(fps)", category: "fps")
PerformanceLogger.log("메모리: \(memory)", category: "memory")
```

### 3. 성능 임계값 설정

```swift
if monitor.fps < 55 {
    // 성능 저하 경고
    PerformanceLogger.error("FPS 저하 감지: \(monitor.fps)", category: "fps")
}
```

---

## 📚 참고 자료

- [Instruments User Guide](https://developer.apple.com/documentation/xcode/instruments)
- [Performance Best Practices](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [Memory Management](https://developer.apple.com/documentation/swift/memory-management)

---

**Happy Optimizing! ⚡**

