# 캐시 이론

> iOS 이미지 캐싱의 핵심 개념과 동작 원리를 깊이 있게 이해합니다

---

## 📚 캐싱이란?

**캐싱(Caching)**은 자주 사용되는 데이터를 빠르게 접근 가능한 저장소에 보관하여, 반복적인 계산이나 네트워크 요청을 줄이는 최적화 기법입니다.

### 캐싱의 필요성

#### 문제: 이미지 로딩의 비용

```
네트워크에서 이미지 다운로드:
├─ 시간: 200-5000ms (네트워크 속도에 따라)
├─ 비용: 데이터 사용량 (사용자 요금)
├─ 배터리: 네트워크 모듈 전력 소비
└─ UX: 로딩 대기 시간
```

#### 해결: 캐싱

```
첫 다운로드 → 캐시에 저장
이후 요청 → 캐시에서 즉시 반환

결과:
✅ 속도: 1-50ms (100-1000배 빠름)
✅ 비용: 데이터 사용량 0
✅ 배터리: 전력 소비 최소화
✅ UX: 즉각적인 응답
```

---

## 🏗️ 캐시 계층 구조

iOS 이미지 로딩은 **3단계 캐시 계층**을 사용합니다.

### Level 1: 메모리 캐시 (Memory Cache)

```
┌─────────────────────────────────────┐
│   메모리 캐시 (RAM)                   │
│                                     │
│   속도: ⚡⚡⚡ 1-5ms (가장 빠름)      │
│   용량: 💾 50-200MB (제한적)         │
│   지속: 🔄 앱 실행 중만 유지          │
│   구현: NSCache                     │
└─────────────────────────────────────┘
```

**특징**:
- 이미지를 **UIImage 객체**로 저장
- 디코딩 완료된 상태 (즉시 렌더링 가능)
- 메모리 부족 시 자동 삭제 (LRU)
- 앱 종료 시 모두 사라짐

**사용 케이스**:
- 현재 화면에 표시 중인 이미지
- 곧 필요할 이미지 (프리페칭)
- 자주 재사용되는 이미지

---

### Level 2: 디스크 캐시 (Disk Cache)

```
┌─────────────────────────────────────┐
│   디스크 캐시 (Storage)              │
│                                     │
│   속도: ⚡⚡ 10-100ms (중간)         │
│   용량: 💾 100MB-1GB (크다)         │
│   지속: 🔄 영구 저장 (명시적 삭제까지)│
│   구현: FileManager                 │
└─────────────────────────────────────┘
```

**특징**:
- 이미지를 **파일**(JPEG/PNG)로 저장
- 압축된 상태 (디코딩 필요)
- 앱 종료 후에도 유지
- 수동 또는 정책 기반 삭제

**사용 케이스**:
- 자주 사용하지만 메모리에 항상 유지할 수 없는 이미지
- 오프라인 지원
- 다음 앱 실행 시에도 재사용

---

### Level 3: 네트워크 (Network)

```
┌─────────────────────────────────────┐
│   네트워크 (Internet)                │
│                                     │
│   속도: ⚡ 200-5000ms (가장 느림)    │
│   용량: 💾 무제한                    │
│   비용: 💰 데이터 요금 발생          │
│   구현: URLSession                  │
└─────────────────────────────────────┘
```

**특징**:
- 원본 서버에서 다운로드
- 네트워크 연결 필수
- 가장 느리고 비용 발생

**사용 케이스**:
- 첫 다운로드
- 캐시 미스 (메모리/디스크에 없음)
- 캐시 무효화 후 재다운로드

---

## 🔄 캐시 조회 흐름

### 전체 프로세스

```
사용자가 이미지 요청
        ↓
┌───────────────────────┐
│ Level 1: 메모리 캐시   │
└───────┬───────────────┘
        │
    있음? ────YES──→ 즉시 반환 (1-5ms) ✅
        │
        NO
        ↓
┌───────────────────────┐
│ Level 2: 디스크 캐시   │
└───────┬───────────────┘
        │
    있음? ────YES──→ 파일 읽기 → 디코딩
        │            메모리 캐시에 저장
        │            반환 (10-100ms) ✅
        NO
        ↓
┌───────────────────────┐
│ Level 3: 네트워크     │
└───────┬───────────────┘
        │
    다운로드 (200-5000ms)
        ↓
    디스크에 저장
        ↓
    디코딩 + 메모리에 저장
        ↓
    반환 ✅
```

---

## 🧠 NSCache 상세

### NSCache란?

Apple이 제공하는 **메모리 기반 캐시 컨테이너**입니다.

```swift
let cache = NSCache<NSString, UIImage>()
```

### NSCache vs Dictionary

