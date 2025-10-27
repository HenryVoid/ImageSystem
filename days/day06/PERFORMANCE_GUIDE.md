# SwiftUI Image 성능 최적화 가이드

> SwiftUI Image 렌더링 성능을 최적화하여 부드러운 60fps를 달성하세요.

---

## 📚 목차

1. [성능 측정 기초](#성능-측정-기초)
2. [렌더링 파이프라인 이해](#렌더링-파이프라인-이해)
3. [메모리 최적화](#메모리-최적화)
4. [렌더링 속도 최적화](#렌더링-속도-최적화)
5. [스크롤 성능](#스크롤-성능)
6. [Retina 디스플레이 최적화](#retina-디스플레이-최적화)
7. [실기기 테스트](#실기기-테스트)

---

## 성능 측정 기초

### 측정 지표

| 지표 | 목표 | 도구 |
|------|------|------|
| **FPS** | 60 fps | Instruments (Core Animation) |
| **렌더링 시간** | < 16ms | os_signpost |
| **메모리** | 최소화 | Instruments (Allocations) |
| **CPU** | < 50% | Instruments (Time Profiler) |

### 16ms 규칙

```
60 fps = 1000ms ÷ 60 = 16.67ms per frame

1 프레임을 16ms 안에 완료해야:
- 레이아웃 계산: ~3ms
- 렌더링: ~10ms
- 여유: ~3ms
```

**초과 시**:
- 16ms 초과 → 프레임 드랍 → 끊김 현상

### os_signpost로 측정

```swift
import os.signpost

let log = OSLog(subsystem: "com.study.day06", category: "rendering")

// 렌더링 구간 측정
os_signpost(.begin, log: log, name: "Image Rendering")
// ... 이미지 렌더링 코드
os_signpost(.end, log: log, name: "Image Rendering")
```

**Instruments에서 확인**:
1. Xcode → Product → Profile (⌘I)
2. os_signpost 템플릿 선택
3. 그래프로 시간 확인

---

## 렌더링 파이프라인 이해

### SwiftUI 렌더링 단계

```
1. View Body 계산
   ↓
2. 레이아웃 계산
   ↓
3. 이미지 디코딩
   ↓
4. 스케일링/보간
   ↓
5. Core Animation 커밋
   ↓
6. GPU 렌더링
   ↓
7. 화면 출력
```

### 각 단계의 비용

```swift
// ⚡ 빠름 (< 1ms)
Image(systemName: "star")  // 벡터, 캐시됨

// 🔶 중간 (~5ms)
Image("small-icon")
    .resizable()
    .frame(width: 50, height: 50)

// 🔴 느림 (~20ms)
Image("4K-photo")
    .resizable()
    .interpolation(.high)
    .frame(width: 2000, height: 1500)
```

### 병목 지점

1. **이미지 디코딩**: JPEG/PNG 압축 해제
2. **스케일링**: 큰 이미지 축소
3. **보간 계산**: `.high` 품질
4. **메모리 복사**: CPU → GPU

---

## 메모리 최적화

### 원본 크기 문제

```swift
// ❌ 나쁜 예: 4K 이미지를 작게 표시
Image("4K-photo")  // 4032 × 3024 = 48MB
    .resizable()
    .frame(width: 100, height: 100)  // 메모리는 48MB 사용
```

**문제**:
- 원본 이미지 전체를 메모리에 로드
- 100×100으로 표시해도 48MB 사용
- 100개 로드 시 4.8GB 💥

### 해결: 다운샘플링

```swift
// ✅ 좋은 예: 미리 축소된 이미지 사용
// Asset Catalog에 여러 크기 준비
Image("photo-thumbnail")  // 200 × 200 = 160KB
    .resizable()
    .frame(width: 100, height: 100)  // 메모리 160KB

// 또는 동적 다운샘플링
func downsample(imageAt url: URL, to size: CGSize) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
        kCGImageSourceCreateThumbnailFromImageAlways: true
    ]
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        return nil
    }
    return UIImage(cgImage: cgImage)
}
```

### LazyVStack/LazyHStack

```swift
// ❌ 나쁜 예: 즉시 모든 이미지 로드
VStack {
    ForEach(0..<100) { i in
        Image("photo-\(i)")  // 100개 모두 즉시 로드
            .resizable()
            .frame(height: 200)
    }
}
// 메모리: 100 × 48MB = 4.8GB 💥

// ✅ 좋은 예: 화면에 보이는 것만 로드
ScrollView {
    LazyVStack {
        ForEach(0..<100) { i in
            Image("photo-\(i)")  // 보이는 ~5개만 로드
                .resizable()
                .frame(height: 200)
        }
    }
}
// 메모리: 5 × 48MB = 240MB ✅
```

### 메모리 압박 대응

```swift
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    init() {
        // 메모리 압박 시 자동 해제
        cache.totalCostLimit = 100 * 1024 * 1024  // 100MB
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc func clearCache() {
        cache.removeAllObjects()
    }
}
```

---

## 렌더링 속도 최적화

### interpolation 선택

```swift
// 성능 비교 (100개 이미지 렌더링)
.interpolation(.none)   // 15ms  ⚡ 가장 빠름
.interpolation(.low)    // 25ms  ⚡ 빠름
.interpolation(.medium) // 45ms  🔶 기본 (권장)
.interpolation(.high)   // 120ms 🔴 느림
```

**권장 사용**:

```swift
// 스크롤 뷰: .medium
ScrollView {
    LazyVStack {
        ForEach(images) { img in
            Image(img)
                .resizable()
                .interpolation(.medium)  // 균형
                .frame(height: 200)
        }
    }
}

// 정적 화면: .high
struct DetailView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(.high)  // 최고 품질
            .aspectRatio(contentMode: .fit)
    }
}
```

### resizable() 최소화

```swift
// ❌ 나쁜 예: SF Symbol에 resizable()
Image(systemName: "star.fill")
    .resizable()
    .frame(width: 20, height: 20)

// ✅ 좋은 예: font()로 크기 조절
Image(systemName: "star.fill")
    .font(.system(size: 20))  // 벡터라 빠름
```

### clipped() 활용

```swift
// ❌ 나쁜 예: 넘친 부분도 렌더링
Image("wide-photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 300, height: 200)
// GPU가 보이지 않는 부분도 렌더링

// ✅ 좋은 예: 보이는 부분만
Image("wide-photo")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 300, height: 200)
    .clipped()  // 넘친 부분 제거
```

### 조건부 렌더링

```swift
// ❌ 나쁜 예: 보이지 않아도 렌더링
struct ImageCard: View {
    let image: String
    let isVisible: Bool
    
    var body: some View {
        VStack {
            Image(image)
                .resizable()
                .frame(height: 300)
                .opacity(isVisible ? 1 : 0)  // 렌더링은 됨!
            
            Text("Title")
        }
    }
}

// ✅ 좋은 예: 조건부로 생성
struct ImageCard: View {
    let image: String
    let isVisible: Bool
    
    var body: some View {
        VStack {
            if isVisible {
                Image(image)
                    .resizable()
                    .frame(height: 300)
            }
            
            Text("Title")
        }
    }
}
```

---

## 스크롤 성능

### 목표

- **60 fps** 유지
- **끊김 없음** (hitch-free)
- **부드러운 스크롤**

### 최적화 체크리스트

```swift
ScrollView {
    LazyVStack(spacing: 10) {  // ✅ Lazy 사용
        ForEach(images, id: \.self) { imageName in
            Image(imageName)
                .resizable()
                .interpolation(.medium)  // ✅ .high 대신 .medium
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()  // ✅ 넘친 부분 자르기
        }
    }
}
```

### 실시간 측정

```swift
struct PerformanceView: View {
    @StateObject private var fpsMonitor = FPSMonitor()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                LazyVStack {
                    ForEach(0..<100) { i in
                        Image("photo-\(i)")
                            .resizable()
                            .frame(height: 200)
                    }
                }
            }
            
            // FPS 표시
            Text("\(fpsMonitor.fps) fps")
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(fpsColor)
                .cornerRadius(8)
                .padding()
        }
    }
    
    var fpsColor: Color {
        if fpsMonitor.fps >= 55 { return .green }
        if fpsMonitor.fps >= 45 { return .yellow }
        return .red
    }
}
```

### 프리페칭 (고급)

```swift
// 다음 이미지 미리 로드
class ImagePrefetcher: ObservableObject {
    func prefetch(at indices: [Int]) {
        DispatchQueue.global(qos: .utility).async {
            for index in indices {
                let imageName = "photo-\(index)"
                _ = UIImage(named: imageName)  // 캐시에 로드
            }
        }
    }
}

struct PrefetchingList: View {
    @StateObject private var prefetcher = ImagePrefetcher()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<100) { i in
                    Image("photo-\(i)")
                        .resizable()
                        .frame(height: 200)
                        .onAppear {
                            // 다음 5개 미리 로드
                            prefetcher.prefetch(at: Array(i+1...min(i+5, 99)))
                        }
                }
            }
        }
    }
}
```

---

## Retina 디스플레이 최적화

### 디바이스별 스케일

| 디바이스 | 스케일 | 논리적 100px | 실제 픽셀 |
|----------|--------|--------------|-----------|
| iPad 2 | 1x | 100 × 100 | 100 × 100 |
| iPhone 8 | 2x | 100 × 100 | 200 × 200 |
| iPhone 15 Pro | 3x | 100 × 100 | 300 × 300 |

### Asset Catalog 활용

```
sample.imageset/
  ├── sample.png      (100 × 100)   → 1x
  ├── sample@2x.png   (200 × 200)   → 2x
  └── sample@3x.png   (300 × 300)   → 3x
```

**자동 선택**:
```swift
Image("sample")  // 디바이스에 맞게 자동 선택
    .resizable()
    .frame(width: 100, height: 100)
// iPhone 15 Pro: sample@3x.png 사용
// iPhone 8: sample@2x.png 사용
```

### 동적 스케일 대응

```swift
// 현재 디바이스 스케일
let scale = UIScreen.main.scale  // 2.0 or 3.0

// 필요한 실제 픽셀 크기 계산
let logicalSize: CGFloat = 100
let actualSize = logicalSize * scale  // 200 또는 300

// 최적 크기로 로드
let optimizedImage = downsample(
    imageAt: url,
    to: CGSize(width: actualSize, height: actualSize)
)
```

### 벡터 이미지 활용

```swift
// PDF 벡터 이미지 (확장 시 깨지지 않음)
// sample.imageset/
//   └── sample.pdf

Image("sample")  // 모든 스케일에 선명
    .resizable()
    .frame(width: 200, height: 200)
// 2x 디바이스: 400×400 렌더링
// 3x 디바이스: 600×600 렌더링
```

**SF Symbols는 벡터**:
```swift
// 모든 크기에 선명
Image(systemName: "star.fill")
    .font(.system(size: 200))  // 자유로운 크기 조절
```

---

## 실기기 테스트

### 준비 사항

1. **실기기 연결** (시뮬레이터 금지!)
2. **Release 모드**:
   ```
   Edit Scheme → Run → Build Configuration → Release
   ```
3. **다른 앱 종료**
4. **충전 상태 확인**

### Console.app으로 로그 확인

```bash
1. Console.app 실행
2. 필터: subsystem:com.study.day06
3. 앱에서 테스트
4. 로그 분석
```

**로그 예시**:
```
[rendering] Image load: 15ms
[rendering] Interpolation: 8ms
[memory] Current usage: 145MB
```

### Instruments 프로파일링

#### Time Profiler
```
1. Xcode → Product → Profile (⌘I)
2. Time Profiler 선택
3. 스크롤 테스트
4. Call Tree 확인
   - Image 관련 함수 시간 확인
   - 병목 지점 찾기
```

#### Allocations
```
1. Allocations 템플릿 선택
2. 이미지 로드 테스트
3. 메모리 그래프 관찰
   - 급격한 상승: 문제
   - 서서히 해제: 정상
```

#### Core Animation
```
1. Core Animation 템플릿
2. FPS 그래프 확인
3. 목표: 60 fps 유지
4. 끊김 지점 분석
```

### 벤치마크 코드

```swift
import os.signpost

class RenderingBenchmark {
    static let log = OSLog(subsystem: "com.study.day06", category: .pointsOfInterest)
    
    static func measureImageRendering(
        imageName: String,
        interpolation: Image.Interpolation,
        size: CGSize
    ) -> TimeInterval {
        let start = Date()
        
        os_signpost(.begin, log: log, name: "Image Rendering")
        
        // 이미지 렌더링
        let image = UIImage(named: imageName)
        let renderer = UIGraphicsImageRenderer(size: size)
        _ = renderer.image { context in
            image?.draw(in: CGRect(origin: .zero, size: size))
        }
        
        os_signpost(.end, log: log, name: "Image Rendering")
        
        let elapsed = Date().timeIntervalSince(start)
        return elapsed * 1000  // ms
    }
}

// 사용 예
struct BenchmarkView: View {
    @State private var results: [String] = []
    
    var body: some View {
        List(results, id: \.self) { result in
            Text(result)
        }
        .onAppear {
            runBenchmarks()
        }
    }
    
    func runBenchmarks() {
        let interpolations: [Image.Interpolation] = [.none, .low, .medium, .high]
        
        for interpolation in interpolations {
            let time = RenderingBenchmark.measureImageRendering(
                imageName: "sample",
                interpolation: interpolation,
                size: CGSize(width: 500, height: 500)
            )
            results.append("\(interpolation): \(String(format: "%.2f", time))ms")
        }
    }
}
```

---

## 성능 체크리스트

### 메모리

- [ ] LazyVStack/LazyHStack 사용
- [ ] 큰 이미지는 다운샘플링
- [ ] 썸네일 이미지 별도 준비
- [ ] NSCache로 캐시 관리
- [ ] 메모리 압박 시 캐시 해제

### 렌더링 속도

- [ ] 적절한 interpolation 선택
- [ ] SF Symbols는 font() 사용
- [ ] clipped()로 넘친 부분 제거
- [ ] 조건부 렌더링 활용
- [ ] resizable() 최소화

### 스크롤

- [ ] Lazy 컨테이너 사용
- [ ] 60 fps 유지
- [ ] 프리페칭 고려
- [ ] FPS 모니터링

### Retina 대응

- [ ] Asset Catalog에 @2x, @3x 준비
- [ ] 또는 PDF 벡터 사용
- [ ] SF Symbols 적극 활용
- [ ] 동적 스케일 계산

---

## 실무 패턴

### 고성능 이미지 그리드

```swift
struct OptimizedImageGrid: View {
    let images: [String]
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(images, id: \.self) { imageName in
                    Image(imageName)
                        .resizable()
                        .interpolation(.medium)  // 균형
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

### 프로그레시브 로딩

```swift
struct ProgressiveImage: View {
    let imageName: String
    @State private var quality: Image.Interpolation = .low
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(quality)
            .aspectRatio(contentMode: .fit)
            .onAppear {
                // 처음엔 낮은 품질
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 0.5초 후 고품질
                    withAnimation {
                        quality = .high
                    }
                }
            }
    }
}
```

### 조건부 품질

```swift
struct AdaptiveQualityImage: View {
    let imageName: String
    @Environment(\.displayScale) var displayScale
    @State private var isScrolling = false
    
    var interpolation: Image.Interpolation {
        if isScrolling {
            return .medium  // 스크롤 중: 빠른 렌더링
        } else {
            return .high    // 정지 시: 고품질
        }
    }
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(interpolation)
            .aspectRatio(contentMode: .fit)
    }
}
```

---

## 디버깅 팁

### 느린 렌더링

```
증상: 이미지 표시가 느림
원인:
1. interpolation(.high) 과다 사용
2. 큰 이미지를 작게 표시
3. resizable() 불필요하게 사용

해결:
1. .medium으로 변경
2. 썸네일 이미지 사용
3. SF Symbols는 font() 사용
```

### 메모리 부족

```
증상: EXC_RESOURCE RESOURCE_TYPE_MEMORY
원인:
1. VStack에 많은 이미지
2. 원본 크기 이미지 로드
3. 캐시 미해제

해결:
1. LazyVStack 사용
2. 다운샘플링
3. NSCache 사용 + 메모리 압박 대응
```

### 끊김 현상

```
증상: 스크롤 시 버벅임
원인:
1. 메인 스레드에서 이미지 로드
2. Lazy 미사용
3. 과도한 계산

해결:
1. 백그라운드 스레드 로드
2. LazyVStack 사용
3. 프리페칭
```

---

## 성능 목표

### 좋은 성능

- **FPS**: 55~60 (초록)
- **렌더링**: < 10ms
- **메모리**: < 100MB (썸네일 그리드)
- **CPU**: < 30%

### 허용 가능

- **FPS**: 45~55 (노랑)
- **렌더링**: < 16ms
- **메모리**: < 200MB
- **CPU**: < 50%

### 나쁜 성능 (개선 필요)

- **FPS**: < 45 (빨강)
- **렌더링**: > 16ms
- **메모리**: > 300MB
- **CPU**: > 70%

---

## 핵심 정리

### 성능 최적화 우선순위

1. **LazyVStack/LazyHStack** 사용
2. **다운샘플링** (큰 이미지)
3. **적절한 interpolation** 선택
4. **Retina 대응** (Asset Catalog)
5. **실기기 테스트**

### 일반적인 실수

```swift
// ❌ 흔한 실수들
VStack {  // Lazy 아님
    ForEach(0..<100) { i in
        Image("4K-photo")  // 원본 크기
            .resizable()
            .interpolation(.high)  // 과도한 품질
            .frame(width: 100)
    }
}

// ✅ 올바른 패턴
ScrollView {
    LazyVStack {  // Lazy
        ForEach(0..<100) { i in
            Image("thumbnail")  // 썸네일
                .resizable()
                .interpolation(.medium)  // 적절한 품질
                .frame(width: 100)
                .clipped()
        }
    }
}
```

---

**다음 단계**: 실습 뷰에서 직접 성능을 측정하고 최적화해보세요!



