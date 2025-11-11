# PHPhotoLibrary 이론 가이드

> PHPhotoLibrary, PHAsset, PHImageManager의 관계와 사용법을 이해합니다

---

## 📚 핵심 개념

### 1. PHPhotoLibrary

**사진 라이브러리의 진입점**

```swift
import Photos

// 싱글톤 인스턴스
let library = PHPhotoLibrary.shared()
```

**주요 역할**:
- 권한 상태 확인 및 요청
- 라이브러리 변경 감지
- 변경사항 저장 (사진 추가/삭제)

**핵심 메서드**:
```swift
// 권한 상태 확인
PHPhotoLibrary.authorizationStatus(for: .readWrite)

// 권한 요청
PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
    // .notDetermined → .limited/.authorized/.denied
}

// 변경사항 감지
PHPhotoLibrary.shared().register(self)
```

---

### 2. PHAsset

**개별 사진/비디오의 메타데이터**

```swift
// PHAsset은 실제 이미지 데이터가 아닌 메타데이터만 포함
let asset: PHAsset = ...

// 메타데이터 접근
asset.pixelWidth          // 이미지 너비
asset.pixelHeight         // 이미지 높이
asset.creationDate        // 촬영 날짜
asset.location            // GPS 위치
asset.mediaType           // .image, .video, .audio
asset.mediaSubtypes       // .photoPanorama, .photoHDR 등
```

**PHAsset의 특징**:
- ✅ 메타데이터만 포함 (가볍다)
- ✅ 실제 이미지 데이터는 PHImageManager로 로드
- ✅ 썸네일, 풀사이즈 등 다양한 크기 요청 가능

**PHAsset Fetch**:
```swift
// 모든 사진 가져오기
let fetchOptions = PHFetchOptions()
fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

// 특정 컬렉션에서 가져오기
let smartAlbums = PHAssetCollection.fetchAssetCollections(
    with: .smartAlbum,
    subtype: .smartAlbumUserLibrary,
    options: nil
)
```

---

### 3. PHImageManager

**이미지 로딩 및 캐싱**

```swift
let imageManager = PHImageManager.default()

// 썸네일 요청
imageManager.requestImage(
    for: asset,
    targetSize: CGSize(width: 200, height: 200),
    contentMode: .aspectFill,
    options: nil
) { image, info in
    // 이미지 로드 완료
}
```

**PHImageRequestOptions**:
```swift
let options = PHImageRequestOptions()
options.deliveryMode = .highQualityFormat      // 품질 우선
options.resizeMode = .exact                     // 정확한 크기
options.isSynchronous = false                  // 비동기 (기본값)
options.isNetworkAccessAllowed = true          // iCloud에서 다운로드 허용

imageManager.requestImage(
    for: asset,
    targetSize: targetSize,
    contentMode: .aspectFill,
    options: options
) { image, info in
    // ...
}
```

**캐싱 전략**:
- PHImageManager는 자동으로 썸네일 캐싱
- 같은 크기 요청은 캐시에서 즉시 반환
- 메모리 효율적

---

## 🔄 관계 구조

```
PHPhotoLibrary (싱글톤)
    ↓
    ├─ 권한 관리
    │   ├─ authorizationStatus()
    │   └─ requestAuthorization()
    │
    └─ 변경 감지
        └─ PHPhotoLibraryChangeObserver

PHAssetCollection (앨범/컬렉션)
    ↓
    └─ PHAsset.fetchAssets(in:collection, options:)

PHAsset (개별 사진 메타데이터)
    ↓
    └─ PHImageManager.requestImage(for:asset, ...)

UIImage (실제 이미지 데이터)
```

---

## 📖 사용 패턴

### 패턴 1: 갤러리 그리드 구현

```swift
// 1. PHAsset fetch
let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

// 2. 각 asset에 대해 썸네일 요청
for i in 0..<assets.count {
    let asset = assets[i]
    
    imageManager.requestImage(
        for: asset,
        targetSize: CGSize(width: 200, height: 200),
        contentMode: .aspectFill,
        options: nil
    ) { image, _ in
        // 썸네일 표시
    }
}
```

### 패턴 2: 풀사이즈 이미지 로드

