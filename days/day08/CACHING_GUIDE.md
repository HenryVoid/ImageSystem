# 이미지 캐싱 전략

> NSCache를 활용한 효율적인 이미지 캐싱 구현

---

## 📚 캐싱이란?

**캐싱(Caching)**은 자주 사용되는 데이터를 **빠르게 접근 가능한 저장소**에 보관하는 기법입니다.

### 이미지 로딩 without 캐시

```
사용자가 이미지 요청
        ↓
네트워크 요청 (500ms)
        ↓
데이터 다운로드
        ↓
이미지 변환
        ↓
화면 표시

// 같은 이미지 다시 요청 시
네트워크 요청 (500ms) ← 또 다운로드! 💸
```

### 이미지 로딩 with 캐시

```
사용자가 이미지 요청
        ↓
캐시 확인
        ↓
    없음?
        ↓
네트워크 요청 (500ms)
        ↓
캐시에 저장
        ↓
화면 표시

// 같은 이미지 다시 요청 시
캐시에서 즉시 반환 (1ms) ← 빠름! ⚡
```

### 효과

- **속도**: 500배 빠름 (500ms → 1ms)
- **비용**: 데이터 사용량 감소
- **UX**: 즉각적인 이미지 표시

---

## 🗄️ 캐싱 레벨

### 3단계 캐싱 전략

```
┌────────────────────────────────────┐
│   Level 1: 메모리 캐시 (RAM)        │
│   - 가장 빠름 (1-5ms)               │
│   - 용량 제한 (100MB)               │
│   - 앱 종료 시 사라짐                │
└────────────────────────────────────┘
            ↓ 없으면
┌────────────────────────────────────┐
│   Level 2: 디스크 캐시 (Storage)    │
│   - 중간 속도 (10-50ms)             │
│   - 용량 많음 (1GB)                 │
│   - 앱 종료 후에도 유지              │
└────────────────────────────────────┘
            ↓ 없으면
┌────────────────────────────────────┐
│   Level 3: 네트워크 (Internet)      │
│   - 가장 느림 (500-5000ms)          │
│   - 데이터 비용 발생                 │
└────────────────────────────────────┘
```

**Day 8에서는 Level 1 (메모리 캐시) 집중**

---

## 🧠 NSCache 소개

`NSCache`는 iOS에서 제공하는 **메모리 기반 캐시** 클래스입니다.

### NSCache vs Dictionary

| 기능 | NSCache | Dictionary |
|------|---------|------------|
| 메모리 부족 시 | **자동 삭제** | 수동 관리 필요 |
| 스레드 안전 | **✅ 안전** | ❌ 불안전 |
| 용량 제한 | **✅ 지원** | ❌ 불가 |
| 사용 복잡도 | 간단 | 간단 |
| 성능 | 최적화됨 | 빠름 |

**결론**: 이미지 캐싱에는 **NSCache 필수**

---

## 🏗️ NSCache 기본 사용법

### 1. 캐시 생성

```swift
class ImageCache {
    // Singleton 패턴
    static let shared = ImageCache()
    
    // NSCache 인스턴스
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // 최대 100MB
        cache.totalCostLimit = 100 * 1024 * 1024
        
        // 최대 50개 이미지
        cache.countLimit = 50
    }
}
```

### 2. 캐시에 저장

```swift
func setImage(_ image: UIImage, forKey key: String) {
    let nsKey = key as NSString
    
    // 이미지 크기 계산 (비용)
    let cost = image.size.width * image.size.height * 4  // RGBA
    
    // 캐시에 저장
    cache.setObject(image, forKey: nsKey, cost: Int(cost))
}
```

### 3. 캐시에서 읽기

```swift
func image(forKey key: String) -> UIImage? {
    let nsKey = key as NSString
    return cache.object(forKey: nsKey)
}
```

### 4. 캐시 삭제

```swift
// 특정 이미지 삭제
func removeImage(forKey key: String) {
    let nsKey = key as NSString
    cache.removeObject(forKey: nsKey)
}

// 전체 캐시 삭제
func clearCache() {
    cache.removeAllObjects()
}
```

---

## 🔑 캐시 키 설계

### 올바른 키 선택

캐시 키는 이미지를 **고유하게 식별**해야 합니다.

