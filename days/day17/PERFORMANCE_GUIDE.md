# 동영상 녹화 성능 가이드

> 동영상 녹화 시 성능 최적화 및 모니터링 가이드

---

## 📊 성능 측정 항목

### 1. FPS (Frames Per Second)

**목표**: 30 FPS 이상 유지

```swift
// CADisplayLink로 FPS 측정
private var displayLink: CADisplayLink?
private var lastTimestamp: CFTimeInterval = 0
private var frameCount: Int = 0

func startFPSTracking() {
    displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
    displayLink?.add(to: .main, forMode: .common)
}

@objc private func updateFPS() {
    let currentTimestamp = CACurrentMediaTime()
    frameCount += 1
    
    let elapsed = currentTimestamp - lastTimestamp
    if elapsed >= 1.0 {
        let fps = Double(frameCount) / elapsed
        print("FPS: \(fps)")
        
        frameCount = 0
        lastTimestamp = currentTimestamp
    }
}
```

---

### 2. 메모리 사용량

**목표**: 녹화 중 메모리 증가 최소화

```swift
func measureMemoryUsage() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        let memoryMB = Double(info.resident_size) / 1024.0 / 1024.0
        print("메모리 사용량: \(String(format: "%.2f", memoryMB)) MB")
    }
}
```

---

### 3. 파일 크기

**목표**: 적절한 파일 크기 유지

```swift
func getFileSize(url: URL) -> Int64 {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
          let fileSize = attributes[.size] as? Int64 else {
        return 0
    }
    return fileSize
}

func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
```

---

## ⚡ 성능 최적화 팁

### 1. 세션 Preset 선택

**권장 설정**:

```swift
// 고품질이 필요하면
session.sessionPreset = .high

// 성능이 중요하면
session.sessionPreset = .medium

// 최대 성능이 필요하면
session.sessionPreset = .low
```

**비교**:

| Preset | 해상도 | FPS | 메모리 |
|--------|--------|-----|--------|
| `.high` | 1920x1080 | 30 | 높음 |
| `.medium` | 1280x720 | 30 | 중간 |
| `.low` | 640x480 | 30 | 낮음 |

---

### 2. 최대 녹화 시간 제한

**과도한 녹화 방지**:

```swift
movieOutput.maxRecordedDuration = CMTime(seconds: 60, preferredTimescale: 600)
```

**효과**:
- 메모리 사용량 제한
- 파일 크기 예측 가능
- 저장 공간 관리

---

### 3. 최대 파일 크기 제한

**디스크 공간 보호**:

```swift
movieOutput.maxRecordedFileSize = 100 * 1024 * 1024 // 100MB
```

**효과**:
- 디스크 공간 보호
- 예상치 못한 대용량 파일 방지

---

### 4. 세션 Queue 사용

**메인 스레드 블로킹 방지**:

```swift
private let sessionQueue = DispatchQueue(label: "video.session.queue")

func startRecording() {
    sessionQueue.async { [weak self] in
        // 세션 작업은 백그라운드에서
        guard let self = self else { return }
        // ...
    }
}
```

**효과**:
- UI 반응성 유지
- 세션 작업 분리

---

### 5. Preview Layer 최적화

**비디오 Gravity 설정**:

```swift
previewLayer.videoGravity = .resizeAspectFill // 성능 좋음
// .resizeAspect // 중간
// .resize // 성능 낮음
```

**효과**:
- 렌더링 성능 향상
- 메모리 사용량 감소

---

## 🔍 성능 모니터링

### 실시간 모니터링

```swift
class PerformanceMonitor: ObservableObject {
    @Published var fps: Double = 0
    @Published var memoryUsage: String = "0 MB"
    @Published var fileSize: String = "0 MB"
    
    private var displayLink: CADisplayLink?
    private var memoryTimer: Timer?
    private var fileSizeTimer: Timer?
    
    func startMonitoring() {
        // FPS 측정
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .common)
        
        // 메모리 측정 (1초마다)
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMemory()
        }
        
        // 파일 크기 측정 (1초마다)
        fileSizeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateFileSize()
        }
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        memoryTimer?.invalidate()
        fileSizeTimer?.invalidate()
    }
}
```

---

## 📈 성능 벤치마크

### 테스트 시나리오

1. **짧은 녹화** (10초)
   - 목표 FPS: 30+
   - 메모리 증가: <50MB
   - 파일 크기: <10MB

2. **중간 녹화** (30초)
   - 목표 FPS: 30+
   - 메모리 증가: <100MB
   - 파일 크기: <30MB

3. **긴 녹화** (60초)
   - 목표 FPS: 30+
   - 메모리 증가: <150MB
   - 파일 크기: <60MB

---

## ⚠️ 성능 문제 해결

### FPS가 낮은 경우

**원인**:
- 세션 Preset이 너무 높음
- 메인 스레드에서 세션 작업 수행
- Preview Layer 설정 문제

**해결**:
```swift
// Preset 낮추기
session.sessionPreset = .medium

// 세션 Queue 사용
sessionQueue.async { ... }

// Preview Gravity 변경
previewLayer.videoGravity = .resizeAspectFill
```

---

### 메모리 사용량이 높은 경우

**원인**:
- 녹화 시간이 너무 김
- 파일 크기 제한 없음
- 메모리 누수

**해결**:
```swift
// 최대 녹화 시간 제한
movieOutput.maxRecordedDuration = CMTime(seconds: 60, preferredTimescale: 600)

// 최대 파일 크기 제한
movieOutput.maxRecordedFileSize = 100 * 1024 * 1024

// 녹화 완료 후 정리
func cleanup() {
    recordingTimer?.invalidate()
    recordingTimer = nil
}
```

---

### 파일 크기가 큰 경우

**원인**:
- 해상도가 너무 높음
- 비트레이트가 높음
- 코덱 설정 문제

**해결**:
```swift
// Preset 낮추기
session.sessionPreset = .medium

// 비트레이트 제한 (고급)
let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 5_000_000 // 5Mbps
    ]
]
```

---

## 📚 참고 자료

### Instruments 사용

1. **Time Profiler**: CPU 사용량 분석
2. **Allocations**: 메모리 할당 추적
3. **Leaks**: 메모리 누수 감지

### 성능 로깅

```swift
func logPerformance(metric: String, value: Double) {
    let logMessage = "[Performance] \(metric): \(value)"
    print(logMessage)
    // 또는 파일/서버에 저장
}
```

---

## ✅ 체크리스트

성능 최적화를 완료했다면:

- [ ] FPS가 30 이상 유지되는가?
- [ ] 메모리 사용량이 적절한가?
- [ ] 파일 크기가 예상 범위 내인가?
- [ ] UI가 부드럽게 동작하는가?
- [ ] 녹화 중 앱이 크래시하지 않는가?

---

**Happy Optimizing! ⚡**

