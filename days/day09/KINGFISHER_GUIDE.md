# Kingfisher 완벽 가이드

> Swift 네이티브, 우아한 API 디자인의 이미지 로딩 라이브러리

---

## 📚 개요

### Kingfisher란?

**출시**: 2015년  
**언어**: Pure Swift  
**저장소**: https://github.com/onevcat/Kingfisher  
**라이선스**: MIT  
**스타**: 23,000+  
**작성자**: Wei Wang (@onevcat)

Kingfisher는 Swift로 처음부터 작성된 현대적인 이미지 로딩 라이브러리입니다. 깔끔한 API와 SwiftUI 통합으로 개발자 경험(DX)이 뛰어납니다.

### 핵심 특징

✅ **Pure Swift**: 100% Swift로 작성  
✅ **깔끔한 API**: 체이닝과 Modifier 패턴  
✅ **SwiftUI 우수**: KFImage로 네이티브 통합  
✅ **타입 안전**: Swift의 타입 시스템 활용  
✅ **모던**: async/await 완벽 지원  
✅ **확장성**: Protocol 중심 설계  
✅ **성능**: 메모리 효율적

---

## 🏗️ 아키텍처

### 전체 구조

```
┌─────────────────────────────────────┐
│      KFImage (SwiftUI)              │
│      UIImageView+Kingfisher         │  ← UI Extension
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      KingfisherManager              │  ← 중앙 관리자
└─────────┬────────────────┬──────────┘
          │                │
┌─────────▼────────┐  ┌───▼──────────┐
│ ImageCache       │  │ ImageDown    │
│                  │  │ loader       │
│ ┌──────────────┐ │  └───┬──────────┘
│ │MemoryStorage │ │      │
│ │(NSCache)     │ │  ┌───▼──────────┐
│ └──────────────┘ │  │ URLSession   │
│ ┌──────────────┐ │  └──────────────┘
│ │ DiskStorage  │ │
│ │(FileManager) │ │
│ └──────────────┘ │
└──────────────────┘
```

### 주요 컴포넌트

#### 1. KingfisherManager
**역할**: 전체 이미지 로딩 프로세스 조율

```swift
// 싱글톤 패턴
KingfisherManager.shared
```

**주요 메서드**:
```swift
// 이미지 로드
manager.retrieveImage(
    with: url,
    options: options
) { result in
    switch result {
    case .success(let value):
        print("이미지: \(value.image)")
        print("캐시 타입: \(value.cacheType)")
    case .failure(let error):
        print("에러: \(error)")
    }
}
```

#### 2. ImageCache
**역할**: 메모리 + 디스크 2단계 캐싱

```swift
let cache = ImageCache.default

// 메모리 캐시 설정
cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
cache.memoryStorage.config.countLimit = 50

// 디스크 캐시 설정
cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
cache.diskStorage.config.expiration = .days(7)
```

#### 3. ImageDownloader
**역할**: 네트워크 다운로드

```swift
let downloader = ImageDownloader.default

// 다운로드 설정
downloader.downloadTimeout = 15.0
downloader.trustedHosts = Set(["example.com"])
```

---

## 🚀 기본 사용법

### UIKit (UIImageView)

가장 간단한 사용법:

```swift
import Kingfisher

let imageView = UIImageView()
let url = URL(string: "https://example.com/image.jpg")

// 기본 로딩
imageView.kf.setImage(with: url)
```

### 플레이스홀더

```swift
imageView.kf.setImage(
    with: url,
    placeholder: UIImage(named: "placeholder")
)
```

### 완료 핸들러

```swift
imageView.kf.setImage(with: url) { result in
    switch result {
    case .success(let value):
        print("이미지 로드 성공")
        print("이미지: \(value.image)")
        print("캐시 타입: \(value.cacheType)")
        print("소스: \(value.source)")
        
    case .failure(let error):
        print("로드 실패: \(error.localizedDescription)")
    }
}
```

### 프로그레스

```swift
imageView.kf.setImage(
    with: url,
    progressBlock: { receivedSize, totalSize in
        let percentage = (Float(receivedSize) / Float(totalSize)) * 100
        print("진행: \(percentage)%")
    }
)
```

