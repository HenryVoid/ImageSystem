# Day 15: PHPhotoLibrary 이미지 선택기 학습

> 사진 라이브러리 접근, 권한 관리, EXIF 메타데이터를 학습합니다

---

## 📚 학습 목표

### 핵심 목표
- **PHPhotoLibrary, PHAsset, PHImageManager 관계 구조 이해**
- **iOS 14+ 권한 시스템 (.limited, .authorized, .denied) 완전 정복**
- **PhotosPicker vs UIImagePickerController 차이점 파악**
- **EXIF 메타데이터 읽기 및 활용**

### 학습 포인트

#### PHPhotoLibrary란?
**Photos Framework** - iOS의 사진 라이브러리 접근 프레임워크
- PHPhotoLibrary: 라이브러리 접근 및 권한 관리
- PHAsset: 개별 사진/비디오 메타데이터
- PHImageManager: 이미지 로딩 및 캐싱

#### iOS 14+ 권한 시스템
- `.notDetermined` → 아직 요청하지 않음
- `.limited` → 선택한 사진만 접근 가능 (iOS 14+)
- `.authorized` → 전체 접근 허용
- `.denied` → 거부됨

---

## 🗂️ 파일 구조

```
day15/
├── PHOTOS_THEORY.md              # PHPhotoLibrary 이론 설명
├── PERMISSION_GUIDE.md           # 권한 시스템 가이드
├── PERFORMANCE_GUIDE.md          # 성능 최적화 가이드
├── README.md                     # 이 파일
├── 시작하기.md                   # 빠른 시작 가이드
│
└── day15/
    ├── ContentView.swift         # 메인 네비게이션
    │
    ├── Core/                     # 핵심 로직
    │   ├── PhotoLibraryManager.swift    # PHPhotoLibrary 래퍼
    │   ├── PermissionManager.swift       # 권한 관리
    │   └── EXIFReader.swift             # EXIF 읽기
    │
    ├── Views/                    # 학습 뷰
    │   ├── PhotosPickerView.swift       # SwiftUI PhotosPicker 기본
    │   ├── PHAssetGalleryView.swift     # PHAsset으로 갤러리 구현
    │   ├── PermissionFlowView.swift     # 권한 흐름 테스트
    │   ├── MetadataView.swift           # EXIF 메타데이터 표시
    │   └── ComparisonView.swift         # PhotosPicker vs UIImagePicker
    │
    ├── tool/                     # 유틸리티
    │   ├── PerformanceLogger.swift
    │   └── MemorySampler.swift
    │
    └── Info.plist                # 권한 설명
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day15
open day15.xcodeproj
```

### 2. 권한 설정 확인
Info.plist에 다음 권한 설명이 포함되어 있는지 확인:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

### 3. 앱 실행
```
⌘R (Run)
```

**중요**: 실제 기기에서 테스트하는 것을 권장합니다. 시뮬레이터는 사진 라이브러리가 비어있을 수 있습니다.

---

## 📖 학습 순서

### 📚 1단계: 이론 학습
먼저 이론 문서를 읽어보세요:

1. **PHOTOS_THEORY.md** 읽기
   - PHPhotoLibrary 구조
   - PHAsset, PHImageManager 사용법
   - 이미지 로딩 패턴

2. **PERMISSION_GUIDE.md** 읽기
   - iOS 14+ 권한 시스템
   - Limited 권한 처리
   - 권한 변경 감지

3. **PERFORMANCE_GUIDE.md** 읽기
   - 썸네일 우선 로딩
   - Lazy 로딩 전략
   - 메모리 최적화

### 👨‍💻 2단계: 기본 실습

#### PhotosPickerView
- SwiftUI PhotosPicker 기본 사용법
- 단일/다중 선택
- 이미지 로드

```swift
PhotosPicker(selection: $selectedItem, matching: .images) {
    Label("사진 선택", systemImage: "photo.on.rectangle.angled")
}
```

#### PHAssetGalleryView
- PHAsset으로 갤러리 그리드 구현
- 썸네일 우선 로딩
- 스크롤 성능 최적화

#### PermissionFlowView
- 권한 상태 확인
- 권한 요청 흐름 테스트
- Limited 권한 시나리오

### 🚀 3단계: 실전 응용

#### MetadataView
- 선택한 이미지의 EXIF 메타데이터 읽기
- 촬영 정보, 위치 정보 표시

