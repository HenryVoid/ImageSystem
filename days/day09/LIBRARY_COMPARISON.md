# 라이브러리 아키텍처 비교

> SDWebImage, Kingfisher, Nuke의 설계 철학과 아키텍처 심층 비교

---

## 📊 전체 비교표

| 항목 | SDWebImage | Kingfisher | Nuke |
|------|-----------|-----------|------|
| **출시 연도** | 2009 | 2015 | 2015 |
| **언어** | Objective-C | Pure Swift | Pure Swift |
| **GitHub 스타** | 25,000+ | 23,000+ | 8,000+ |
| **iOS 지원** | 9.0+ | 12.0+ | 12.0+ |
| **SwiftUI** | 제한적 | 우수 | 우수 |
| **설계 철학** | 안정성 | 사용성 | 성능 |
| **학습 곡선** | 중간 | 쉬움 | 어려움 |
| **커뮤니티** | 가장 큼 | 큼 | 작음 |

---

## 🏗️ 아키텍처 비교

### 1. SDWebImage

```
┌─────────────────────────────┐
│   UIImageView+WebCache      │  ← Category 패턴
└─────────────┬───────────────┘
              │
┌─────────────▼───────────────┐
│   SDWebImageManager         │  ← Manager 패턴
│   (Objective-C)             │
└──────┬──────────────┬───────┘
       │              │
┌──────▼──────┐  ┌───▼─────────┐
│ SDImageCache│  │ SDWebImage  │
│             │  │ Downloader  │
│ NSCache +   │  │             │
│ FileManager │  │ NSOperation │
└─────────────┘  └─────────────┘
```

**특징**:
- **패턴**: Objective-C 전통 패턴 (Manager, Category)
- **구조**: 계층적 (Manager → Cache/Downloader)
- **확장**: Subclass와 Protocol
- **장점**: 성숙하고 안정적
- **단점**: 레거시 코드, Swift 통합 제한

---

### 2. Kingfisher

```
┌─────────────────────────────┐
│   KFImage (SwiftUI)         │  ← Modifier 패턴
│   UIImageView.kf            │  ← Extension
└─────────────┬───────────────┘
              │
┌─────────────▼───────────────┐
│   KingfisherManager         │  ← Coordinator
│   (Pure Swift)              │
└──────┬──────────────┬───────┘
       │              │
┌──────▼──────┐  ┌───▼─────────┐
│ ImageCache  │  │ ImageDown   │
│             │  │ loader      │
│ Protocol    │  │             │
│ Oriented    │  │ GCD Based   │
└─────────────┘  └─────────────┘
```

**특징**:
- **패턴**: Protocol Oriented Programming
- **구조**: Coordinator + Extension
- **확장**: Protocol + Generic
- **장점**: Swift 네이티브, 깔끔한 API
- **단점**: 고급 기능 제한적

---

### 3. Nuke

```
┌─────────────────────────────┐
│   LazyImage (SwiftUI)       │  ← Declarative
│   NukeExtensions            │  ← Extension
└─────────────┬───────────────┘
              │
┌─────────────▼───────────────┐
│   ImagePipeline             │  ← Pipeline 패턴
│   (Pure Swift)              │
└──┬────┬─────────┬───────┬───┘
   │    │         │       │
┌──▼──┐ │    ┌────▼───┐  │
│Image│ │    │Data    │  │
│Cache│ │    │Cache   │  │
└─────┘ │    └────────┘  │
    ┌───▼────┐       ┌───▼────┐
    │Decoder │       │ Loader │
    └────────┘       └────────┘
```

**특징**:
- **패턴**: Pipeline + Functional
- **구조**: 파이프라인 (데이터 흐름)
- **확장**: Pipeline Configuration
- **장점**: 최고 성능, 유연한 확장
- **단점**: 복잡한 구조, 높은 학습 곡선

---

## 🎨 API 설계 비교