### SwiftUI

**KFImage** - Kingfisher의 SwiftUI 컴포넌트:

```swift
import Kingfisher
import SwiftUI

struct MyView: View {
    var body: some View {
        KFImage(URL(string: "https://example.com/image.jpg"))
            .placeholder {
                // 플레이스홀더
                ProgressView()
            }
            .retry(maxCount: 3, interval: .seconds(5))
            .onSuccess { result in
                print("성공: \(result.cacheType)")
            }
            .onFailure { error in
                print("실패: \(error)")
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 300, height: 300)
            .cornerRadius(10)
    }
}
```

---

## ⚙️ Modifier 체이닝

### 기본 Modifier

Kingfisher의 가장 강력한 기능:

```swift
imageView.kf.setImage(
    with: url,
    placeholder: UIImage(named: "placeholder"),
    options: [
        .transition(.fade(0.2)),           // 페이드 인 애니메이션
        .cacheOriginalImage,               // 원본 이미지 캐싱
        .scaleFactor(UIScreen.main.scale), // 리티나 배율
        .processor(DownsamplingImageProcessor(size: size))  // 다운샘플링
    ]
)
```

### 주요 옵션

```swift
// 캐싱 관련
.cacheOriginalImage              // 원본 캐싱
.fromMemoryCacheOrRefresh        // 메모리 캐시 우선, 없으면 새로고침
.onlyFromCache                   // 캐시에서만 로드

// 네트워크 관련
.downloadPriority(0.5)           // 다운로드 우선순위
.backgroundDecode                // 백그라운드에서 디코딩
.callbackQueue(.mainAsync)       // 콜백 큐 지정

// 변환 관련
.processor(processor)            // 이미지 프로세서
.scaleFactor(scale)              // 스케일 팩터
.cacheSerializer(serializer)     // 캐시 시리얼라이저

// 애니메이션 관련
.transition(.fade(0.3))          // 전환 애니메이션
.forceTransition                 // 캐시 히트에도 애니메이션

// 기타
.keepCurrentImageWhileLoading    // 로딩 중 현재 이미지 유지
.onlyLoadFirstFrame              // 첫 프레임만 (GIF 등)
.waitForCache                    // 캐시 쓰기 대기
```

---

## 🎨 이미지 프로세서

### 내장 프로세서

#### 1. DownsamplingImageProcessor
큰 이미지를 효율적으로 리사이징:

```swift
let processor = DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))

imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)
```

#### 2. RoundCornerImageProcessor
라운드 코너 적용:

```swift
let processor = RoundCornerImageProcessor(
    cornerRadius: 20,
    backgroundColor: .white
)

imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)
```

#### 3. BlurImageProcessor
블러 효과:

```swift
let processor = BlurImageProcessor(blurRadius: 10)

imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)
```

#### 4. 프로세서 체이닝

여러 프로세서 조합:

```swift
let processor = 
    DownsamplingImageProcessor(size: size)
    |> RoundCornerImageProcessor(cornerRadius: 20)
    |> BlurImageProcessor(blurRadius: 5)

imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)
```

### 커스텀 프로세서

```swift
struct GrayscaleProcessor: ImageProcessor {
    let identifier = "com.example.grayscale"
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.grayscaled()
        case .data(_):
            return nil
        }
    }
}

// 사용
let processor = GrayscaleProcessor()
imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)
```

---

## 🗄️ 캐싱 전략

### 캐시 설정

```swift
let cache = ImageCache.default

// 메모리 캐시
cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024  // 100MB
cache.memoryStorage.config.countLimit = 50                      // 최대 50개
cache.memoryStorage.config.expiration = .seconds(300)           // 5분

// 디스크 캐시
cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024         // 200MB
cache.diskStorage.config.expiration = .days(7)                  // 7일

// 경로 커스터마이징
let diskCachePath = FileManager.default.urls(
    for: .cachesDirectory,
    in: .userDomainMask
).first!.appendingPathComponent("MyCache")

let cache = try! ImageCache(
    name: "MyCache",
    cacheDirectoryURL: diskCachePath
)
```

### 캐시 조작

