# 카메라 세션 구성 가이드

> 권한 요청부터 사진 캡처까지 단계별 구현 가이드

---

## 🎯 학습 목표

이 가이드를 따라하면:
- ✅ 카메라 권한 요청 구현
- ✅ AVCaptureSession 구성
- ✅ 실시간 미리보기 표시
- ✅ 사진 캡처 기능 구현

---

## 📋 단계별 구현

### 1단계: 권한 요청

#### Info.plist 설정

**필수**: 카메라 권한 설명 추가

```xml
<key>NSCameraUsageDescription</key>
<string>사진을 촬영하기 위해 카메라 접근이 필요합니다.</string>
```

#### 권한 확인 및 요청

```swift
import AVFoundation

class PermissionManager: ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus
    
    init() {
        self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            // 권한 요청
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                authorizationStatus = granted ? .authorized : .denied
            }
        default:
            await MainActor.run {
                authorizationStatus = status
            }
        }
    }
}
```

**사용법**:
```swift
let permissionManager = PermissionManager()

// 권한 요청
await permissionManager.requestPermission()

if permissionManager.authorizationStatus == .authorized {
    // 카메라 사용 가능
}
```

---

### 2단계: 카메라 세션 구성

#### CameraSessionManager 구현

```swift
import AVFoundation
import Combine

class CameraSessionManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    @Published var isSessionRunning = false
    @Published var error: Error?
    
    var photoOutput: AVCapturePhotoOutput?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // 카메라 장치 선택
            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ) else {
                self.error = CameraError.noCameraAvailable
                return
            }
            
            // 입력 추가
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
            } catch {
                self.error = error
                self.session.commitConfiguration()
                return
            }
            
            // 출력 추가
            let photoOutput = AVCapturePhotoOutput()
            if self.session.canAddOutput(photoOutput) {
                self.session.addOutput(photoOutput)
                self.photoOutput = photoOutput
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
}

enum CameraError: LocalizedError {
    case noCameraAvailable
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "카메라를 사용할 수 없습니다."
        case .permissionDenied:
            return "카메라 권한이 거부되었습니다."
        }
    }
}
```

**핵심 포인트**:
- `sessionQueue`: 세션 작업은 백그라운드 큐에서 수행
- `beginConfiguration()` / `commitConfiguration()`: 원자적 설정 변경
- `canAddInput` / `canAddOutput`: 추가 가능 여부 확인

---

### 3단계: 미리보기 표시

#### UIViewRepresentable로 통합

```swift
import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
```

#### SwiftUI에서 사용

```swift
struct SimpleCameraView: View {
    @StateObject private var sessionManager = CameraSessionManager()
    @StateObject private var permissionManager = PermissionManager()
    
    var body: some View {
        ZStack {
            if permissionManager.authorizationStatus == .authorized {
                CameraPreview(session: sessionManager.session)
                    .onAppear {
                        sessionManager.startSession()
                    }
                    .onDisappear {
                        sessionManager.stopSession()
                    }
            } else {
                // 권한 요청 UI
                PermissionRequestView(permissionManager: permissionManager)
            }
        }
    }
}
```

---

### 4단계: 사진 캡처

#### AVCapturePhotoCaptureDelegate 구현

```swift
extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = error
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // 이미지 처리
        DispatchQueue.main.async {
            // UIImage로 표시하거나 저장
            self.handleCapturedImage(image)
        }
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        // 이미지 저장 또는 표시
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}
```

#### 캡처 버튼 추가

```swift
struct CaptureView: View {
    @StateObject private var sessionManager = CameraSessionManager()
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            CameraPreview(session: sessionManager.session)
            
            VStack {
                Spacer()
                
                Button(action: {
                    sessionManager.capturePhoto()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 3)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 50)
            }
        }
    }
}
```

---

## 🔄 전체 플로우 통합

### CameraFlowView 예시

```swift
struct CameraFlowView: View {
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var sessionManager = CameraSessionManager()
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            switch permissionManager.authorizationStatus {
            case .notDetermined:
                // 권한 요청 화면
                PermissionRequestView(permissionManager: permissionManager)
                
            case .authorized:
                // 카메라 미리보기
                CameraPreview(session: sessionManager.session)
                    .onAppear {
                        sessionManager.startSession()
                    }
                    .onDisappear {
                        sessionManager.stopSession()
                    }
                
                // 캡처 버튼
                VStack {
                    Spacer()
                    CaptureButton {
                        sessionManager.capturePhoto()
                    }
                }
                
            case .denied, .restricted:
                // 권한 거부 안내
                PermissionDeniedView()
            }
        }
    }
}
```

---

## ⚠️ 주의사항

### 1. 실제 기기 필수

**시뮬레이터에서는 카메라를 사용할 수 없습니다!**
- 반드시 실제 iPhone/iPad에서 테스트
- 시뮬레이터에서는 권한 요청만 테스트 가능

### 2. 세션 생명주기

```swift
// 뷰가 나타날 때
.onAppear {
    sessionManager.startSession()
}

// 뷰가 사라질 때
.onDisappear {
    sessionManager.stopSession()
}
```

### 3. 백그라운드 처리

```swift
// 앱이 백그라운드로 갈 때 세션 중지
NotificationCenter.default.addObserver(
    forName: UIApplication.willResignActiveNotification,
    object: nil,
    queue: .main
) { _ in
    sessionManager.stopSession()
}
```

### 4. 메모리 관리

- 세션은 무거운 객체 → 필요할 때만 생성
- 뷰가 사라지면 세션 중지
- `deinit`에서 정리

```swift
deinit {
    session.stopRunning()
    // 입력/출력 제거
}
```

---

## 🐛 문제 해결

### "카메라를 사용할 수 없습니다"

**원인**: 시뮬레이터 사용 또는 권한 거부

**해결**:
1. 실제 기기에서 테스트
2. Info.plist에 권한 설명 확인
3. 설정 앱에서 권한 확인

### "세션이 시작되지 않습니다"

**원인**: 세션 설정 전에 `startRunning()` 호출

**해결**:
- `setupSession()` 완료 후 시작
- `sessionQueue`에서 순차적으로 처리

### "미리보기가 표시되지 않습니다"

**원인**: PreviewLayer 프레임 미설정

**해결**:
```swift
func updateUIView(_ uiView: UIView, context: Context) {
    if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
        previewLayer.frame = uiView.bounds  // 프레임 업데이트
    }
}
```

---

## 📚 다음 단계

- [PERFORMANCE_GUIDE.md](./PERFORMANCE_GUIDE.md) - 성능 측정 및 최적화
- [README.md](./README.md) - 전체 프로젝트 가이드

---

**Happy Coding! 📸**