```swift
// ✅ 좋은 예: URL 문자열
let key = url.absoluteString
cache.setObject(image, forKey: key as NSString)

// ✅ 좋은 예: 파라미터 포함
let key = "\(url.absoluteString)-\(width)x\(height)"

// ❌ 나쁜 예: 불완전한 키
let key = "image"  // 모든 이미지가 같은 키!
```

### 키 생성 헬퍼

```swift
extension URL {
    func cacheKey(size: CGSize? = nil) -> String {
        var key = absoluteString
        
        if let size = size {
            key += "-\(Int(size.width))x\(Int(size.height))"
        }
        
        return key
    }
}

// 사용
let key = url.cacheKey(size: CGSize(width: 200, height: 200))
```

---

## 🚀 완전한 캐시 구현

### CachedImageLoader.swift

```swift
import UIKit

class CachedImageLoader {
    static let shared = CachedImageLoader()
    
    // 메모리 캐시
    private let cache = NSCache<NSString, UIImage>()
    
    // 진행 중인 요청 추적 (중복 방지)
    private var runningRequests = [String: [((UIImage?) -> Void)]]()
    
    private init() {
        cache.totalCostLimit = 100 * 1024 * 1024  // 100MB
        cache.countLimit = 50
    }
    
    // 이미지 로드 (completion handler)
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString
        
        // 1. 캐시 확인
        if let cachedImage = cache.object(forKey: key as NSString) {
            print("✅ 캐시 히트: \(key)")
            completion(cachedImage)
            return
        }
        
        print("❌ 캐시 미스: \(key)")
        
        // 2. 이미 다운로드 중인지 확인
        if runningRequests[key] != nil {
            print("⏳ 진행 중인 요청에 합류: \(key)")
            runningRequests[key]?.append(completion)
            return
        }
        
        // 3. 새 다운로드 시작
        runningRequests[key] = [completion]
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                // 완료 후 요청 목록에서 제거
                self.runningRequests.removeValue(forKey: key)
            }
            
            // 이미지 변환
            guard let data = data, let image = UIImage(data: data) else {
                // 실패 시 모든 대기 중인 completion 호출
                self.runningRequests[key]?.forEach { $0(nil) }
                return
            }
            
            // 4. 캐시에 저장
            let cost = Int(image.size.width * image.size.height * 4)
            self.cache.setObject(image, forKey: key as NSString, cost: cost)
            
            // 5. 모든 대기 중인 completion 호출
            DispatchQueue.main.async {
                self.runningRequests[key]?.forEach { $0(image) }
            }
        }.resume()
    }
    
    // 캐시 삭제
    func clearCache() {
        cache.removeAllObjects()
    }
}
```

### async/await 버전

```swift
extension CachedImageLoader {
    func loadImage(from url: URL) async throws -> UIImage {
        let key = url.absoluteString
        
        // 캐시 확인
        if let cachedImage = cache.object(forKey: key as NSString) {
            print("✅ 캐시 히트: \(key)")
            return cachedImage
        }
        
        print("❌ 캐시 미스: \(key)")
        
        // 네트워크 요청
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidData
        }
        
        // 캐시에 저장
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        
        return image
    }
}
```

---

## 🎯 중복 요청 방지

### 문제 상황

```swift
// 10개의 셀이 동시에 같은 이미지 요청
for _ in 0..<10 {
    loadImage(url: sameURL) { image in
        // 같은 이미지를 10번 다운로드! 💸
    }
}
```

### 해결: 요청 병합

```swift
private var runningRequests = [String: [((UIImage?) -> Void)]]()

func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    let key = url.absoluteString
    
    // 이미 진행 중인 요청이 있다면
    if runningRequests[key] != nil {
        // 기존 요청에 completion만 추가
        runningRequests[key]?.append(completion)
        return
    }
    
    // 새 요청 시작
    runningRequests[key] = [completion]
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, let image = UIImage(data: data) else {
            // 모든 대기자에게 실패 전달
            self.runningRequests[key]?.forEach { $0(nil) }
            self.runningRequests.removeValue(forKey: key)
            return
        }
        
        // 모든 대기자에게 이미지 전달
        self.runningRequests[key]?.forEach { $0(image) }
        self.runningRequests.removeValue(forKey: key)
    }.resume()
}
```

**효과**:
- 10번 요청 → **1번 다운로드**
- 네트워크 트래픽 **90% 감소**

---

## 📊 캐시 히트율 측정

### 통계 추적