```swift
let cache = ImageCache.default

// 캐시 확인
cache.isCached(forKey: url.cacheKey) { result in
    switch result {
    case .success(let cached):
        if cached.cached {
            print("캐시 타입: \(cached.cacheType)")
        }
    case .failure(let error):
        print("에러: \(error)")
    }
}

// 캐시에서 가져오기
cache.retrieveImage(forKey: url.cacheKey) { result in
    switch result {
    case .success(let value):
        if let image = value.image {
            print("캐시 히트: \(value.cacheType)")
        }
    case .failure(let error):
        print("에러: \(error)")
    }
}

// 캐시 저장
cache.store(image, forKey: url.cacheKey, toDisk: true)

// 캐시 삭제
cache.removeImage(forKey: url.cacheKey)

// 전체 캐시 삭제
cache.clearMemoryCache()
cache.clearDiskCache()

// 만료된 캐시 삭제
cache.cleanExpiredDiskCache()
```

---

## 📥 프리페칭

대량 이미지를 미리 로드:

```swift
import Kingfisher

class MyViewController: UIViewController {
    let prefetcher = ImagePrefetcher(
        urls: [
            URL(string: "https://example.com/1.jpg")!,
            URL(string: "https://example.com/2.jpg")!,
            URL(string: "https://example.com/3.jpg")!
        ],
        options: [.processor(DownsamplingImageProcessor(size: size))]
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prefetcher.completionHandler = { skipped, failed, completed in
            print("완료: \(completed.count)")
            print("실패: \(failed.count)")
            print("스킵: \(skipped.count)")
        }
        
        prefetcher.start()
    }
}
```

### UITableView/UICollectionView 통합

```swift
class MyViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    let prefetcher = ImagePrefetcher()
    var urls: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prefetch Data Source 설정
        tableView.prefetchDataSource = self
    }
}

extension MyViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { self.urls[$0.row] }
        prefetcher.start(with: urls)
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { self.urls[$0.row] }
        prefetcher.stop(with: urls)
    }
}
```

---

## ⚡ async/await 지원

### Modern Concurrency

```swift
// Swift 5.5+ async/await
Task {
    do {
        let result = try await KingfisherManager.shared.retrieveImage(with: url)
        imageView.image = result.image
        print("캐시 타입: \(result.cacheType)")
    } catch {
        print("에러: \(error)")
    }
}
```

### AsyncImage 대체

```swift
struct MyView: View {
    var body: some View {
        KFImage(url)
            .placeholder {
                ProgressView()
            }
            .resizable()
            .frame(width: 300, height: 300)
    }
}
```

---

## 🔧 고급 기능

### 1. 커스텀 Cache Key

```swift
// Resource 프로토콜 구현
struct CustomResource: Resource {
    var cacheKey: String {
        return "custom_\(downloadURL.lastPathComponent)"
    }
    
    var downloadURL: URL
}

let resource = CustomResource(downloadURL: url)
imageView.kf.setImage(with: resource)
```

### 2. 이미지 다운로드만

```swift
ImageDownloader.default.downloadImage(with: url) { result in
    switch result {
    case .success(let value):
        print("다운로드 완료: \(value.image)")
    case .failure(let error):
        print("실패: \(error)")
    }
}
```

### 3. Request Modifier

헤더 추가 등:

```swift
struct AuthModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        var r = request
        r.setValue("Bearer token", forHTTPHeaderField: "Authorization")
        return r
    }
}

let modifier = AuthModifier()
imageView.kf.setImage(
    with: url,
    options: [.requestModifier(modifier)]
)
```

### 4. 리다이렉트 핸들러

```swift
struct RedirectHandler: ImageDownloadRedirectHandler {
    func handleHTTPRedirection(
        for task: URLSessionTask,
        response: HTTPURLResponse,
        newRequest: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // 리다이렉트 로직
        completionHandler(newRequest)
    }
}

let handler = RedirectHandler()
imageView.kf.setImage(
    with: url,
    options: [.redirectHandler(handler)]
)
```

---

## 📊 성능 최적화

### 1. 다운샘플링

메모리 효율적인 리사이징:

```swift
let processor = DownsamplingImageProcessor(size: targetSize)
imageView.kf.setImage(
    with: url,
    options: [
        .processor(processor),
        .scaleFactor(UIScreen.main.scale),
        .cacheOriginalImage
    ]
)
```

### 2. 백그라운드 디코딩

```swift
imageView.kf.setImage(
    with: url,
    options: [.backgroundDecode]
)
```

### 3. 메모리 경고 대응

```swift
// 자동 처리 (기본 활성화)
// NotificationCenter가 자동으로 처리

// 수동 처리
override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    ImageCache.default.clearMemoryCache()
}
```

### 4. 취소 처리

```swift
class MyCell: UITableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 현재 다운로드 취소
        imageView.kf.cancelDownloadTask()
    }
}
```

---

## 💡 베스트 프랙티스

### 1. SwiftUI에서 KFImage 사용

```swift
// ✅ 좋음
KFImage(url)
    .placeholder { ProgressView() }
    .retry(maxCount: 3, interval: .seconds(5))
    .resizable()
    .frame(width: 200, height: 200)

// ❌ 나쁨 (AsyncImage는 캐싱 없음)
AsyncImage(url: url)
```

### 2. 옵션 재사용

```swift
// ✅ 좋음
let commonOptions: KingfisherOptionsInfo = [
    .transition(.fade(0.2)),
    .cacheOriginalImage,
    .backgroundDecode
]

imageView1.kf.setImage(with: url1, options: commonOptions)
imageView2.kf.setImage(with: url2, options: commonOptions)
```

### 3. 프로세서 체이닝

```swift
// ✅ 좋음
let processor = 
    DownsamplingImageProcessor(size: size)
    |> RoundCornerImageProcessor(cornerRadius: 10)

imageView.kf.setImage(with: url, options: [.processor(processor)])
```

### 4. 에러 처리

```swift
// ✅ 좋음
imageView.kf.setImage(with: url) { result in
    switch result {
    case .success(let value):
        print("성공: \(value.cacheType)")
    case .failure(let error):
        if case .imageSettingError(reason: .notCurrentSourceTask) = error {
            // 셀 재사용으로 인한 에러, 무시해도 됨
        } else {
            print("실제 에러: \(error)")
        }
    }
}
```

---

## 🐛 문제 해결

### 이미지가 깜빡임

**원인**: 캐시 히트에도 애니메이션 적용

**해결**:
```swift
// 애니메이션 제거
imageView.kf.setImage(
    with: url,
    options: [.transition(.none)]
)

// 또는 캐시 미스에만 애니메이션
imageView.kf.setImage(with: url) { result in
    if case .success(let value) = result {
        if value.cacheType == .none {
            // 애니메이션
        }
    }
}
```

### 메모리 부족

**원인**: 큰 이미지를 다운샘플링 없이 로드

**해결**:
```swift
let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)
```

### HTTPS 인증서 에러

**원인**: 자체 서명 인증서

**해결**:
```swift
let downloader = ImageDownloader.default
downloader.trustedHosts = Set(["your-domain.com"])
```

---

## 📚 참고 자료

### 공식 문서
- [GitHub](https://github.com/onevcat/Kingfisher)
- [Documentation](https://kingfisher-docs.netlify.app/)
- [Cheat Sheet](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet)

### 블로그
- [OneV's Den (작성자 블로그)](https://onevcat.com/)
- [Kingfisher 튜토리얼](https://www.raywenderlich.com/5896-kingfisher-tutorial-for-ios)

---

## 💬 요약

### 장점
✅ Pure Swift, 타입 안전  
✅ 깔끔하고 직관적인 API  
✅ SwiftUI 우수한 통합  
✅ 체이닝과 Modifier 패턴  
✅ async/await 완벽 지원  
✅ 활발한 유지보수  
✅ 풍부한 이미지 프로세서

### 단점
❌ SDWebImage보다 커뮤니티 작음  
❌ 일부 고급 기능 부족  
❌ Objective-C 프로젝트 불가

### 추천 상황
- 새로운 Swift 프로젝트
- SwiftUI 앱
- 코드 가독성 중시
- 개발자 경험(DX) 중요
- 중소 규모 앱

---

**Kingfisher로 우아한 이미지 로딩을 구현하세요! 🎨**