### 기본 사용

#### SDWebImage
```swift
// Objective-C 스타일
imageView.sd_setImage(with: url)

// 옵션 배열
imageView.sd_setImage(
    with: url,
    placeholderImage: placeholder,
    options: [.progressiveLoad, .retryFailed]
)
```

**특징**:
- `sd_` 접두사 (name collision 방지)
- 옵션 배열
- Completion block

---

#### Kingfisher
```swift
// Swift 스타일
imageView.kf.setImage(with: url)

// 체이닝 + Modifier
imageView.kf.setImage(
    with: url,
    placeholder: placeholder,
    options: [
        .transition(.fade(0.2)),
        .processor(processor)
    ]
)

// SwiftUI
KFImage(url)
    .placeholder { ProgressView() }
    .retry(maxCount: 3)
```

**특징**:
- `kf` 네임스페이스
- Swift Result 타입
- SwiftUI Modifier

---

#### Nuke
```swift
// Functional 스타일
Nuke.loadImage(with: url, into: imageView)

// ImageRequest 중심
let request = ImageRequest(
    url: url,
    processors: [.resize(size: size)]
)
ImagePipeline.shared.loadImage(with: request)

// SwiftUI
LazyImage(url: url)

// async/await
let image = try await ImagePipeline.shared.image(for: url)
```

**특징**:
- Request 중심 설계
- Pipeline 명시적 제어
- Swift Concurrency 네이티브

---

## 🗄️ 캐싱 전략 비교

### 메모리 캐시

| 라이브러리 | 구현 | 특징 |
|-----------|-----|------|
| **SDWebImage** | NSCache + 커스텀 | LRU, Cost 기반 |
| **Kingfisher** | NSCache + Protocol | LRU, 만료 시간 |
| **Nuke** | 커스텀 LRU | 우선순위, TTL |

### 디스크 캐시

| 라이브러리 | 저장 방식 | 특징 |
|-----------|---------|------|
| **SDWebImage** | FileManager | 폴더 기반, MD5 해시 |
| **Kingfisher** | FileManager | 파일 기반, SHA256 해시 |
| **Nuke** | URLCache + 커스텀 | 2단계 (Data + Image) |

### 캐시 키

#### SDWebImage
```swift
// URL 그대로 사용
let key = url.absoluteString

// 커스텀 키
let filter = SDWebImageCacheKeyFilter { url in
    return customKey
}
```

#### Kingfisher
```swift
// Resource 프로토콜
struct CustomResource: Resource {
    var cacheKey: String {
        return "custom_\(downloadURL.lastPathComponent)"
    }
    var downloadURL: URL
}
```

#### Nuke
```swift
// ImageRequest의 URL + Processor ID
let request = ImageRequest(
    url: url,
    processors: [.resize(size: size)]
)
// 캐시 키: "url + resize_200x200"
```

---

## ⚡ 성능 최적화 비교

### 중복 제거

| 라이브러리 | 방식 | 효과 |
|-----------|-----|------|
| **SDWebImage** | URL 기반 대기열 | 중간 |
| **Kingfisher** | URL 기반 대기열 | 중간 |
| **Nuke** | Request 기반 자동 | **최고** |

### 동시 다운로드

```swift
// SDWebImage
SDWebImageDownloader.shared.config.maxConcurrentDownloads = 6

// Kingfisher
ImageDownloader.default.downloadTimeout = 15.0

// Nuke
// 자동 조절 (기본적으로 최적화됨)
```

### 프리로딩

#### SDWebImage
```swift
let prefetcher = SDWebImagePrefetcher.shared
prefetcher.prefetchURLs(urls)
```

#### Kingfisher
```swift
let prefetcher = ImagePrefetcher(urls: urls)
prefetcher.start()
```

#### Nuke
```swift
let preheater = ImagePreheater()
preheater.startPreheating(with: requests)
```

