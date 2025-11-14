# Day 17: 동영상 녹화 및 저장 (AVFoundation)

> AVFoundation으로 동영상 녹화 기능을 직접 구현하고, 카메라와 마이크 입력을 추가하여 완전한 동영상 녹화 앱을 만듭니다

---

## 📚 학습 목표

### 핵심 목표

- **AVCaptureMovieFileOutput 마스터**: 동영상 녹화 출력 클래스 이해
- **권한 관리**: 카메라 + 마이크 권한 요청 및 상태 관리
- **세션 구성**: 비디오 + 오디오 입력을 포함한 세션 설정
- **동영상 녹화**: AVCaptureMovieFileOutputDelegate를 통한 녹화 처리
- **파일 관리**: 앱 내부 저장소에 동영상 저장 및 관리
- **동영상 재생**: AVPlayer로 저장된 동영상 재생

### 학습 포인트

#### AVFoundation 비디오 녹화

- AVCaptureSession: 비디오 + 오디오 세션 구성
- AVCaptureMovieFileOutput: 동영상 파일 출력
- AVCaptureMovieFileOutputDelegate: 녹화 완료 콜백
- AVCaptureVideoPreviewLayer: 실시간 미리보기

#### 권한 관리

- `AVCaptureDevice.authorizationStatus(for: .video)`: 카메라 권한 확인
- `AVCaptureDevice.authorizationStatus(for: .audio)`: 마이크 권한 확인
- `AVCaptureDevice.requestAccess(for:)`: 권한 요청
- Info.plist에 `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` 필수

#### 세션 구성 플로우

1. 권한 확인 (카메라 + 마이크)
2. AVCaptureSession 생성
3. 카메라 장치 선택 및 입력 추가
4. 마이크 장치 선택 및 입력 추가
5. AVCaptureMovieFileOutput 생성 및 추가
6. AVCaptureVideoPreviewLayer 설정
7. 세션 시작
8. 녹화 시작/중지

---

## 🗂️ 파일 구조

```
day17/
├── README.md                          # 이 파일
├── 시작하기.md                        # 빠른 시작 가이드
├── VIDEO_RECORDING_THEORY.md         # 동영상 녹화 기본 개념
├── VIDEO_RECORDING_GUIDE.md          # 동영상 녹화 구현 가이드
├── PERFORMANCE_GUIDE.md              # 성능 측정 가이드
│
└── day17/
    ├── ContentView.swift              # 메인 네비게이션
    ├── Info.plist                    # 카메라, 마이크 권한 설정
    │
    ├── Core/                         # 핵심 로직
    │   ├── VideoSessionManager.swift     # AVCaptureSession 관리
    │   └── PermissionManager.swift       # 카메라 + 마이크 권한 관리
    │
    ├── Views/                        # 학습 뷰
    │   ├── VideoPreview.swift             # 미리보기 레이어 래퍼
    │   ├── SimpleVideoView.swift         # 기본 비디오 미리보기
    │   ├── RecordingView.swift           # 동영상 녹화 기능
    │   ├── PlaybackView.swift            # 저장된 동영상 재생
    │   └── VideoFlowView.swift           # 전체 플로우 통합
    │
    └── tool/                         # 성능 측정 도구
        ├── PerformanceMonitor.swift      # FPS, 메모리 측정
        ├── VideoFileManager.swift        # 동영상 파일 관리
        ├── MemorySampler.swift           # 메모리 샘플링
        └── PerformanceLogger.swift      # 성능 로깅
```

---

## 🚀 시작하기

### 1. 프로젝트 열기

```bash
cd day17
open day17.xcodeproj
```

### 2. 권한 설정 확인

Info.plist에 다음 권한 설명이 포함되어 있는지 확인:

- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSPhotoLibraryAddUsageDescription` (동영상 저장용, 선택)

### 3. 앱 실행

```
⌘R (Run)
```

**중요**: **실제 기기에서만 테스트 가능합니다!** 시뮬레이터는 카메라와 마이크를 사용할 수 없습니다.

---

## 📖 학습 순서

### 📚 1단계: 이론 학습

먼저 이론 문서를 읽어보세요:

1. **VIDEO_RECORDING_THEORY.md** 읽기
   - AVCaptureMovieFileOutput 기본 개념
   - 카메라 + 마이크 권한 요청
   - 세션 구성 원리

2. **VIDEO_RECORDING_GUIDE.md** 읽기
   - 단계별 구현 가이드
   - 권한 → 세션 → 녹화 → 재생 플로우

3. **PERFORMANCE_GUIDE.md** 읽기
   - 성능 측정 방법
   - FPS, 메모리, 파일 크기 모니터링

### 👨‍💻 2단계: 기본 실습

#### SimpleVideoView

- 카메라 + 마이크 권한 요청
- 기본 미리보기 표시
- 세션 시작/중지

#### RecordingView

- 동영상 녹화 기능
- 녹화 시간 표시
- 카메라 전환 (전면/후면)

### 🚀 3단계: 실전 응용

#### PlaybackView

- 저장된 동영상 목록 표시
- AVPlayer로 동영상 재생
- 재생 컨트롤

#### VideoFlowView

- 전체 플로우 통합
- 녹화 → 저장 → 재생 플로우
- 성능 모니터 표시

---

## 🔑 핵심 개념

### 1. 권한 요청

```swift
// 카메라 권한
let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
if cameraStatus == .notDetermined {
    await AVCaptureDevice.requestAccess(for: .video)
}

