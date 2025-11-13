# Day 16: AVFoundation 카메라 세션 학습

> AVFoundation으로 기본 카메라 세션을 직접 구성하고, 권한 요청부터 사진 캡처까지의 전체 플로우를 학습합니다

---

## 📚 학습 목표

### 핵심 목표
- **AVFoundation 마스터**: AVCaptureSession, AVCaptureDevice, AVCapturePhotoOutput 구조 이해
- **권한 관리**: 카메라 권한 요청 및 상태 관리
- **세션 구성**: 카메라 세션 설정 및 미리보기 표시
- **사진 캡처**: AVCapturePhotoCaptureDelegate를 통한 사진 촬영

### 학습 포인트

#### AVFoundation 기초
- AVCaptureSession: 모든 캡처 작업의 중심
- AVCaptureDevice: 물리적 카메라 하드웨어
- AVCaptureVideoPreviewLayer: 실시간 미리보기
- AVCapturePhotoOutput: 사진 캡처 처리

#### 권한 관리
- `AVCaptureDevice.authorizationStatus(for:)`: 권한 상태 확인
- `AVCaptureDevice.requestAccess(for:)`: 권한 요청
- Info.plist에 `NSCameraUsageDescription` 필수

#### 세션 구성 플로우
1. 권한 확인
2. AVCaptureSession 생성
3. AVCaptureDevice 선택
4. AVCaptureDeviceInput 생성 및 추가
5. AVCapturePhotoOutput 생성 및 추가
6. AVCaptureVideoPreviewLayer 설정
7. 세션 시작

---

## 🗂️ 파일 구조

```
day16/
├── README.md                          # 이 파일
├── 시작하기.md                        # 빠른 시작 가이드
├── AVFOUNDATION_THEORY.md            # AVFoundation 기본 개념
├── CAMERA_SESSION_GUIDE.md           # 카메라 세션 구성 가이드
├── PERFORMANCE_GUIDE.md              # 성능 측정 가이드
│
└── day16/
    ├── ContentView.swift              # 메인 네비게이션
    ├── Info.plist                    # 카메라 권한 설정
    │
    ├── Core/                         # 핵심 로직
    │   ├── CameraSessionManager.swift    # AVCaptureSession 관리
    │   └── PermissionManager.swift       # 카메라 권한 관리
    │
    ├── Views/                        # 학습 뷰
    │   ├── CameraPreview.swift           # 미리보기 레이어 래퍼
    │   ├── SimpleCameraView.swift        # 기본 카메라 미리보기
    │   ├── CaptureView.swift             # 사진 캡처 기능
    │   └── CameraFlowView.swift          # 전체 플로우 통합
    │
    └── tool/                         # 성능 측정 도구
        ├── PerformanceMonitor.swift      # FPS, 메모리 측정
        ├── MemorySampler.swift           # 메모리 샘플링
        └── PerformanceLogger.swift       # 성능 로깅
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day16
open day16.xcodeproj
```

### 2. 권한 설정 확인
Info.plist에 다음 권한 설명이 포함되어 있는지 확인:
- `NSCameraUsageDescription`
- `NSPhotoLibraryAddUsageDescription` (사진 저장용)

### 3. 앱 실행
```
⌘R (Run)
```

**중요**: **실제 기기에서만 테스트 가능합니다!** 시뮬레이터는 카메라를 사용할 수 없습니다.

---

## 📖 학습 순서

### 📚 1단계: 이론 학습
먼저 이론 문서를 읽어보세요:

1. **AVFOUNDATION_THEORY.md** 읽기
   - AVFoundation 기본 개념
   - AVCaptureSession, AVCaptureDevice 구조
   - 세션 구성 원리

2. **CAMERA_SESSION_GUIDE.md** 읽기
   - 단계별 구현 가이드
   - 권한 → 세션 → 프리뷰 → 캡처 플로우

3. **PERFORMANCE_GUIDE.md** 읽기
   - 성능 측정 방법
   - FPS 및 메모리 모니터링

### 👨‍💻 2단계: 기본 실습

#### SimpleCameraView
- 카메라 권한 요청
- 기본 미리보기 표시
- 세션 시작/중지

#### CaptureView
- 사진 캡처 기능
- 카메라 전환 (전면/후면)
- 촬영한 사진 표시 및 저장

### 🚀 3단계: 실전 응용

#### CameraFlowView
- 전체 플로우 통합
- 성능 모니터 표시
- 실시간 FPS 및 메모리 측정