**비교**:
- SDWebImage: 기본적
- Kingfisher: UITableView 통합 우수
- Nuke: **우선순위 관리 최고**

---

## 🎨 이미지 처리 비교

### 트랜스포머/프로세서

#### SDWebImage
```swift
let transformer = SDImageResizingTransformer(
    size: size,
    scaleMode: .aspectFill
)
imageView.sd_setImage(
    with: url,
    context: [.imageTransformer: transformer]
)
```

#### Kingfisher
```swift
let processor = DownsamplingImageProcessor(size: size)
    |> RoundCornerImageProcessor(cornerRadius: 20)

imageView.kf.setImage(
    with: url,
    options: [.processor(processor)]
)
```

#### Nuke
```swift
let request = ImageRequest(
    url: url,
    processors: [
        .resize(size: size),
        .roundedCorners(radius: 20)
    ]
)
```

**비교**:
- SDWebImage: Context 기반 (복잡)
- Kingfisher: **파이프 연산자 (가독성 최고)**
- Nuke: 배열 기반 (간단)

---

## 📱 SwiftUI 지원 비교

### SDWebImage

```swift
// SDWebImageSwiftUI 필요
import SDWebImageSwiftUI

WebImage(url: url)
    .resizable()
    .placeholder {
        Rectangle().foregroundColor(.gray)
    }
```

**평가**: ⭐⭐⭐ (제한적 지원)

---

### Kingfisher

```swift
// 기본 패키지에 포함
import Kingfisher

KFImage(url)
    .placeholder { ProgressView() }
    .retry(maxCount: 3, interval: .seconds(5))
    .onSuccess { result in }
    .onFailure { error in }
    .resizable()
```

**평가**: ⭐⭐⭐⭐⭐ (최고 지원)

---

### Nuke

```swift
// NukeUI 필요
import NukeUI

LazyImage(url: url)
    .placeholder { _ in ProgressView() }
    .onCompletion { result in }
```

**평가**: ⭐⭐⭐⭐ (우수)

---

## 🔧 확장성 비교

### SDWebImage

**방식**: Subclassing + Category

```swift
// 커스텀 Downloader
class MyDownloader: SDWebImageDownloader {
    override func downloadImage(with url: URL) {
        // 커스텀 로직
    }
}
```

**평가**: 
- ✅ 성숙한 확장 포인트
- ❌ Objective-C 제약

---

### Kingfisher

**방식**: Protocol + Extension

```swift
// 커스텀 Processor
struct MyProcessor: ImageProcessor {
    let identifier = "my.processor"
    func process(item: ImageProcessItem) -> UIImage? {
        // 커스텀 로직
    }
}
```

**평가**:
- ✅ Swift Protocol 활용
- ✅ 타입 안전
- ✅ 깔끔한 코드

---

### Nuke

**방식**: Pipeline Configuration

```swift
// 커스텀 Pipeline
let pipeline = ImagePipeline {
    $0.dataLoader = MyDataLoader()
    $0.imageCache = MyImageCache()
    // 모든 컴포넌트 교체 가능
}
```

**평가**:
- ✅ 최고 수준 확장성
- ✅ 모든 컴포넌트 교체 가능
- ❌ 복잡함

---

## 💬 언제 어떤 라이브러리를 선택할까?

### SDWebImage를 선택하는 경우

```
✅ 레거시 Objective-C 프로젝트
✅ 이미 SDWebImage 사용 중
✅ 극도의 안정성 필요
✅ 커뮤니티 지원 중요
✅ UIKit 중심 앱
✅ 다양한 이미지 포맷 (WebP, SVG 등)
```

**대표 사용 사례**:
- 대규모 레거시 앱
- 금융/의료 앱 (안정성 최우선)
- UIKit 전용 앱

---

### Kingfisher를 선택하는 경우