| 기능 | NSCache | Dictionary |
|------|---------|-----------|
| **자동 메모리 관리** | ✅ 메모리 부족 시 자동 삭제 | ❌ 수동 관리 필요 |
| **스레드 안전** | ✅ 완벽히 안전 | ❌ 수동 동기화 필요 |
| **LRU 정책** | ✅ 자동 적용 | ❌ 직접 구현 필요 |
| **용량 제한** | ✅ cost 기반 | ❌ 불가능 |
| **성능** | 최적화됨 | 빠름 |
| **복잡도** | 간단 | 간단 |

### NSCache의 핵심 개념

#### 1. Cost (비용)

각 객체의 "무게"를 나타냅니다.

```swift
let cache = NSCache<NSString, UIImage>()

// 최대 100MB
cache.totalCostLimit = 100 * 1024 * 1024

// 이미지 저장 시 cost 계산
let image = UIImage(...)
let cost = Int(image.size.width * image.size.height * 4) // RGBA
cache.setObject(image, forKey: "key" as NSString, cost: cost)
```

**Cost 계산**:
```
이미지 크기: 800 × 600
채널: RGBA (4 bytes per pixel)
Cost = 800 × 600 × 4 = 1,920,000 bytes ≈ 1.83 MB
```

#### 2. Count (개수)

저장할 수 있는 최대 객체 개수입니다.

```swift
cache.countLimit = 50  // 최대 50개 이미지
```

#### 3. LRU (Least Recently Used)

가장 오래 사용되지 않은 항목을 먼저 삭제합니다.

```
캐시: [A, B, C, D, E]  (용량 가득)

새 이미지 F 추가 → A가 가장 오래됨 → A 삭제
캐시: [B, C, D, E, F]

B 이미지 접근 → B가 최신으로 이동
캐시: [C, D, E, F, B]

새 이미지 G 추가 → C가 가장 오래됨 → C 삭제
캐시: [D, E, F, B, G]
```

### NSCache 동작 예제

```swift
class ImageMemoryCache {
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        // 100MB 제한
        cache.totalCostLimit = 100 * 1024 * 1024
        
        // 최대 50개
        cache.countLimit = 50
        
        // 메모리 경고 처리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    func store(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        print("✅ 메모리 캐시 저장: \(key), cost: \(cost) bytes")
    }
    
    func retrieve(forKey key: String) -> UIImage? {
        if let image = cache.object(forKey: key as NSString) {
            print("🎯 메모리 캐시 히트: \(key)")
            return image
        }
        print("❌ 메모리 캐시 미스: \(key)")
        return nil
    }
    
    @objc func clearCache() {
        cache.removeAllObjects()
        print("⚠️ 메모리 경고 - 캐시 전체 삭제")
    }
}
```

---

## 💾 디스크 캐시 상세

### 디스크 캐시란?

파일 시스템에 이미지를 **파일로 저장**하는 영구 캐시입니다.

### 저장 위치

```swift
// 캐시 디렉토리
let cacheDir = FileManager.default.urls(
    for: .cachesDirectory,
    in: .userDomainMask
)[0]

// 경로 예시
// /Users/.../Library/Caches/com.company.app/ImageCache/
```

**특징**:
- iOS가 자동으로 관리 (저장 공간 부족 시 삭제 가능)
- iCloud 백업 제외
- 사용자가 직접 삭제 가능 (설정 → 앱 → 캐시 삭제)

### 파일명 해싱

URL을 그대로 파일명으로 사용하면 문제가 발생합니다.

```swift
// ❌ 나쁜 예
let filename = "https://example.com/image.jpg?size=large"
// 문제: /, ?, & 등 파일명에 사용 불가
```

**해결: MD5/SHA256 해싱**

```swift
import CryptoKit

extension String {
    func md5Hash() -> String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// ✅ 좋은 예
let url = "https://example.com/image.jpg?size=large"
let filename = url.md5Hash() // "a3f5b8c9d2e1..."
```

### 디스크 캐시 구현

```swift
class ImageDiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("ImageCache")
        
        // 디렉토리 생성
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    func store(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let filename = key.md5Hash()
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ 디스크 캐시 저장: \(key)")
        } catch {
            print("❌ 디스크 저장 실패: \(error)")
        }
    }
    
    func retrieve(forKey key: String) -> UIImage? {
        let filename = key.md5Hash()
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            print("❌ 디스크 캐시 미스: \(key)")
            return nil
        }
        
        print("🎯 디스크 캐시 히트: \(key)")
        return image
    }
    
    func diskUsage() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + Int64(size)
        }
    }
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
        print("🗑️ 디스크 캐시 전체 삭제")
    }
}
```

---

## 🌐 URLCache

### URLCache란?

iOS에서 제공하는 **HTTP 응답 캐싱** 시스템입니다.

