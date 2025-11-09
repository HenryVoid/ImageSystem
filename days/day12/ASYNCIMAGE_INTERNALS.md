# AsyncImage 내부 동작 원리

> AsyncImage의 내부 구조, 캐싱 메커니즘, 성능 특성을 심층 분석합니다

---

## 📚 목차

1. [AsyncImage 개요](#asyncimage-개요)
2. [내부 구현](#내부-구현)
3. [로딩 단계](#로딩-단계)
4. [캐싱 메커니즘](#캐싱-메커니즘)
5. [성능 특성](#성능-특성)
6. [에러 처리](#에러-처리)
7. [커스텀 구현](#커스텀-구현)

---

## AsyncImage 개요

### 기본 사용법

```swift
// 가장 간단한 형태
AsyncImage(url: URL(string: "https://example.com/image.jpg"))

// 크기 조절
AsyncImage(url: imageURL) { image in
    image.resizable()
        .aspectRatio(contentMode: .fit)
} placeholder: {
    ProgressView()
}

// 전체 제어
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable()
    case .failure(let error):
        ErrorView(error)
    @unknown default:
        EmptyView()
    }
}
```

### AsyncImage의 역할

AsyncImage는 다음을 자동으로 처리합니다:
1. ✅ **비동기 다운로드** (URLSession)
2. ✅ **이미지 디코딩** (백그라운드)
3. ✅ **자동 캐싱** (URLCache)
4. ✅ **상태 관리** (loading/success/failure)
5. ✅ **메인 스레드 업데이트** (UI 갱신)

---

## 내부 구현

### SwiftUI 소스 코드 (추정)

AsyncImage의 실제 구현은 비공개지만, 다음과 같이 동작할 것으로 추정됩니다:

```swift
// ⚠️ 이것은 추정 구현입니다 (실제 Apple 코드가 아님)
public struct AsyncImage<Content: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    @StateObject private var loader = ImageLoader()
    
    public var body: some View {
        content(loader.phase)
            .task(id: url) {
                await loader.load(url: url, scale: scale)
            }
    }
}

// 내부 ImageLoader
@MainActor
class ImageLoader: ObservableObject {
    @Published private(set) var phase: AsyncImagePhase = .empty
    
    private var dataTask: URLSessionDataTask?
    
    func load(url: URL?, scale: CGFloat) async {
        guard let url = url else {
            phase = .empty
            return
        }
        
        // 캐시 확인
        if let cachedImage = checkCache(url: url) {
            phase = .success(cachedImage)
            return
        }
        
        // 네트워크 로딩
        phase = .empty // 로딩 시작
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 백그라운드에서 디코딩
            let image = await decodeImage(data: data, scale: scale)
            
            // 메인 스레드에서 UI 업데이트
            await MainActor.run {
                phase = .success(Image(uiImage: image))
            }
        } catch {
            await MainActor.run {
                phase = .failure(error)
            }
        }
    }
    
    private func decodeImage(data: Data, scale: CGFloat) async -> UIImage {
        await Task.detached {
            UIImage(data: data, scale: scale) ?? UIImage()
        }.value
    }
}
```

### 핵심 컴포넌트

#### 1. AsyncImagePhase (상태)

```swift
public enum AsyncImagePhase {
    case empty                    // 로딩 전 또는 URL이 nil
    case success(Image)          // 이미지 로드 성공
    case failure(Error)          // 로드 실패
}
```

**상태 전환 다이어그램**:
```
        URL 설정
           ↓
      ┌─ empty ─┐
      │         │
      │  ⏳ 로딩  │
      │         │
      └─────────┘
           ↓
      ┌─────────────┐
      │             │
   성공│           실패│
      ↓             ↓
  success      failure
   (Image)      (Error)
```

#### 2. URLSession (네트워크)

```swift
// AsyncImage는 내부적으로 URLSession.shared 사용
let (data, response) = try await URLSession.shared.data(from: url)

// URLSession 설정:
// - 타임아웃: 기본 60초
// - 캐시 정책: .returnCacheDataElseLoad
// - HTTP 파이프라이닝: 활성화
```

#### 3. Image Decoding (디코딩)

```swift
// ⚠️ 이미지 디코딩은 CPU 집약적 작업!
let uiImage = UIImage(data: data)

// 디코딩 단계:
// 1. JPEG/PNG 압축 해제
// 2. 픽셀 버퍼 생성 (width × height × 4 bytes)
// 3. 색상 공간 변환
// 4. 메모리 할당 (약 2MB for 400×400)
```

---

## 로딩 단계

### 전체 프로세스

```
1️⃣ URL 설정
   ↓
2️⃣ 캐시 확인 (URLCache)
   ├─ 히트 → 즉시 표시 (5ms)
   └─ 미스 → 3️⃣로 이동
   ↓
3️⃣ 네트워크 요청 (URLSession)
   ├─ HTTP GET 전송
   ├─ 응답 대기 (100-500ms)
   └─ 데이터 수신
   ↓
4️⃣ 이미지 디코딩 (백그라운드)
   ├─ JPEG 압축 해제
   ├─ 픽셀 버퍼 생성
   └─ UIImage 생성 (50-100ms)
   ↓
5️⃣ UI 업데이트 (메인 스레드)
   ├─ SwiftUI 뷰 재평가
   └─ 화면에 렌더링 (2-5ms)
```

### 각 단계 상세

#### 1단계: URL 설정

```swift
AsyncImage(url: URL(string: "https://picsum.photos/400/400"))
    .task(id: url) {
        // URL이 변경되면 이전 Task 취소하고 새로 시작
    }
```

**시간**: ~0.1ms

#### 2단계: 캐시 확인

```swift
// URLCache 확인
let request = URLRequest(url: url)
if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
    // 캐시 히트! 즉시 사용
    let image = UIImage(data: cachedResponse.data)
    return .success(Image(uiImage: image))
}
```

**시간**: 
- 캐시 히트: ~5ms ⚡
- 캐시 미스: ~0.1ms (다음 단계로)

#### 3단계: 네트워크 요청

```swift
let (data, response) = try await URLSession.shared.data(from: url)

// HTTP 요청:
// GET /400/400 HTTP/1.1
// Host: picsum.photos
// Accept: image/*
// Cache-Control: max-age=3600
```

**시간**:
- 로컬 네트워크: 50-100ms
- Wi-Fi: 100-300ms
- LTE: 200-800ms
- 3G: 1-3초

#### 4단계: 이미지 디코딩

```swift
// 백그라운드 스레드에서 디코딩
Task.detached(priority: .userInitiated) {
    let image = UIImage(data: data)
    // 디코딩 중: CPU 사용률 50-80%
}
```

**시간**:
- 작은 이미지 (200×200): 20-30ms
- 중간 이미지 (400×400): 50-80ms
- 큰 이미지 (1000×1000): 200-500ms

**메모리**:
```
압축된 데이터: 50KB (JPEG)
디코딩된 이미지: 400×400×4 = 640KB
실제 메모리: ~2MB (내부 버퍼 포함)
```

#### 5단계: UI 업데이트

```swift
await MainActor.run {
    self.phase = .success(Image(uiImage: uiImage))
    // SwiftUI 뷰 재평가 → 렌더링
}
```

**시간**: 2-5ms

---

## 캐싱 메커니즘

### URLCache (iOS 15+)

AsyncImage는 **URLCache**를 자동으로 사용합니다.

#### URLCache 구조

```
URLCache
├─ 메모리 캐시 (RAM)
│  ├─ 용량: 기본 512MB
│  ├─ 속도: 5-10ms ⚡⚡⚡
│  └─ 휘발성: 앱 종료 시 삭제
│
└─ 디스크 캐시 (Storage)
   ├─ 용량: 기본 500MB
   ├─ 속도: 20-50ms ⚡⚡
   └─ 영속성: 앱 종료 후에도 유지
```

#### 캐시 정책

```swift
// URLCache 설정
let cache = URLCache(
    memoryCapacity: 100 * 1024 * 1024,   // 100MB 메모리
    diskCapacity: 200 * 1024 * 1024,     // 200MB 디스크
    directory: nil // 기본 디렉토리
)
URLCache.shared = cache
```

#### 캐시 키

```swift
// 캐시 키 = URL 문자열
let key = "https://picsum.photos/400/400"

// ⚠️ 같은 URL이면 같은 캐시
// 다른 크기를 원하면 URL이 달라야 함
"https://picsum.photos/200/200" // 다른 캐시
"https://picsum.photos/400/400" // 다른 캐시
```

### 캐시 동작 예시

```swift
// 첫 번째 로드
AsyncImage(url: imageURL) // 네트워크 → 200ms

// 같은 URL 재로드
AsyncImage(url: imageURL) // 캐시 → 5ms ⚡

// 앱 재시작 후
AsyncImage(url: imageURL) // 디스크 캐시 → 30ms ⚡⚡

// 캐시 만료 후 (1시간 후)
AsyncImage(url: imageURL) // 네트워크 → 200ms
```

### 캐시 효율성

```
100개 이미지 리스트 시나리오:

첫 로드:
- 네트워크 요청: 100회
- 총 시간: 20초
- 데이터 사용: 5MB

재로드 (캐시):
- 네트워크 요청: 0회
- 총 시간: 0.5초 (40배 빠름) ⚡
- 데이터 사용: 0MB

캐시 효율: 99.9% 시간 절감
```

---

## 성능 특성

### 메모리 사용

```swift
AsyncImage(url: imageURL)
```

**메모리 구성**:
```
총 메모리: ~3MB per image
├─ 압축 데이터: 50KB (URLCache)
├─ 디코딩 이미지: 2MB (UIImage)
└─ SwiftUI 내부: ~1MB (렌더링 버퍼)
```

**LazyVStack에서**:
```
화면에 10개 이미지:
- 메모리: 10 × 3MB = 30MB
- 캐시: 추가 50MB (100개 이미지)
---
총: 약 80MB ✅ (효율적)
```

### CPU 사용

```
로딩 단계별 CPU:
1. 네트워크: 5-10% (URLSession)
2. 디코딩: 50-80% (피크)
3. 렌더링: 10-20% (SwiftUI)
```

### 네트워크 효율

```swift
// 동시 로딩
LazyVStack {
    ForEach(0..<100) { index in
        AsyncImage(url: imageURL(index))
        // 각 AsyncImage가 독립적으로 요청
    }
}

// ⚠️ 주의: 동시 요청 수 제한
// URLSession은 기본적으로 호스트당 6개까지만 동시 연결
// 나머지는 큐에서 대기
```

**동시 요청 패턴**:
```
요청 1-6:   ████████ (즉시 시작)
요청 7-12:  ░░░░████ (대기 후 시작)
요청 13-18: ░░░░░░░░████ (더 오래 대기)

평균 대기 시간:
- 처음 6개: 0ms
- 다음 6개: 200ms
- 그 다음: 400ms
```

---

## 에러 처리

### 에러 타입

```swift
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .failure(let error):
        // 가능한 에러들:
        // - URLError.notConnectedToInternet
        // - URLError.timedOut
        // - URLError.cannotFindHost
        // - URLError.badServerResponse
        // - 이미지 디코딩 실패
        ErrorView(error)
    default:
        EmptyView()
    }
}
```

### 재시도 로직

```swift
struct RetryableAsyncImage: View {
    let url: URL?
    @State private var retryCount = 0
    
    var body: some View {
        AsyncImage(url: modifiedURL) { phase in
            switch phase {
            case .failure(let error):
                VStack {
                    Text("로드 실패")
                    Button("재시도") {
                        retryCount += 1
                    }
                }
            case .success(let image):
                image.resizable()
            case .empty:
                ProgressView()
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private var modifiedURL: URL? {
        // URL에 쿼리 파라미터 추가로 재시도
        guard let url = url else { return nil }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "retry", value: "\(retryCount)")]
        return components?.url
    }
}
```

### 타임아웃 처리

```swift
// URLSession 커스텀 설정
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 10 // 10초
config.timeoutIntervalForResource = 30 // 총 30초

let session = URLSession(configuration: config)

// AsyncImage는 기본 URLSession.shared 사용
// 커스텀 타임아웃을 원하면 직접 구현 필요
```

---

## 커스텀 구현

### 기본 커스텀 AsyncImage

```swift
struct CustomAsyncImage: View {
    let url: URL?
    
    @State private var phase: LoadingPhase = .loading
    
    enum LoadingPhase {
        case loading
        case success(UIImage)
        case failure(Error)
    }
    
    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
            case .success(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
            case .failure:
                Image(systemName: "exclamationmark.triangle")
            }
        }
        .task(id: url) {
            await load()
        }
    }
    
    private func load() async {
        guard let url = url else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = await decodeImage(data) {
                phase = .success(image)
            }
        } catch {
            phase = .failure(error)
        }
    }
    
    private func decodeImage(_ data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value
    }
}
```

### 캐싱 추가

```swift
actor ImageCache {
    private var cache = NSCache<NSURL, UIImage>()
    
    init() {
        cache.countLimit = 100 // 최대 100개
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    static let cache = ImageCache()
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray
            }
        }
        .task(id: url) {
            await load()
        }
    }
    
    private func load() async {
        guard let url = url else { return }
        
        // 캐시 확인
        if let cached = await Self.cache.image(for: url) {
            image = cached
            return
        }
        
        // 네트워크 로드
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                await Self.cache.setImage(uiImage, for: url)
                image = uiImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}
```

### 다운샘플링 추가

```swift
extension CachedAsyncImage {
    private func downsample(_ data: Data, to targetSize: CGSize) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height),
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
```

---

## 💡 핵심 정리

### AsyncImage 장점

✅ **간편함**:
- 한 줄로 비동기 이미지 로딩
- 상태 관리 자동화

✅ **자동 캐싱**:
- URLCache 활용
- 재로드 시 즉시 표시

✅ **에러 처리**:
- 실패 시 자동 처리
- 플레이스홀더 지원

### AsyncImage 한계

❌ **제한적 제어**:
- 캐시 정책 커스터마이징 어려움
- 다운샘플링 미지원
- 진행률 표시 불가

❌ **동시 요청 제한**:
- 호스트당 6개까지만
- 대규모 리스트에서 병목

### 사용 권장

**AsyncImage 사용**:
- 간단한 이미지 로딩
- 프로토타입
- 작은 규모 앱

**라이브러리 사용**:
- 대규모 이미지 리스트
- 고급 캐싱 필요
- 다운샘플링 필요
- 진행률 표시 필요

---

**AsyncImage = 간편함과 성능의 균형!** ⚡


