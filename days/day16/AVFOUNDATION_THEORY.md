# AVFoundation 기본 개념

> AVFoundation 프레임워크의 핵심 개념과 카메라 세션 구성 원리

---

## 📚 AVFoundation이란?

**AVFoundation**은 iOS/macOS에서 오디오, 비디오 미디어를 다루는 핵심 프레임워크입니다.

### 주요 용도
- 📹 **카메라 세션**: 실시간 비디오 캡처
- 📸 **사진 촬영**: 고품질 사진 캡처
- 🎥 **비디오 녹화**: 동영상 녹화 및 편집
- 🎵 **오디오 재생/녹음**: 오디오 처리

---

## 🏗️ 핵심 클래스 구조

### 1. AVCaptureSession

**세션의 중심** - 모든 캡처 작업을 조율하는 객체

```swift
let session = AVCaptureSession()
```

**역할**:
- 입력(Input)과 출력(Output)을 연결
- 캡처 품질 설정 (preset)
- 세션 시작/중지 제어

**Preset 종류**:
- `.photo`: 고품질 사진 촬영
- `.high`: 고해상도 비디오
- `.medium`: 중간 해상도
- `.low`: 저해상도 (빠른 처리)

```swift
session.sessionPreset = .photo
```

---

### 2. AVCaptureDevice

**물리적 하드웨어** - 카메라, 마이크 등 실제 장치

```swift
// 후면 카메라
let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

// 전면 카메라
let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
```

**주요 메서드**:
- `default(_:for:position:)`: 기본 장치 가져오기
- `authorizationStatus(for:)`: 권한 상태 확인
- `requestAccess(for:)`: 권한 요청

**장치 타입**:
- `.builtInWideAngleCamera`: 일반 카메라
- `.builtInUltraWideCamera`: 초광각 카메라
- `.builtInTelephotoCamera`: 망원 카메라

---

### 3. AVCaptureDeviceInput

**입력 연결** - 장치를 세션에 연결하는 브릿지

```swift
guard let input = try? AVCaptureDeviceInput(device: camera) else {
    return
}

if session.canAddInput(input) {
    session.addInput(input)
}
```

**역할**:
- AVCaptureDevice를 AVCaptureSession에 연결
- 여러 입력 동시 지원 (예: 전면+후면 카메라)

---

### 4. AVCaptureVideoPreviewLayer

**미리보기 레이어** - 실시간 카메라 화면 표시

```swift
let previewLayer = AVCaptureVideoPreviewLayer(session: session)
previewLayer.videoGravity = .resizeAspectFill
previewLayer.frame = view.bounds
view.layer.addSublayer(previewLayer)
```

**videoGravity 옵션**:
- `.resizeAspectFill`: 비율 유지하며 채움 (잘림 가능)
- `.resizeAspect`: 비율 유지하며 맞춤 (여백 가능)
- `.resize`: 비율 무시하고 채움

---

### 5. AVCapturePhotoOutput

**사진 출력** - 사진 캡처 처리

```swift
let photoOutput = AVCapturePhotoOutput()

if session.canAddOutput(photoOutput) {
    session.addOutput(photoOutput)
}
```

**사진 캡처**:
```swift
let settings = AVCapturePhotoSettings()
photoOutput.capturePhoto(with: settings, delegate: self)
```

**AVCapturePhotoCaptureDelegate**:
- `photoOutput(_:didFinishProcessingPhoto:error:)`: 캡처 완료 콜백

---

## 🔄 세션 구성 플로우

### 기본 단계

```
1. 권한 확인
   ↓
2. AVCaptureSession 생성
   ↓
3. AVCaptureDevice 선택
   ↓
4. AVCaptureDeviceInput 생성 및 추가
   ↓
5. AVCapturePhotoOutput 생성 및 추가
   ↓
6. AVCaptureVideoPreviewLayer 설정
   ↓
7. 세션 시작 (startRunning)
```

### 코드 예시

```swift
// 1. 세션 생성
let session = AVCaptureSession()
session.sessionPreset = .photo

// 2. 장치 선택
guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                           for: .video, 
                                           position: .back) else {
    return
}

// 3. 입력 생성 및 추가
do {
    let input = try AVCaptureDeviceInput(device: camera)
    if session.canAddInput(input) {
        session.addInput(input)
    }
} catch {
    print("입력 생성 실패: \(error)")
}

// 4. 출력 생성 및 추가
let photoOutput = AVCapturePhotoOutput()
if session.canAddOutput(photoOutput) {
    session.addOutput(photoOutput)
}

// 5. 미리보기 레이어 설정
let previewLayer = AVCaptureVideoPreviewLayer(session: session)
previewLayer.videoGravity = .resizeAspectFill
previewLayer.frame = view.bounds
view.layer.addSublayer(previewLayer)

// 6. 세션 시작
session.startRunning()
```

---

## 🔐 권한 관리

### 권한 상태

```swift
enum AVAuthorizationStatus {
    case notDetermined    // 아직 요청하지 않음
    case restricted       // 제한됨 (부모 제어 등)
    case denied          // 거부됨
    case authorized      // 허용됨
}
```

### 권한 요청

```swift
let status = AVCaptureDevice.authorizationStatus(for: .video)

switch status {
case .notDetermined:
    // 권한 요청
    await AVCaptureDevice.requestAccess(for: .video)
case .authorized:
    // 카메라 사용 가능
    setupCamera()
case .denied, .restricted:
    // 권한 없음 - 설정으로 안내
    showSettingsAlert()
}
```

**중요**: Info.plist에 `NSCameraUsageDescription` 필수!

---

## ⚙️ 세션 설정 패턴

### Configuration 블록 사용

```swift
session.beginConfiguration()
// 여기서 모든 설정 변경
session.sessionPreset = .photo
session.addInput(input)
session.addOutput(output)
session.commitConfiguration()  // 한 번에 적용
```

**이유**: 
- 원자적(atomic) 변경 보장
- 세션 중단 없이 설정 변경 가능
- 성능 최적화

---

## 🎯 실전 팁

### 1. 세션 생명주기 관리

```swift
// 시작
session.startRunning()

// 중지
session.stopRunning()

// 백그라운드 전환 시
NotificationCenter.default.addObserver(
    forName: UIApplication.willResignActiveNotification,
    object: nil,
    queue: .main
) { _ in
    session.stopRunning()
}
```

### 2. 에러 처리

```swift
do {
    let input = try AVCaptureDeviceInput(device: camera)
    // ...
} catch {
    print("카메라 입력 생성 실패: \(error.localizedDescription)")
    // 사용자에게 알림
}
```

### 3. 메모리 관리

- 세션은 무거운 객체 → 필요할 때만 생성
- 뷰가 사라질 때 `stopRunning()` 호출
- `deinit`에서 정리 작업

```swift
deinit {
    session.stopRunning()
    // 입력/출력 제거
}
```

---

## 📖 참고 자료

- [AVFoundation Framework](https://developer.apple.com/documentation/avfoundation)
- [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [AVCaptureDevice](https://developer.apple.com/documentation/avfoundation/avcapturedevice)
- [AVCapturePhotoOutput](https://developer.apple.com/documentation/avfoundation/avcapturephotooutput)

---

**다음**: [CAMERA_SESSION_GUIDE.md](./CAMERA_SESSION_GUIDE.md) - 단계별 구현 가이드