```
✅ 새로운 Swift 프로젝트
✅ SwiftUI 앱
✅ 코드 가독성 중요
✅ 빠른 개발 속도
✅ 중소 규모 앱
✅ 팀 협업 (명확한 API)
```

**대표 사용 사례**:
- 신규 iOS 앱
- SwiftUI 중심 앱
- 스타트업 MVP
- 소셜 미디어 앱

---

### Nuke를 선택하는 경우

```
✅ 성능이 핵심 요구사항
✅ 대용량 이미지 처리
✅ 메모리 제약 있는 기기
✅ 고급 커스터마이징 필요
✅ 스크롤 성능 중요
✅ 프리로딩 전략 필요
```

**대표 사용 사례**:
- 이미지 중심 앱 (Instagram, Pinterest 스타일)
- 전자상거래 앱
- 갤러리 앱
- 고성능 요구 앱

---

## 📊 종합 평가

### 안정성

```
1. SDWebImage  ⭐⭐⭐⭐⭐ (10년+ 검증)
2. Kingfisher  ⭐⭐⭐⭐   (8년 검증)
3. Nuke        ⭐⭐⭐⭐   (8년 검증)
```

### 성능

```
1. Nuke        ⭐⭐⭐⭐⭐ (최고 성능)
2. Kingfisher  ⭐⭐⭐⭐   (우수)
3. SDWebImage  ⭐⭐⭐     (양호)
```

### 사용성 (DX)

```
1. Kingfisher  ⭐⭐⭐⭐⭐ (깔끔한 API)
2. Nuke        ⭐⭐⭐     (복잡)
3. SDWebImage  ⭐⭐⭐     (레거시 API)
```

### SwiftUI 지원

```
1. Kingfisher  ⭐⭐⭐⭐⭐ (KFImage 우수)
2. Nuke        ⭐⭐⭐⭐   (LazyImage 우수)
3. SDWebImage  ⭐⭐⭐     (제한적)
```

### 확장성

```
1. Nuke        ⭐⭐⭐⭐⭐ (Pipeline 최고)
2. Kingfisher  ⭐⭐⭐⭐   (Protocol 우수)
3. SDWebImage  ⭐⭐⭐     (Subclass)
```

### 커뮤니티

```
1. SDWebImage  ⭐⭐⭐⭐⭐ (가장 큼)
2. Kingfisher  ⭐⭐⭐⭐   (큼)
3. Nuke        ⭐⭐⭐     (작음)
```

---

## 🎯 최종 권장사항

### 일반적인 경우

**1순위: Kingfisher**
- 균형 잡힌 성능과 사용성
- Swift/SwiftUI 프로젝트에 최적
- 대부분의 사용 사례 충족

### 성능이 중요한 경우

**1순위: Nuke**
- 최고 수준의 성능과 메모리 효율
- 이미지 중심 앱에 적합
- 고급 최적화 필요 시

### 안정성이 최우선인 경우

**1순위: SDWebImage**
- 10년+ 검증된 안정성
- 레거시 프로젝트 유지보수
- UIKit 전용 앱

---

## 💡 마이그레이션 가이드

### SDWebImage → Kingfisher

```swift
// Before (SDWebImage)
imageView.sd_setImage(with: url)

// After (Kingfisher)
imageView.kf.setImage(with: url)
```

**난이도**: ⭐⭐ (쉬움)

---

### SDWebImage → Nuke

```swift
// Before (SDWebImage)
imageView.sd_setImage(with: url)

// After (Nuke)
Nuke.loadImage(with: url, into: imageView)
```

**난이도**: ⭐⭐⭐ (중간)

---

### Kingfisher → Nuke

```swift
// Before (Kingfisher)
imageView.kf.setImage(with: url)

// After (Nuke)
Nuke.loadImage(with: url, into: imageView)
```

**난이도**: ⭐⭐⭐ (중간)

---

**세 라이브러리의 차이를 이해하고 프로젝트에 맞는 선택을 하세요! 🎯**