```swift
class CachedImageLoader {
    private(set) var cacheHits = 0
    private(set) var cacheMisses = 0
    
    var hitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total) * 100
    }
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString
        
        if let cachedImage = cache.object(forKey: key as NSString) {
            cacheHits += 1  // 히트!
            print("✅ 캐시 히트율: \(String(format: "%.1f", hitRate))%")
            completion(cachedImage)
            return
        }
        
        cacheMisses += 1  // 미스
        // 다운로드 로직...
    }
    
    func resetStats() {
        cacheHits = 0
        cacheMisses = 0
    }
}
```

---

## 💾 메모리 경고 처리

### 메모리 부족 시 캐시 정리

```swift
class CachedImageLoader {
    private init() {
        // 메모리 경고 옵저버 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ 메모리 경고 - 캐시 정리")
        cache.removeAllObjects()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

---

## 🔄 캐시 무효화 전략

### 1. TTL (Time To Live)

```swift
class TimedCachedImageLoader {
    private struct CachedImage {
        let image: UIImage
        let timestamp: Date
    }
    
    private var cache = [String: CachedImage]()
    private let ttl: TimeInterval = 3600  // 1시간
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString
        
        // 캐시 확인 + 유효성 검사
        if let cached = cache[key],
           Date().timeIntervalSince(cached.timestamp) < ttl {
            completion(cached.image)
            return
        }
        
        // 만료되었거나 없으면 다운로드
        // ...
    }
}
```

### 2. LRU (Least Recently Used)

NSCache가 자동으로 LRU 정책을 사용합니다.

```swift
// NSCache는 다음 순서로 자동 삭제:
// 1. 가장 오래 사용되지 않은 항목
// 2. 메모리 부족 시 자동 정리
// 3. totalCostLimit 초과 시 정리
```

---

## 🎨 SwiftUI에서 활용

### AsyncImage 대체

```swift
struct CachedAsyncImage: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        CachedImageLoader.shared.loadImage(from: url) { loadedImage in
            self.image = loadedImage
            self.isLoading = false
        }
    }
}
```

---

## 📈 성능 비교

### 벤치마크 결과 (예상)

**시나리오**: 10개 이미지를 2번 로드

| 방식 | 첫 로드 | 두 번째 로드 | 총 시간 |
|------|---------|--------------|---------|
| **캐시 없음** | 5000ms | 5000ms | **10000ms** |
| **캐시 적용** | 5000ms | 50ms | **5050ms** |

**개선**: **50% 시간 단축** ⚡

### 네트워크 사용량

| 방식 | 데이터 사용 |
|------|------------|
| **캐시 없음** | 10MB × 2 = **20MB** |
| **캐시 적용** | 10MB × 1 = **10MB** |

**개선**: **50% 데이터 절감** 💰

---

## 🎯 실전 팁

### 1. 적절한 캐시 크기 설정

```swift
// iPhone SE: 50MB
// iPhone 15: 100MB
// iPad: 200MB

let maxMemory = ProcessInfo.processInfo.physicalMemory
let cacheSize = min(maxMemory / 10, 200 * 1024 * 1024)
cache.totalCostLimit = Int(cacheSize)
```

### 2. 썸네일 캐시 분리

```swift
class ImageCache {
    private let fullSizeCache = NSCache<NSString, UIImage>()
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    // 큰 이미지는 적게, 썸네일은 많이
    init() {
        fullSizeCache.countLimit = 20
        thumbnailCache.countLimit = 100
    }
}
```

### 3. 백그라운드 진입 시 캐시 정리

```swift
NotificationCenter.default.addObserver(
    forName: UIApplication.didEnterBackgroundNotification,
    object: nil,
    queue: .main
) { _ in
    // 백그라운드 진입 시 캐시 일부 정리
    ImageCache.shared.clearOldCache()
}
```

---

## 🎓 핵심 요약

### NSCache 사용 이유
- ✅ 메모리 자동 관리
- ✅ 스레드 안전
- ✅ 용량 제한 지원

### 캐싱 전략
- **키 설계**: URL 기반 고유 키
- **중복 방지**: 진행 중인 요청 병합
- **메모리 관리**: 메모리 경고 대응

### 성능 개선
- 속도: **50배 향상** (500ms → 10ms)
- 데이터: **50% 절감**
- UX: 즉각적인 이미지 표시

---

**다음 단계**: PERFORMANCE_GUIDE.md에서 캐시 적용 전후 성능을 실제로 측정해봅니다! 📊


