```swift
let options = PHImageRequestOptions()
options.deliveryMode = .highQualityFormat
options.isNetworkAccessAllowed = true  // iCloud 동기화

imageManager.requestImage(
    for: asset,
    targetSize: PHImageManagerMaximumSize,  // 최대 크기
    contentMode: .aspectFit,
    options: options
) { image, info in
    if let image = image {
        // 풀사이즈 이미지 사용
    }
}
```

### 패턴 3: 이미지 데이터 직접 가져오기

```swift
let options = PHImageRequestOptions()
options.version = .current
options.deliveryMode = .highQualityFormat

imageManager.requestImageDataAndOrientation(
    for: asset,
    options: options
) { data, orientation, _, info in
    if let data = data {
        // Data 형식으로 받음 (EXIF 포함)
        let image = UIImage(data: data)
    }
}
```

---

## 🎯 주요 차이점: PhotosPicker vs PHAsset

### PhotosPicker (SwiftUI)

**장점**:
- ✅ 간단한 API
- ✅ 권한 자동 처리
- ✅ SwiftUI 네이티브 통합
- ✅ iOS 16+ 최신 방식

**단점**:
- ❌ 세밀한 제어 불가
- ❌ 썸네일 캐싱 직접 제어 불가
- ❌ 커스텀 UI 불가

### PHAsset (Photos Framework)

**장점**:
- ✅ 완전한 제어권
- ✅ 썸네일 최적화 가능
- ✅ 커스텀 갤러리 UI 구현 가능
- ✅ 필터링, 정렬 등 고급 기능

**단점**:
- ❌ 복잡한 API
- ❌ 권한 직접 관리 필요
- ❌ 더 많은 코드 필요

---

## 💡 실무 활용 팁

### 1. 썸네일 우선 로딩

```swift
// 먼저 썸네일 표시
imageManager.requestImage(
    for: asset,
    targetSize: CGSize(width: 200, height: 200),
    contentMode: .aspectFill,
    options: nil
) { thumbnail, _ in
    // 썸네일 즉시 표시
}

// 사용자가 탭하면 풀사이즈 로드
imageManager.requestImage(
    for: asset,
    targetSize: PHImageManagerMaximumSize,
    contentMode: .aspectFit,
    options: fullSizeOptions
) { fullImage, _ in
    // 풀사이즈 표시
}
```

### 2. 메모리 효율적인 로딩

```swift
let options = PHImageRequestOptions()
options.deliveryMode = .opportunistic  // 빠른 저품질 먼저, 고품질는 나중에
options.resizeMode = .fast             // 빠른 리사이즈

// 스크롤 중에는 저품질, 멈추면 고품질
```

### 3. iCloud 동기화 처리

```swift
let options = PHImageRequestOptions()
options.isNetworkAccessAllowed = true
options.isSynchronous = false

// iCloud에서 다운로드 중임을 표시
if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
   isDegraded {
    // 저품질 이미지 (다운로드 중)
} else {
    // 고품질 이미지 (다운로드 완료)
}
```

---

## 🔍 디버깅 팁

### PHAsset이 비어있는 경우

```swift
// 권한 확인
let status = PHPhotoLibrary.authorizationStatus()
if status == .denied || status == .restricted {
    // 권한 없음
}

// Limited 권한인 경우
if status == .limited {
    // 사용자가 선택한 사진만 접근 가능
}
```

### 이미지 로드 실패

```swift
imageManager.requestImage(...) { image, info in
    if let error = info?[PHImageErrorKey] as? Error {
        print("로드 실패: \(error)")
    }
    
    if let cancelled = info?[PHImageCancelledKey] as? Bool,
       cancelled {
        // 요청 취소됨
    }
}
```

---

## 📚 참고 자료

- [Apple: Photos Framework](https://developer.apple.com/documentation/photos)
- [Apple: PHPhotoLibrary](https://developer.apple.com/documentation/photos/phphotolibrary)
- [Apple: PHAsset](https://developer.apple.com/documentation/photos/phasset)
- [Apple: PHImageManager](https://developer.apple.com/documentation/photos/phimagemanager)

---

**다음**: `PERMISSION_GUIDE.md`에서 권한 시스템을 자세히 학습하세요.

