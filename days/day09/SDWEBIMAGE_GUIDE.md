# SDWebImage 완벽 가이드

> iOS 이미지 로딩 라이브러리의 선구자, SDWebImage의 모든 것

---

## 📚 개요

### SDWebImage란?

**출시**: 2009년  
**언어**: Objective-C (Swift 래퍼 제공)  
**저장소**: https://github.com/SDWebImage/SDWebImage  
**라이선스**: MIT  
**스타**: 25,000+

SDWebImage는 iOS 이미지 로딩 라이브러리의 선구자입니다. 10년 이상의 역사를 가진 가장 안정적이고 성숙한 라이브러리로, UIKit에 최적화되어 있습니다.

### 핵심 특징

✅ **안정성**: 10년+ 검증된 프로덕션 레벨  
✅ **호환성**: iOS 9.0+, macOS 10.11+, tvOS, watchOS 지원  
✅ **포맷**: JPEG, PNG, GIF, WebP, HEIC, SVG 등 다양한 포맷  
✅ **캐싱**: 메모리 + 디스크 2단계 캐싱  
✅ **프로그레시브**: 점진적 이미지 로딩  
✅ **애니메이션**: GIF, APNG 애니메이션 지원  
✅ **커뮤니티**: 가장 큰 커뮤니티와 생태계

---

## 🏗️ 아키텍처

### 전체 구조

```
┌─────────────────────────────────────┐
│         UIImageView+WebCache        │  ← UIKit Extension
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      SDWebImageManager              │  ← 중앙 관리자
└─────────┬────────────────┬──────────┘
          │                │
┌─────────▼────────┐  ┌───▼──────────┐
│ SDImageCache     │  │ SDWebImage   │
│                  │  │ Downloader   │
│ ┌──────────────┐ │  └───┬──────────┘
│ │MemoryCache   │ │      │
│ │(NSCache)     │ │  ┌───▼──────────┐
│ └──────────────┘ │  │ NSURLSession │
│ ┌──────────────┐ │  └──────────────┘
│ │ DiskCache    │ │
│ │(FileManager) │ │
│ └──────────────┘ │
└──────────────────┘
```

### 주요 컴포넌트

#### 1. SDWebImageManager
**역할**: 전체 이미지 로딩 프로세스 조율

```swift
// 싱글톤 패턴
SDWebImageManager.shared
```

**주요 메서드**:
- `loadImage(with:options:progress:completed:)`: 이미지 로드
- `cancelAll()`: 모든 작업 취소
- `imageCache`: 캐시 접근
- `imageLoader`: 다운로더 접근

#### 2. SDImageCache
**역할**: 메모리 + 디스크 2단계 캐싱

**메모리 캐시**:
```swift
// NSCache 기반
let memoryCache = SDImageCache.shared.memoryCache
memoryCache.config.costLimit = 100 * 1024 * 1024  // 100MB
memoryCache.config.countLimit = 50  // 최대 50개
```

**디스크 캐시**:
```swift
// FileManager 기반
let diskCache = SDImageCache.shared.diskCache
diskCache.config.maxDiskAge = 60 * 60 * 24 * 7  // 7일
diskCache.config.maxDiskSize = 100 * 1024 * 1024  // 100MB
```

#### 3. SDWebImageDownloader
**역할**: 네트워크 다운로드 관리

**특징**:
- NSURLSession 기반
- 다운로드 큐 관리
- 동시 다운로드 수 제어
- 프로그레시브 다운로드

```swift
let downloader = SDWebImageDownloader.shared
downloader.config.maxConcurrentDownloads = 6
downloader.config.downloadTimeout = 15.0
```

---

## 🚀 기본 사용법

### UIKit (UIImageView)

가장 간단한 사용법:

```swift
import SDWebImage

let imageView = UIImageView()
let url = URL(string: "https://example.com/image.jpg")

// 기본 로딩
imageView.sd_setImage(with: url)
```

### 플레이스홀더 설정

```swift
imageView.sd_setImage(
    with: url,
    placeholderImage: UIImage(named: "placeholder")
)
```

### 옵션 활용

```swift
imageView.sd_setImage(
    with: url,
    placeholderImage: UIImage(named: "placeholder"),
    options: [.progressiveLoad, .retryFailed]
)
```

### 완료 핸들러

```swift
imageView.sd_setImage(with: url) { image, error, cacheType, url in
    if let error = error {
        print("로딩 실패: \(error)")
        return
    }
    
    switch cacheType {
    case .none:
        print("네트워크에서 다운로드")
    case .memory:
        print("메모리 캐시 히트")
    case .disk:
        print("디스크 캐시 히트")
    @unknown default:
        break
    }
}
```

### SwiftUI

SwiftUI에서도 사용 가능 (SDWebImageSwiftUI 패키지 필요):

```swift
import SDWebImageSwiftUI

WebImage(url: URL(string: "https://example.com/image.jpg"))
    .resizable()
    .placeholder {
        Rectangle().foregroundColor(.gray)
    }
    .indicator(.activity)
    .frame(width: 300, height: 300)
```