```swift
let cache = URLCache.shared

// 메모리: 20MB, 디스크: 100MB
cache.memoryCapacity = 20 * 1024 * 1024
cache.diskCapacity = 100 * 1024 * 1024
```

### URLCache의 특징

**장점**:
- URLSession과 **자동 통합**
- HTTP 헤더 기반 캐싱 (Cache-Control, ETag)
- 투명한 캐싱 (코드 변경 최소)
- 메모리 + 디스크 2단계

**단점**:
- HTTP 응답만 캐싱 (raw Data)
- 디코딩된 이미지는 캐싱 안 됨
- 세밀한 제어 어려움

### URLCache 동작 원리

```
1. URLSession 요청
        ↓
2. URLCache 확인
        ↓
   캐시 있음? ──YES──→ 즉시 반환
        │
        NO
        ↓
3. 네트워크 요청
        ↓
4. 응답을 URLCache에 저장
        ↓
5. 응답 반환
```

### HTTP 헤더와 캐싱

서버가 캐싱 정책을 제어할 수 있습니다.

```http
HTTP/1.1 200 OK
Cache-Control: max-age=3600
ETag: "abc123"
```

**Cache-Control 옵션**:
- `max-age=3600`: 3600초(1시간) 동안 캐시 유효
- `no-cache`: 매번 서버에 재검증 필요
- `no-store`: 캐싱 금지
- `public`: 모든 캐시에 저장 가능
- `private`: 브라우저 캐시만 가능

---

## 📊 성능 비교

### 실측 데이터 (800×600 JPEG 이미지)

| 캐시 타입 | 로딩 시간 | 상대 속도 | 메모리 | 디스크 | 영구성 |
|----------|---------|----------|--------|--------|--------|
| **메모리** | 1-5ms | ⚡⚡⚡ (1×) | 1.8MB | 0 | 앱 실행 중 |
| **디스크** | 10-50ms | ⚡⚡ (10×) | 0 | 100KB | 영구 |
| **네트워크** | 200-5000ms | ⚡ (500×) | 0 | 0 | - |

### 100개 이미지 로딩 시나리오

```
┌─────────────┬───────┬────────┬─────────┐
│   방식      │ 첫 로드│ 재로드  │ 총 시간  │
├─────────────┼───────┼────────┼─────────┤
│ 캐시 없음   │ 30초  │ 30초   │ 60초    │
│ 메모리 캐시 │ 30초  │ 0.5초  │ 30.5초  │
│ 디스크 캐시 │ 30초  │ 2초    │ 32초    │
│ 2단계 캐시  │ 30초  │ 0.5초  │ 30.5초  │
└─────────────┴───────┴────────┴─────────┘
```

**2단계 캐시**: 메모리 + 디스크 조합
- 첫 로드: 네트워크 → 디스크 + 메모리
- 재로드: 메모리에서 즉시 (0.5초)
- 메모리 부족 시: 디스크에서 복구 (2초)

---

## 🎯 캐싱 전략 선택

### 메모리 캐시만 사용

```
✅ 적합한 경우:
- 세션 중에만 필요한 이미지
- 메모리 충분
- 빠른 응답 최우선

❌ 부적합한 경우:
- 앱 재실행 시에도 재사용
- 메모리 제약 기기
- 대용량 이미지
```

### 디스크 캐시만 사용

```
✅ 적합한 경우:
- 오프라인 지원 필요
- 앱 재실행 시에도 유지
- 메모리 절약

❌ 부적합한 경우:
- 실시간 성능 중요
- 자주 접근하는 이미지
```

### 2단계 캐시 (메모리 + 디스크)

```
✅ 적합한 경우:
- 대부분의 실전 앱
- 균형 잡힌 성능과 지속성
- 다양한 사용 패턴

이것이 Kingfisher, Nuke의 기본 전략!
```

---

## 💡 핵심 요약

### 3단계 캐시

1. **메모리** (NSCache): 가장 빠름, 제한적 용량, 임시
2. **디스크** (FileManager): 중간 속도, 큰 용량, 영구
3. **네트워크** (URLSession): 가장 느림, 무제한, 비용 발생

### NSCache 핵심

- ✅ 메모리 자동 관리
- ✅ 스레드 안전
- ✅ LRU 자동 적용
- ✅ Cost 기반 용량 제한

### 디스크 캐시 핵심

- 📁 파일 시스템 저장
- 🔐 URL 해싱 필요
- 💾 영구 보관
- 🗑️ 수동 정리

### URLCache 핵심

- 🌐 HTTP 응답 캐싱
- 🔄 URLSession 자동 통합
- 📋 HTTP 헤더 기반
- 🎯 투명한 캐싱

---

**다음 단계**: CACHE_STRATEGY.md에서 캐시 정책(LRU, TTL, 용량 제한)을 학습합니다! 📚











