# 사진 라이브러리 권한 가이드

> iOS 14+ 권한 시스템 (.limited, .authorized, .denied) 완전 정복

---

## 🔐 권한 상태 종류

### PHAuthorizationStatus

```swift
enum PHAuthorizationStatus {
    case notDetermined    // 아직 요청하지 않음
    case restricted       // 제한됨 (부모 제어 등)
    case denied           // 거부됨
    case authorized       // 전체 접근 허용 (iOS 13 이하)
    case limited          // 제한적 접근 허용 (iOS 14+)
}
```

---

## 📱 iOS 14+ 권한 시스템 변화

### 이전 (iOS 13 이하)

```
사용자 선택
    ├─ 허용 → 전체 사진 접근
    └─ 거부 → 접근 불가
```

**문제점**:
- 모든 사진에 접근하거나 아예 접근 불가
- 중간 선택지 없음

### 현재 (iOS 14+)

```
사용자 선택
    ├─ 모든 사진 선택 → .authorized
    ├─ 선택한 사진만 → .limited
    └─ 거부 → .denied
```

**개선점**:
- ✅ 사용자가 선택한 사진만 공유 가능
- ✅ 개인정보 보호 강화
- ✅ 더 많은 사용자가 권한 허용

---

## 🔄 권한 흐름

### 1. 처음 실행 (.notDetermined)

```swift
let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

switch status {
case .notDetermined:
    // 권한 요청
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
        // .limited 또는 .authorized 또는 .denied
    }
}
```

**사용자 경험**:
1. 앱이 권한 요청 팝업 표시
2. 사용자 선택:
   - "모든 사진 허용" → `.authorized`
   - "선택한 사진만" → `.limited`
   - "허용 안 함" → `.denied`

### 2. Limited 권한 (.limited)

```swift
if status == .limited {
    // 사용자가 선택한 사진만 접근 가능
    // 추가 사진 선택 UI 제공 가능
}
```

**특징**:
- 선택한 사진만 `PHAsset.fetchAssets()`에서 반환
- 나머지 사진은 보이지 않음
- 사용자가 설정에서 변경 가능

**추가 사진 선택 UI**:
```swift
// iOS 14+에서 추가 사진 선택 UI 제공
PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
```

### 3. Authorized 권한 (.authorized)

```swift
if status == .authorized {
    // 모든 사진 접근 가능
    let assets = PHAsset.fetchAssets(with: .image, options: nil)
    // 전체 라이브러리 접근
}
```

### 4. Denied 권한 (.denied)

```swift
if status == .denied {
    // 접근 불가
    // 설정 앱으로 이동 안내
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

---

## 💻 구현 예제

### 권한 확인 및 요청

```swift
import Photos

class PermissionManager {
    static func checkPermission() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    static func requestPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
        let currentStatus = checkPermission()
        
        switch currentStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(status)
                }
            }
        default:
            completion(currentStatus)
        }
    }
}
```

### 권한 상태별 UI 처리

```swift
func handlePermissionStatus(_ status: PHAuthorizationStatus) {
    switch status {
    case .notDetermined:
        // 권한 요청
        requestPermission()
        
    case .limited:
        // 제한적 접근 - 선택한 사진만 표시
        showLimitedAccessMessage()
        loadLimitedPhotos()
        
    case .authorized:
        // 전체 접근 - 모든 사진 표시
        loadAllPhotos()
        
    case .denied:
        // 거부됨 - 설정으로 이동 안내
        showSettingsAlert()
        
    case .restricted:
        // 제한됨 - 부모 제어 등
        showRestrictedMessage()
        
    @unknown default:
        break
    }
}
```

### Limited 권한에서 추가 사진 선택

```swift
import SwiftUI
import PhotosUI

struct LimitedAccessView: View {
    @State private var showPicker = false
    
    var body: some View {
        Button("더 많은 사진 선택") {
            // iOS 14+ 시스템 UI 표시
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: UIApplication.shared.windows.first!.rootViewController!)
        }
    }
}
```

---

## 🔔 권한 변경 감지

### PHPhotoLibraryChangeObserver

```swift
class PhotoLibraryObserver: NSObject, PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // 권한 변경 또는 사진 추가/삭제 감지
        DispatchQueue.main.async {
            // UI 업데이트
        }
    }
}

// 등록
PHPhotoLibrary.shared().register(observer)
```

**변경 감지 시나리오**:
1. 사용자가 설정에서 권한 변경
2. 사용자가 사진 추가/삭제
3. Limited 권한에서 추가 사진 선택

---

## 📋 권한 요청 모범 사례

### 1. 적절한 타이밍

```swift
// ❌ 나쁜 예: 앱 시작 즉시 요청
func applicationDidFinishLaunching() {
    requestPermission()  // 너무 이르다
}

// ✅ 좋은 예: 사용자가 사진 선택 버튼을 탭할 때
func didTapSelectPhotoButton() {
    requestPermission { status in
        if status == .authorized || status == .limited {
            showPhotoPicker()
        }
    }
}
```

### 2. 명확한 설명

**Info.plist**:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 선택하여 이미지를 불러오기 위해 사진 라이브러리 접근이 필요합니다.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>편집한 이미지를 저장하기 위해 사진 라이브러리 접근이 필요합니다.</string>
```

### 3. 권한 거부 시 안내

```swift
func showSettingsAlert() {
    let alert = UIAlertController(
        title: "사진 접근 권한 필요",
        message: "설정에서 사진 접근 권한을 허용해주세요.",
        preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    })
    
    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
    present(alert, animated: true)
}
```

---

## 🎯 Limited 권한 전략

### 전략 1: 선택한 사진만 표시

```swift
// Limited 권한이면 자동으로 선택한 사진만 반환됨
let assets = PHAsset.fetchAssets(with: .image, options: nil)
// 사용자가 선택한 사진만 포함
```

### 전략 2: 추가 선택 UI 제공

```swift
if status == .limited {
    // "더 많은 사진 선택" 버튼 표시
    Button("더 많은 사진 선택") {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(...)
    }
}
```

### 전략 3: 권한 업그레이드 안내

```swift
if status == .limited {
    // "모든 사진에 접근하려면 설정에서 변경하세요" 안내
    showUpgradeMessage()
}
```

---

## 🔍 디버깅

### 권한 상태 확인

```swift
let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
print("현재 권한 상태: \(status)")

switch status {
case .notDetermined:
    print("아직 요청하지 않음")
case .limited:
    print("제한적 접근")
case .authorized:
    print("전체 접근")
case .denied:
    print("거부됨")
case .restricted:
    print("제한됨")
@unknown default:
    break
}
```

### 시뮬레이터에서 테스트

1. **Settings → Privacy → Photos**에서 권한 변경
2. 앱 재시작하여 변경사항 확인
3. Limited 권한 테스트는 실제 기기 권장

---

## 📚 참고 자료

- [Apple: PHAuthorizationStatus](https://developer.apple.com/documentation/photos/phauthorizationstatus)
- [Apple: Privacy - Photos](https://developer.apple.com/documentation/photokit/requesting_authorization_to_access_photos)
- [WWDC 2020: What's New in Photos](https://developer.apple.com/videos/play/wwdc2020/10652/)

---

**다음**: `PERFORMANCE_GUIDE.md`에서 성능 최적화를 학습하세요.

