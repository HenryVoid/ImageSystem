# Day 21 회고: 미디어 리더 앱 프로젝트

## 1. PHAsset과 AVAsset의 차이점

### PHAsset
- **메타데이터 중심**: `Photos` 프레임워크의 기본 단위로, 사진이나 비디오 파일의 메타데이터(식별자, 생성일, 위치, 미디어 타입 등)만 포함합니다.
- **가벼움**: 실제 이미지나 비디오 데이터는 포함하지 않으므로, 수천 개의 에셋을 배열에 담아도 메모리 부담이 적습니다.
- **데이터 로딩**: 실제 데이터를 얻으려면 `PHImageManager`를 통해 별도로 요청해야 합니다.

### AVAsset
- **미디어 데이터 추상화**: `AVFoundation` 프레임워크의 클래스로, 비디오나 오디오 같은 시한성(time-based) 미디어를 표현합니다.
- **비동기 로딩**: 트랙 정보, 지속 시간 등 세부 속성을 로드할 때 비동기적으로 처리해야 합니다.
- **재생**: `AVPlayerItem`으로 변환하여 `AVPlayer`에서 재생합니다.

### 연동 흐름
1. `PHAsset`을 `fetchAssets`로 가져옴.
2. 사용자가 비디오를 탭하면 `PHImageManager.requestPlayerItem(forVideo:)`를 호출.
3. 결과로 받은 `AVPlayerItem` (내부에 `AVAsset` 포함)을 `AVPlayer`에 주입하여 재생.

## 2. 이미지 vs 동영상 로딩 비용 및 최적화

- **이미지**:
  - 썸네일은 `targetSize`를 작게 지정하여 `fastFormat` 혹은 `opportunistic` 모드로 빠르게 로딩합니다.
  - 리스트 스크롤 시 `PHCachingImageManager`를 사용하여 미리 캐싱하면 버벅임을 줄일 수 있습니다.
  - 상세 보기에서는 `highQualityFormat`으로 원본에 가까운 이미지를 다시 로드합니다.

- **동영상**:
  - 동영상 로딩은 이미지보다 훨씬 비용이 큽니다.
  - 리스트에서는 동영상도 **이미지 썸네일**만 로드하여 보여주는 것이 필수적입니다.
  - 실제 `AVPlayer` 생성은 상세 화면 진입 후에만 수행해야 메모리와 CPU를 절약할 수 있습니다.

## 3. 썸네일 캐싱 전략 (PHCachingImageManager)

- **기본 동작**: `PHCachingImageManager`는 요청된 이미지를 메모리에 캐싱하여 재요청 시 빠르게 반환합니다.
- **Prefetching**: `PHCachingImageManager.startCachingImages(for:targetSize:contentMode:options:)`를 사용하여 화면에 보일 가능성이 높은 에셋들의 썸네일을 백그라운드에서 미리 디코딩할 수 있습니다.
- **구현 포인트**: SwiftUI의 `LazyVGrid`는 화면에 보이는 아이템만 뷰를 생성하므로, 뷰가 나타날 때 (`onAppear`) 이미지 요청을 하고, 사라질 때 취소하거나 관리하는 방식이 자연스럽습니다. 더 고도화하려면 `prefetching` 로직을 뷰모델에 추가하여 스크롤 위치에 따라 미리 캐싱 명령을 보낼 수 있습니다.

## 4. SwiftUI에서의 MediaView 아키텍처 흐름

1. **ViewModel**: `PHAsset` 컬렉션을 관리하고 권한을 체크합니다. UI 상태(`isLoading`, `permissionStatus`)를 발행합니다.
2. **Grid View**: `LazyVGrid`를 통해 효율적으로 셀을 그립니다. `NavigationLink`로 상세 화면 전환을 처리합니다.
3. **Detail View**: `TabView`를 사용하여 페이징을 구현합니다. 여기서 중요한 점은 `TabView` 내부의 각 페이지가 무거운 리소스(고화질 이미지, AVPlayer)를 가지고 있을 수 있다는 점입니다.
4. **Lazy Loading**: `TabView` 내부에서도 실제로 보이는 페이지의 컨텐츠만 로드하도록 `onAppear` 트리거를 잘 활용해야 합니다. 이번 프로젝트에서는 `MediaDetailItemView`가 나타날 때 고화질 이미지를 요청하도록 하여 이를 처리했습니다.

