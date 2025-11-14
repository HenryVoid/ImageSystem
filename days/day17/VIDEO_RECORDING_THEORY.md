# 동영상 녹화 이론 (AVFoundation)

> AVCaptureMovieFileOutput을 사용한 동영상 녹화의 핵심 개념과 원리

---

## 📚 AVCaptureMovieFileOutput이란?

**AVCaptureMovieFileOutput**은 AVFoundation에서 동영상을 파일로 녹화하는 출력 클래스입니다.

### 주요 특징

- **파일 기반 녹화**: 실시간으로 동영상을 파일에 저장
- **오디오 + 비디오**: 카메라와 마이크 입력을 동시에 처리
- **고품질 녹화**: 다양한 해상도와 프레임레이트 지원
- **백그라운드 처리**: 녹화 완료 시 델리게이트 콜백

---

## 🏗️ 핵심 클래스 구조

### 1. AVCaptureMovieFileOutput

**동영상 녹화 출력** - 세션의 출력으로 사용

```swift
let movieOutput = AVCaptureMovieFileOutput()
```

**주요 메서드**:
- `startRecording(to:delegate:)`: 녹화 시작
- `stopRecording()`: 녹화 중지
- `isRecording`: 녹화 중 여부 확인

**설정**:
```swift
// 최대 녹화 시간 설정
movieOutput.maxRecordedDuration = CMTime(seconds: 60, preferredTimescale: 600)

// 최대 파일 크기 설정
movieOutput.maxRecordedFileSize = 100 * 1024 * 1024 // 100MB
```

---

### 2. AVCaptureMovieFileOutputDelegate

**녹화 완료 콜백** - 녹화가 완료되면 호출

```swift
extension VideoSessionManager: AVCaptureMovieFileOutputDelegate {
    func fileOutput(
        _ output: AVCaptureMovieFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        // 녹화 완료 처리
    }
}
```

**콜백 시점**:
- 정상 완료: `error == nil`
- 오류 발생: `error != nil`
- 최대 시간/크기 도달: 자동 중지

---

### 3. 마이크 입력 추가

**오디오 입력** - 동영상에 오디오를 포함하려면 필수

```swift
// 마이크 장치 선택
guard let microphone = AVCaptureDevice.default(
    .builtInMicrophone,
    for: .audio,
    position: .unspecified
) else {
    return
}

// 마이크 입력 생성
let audioInput = try AVCaptureDeviceInput(device: microphone)
if session.canAddInput(audioInput) {
    session.addInput(audioInput)
}
```

**권한 필요**:
- `NSMicrophoneUsageDescription`: Info.plist에 필수

---

## 🔄 녹화 세션 구성 플로우

### 1단계: 권한 요청

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

### 2단계: 세션 구성

```swift
let session = AVCaptureSession()
session.sessionPreset = .high // 고품질 녹화

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

### 3단계: 녹화 시작

```swift
// 저장 위치 설정
let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                             in: .userDomainMask)[0]
let videoURL = documentsPath.appendingPathComponent("video.mov")

// 녹화 시작
movieOutput.startRecording(to: videoURL, recordingDelegate: self)
```

### 4단계: 녹화 중지

```swift
movieOutput.stopRecording()
// didFinishRecordingTo 콜백에서 처리
```

---

## 📁 파일 저장 위치

### 앱 내부 저장소

**Documents 디렉토리**: 사용자 데이터 저장

```swift
let documentsPath = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]

let videoURL = documentsPath.appendingPathComponent("video_\(timestamp).mov")
```

**특징**:
- ✅ iCloud 백업 포함 (기본)
- ✅ 앱 삭제 시 함께 삭제
- ✅ 사용자가 직접 접근 가능

### 임시 디렉토리

**Temporary 디렉토리**: 임시 파일

```swift
let tempPath = FileManager.default.temporaryDirectory
let videoURL = tempPath.appendingPathComponent("temp_video.mov")
```

**특징**:
- ⚠️ 시스템이 자동으로 정리할 수 있음
- ⚠️ iCloud 백업 제외
- ✅ 임시 파일에 적합

---

## 🎬 동영상 재생

### AVPlayer 사용

```swift
let player = AVPlayer(url: videoURL)
let playerViewController = AVPlayerViewController()
playerViewController.player = player

present(playerViewController, animated: true)
```

### SwiftUI에서 재생

```swift
import AVKit

VideoPlayer(player: AVPlayer(url: videoURL))
    .frame(height: 300)
```

---

## ⚙️ 녹화 설정

### 세션 Preset

```swift
session.sessionPreset = .high        // 고해상도
session.sessionPreset = .medium      // 중간 해상도
session.sessionPreset = .low         // 저해상도
session.sessionPreset = .photo       // 사진용 (비디오 아님)
```

### 비디오 코덱

```swift
// H.264 (기본)
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264
]

// HEVC (iOS 11+)
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.hevc
]
```

### 오디오 설정

```swift
// AAC 코덱 (기본)
let audioSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVSampleRateKey: 44100,
    AVNumberOfChannelsKey: 2
]
```

---

## 🔍 주요 차이점 (사진 vs 동영상)

| 항목 | 사진 (Photo) | 동영상 (Movie) |
|------|-------------|---------------|
| 출력 클래스 | `AVCapturePhotoOutput` | `AVCaptureMovieFileOutput` |
| 델리게이트 | `AVCapturePhotoCaptureDelegate` | `AVCaptureMovieFileOutputDelegate` |
| 입력 필요 | 카메라만 | 카메라 + 마이크 |
| 권한 | 카메라 | 카메라 + 마이크 |
| 저장 형식 | UIImage | URL (파일) |
| 처리 방식 | 즉시 완료 | 시간 경과 |

---

## ⚠️ 주의사항

### 1. 세션 생명주기

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

### 2. 녹화 중 세션 변경 금지

녹화 중에는 세션 설정을 변경하면 안 됩니다:
- 카메라 전환 불가
- Preset 변경 불가
- 입력/출력 추가/제거 불가

### 3. 메모리 관리

동영상 파일은 크기가 클 수 있으므로:
- 적절한 파일 크기 제한 설정
- 녹화 완료 후 즉시 처리
- 불필요한 파일 정리

### 4. 백그라운드 처리

앱이 백그라운드로 가면:
- 녹화가 자동으로 중지될 수 있음
- Info.plist에 `UIBackgroundModes` 설정 필요

---

## 📚 참고 자료

### Apple 공식 문서

- [AVCaptureMovieFileOutput](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutput)
- [AVCaptureMovieFileOutputDelegate](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutputdelegate)
- [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession)

### 관련 가이드

- `VIDEO_RECORDING_GUIDE.md` - 구현 가이드
- `PERFORMANCE_GUIDE.md` - 성능 최적화

---

**Happy Recording! 🎥**

