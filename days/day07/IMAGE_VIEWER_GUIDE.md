# 이미지 뷰어 구현 가이드

> SwiftUI와 UIKit을 활용한 이미지 뷰어 구현 상세 가이드

---

## 📚 목차

1. [SwiftUI 뷰어 구현](#1-swiftui-뷰어-구현)
2. [UIKit 뷰어 구현](#2-uikit-뷰어-구현)
3. [줌/패닝 구현 패턴](#3-줌패닝-구현-패턴)
4. [포맷별 로딩 전략](#4-포맷별-로딩-전략)
5. [최적화 기법](#5-최적화-기법)

---

## 1. SwiftUI 뷰어 구현

### 갤러리 그리드

**LazyVGrid 활용**

```swift
struct GalleryGridView: View {
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { item in
                    ThumbnailCell(item: item)
                }
            }
        }
    }
}
```

**핵심 포인트**:
- `LazyVGrid`: 화면에 보이는 셀만 렌더링 (메모리 효율)
- `GridItem(.flexible())`: 가용 공간을 균등 분배
- `spacing`: 셀 간 간격 조정

### 썸네일 셀 구현

```swift
struct ThumbnailCell: View {
    let item: ImageItem
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
            } else {
                ProgressView()
                    .frame(height: 120)
            }
            
            Text(item.name)
                .font(.caption)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            let thumb = ImageCache.shared.getThumbnailOrCreate(
                forKey: item.name,
                maxSize: 200
            )
            DispatchQueue.main.async {
                self.thumbnail = thumb
            }
        }
    }
}
```

**핵심 포인트**:
- 비동기 로딩: 메인 스레드 블로킹 방지
- 캐시 활용: 중복 로딩 방지
- `onAppear`: 셀이 화면에 나타날 때 로드

### 이미지 상세보기 - 줌/패닝

```swift
struct ImageDetailView: View {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(magnificationGesture)
            .gesture(dragGesture)
            .onTapGesture(count: 2) {
                resetZoom()
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale *= delta
                scale = min(max(scale, 0.5), 5.0)  // 제한
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    private func resetZoom() {
        withAnimation(.spring()) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}
```

**핵심 포인트**:
- `scaleEffect`: 이미지 확대/축소
- `offset`: 이미지 이동
- `lastScale`/`lastOffset`: 이전 상태 저장
- 스케일 제한: 0.5x ~ 5.0x
- 애니메이션: `.spring()` 효과

### 메타데이터 오버레이

```swift
struct MetadataOverlay: View {
    let metadata: ImageMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("메타데이터", systemImage: "info.circle.fill")
                .font(.headline)
            
            Divider()
            
            MetadataRow(label: "포맷", value: metadata.format.rawValue)
            MetadataRow(label: "크기", value: "\(Int(metadata.size.width)) × \(Int(metadata.size.height)) px")
            // ... 추가 정보
        }
        .padding()
        .background(.ultraThinMaterial)  // 블러 배경
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

**핵심 포인트**:
- `.ultraThinMaterial`: iOS 15+ 블러 배경
- `Label`: SF Symbols와 텍스트 조합
- 정보 구조화: VStack + 커스텀 Row

---

## 2. UIKit 뷰어 구현

### 갤러리 - UICollectionView

**기본 설정**

```swift
class UIKitGalleryViewController: UIViewController {
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 10
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns + 1)
        let itemWidth = (view.bounds.width - totalSpacing) / columns
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 30)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(
            top: spacing,
            left: spacing,
            bottom: spacing,
            right: spacing
        )
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            ThumbnailCollectionCell.self,
            forCellWithReuseIdentifier: "ThumbnailCell"
        )
        
        view.addSubview(collectionView)
    }
}
```

**핵심 포인트**:
- `UICollectionViewFlowLayout`: 그리드 레이아웃
- 동적 크기 계산: 화면 너비 기반
- `sectionInset`: 여백 설정

### 셀 구현

```swift
class ThumbnailCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        
        // Auto Layout
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func configure(with item: ImageItem) {
        nameLabel.text = item.name
        
        // 비동기 로딩
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let thumbnail = ImageCache.shared.getThumbnailOrCreate(
                forKey: item.name,
                maxSize: 200
            )
            DispatchQueue.main.async {
                self?.imageView.image = thumbnail
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil  // 메모리 절약
    }
}
```

**핵심 포인트**:
- Auto Layout: 동적 레이아웃
- `prepareForReuse`: 셀 재사용 시 초기화
- `[weak self]`: 메모리 누수 방지

### 이미지 상세보기 - UIScrollView

```swift
class UIKitImageDetailViewController: UIViewController {
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupImageView()
        setupGestures()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
    }
    
    private func setupImageView() {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
    }
    
    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // 축소
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // 확대
            let touchPoint = gesture.location(in: imageView)
            let newZoomScale = scrollView.maximumZoomScale / 2
            let size = scrollView.bounds.size
            let width = size.width / newZoomScale
            let height = size.height / newZoomScale
            let x = touchPoint.x - (width / 2)
            let y = touchPoint.y - (height / 2)
            let rectToZoom = CGRect(x: x, y: y, width: width, height: height)
            scrollView.zoom(to: rectToZoom, animated: true)
        }
    }
    
    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
}