#### ComparisonView
- PhotosPicker vs UIImagePickerController 비교
- 각각의 장단점 이해

---

## 🔑 핵심 개념

### 1. PHPhotoLibrary 구조

```swift
// 권한 확인
let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

// 권한 요청
PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
    // .limited 또는 .authorized 또는 .denied
}
```

### 2. PHAsset Fetch

```swift
let fetchOptions = PHFetchOptions()
fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
```

### 3. 이미지 로딩

```swift
// 썸네일
imageManager.requestImage(
    for: asset,
    targetSize: CGSize(width: 200, height: 200),
    contentMode: .aspectFill,
    options: nil
) { image, info in
    // 썸네일 표시
}

// 풀사이즈
imageManager.requestImage(
    for: asset,
    targetSize: PHImageManagerMaximumSize,
    contentMode: .aspectFit,
    options: options
) { image, info in
    // 풀사이즈 표시
}
```

---

## 💡 실무 활용

### 갤러리 앱
- PHAsset으로 갤러리 그리드 구현
- 썸네일 우선 로딩으로 성능 최적화
- 스크롤 성능 향상

### 사진 편집 앱
- PhotosPicker로 이미지 선택
- EXIF 메타데이터 보존
- 편집 후 저장

### 위치 기반 앱
- GPS 태그로 촬영 위치 확인
- 지도에 사진 표시
- 위치별 사진 그룹화

---

## 🔍 디버깅 팁

### 권한이 거부된 경우

```swift
if status == .denied {
    // 설정으로 이동 안내
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

### Limited 권한 처리

```swift
if status == .limited {
    // 추가 사진 선택 UI 제공
    PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
}
```

### 이미지 로드 실패

```swift
imageManager.requestImage(...) { image, info in
    if let error = info?[PHImageErrorKey] as? Error {
        print("로드 실패: \(error)")
    }
}
```

---

## 🎯 학습 체크리스트

### 기본
- [ ] PHPhotoLibrary 구조를 이해한다
- [ ] PHAsset으로 사진을 가져올 수 있다
- [ ] 썸네일과 풀사이즈를 구분해서 로드할 수 있다
- [ ] 권한 상태를 확인하고 요청할 수 있다

### 응용
- [ ] PhotosPicker를 사용할 수 있다
- [ ] PHAsset으로 갤러리를 구현할 수 있다
- [ ] Limited 권한을 처리할 수 있다
- [ ] EXIF 메타데이터를 읽을 수 있다

### 심화
- [ ] 성능 최적화 기법을 적용할 수 있다
- [ ] 권한 변경을 감지할 수 있다
- [ ] PhotosPicker와 UIImagePicker의 차이를 안다
- [ ] 메모리 효율적인 이미지 로딩을 구현할 수 있다

---

## 📚 참고 자료

### Apple 공식 문서
- [Photos Framework](https://developer.apple.com/documentation/photos)
- [PHPhotoLibrary](https://developer.apple.com/documentation/photos/phphotolibrary)
- [PHAsset](https://developer.apple.com/documentation/photos/phasset)
- [PHImageManager](https://developer.apple.com/documentation/photos/phimagemanager)
- [PhotosPicker](https://developer.apple.com/documentation/photospicker/photospicker)

### 가이드 문서
- `PHOTOS_THEORY.md` - 이론 정리
- `PERMISSION_GUIDE.md` - 권한 시스템 가이드
- `PERFORMANCE_GUIDE.md` - 성능 최적화

---

## 🐛 알려진 이슈

### iOS 시뮬레이터
- 사진 라이브러리가 비어있을 수 있음
- 실제 기기에서 테스트 권장

### PhotosPicker
- iOS 16+ 필요
- 이전 버전은 UIImagePickerController 사용

---

## 🎓 다음 단계

PHPhotoLibrary를 마스터했다면:

1. **복습**: 코드를 다시 읽어보기
2. **응용**: 나만의 갤러리 앱 만들기
3. **공유**: 배운 내용 정리하기
4. **다음**: Vision 프레임워크로 이미지 분석

---

## 💬 질문 & 피드백

학습 중 궁금한 점이 있다면:
- 각 View의 코드 주석 확인
- 가이드 문서 참고
- Apple 공식 문서 읽기

---

**Happy Learning! 📸**

*PHPhotoLibrary로 더 똑똑한 사진 앱을 만들어보세요!*

