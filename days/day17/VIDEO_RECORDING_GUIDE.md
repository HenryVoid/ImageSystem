# 동영상 녹화 구현 가이드

> 단계별 동영상 녹화 기능 구현 가이드

---

## 🎯 구현 목표

1. 카메라 + 마이크 권한 요청
2. AVCaptureSession 구성 (비디오 + 오디오 입력)
3. AVCaptureMovieFileOutput 설정
4. 녹화 시작/중지 기능
5. 저장된 동영상 재생

---

## 📋 구현 단계

### 1단계: 권한 요청

#### Info.plist 설정

```xml
<key>NSCameraUsageDescription</key>
<string>동영상을 녹화하기 위해 카메라 접근이 필요합니다.</string>

<key>NSMicrophoneUsageDescription</key>
<string>동영상에 오디오를 포함하기 위해 마이크 접근이 필요합니다.</string>
```

#### 권한 확인 및 요청

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

---

### 2단계: 세션 구성

#### VideoSessionManager 초기화

```swift
class VideoSessionManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "video.session.queue")
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    var movieOutput: AVCaptureMovieFileOutput?
    
    override init() {
        super.init()
        setupSession()
    }
}
```

#### 세션 설정

```swift
private func setupSession() {
    sessionQueue.async { [weak self] in
        guard let self = self else { return }
        
        self.session.beginConfiguration()
        self.session.sessionPreset = .high
        
        // 카메라 입력
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
                self.videoInput = videoInput
            }
        } catch {
            print("카메라 입력 설정 실패: \(error)")
        }
        
        // 마이크 입력
        guard let microphone = AVCaptureDevice.default(
            .builtInMicrophone,
            for: .audio,
            position: .unspecified
        ) else {
            return
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: microphone)
            if self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
                self.audioInput = audioInput
            }
        } catch {
            print("마이크 입력 설정 실패: \(error)")
        }
        
        // 동영상 출력
        let movieOutput = AVCaptureMovieFileOutput()
        if self.session.canAddOutput(movieOutput) {
            self.session.addOutput(movieOutput)
            self.movieOutput = movieOutput
            
            // 최대 녹화 시간 설정 (60초)
            movieOutput.maxRecordedDuration = CMTime(seconds: 60, preferredTimescale: 600)
        }
        
        self.session.commitConfiguration()
    }
}
```

---

### 3단계: 녹화 시작

#### 저장 위치 설정

```swift
private func getVideoURL() -> URL {
    let documentsPath = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    let fileName = "video_\(formatter.string(from: Date())).mov"
    
    return documentsPath.appendingPathComponent(fileName)
}
```

#### 녹화 시작

```swift
func startRecording() {
    guard let movieOutput = movieOutput,
          !movieOutput.isRecording else {
        return
    }
    
    sessionQueue.async { [weak self] in
        guard let self = self else { return }
        
        let videoURL = self.getVideoURL()
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
        
        movieOutput.startRecording(to: videoURL, recordingDelegate: self)
    }
}
```

---

### 4단계: 녹화 중지

#### 녹화 중지

```swift
func stopRecording() {
    guard let movieOutput = movieOutput,
          movieOutput.isRecording else {
        return
    }
    
    sessionQueue.async { [weak self] in
        movieOutput.stopRecording()
        
        DispatchQueue.main.async {
            self?.isRecording = false
        }
    }
}
```

#### 델리게이트 구현

```swift
extension VideoSessionManager: AVCaptureMovieFileOutputDelegate {
    func fileOutput(
        _ output: AVCaptureMovieFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            print("녹화 오류: \(error.localizedDescription)")
            return
        }
        
        print("녹화 완료: \(outputFileURL)")
        // 녹화 완료 처리 (예: 재생, 저장 등)
    }
}
```

---

### 5단계: 녹화 시간 추적

#### 타이머 설정

```swift
private var recordingTimer: Timer?

func startRecording() {
    // ... 녹화 시작 코드 ...
    
    // 타이머 시작
    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        guard let self = self,
              let movieOutput = self.movieOutput,
              movieOutput.isRecording else {
            return
        }
        
        let duration = movieOutput.recordedDuration.seconds
        DispatchQueue.main.async {
            self.recordingDuration = duration
        }
    }
}

func stopRecording() {
    // ... 녹화 중지 코드 ...
    
    // 타이머 중지
    recordingTimer?.invalidate()
    recordingTimer = nil
    recordingDuration = 0
}
```

---

### 6단계: 카메라 전환

#### 카메라 전환 구현

```swift
func switchCamera() {
    sessionQueue.async { [weak self] in
        guard let self = self else { return }
        
        // 녹화 중이면 전환 불가
        guard !self.isRecording else { return }
        
        self.session.beginConfiguration()
        
        // 기존 비디오 입력 제거
        if let currentInput = self.videoInput {
            self.session.removeInput(currentInput)
        }
        
        // 카메라 위치 전환
        let newPosition: AVCaptureDevice.Position = 
            self.currentCameraPosition == .back ? .front : .back
        
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: newPosition
        ) else {
            self.session.commitConfiguration()
            return
        }
        
        // 새 입력 추가
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
                self.videoInput = videoInput
                self.currentCameraPosition = newPosition
            }
        } catch {
            print("카메라 전환 실패: \(error)")
        }
        
        self.session.commitConfiguration()
    }
}
```

---

### 7단계: 동영상 재생

#### 파일 목록 조회

```swift
func getRecordedVideos() -> [URL] {
    let documentsPath = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    
    do {
        let files = try FileManager.default.contentsOfDirectory(
            at: documentsPath,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        return files.filter { $0.pathExtension == "mov" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
    } catch {
        print("파일 목록 조회 실패: \(error)")
        return []
    }
}
```

#### AVPlayer로 재생

```swift
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: videoURL)
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}
```

---

## 🎨 UI 구현 예시

### 녹화 버튼

```swift
Button(action: {
    if sessionManager.isRecording {
        sessionManager.stopRecording()
    } else {
        sessionManager.startRecording()
    }
}) {
    ZStack {
        Circle()
            .fill(sessionManager.isRecording ? Color.red : Color.white)
            .frame(width: 70, height: 70)
        
        if sessionManager.isRecording {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: 20, height: 20)
        } else {
            Circle()
                .fill(Color.red)
                .frame(width: 60, height: 60)
        }
    }
}
```

### 녹화 시간 표시

```swift
Text(formatTime(sessionManager.recordingDuration))
    .font(.system(size: 20, weight: .bold))
    .foregroundColor(.white)
    .padding(8)
    .background(Color.black.opacity(0.6))
    .cornerRadius(8)
```

---

## ⚠️ 주의사항

### 1. 실제 기기 필수

시뮬레이터에서는 카메라와 마이크를 사용할 수 없습니다. 반드시 실제 기기에서 테스트하세요.

### 2. 권한 처리

권한이 거부된 경우 사용자에게 설정 앱으로 이동하도록 안내해야 합니다.

### 3. 녹화 중 세션 변경 금지

녹화 중에는 세션 설정을 변경하면 안 됩니다.

### 4. 메모리 관리

동영상 파일은 크기가 클 수 있으므로 적절한 파일 크기 제한을 설정하세요.

---

## 📚 다음 단계

구현을 완료했다면:

1. **성능 최적화**: `PERFORMANCE_GUIDE.md` 참고
2. **에러 처리**: 다양한 에러 시나리오 처리
3. **UI 개선**: 녹화 인디케이터, 진행바 등 추가
4. **기능 확장**: 필터 적용, 편집 기능 등

---

**Happy Coding! 🎥**