---

## 🔑 핵심 개념

### 1. 권한 요청

```swift
let status = AVCaptureDevice.authorizationStatus(for: .video)

switch status {
case .notDetermined:
    await AVCaptureDevice.requestAccess(for: .video)
case .authorized:
    // 카메라 사용 가능
case .denied, .restricted:
    // 권한 없음
}
```

### 2. 세션 구성

```swift
let session = AVCaptureSession()
session.sessionPreset = .photo

// 장치 선택
let camera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                     for: .video, 
                                     position: .back)

// 입력 추가
let input = try AVCaptureDeviceInput(device: camera)
session.addInput(input)

// 출력 추가
let photoOutput = AVCapturePhotoOutput()
session.addOutput(photoOutput)

// 세션 시작
session.startRunning()
```

### 3. 미리보기 표시

```swift
let previewLayer = AVCaptureVideoPreviewLayer(session: session)
previewLayer.videoGravity = .resizeAspectFill
previewLayer.frame = view.bounds
view.layer.addSublayer(previewLayer)
```

### 4. 사진 캡처

```swift
let settings = AVCapturePhotoSettings()
photoOutput.capturePhoto(with: settings, delegate: self)

// AVCapturePhotoCaptureDelegate
func photoOutput(_ output: AVCapturePhotoOutput,
                 didFinishProcessingPhoto photo: AVCapturePhoto,
                 error: Error?) {
    // 이미지 처리
}
```

---

## 💡 실무 활용

### 카메라 앱
- 기본 카메라 기능 구현
- 전면/후면 카메라 전환
- 사진 촬영 및 저장

### AR 앱
- 카메라 세션을 ARKit과 통합
- 실시간 비디오 처리

### 커스텀 카메라 UI
- SwiftUI로 카메라 UI 커스터마이징
- 필터 및 효과 적용

---

## 🔍 디버깅 팁

### "카메라를 사용할 수 없습니다" 오류

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

## 🎯 학습 체크리스트

### 기본
- [ ] AVFoundation 구조를 이해한다
- [ ] 카메라 권한을 요청할 수 있다
- [ ] AVCaptureSession을 구성할 수 있다
- [ ] 미리보기를 표시할 수 있다

### 응용
- [ ] 사진을 캡처할 수 있다
- [ ] 전면/후면 카메라를 전환할 수 있다
- [ ] 촬영한 사진을 저장할 수 있다
- [ ] 성능을 측정할 수 있다

### 심화
- [ ] 세션 생명주기를 관리할 수 있다
- [ ] 백그라운드 전환을 처리할 수 있다
- [ ] 에러를 적절히 처리할 수 있다
- [ ] 메모리 효율적인 세션 관리를 구현할 수 있다

---

## 📚 참고 자료

### Apple 공식 문서
- [AVFoundation Framework](https://developer.apple.com/documentation/avfoundation)
- [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [AVCaptureDevice](https://developer.apple.com/documentation/avfoundation/avcapturedevice)
- [AVCapturePhotoOutput](https://developer.apple.com/documentation/avfoundation/avcapturephotooutput)

### 가이드 문서
- `AVFOUNDATION_THEORY.md` - 이론 정리
- `CAMERA_SESSION_GUIDE.md` - 구현 가이드
- `PERFORMANCE_GUIDE.md` - 성능 측정

---

## ⚠️ 주의사항

### 실제 기기 필수
- 시뮬레이터에서는 카메라를 사용할 수 없습니다
- 반드시 실제 iPhone/iPad에서 테스트하세요

### 권한 설정
- Info.plist에 `NSCameraUsageDescription` 필수
- 권한 설명이 없으면 앱이 크래시할 수 있습니다

### 세션 생명주기
- 뷰가 나타날 때 세션 시작
- 뷰가 사라질 때 세션 중지
- 백그라운드 전환 시 세션 중지

---

## 🎓 다음 단계

AVFoundation 카메라 세션을 마스터했다면:

1. **복습**: 코드를 다시 읽어보기
2. **응용**: 나만의 카메라 앱 만들기
3. **공유**: 배운 내용 정리하기
4. **다음**: 비디오 녹화 기능 추가

---

## 💬 질문 & 피드백

학습 중 궁금한 점이 있다면:
- 각 View의 코드 주석 확인
- 가이드 문서 참고
- Apple 공식 문서 읽기

---

**Happy Learning! 📸**

*AVFoundation으로 더 똑똑한 카메라 앱을 만들어보세요!*