extension UIKitImageDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
```

**핵심 포인트**:
- `UIScrollViewDelegate`: 줌 기능 구현
- `viewForZooming`: 줌 대상 뷰 지정
- `centerImage()`: 이미지 중앙 정렬
- 더블탭 줌: 터치 위치 기반 확대

---

## 3. 줌/패닝 구현 패턴

### SwiftUI vs UIKit 비교

| 기능 | SwiftUI | UIKit |
|------|---------|-------|
| **구현 난이도** | 쉬움 | 중간 |
| **코드 양** | 적음 | 많음 |
| **관성 스크롤** | 없음 | 있음 |
| **세밀한 제어** | 어려움 | 쉬움 |
| **애니메이션** | 자동 | 수동 |
| **성능** | 동등 | 동등 |

### SwiftUI 장점

```swift
// 선언적, 간결
Image(uiImage: image)
    .scaleEffect(scale)
    .offset(offset)
    .gesture(MagnificationGesture()...)
```

- 코드 간결
- 애니메이션 쉬움 (`withAnimation`)
- State 관리 자동

### UIKit 장점

```swift
// 네이티브 스크롤 동작
scrollView.minimumZoomScale = 0.5
scrollView.maximumZoomScale = 5.0
```

- 관성 스크롤 기본 제공
- 정교한 제어 가능
- 성능 튜닝 옵션 많음

---

## 4. 포맷별 로딩 전략

### JPEG

```swift
// 빠른 로딩, 압축된 파일
let image = UIImage(named: "photo.jpg")
```

**특징**:
- 손실 압축
- 파일 크기 작음
- 로딩 빠름
- 투명도 없음

**최적화**:
- 웹/네트워크 전송에 적합
- 썸네일로 적합

### PNG

```swift
// 무손실, 투명도 지원
let image = UIImage(named: "icon.png")
```

**특징**:
- 무손실 압축
- 투명도 지원
- 파일 크기 큼
- 로딩 느림

**최적화**:
- 로고/아이콘에 적합
- 고품질 필요 시

### WebP (iOS 14+)

```swift
// 현대적 포맷, 효율적
// 기본 지원 또는 SDWebImage 사용
```

**특징**:
- 손실/무손실 모두 지원
- JPEG보다 30% 작음
- 투명도 지원
- 브라우저 호환성 좋음

**로딩 전략**:

```swift
// Dataset으로 로드 (iOS 14+)
if let asset = NSDataAsset(name: "sample3") {
    let image = UIImage(data: asset.data)
}

// 또는 SDWebImage
SDWebImageManager.shared.loadImage(with: url) { image, _, _, _, _, _ in
    // ...
}
```

---

## 5. 최적화 기법

### 썸네일 생성 최적화

```swift
// ImageIO 활용 (메모리 효율적)
func generateThumbnail(from image: UIImage, maxSize: CGFloat) -> UIImage? {
    guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    
    let options: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: maxSize,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]
    
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        return nil
    }
    
    return UIImage(cgImage: cgImage)
}
```

**장점**:
- 원본 이미지 전체를 메모리에 로드하지 않음
- GPU 디코딩 활용
- EXIF orientation 자동 처리

### 캐싱 전략

```swift
class ImageCache {
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        // 메모리 제한
        cache.totalCostLimit = 100 * 1024 * 1024  // 100MB
        
        // 메모리 워닝 시 정리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        let cost = estimateImageSize(image)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    private func estimateImageSize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4  // RGBA
    }
}
```

**핵심**:
- `NSCache`: 자동 메모리 관리
- `totalCostLimit`: 최대 메모리 설정
- 메모리 워닝 처리

### 비동기 로딩

```swift
// 메인 스레드 블로킹 방지
DispatchQueue.global(qos: .userInitiated).async {
    let image = ImageLoader.shared.loadUIImage(named: name)
    
    DispatchQueue.main.async {
        self.image = image
    }
}
```

**QoS 레벨**:
- `.userInitiated`: 사용자 요청 작업
- `.utility`: 백그라운드 작업
- `.background`: 우선순위 낮음

### 메모리 관리

```swift
// 셀 재사용 시
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil  // 이전 이미지 제거
    cancelImageLoad()      // 진행 중인 로드 취소
}

// 뷰가 사라질 때
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    // 대용량 리소스 해제
    largeImage = nil
}
```

---

## 📚 참고 자료

- [UIScrollView - Apple](https://developer.apple.com/documentation/uikit/uiscrollview)
- [UICollectionView - Apple](https://developer.apple.com/documentation/uikit/uicollectionview)
- [SwiftUI Gestures - Apple](https://developer.apple.com/documentation/swiftui/gestures)
- [Image I/O Programming Guide - Apple](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/)

---

**이미지 뷰어 구현을 마스터하셨습니다! 🎉**