---

## ⚙️ 주요 옵션

### SDWebImageOptions

```swift
// 프로그레시브 로딩 (JPEG)
.progressiveLoad

// 실패한 URL 재시도
.retryFailed

// 캐시 무시하고 다운로드
.refreshCached

// 백그라운드에서 다운로드
.continueInBackground

// 고해상도 이미지 처리
.scaleDownLargeImages

// 애니메이션 GIF
.delayPlaceholder

// 캐시 키 변경
.transformAnimatedImage
```

### 옵션 조합

```swift
imageView.sd_setImage(
    with: url,
    options: [
        .progressiveLoad,      // 점진적 로딩
        .retryFailed,          // 재시도
        .scaleDownLargeImages  // 다운샘플링
    ]
)
```

---

## 🗄️ 캐싱 전략

### 캐시 흐름

```
이미지 요청
    ↓
메모리 캐시 확인
    ↓
    ├─ 있음 → 즉시 반환 (0-5ms)
    │
    └─ 없음
        ↓
    디스크 캐시 확인
        ↓
        ├─ 있음 → 메모리에 저장 후 반환 (10-50ms)
        │
        └─ 없음
            ↓
        네트워크 다운로드
            ↓
        메모리 + 디스크 저장
            ↓
        반환 (300-2000ms)
```

### 캐시 설정

```swift
let cache = SDImageCache.shared

// 메모리 캐시 설정
cache.config.maxMemoryCost = 100 * 1024 * 1024  // 100MB
cache.config.maxMemoryCount = 50                 // 최대 50개

// 디스크 캐시 설정
cache.config.maxDiskAge = 60 * 60 * 24 * 7      // 7일
cache.config.maxDiskSize = 200 * 1024 * 1024    // 200MB

// 캐시 동작 설정
cache.config.shouldCacheImagesInMemory = true    // 메모리 캐싱
cache.config.shouldUseWeakMemoryCache = true     // 약한 참조 사용
cache.config.diskCacheReadingOptions = .mappedIfSafe  // mmap 사용
```

### 캐시 관리

```swift
// 특정 URL 캐시 확인
cache.containsImage(forKey: url.absoluteString) { cacheType in
    switch cacheType {
    case .none:
        print("캐시 없음")
    case .memory:
        print("메모리에 있음")
    case .disk:
        print("디스크에 있음")
    @unknown default:
        break
    }
}

// 캐시에서 이미지 가져오기
cache.queryImage(forKey: url.absoluteString) { image, data, cacheType in
    if let image = image {
        print("캐시에서 가져옴: \(cacheType)")
    }
}

// 특정 이미지 삭제
cache.removeImage(forKey: url.absoluteString)

// 메모리 캐시만 삭제
cache.clearMemory()

// 디스크 캐시 삭제
cache.clearDisk()

// 오래된 디스크 캐시 삭제
cache.deleteOldFiles()
```

---

## 🎨 고급 기능

### 1. 이미지 트랜스포머

다운로드 후 이미지 변환:

```swift
// 리사이징
let transformer = SDImageResizingTransformer(
    size: CGSize(width: 200, height: 200),
    scaleMode: .aspectFill
)

imageView.sd_setImage(
    with: url,
    placeholderImage: nil,
    context: [.imageTransformer: transformer]
)
```

### 2. 커스텀 트랜스포머

```swift
class RoundedCornerTransformer: NSObject, SDImageTransformer {
    var transformerKey: String {
        return "RoundedCorner"
    }
    
    func transformedImage(with image: UIImage, forKey key: String) -> UIImage? {
        // 라운드 코너 적용
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 20)
            path.addClip()
            image.draw(in: rect)
        }
    }
}

// 사용
let transformer = RoundedCornerTransformer()
imageView.sd_setImage(
    with: url,
    context: [.imageTransformer: transformer]
)
```

### 3. 프로그레시브 다운로드

점진적으로 이미지를 표시:

```swift
imageView.sd_setImage(
    with: url,
    options: .progressiveLoad,
    progress: { receivedSize, expectedSize, _ in
        let progress = Float(receivedSize) / Float(expectedSize)
        print("진행: \(progress * 100)%")
    }
)
```

### 4. 프리페칭

미리 이미지를 캐시에 저장:

```swift
let prefetcher = SDWebImagePrefetcher.shared
let urls = [
    URL(string: "https://example.com/1.jpg")!,
    URL(string: "https://example.com/2.jpg")!,
    URL(string: "https://example.com/3.jpg")!
]

prefetcher.prefetchURLs(urls, progress: { finished, total in
    print("프리페치: \(finished)/\(total)")
}, completed: { finished, skipped in
    print("완료: \(finished)개, 스킵: \(skipped)개")
})
```

### 5. GIF 애니메이션