// 마이크 권한
let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
if micStatus == .notDetermined {
    await AVCaptureDevice.requestAccess(for: .audio)
}
```

### 2. 세션 구성

```swift
let session = AVCaptureSession()
session.sessionPreset = .high

// 카메라 입력
let camera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                     for: .video, 
                                     position: .back)
let videoInput = try AVCaptureDeviceInput(device: camera)
session.addInput(videoInput)

// 마이크 입력
let microphone = AVCaptureDevice.default(.builtInMicrophone, 
                                       for: .audio, 
                                       position: .unspecified)
let audioInput = try AVCaptureDeviceInput(device: microphone)
session.addInput(audioInput)

// 동영상 출력
let movieOutput = AVCaptureMovieFileOutput()
session.addOutput(movieOutput)
```

### 3. 녹화 시작

```swift
let videoURL = documentsPath.appendingPathComponent("video.mov")
movieOutput.startRecording(to: videoURL, recordingDelegate: self)
```

### 4. 녹화 완료 처리

```swift
func fileOutput(_ output: AVCaptureMovieFileOutput,
                didFinishRecordingTo outputFileURL: URL,
                from connections: [AVCaptureConnection],
                error: Error?) {
    if let error = error {
        // 오류 처리
    } else {
        // 녹화 완료 처리
    }
}
```

---

## 💡 실무 활용

### 동영상 녹화 앱

- 기본 동영상 녹화 기능 구현
- 전면/후면 카메라 전환
- 동영상 저장 및 재생

### 라이브 스트리밍

- 동영상 녹화를 라이브 스트리밍으로 확장
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

### "마이크를 사용할 수 없습니다" 오류

**원인**: 마이크 권한 거부

**해결**:
1. Info.plist에 `NSMicrophoneUsageDescription` 확인
2. 설정 앱에서 마이크 권한 확인

### "녹화가 시작되지 않습니다"

**원인**: 세션 설정 전에 녹화 시작 또는 권한 없음

**해결**:
- `setupSession()` 완료 후 시작
- 카메라 + 마이크 권한 모두 확인
- `sessionQueue`에서 순차적으로 처리

---

## 🎯 학습 체크리스트

### 기본

- [ ] AVFoundation 비디오 녹화 구조를 이해한다
- [ ] 카메라 + 마이크 권한을 요청할 수 있다
- [ ] AVCaptureSession을 구성할 수 있다 (비디오 + 오디오)
- [ ] 미리보기를 표시할 수 있다

### 응용

- [ ] 동영상을 녹화할 수 있다
- [ ] 전면/후면 카메라를 전환할 수 있다
- [ ] 녹화된 동영상을 저장할 수 있다
- [ ] 저장된 동영상을 재생할 수 있다

### 심화

- [ ] 세션 생명주기를 관리할 수 있다
- [ ] 녹화 시간을 추적할 수 있다
- [ ] 에러를 적절히 처리할 수 있다
- [ ] 성능을 측정할 수 있다

---

## 📚 참고 자료

### Apple 공식 문서

- [AVFoundation Framework](https://developer.apple.com/documentation/avfoundation)
- [AVCaptureMovieFileOutput](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutput)
- [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer)

### 가이드 문서

- `VIDEO_RECORDING_THEORY.md` - 이론 정리
- `VIDEO_RECORDING_GUIDE.md` - 구현 가이드
- `PERFORMANCE_GUIDE.md` - 성능 측정

---

## ⚠️ 주의사항

### 실제 기기 필수

- 시뮬레이터에서는 카메라와 마이크를 사용할 수 없습니다
- 반드시 실제 iPhone/iPad에서 테스트하세요

### 권한 설정

- Info.plist에 `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` 필수
- 권한 설명이 없으면 앱이 크래시할 수 있습니다

### 세션 생명주기

- 뷰가 나타날 때 세션 시작
- 뷰가 사라질 때 세션 중지
- 백그라운드 전환 시 녹화 중지 고려

---

## 🎓 다음 단계

AVFoundation 동영상 녹화를 마스터했다면:

1. **복습**: 코드를 다시 읽어보기
2. **응용**: 나만의 동영상 녹화 앱 만들기
3. **공유**: 배운 내용 정리하기
4. **다음**: 동영상 편집 기능 추가

---

## 💬 질문 & 피드백

학습 중 궁금한 점이 있다면:

- 각 View의 코드 주석 확인
- 가이드 문서 참고
- Apple 공식 문서 읽기

---

**Happy Learning! 🎥**

*AVFoundation으로 더 똑똑한 동영상 앱을 만들어보세요!*