```swift
import SDWebImage

// GIF 로딩
imageView.sd_setImage(with: gifURL)

// 애니메이션 제어
let animatedImageView = SDAnimatedImageView()
animatedImageView.sd_setImage(with: gifURL)

// 애니메이션 설정
animatedImageView.shouldCustomLoopCount = true
animatedImageView.animationRepeatCount = 3  // 3번 반복
```

---

## 📊 성능 최적화

### 1. 다운샘플링

큰 이미지를 작게 표시할 때:

```swift
// 자동 다운샘플링
imageView.sd_setImage(
    with: url,
    options: .scaleDownLargeImages
)

// 수동 리사이징
let transformer = SDImageResizingTransformer(
    size: imageView.bounds.size,
    scaleMode: .aspectFill
)
imageView.sd_setImage(
    with: url,
    context: [.imageTransformer: transformer]
)
```

### 2. 동시 다운로드 제어

```swift
// 다운로더 설정
let downloader = SDWebImageDownloader.shared

// 최대 동시 다운로드 수
downloader.config.maxConcurrentDownloads = 4  // 기본 6

// 다운로드 순서
downloader.config.executionOrder = .FIFO  // FIFO 또는 LIFO
```

### 3. 메모리 경고 대응

```swift
// 자동 처리 (기본 활성화)
NotificationCenter.default.addObserver(
    forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil,
    queue: .main
) { _ in
    SDImageCache.shared.clearMemory()
}
```

### 4. 백그라운드 다운로드

```swift
imageView.sd_setImage(
    with: url,
    options: .continueInBackground
)
```

---

## 🔧 문제 해결

### 캐시가 작동하지 않음

**원인**: URL이 매번 다름 (예: timestamp 파라미터)

**해결**: 커스텀 캐시 키 사용

```swift
let context: [SDWebImageContextOption: Any] = [
    .cacheKeyFilter: SDWebImageCacheKeyFilter { url in
        // URL에서 쿼리 파라미터 제거
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        return components?.url?.absoluteString ?? url.absoluteString
    }
]

imageView.sd_setImage(with: url, context: context)
```

### 메모리 부족

**원인**: 캐시 크기가 너무 큼

**해결**: 캐시 크기 제한

```swift
let cache = SDImageCache.shared
cache.config.maxMemoryCost = 50 * 1024 * 1024  // 50MB로 축소
cache.config.maxDiskSize = 100 * 1024 * 1024   // 100MB로 축소
```

### 느린 스크롤

**원인**: 디코딩이 메인 스레드에서 발생

**해결**: 강제 디코딩

```swift
imageView.sd_setImage(
    with: url,
    options: .decodeFirstFrameOnly  // 첫 프레임만 디코딩
)
```

---

## 💡 베스트 프랙티스

### 1. 싱글톤 활용

```swift
// ✅ 좋음
let cache = SDImageCache.shared
let manager = SDWebImageManager.shared

// ❌ 나쁨 (메모리 낭비)
let cache = SDImageCache(namespace: "custom")
```

### 2. 옵션 재사용

```swift
// ✅ 좋음
let commonOptions: SDWebImageOptions = [
    .progressiveLoad,
    .retryFailed,
    .scaleDownLargeImages
]

imageView1.sd_setImage(with: url1, options: commonOptions)
imageView2.sd_setImage(with: url2, options: commonOptions)
```

### 3. 메모리 경고 대응

```swift
// ✅ 좋음
class MyViewController: UIViewController {
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        SDImageCache.shared.clearMemory()
    }
}
```

### 4. 취소 처리

```swift
// ✅ 좋음
class MyCell: UITableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
    }
}
```

---

## 📚 참고 자료

### 공식 문서
- [GitHub](https://github.com/SDWebImage/SDWebImage)
- [Wiki](https://github.com/SDWebImage/SDWebImage/wiki)
- [API Reference](https://sdwebimage.github.io/)

### 관련 프로젝트
- [SDWebImageSwiftUI](https://github.com/SDWebImage/SDWebImageSwiftUI): SwiftUI 지원
- [SDWebImageWebPCoder](https://github.com/SDWebImage/SDWebImageWebPCoder): WebP 포맷
- [SDWebImageSVGCoder](https://github.com/SDWebImage/SDWebImageSVGCoder): SVG 포맷

---

## 💬 요약

### 장점
✅ 가장 안정적이고 검증됨  
✅ 방대한 커뮤니티와 생태계  
✅ 다양한 이미지 포맷 지원  
✅ UIKit 완벽 지원  
✅ 풍부한 문서와 예제

### 단점
❌ Objective-C 기반 (Swift 래핑)  
❌ API가 다소 복잡  
❌ SwiftUI 지원 제한적  
❌ 일부 코드가 레거시

### 추천 상황
- 레거시 프로젝트 유지보수
- UIKit 중심 앱
- 안정성이 최우선
- 다양한 포맷 지원 필요
- 커뮤니티 지원 중요

---

**SDWebImage로 안정적인 이미지 로딩을 구현하세요! 🎨**

