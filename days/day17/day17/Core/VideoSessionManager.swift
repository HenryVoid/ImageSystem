//
//  VideoSessionManager.swift
//  day17
//
//  AVCaptureSession 관리 (비디오 + 오디오)
//

import AVFoundation
import UIKit
import Combine

/// 동영상 녹화 세션을 관리하는 클래스
class VideoSessionManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "video.session.queue")
    
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var error: VideoError?
    @Published var recordedVideoURL: URL?
    
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    var movieOutput: AVCaptureMovieFileOutput?
    
    var currentCameraPosition: AVCaptureDevice.Position = .back
    
    private var recordingTimer: Timer?
    
    override init() {
        super.init()
        setupSession()
    }
    
    // MARK: - Session Setup
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // 카메라 장치 선택
            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: self.currentCameraPosition
            ) else {
                DispatchQueue.main.async {
                    self.error = .noCameraAvailable
                }
                self.session.commitConfiguration()
                return
            }
            
            // 비디오 입력 추가
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.videoInput = input
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .inputSetupFailed(error)
                }
                self.session.commitConfiguration()
                return
            }
            
            // 마이크 장치 선택
            guard let microphone = AVCaptureDevice.default(
                .builtInMicrophone,
                for: .audio,
                position: .unspecified
            ) else {
                DispatchQueue.main.async {
                    self.error = .noMicrophoneAvailable
                }
                self.session.commitConfiguration()
                return
            }
            
            // 오디오 입력 추가
            do {
                let audioInput = try AVCaptureDeviceInput(device: microphone)
                if self.session.canAddInput(audioInput) {
                    self.session.addInput(audioInput)
                    self.audioInput = audioInput
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .audioInputSetupFailed(error)
                }
                self.session.commitConfiguration()
                return
            }
            
            // 동영상 출력 추가
            let movieOutput = AVCaptureMovieFileOutput()
            if self.session.canAddOutput(movieOutput) {
                self.session.addOutput(movieOutput)
                self.movieOutput = movieOutput
                
                // 최대 녹화 시간 설정 (60초)
                movieOutput.maxRecordedDuration = CMTime(seconds: 60, preferredTimescale: 600)
                
                // 최대 파일 크기 설정 (100MB)
                movieOutput.maxRecordedFileSize = 100 * 1024 * 1024
            }
            
            self.session.commitConfiguration()
        }
    }
    
    // MARK: - Session Control
    
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
                // 녹화 중이면 먼저 중지
                if self.isRecording {
                    self.stopRecording()
                }
                
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    // MARK: - Camera Switching
    
    func switchCamera() {
        // 녹화 중이면 전환 불가
        guard !isRecording else {
            error = .cannotSwitchWhileRecording
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // 기존 비디오 입력 제거
            if let currentInput = self.videoInput {
                self.session.removeInput(currentInput)
            }
            
            // 카메라 위치 전환
            self.currentCameraPosition = self.currentCameraPosition == .back ? .front : .back
            
            // 새 카메라 선택
            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: self.currentCameraPosition
            ) else {
                DispatchQueue.main.async {
                    self.error = .noCameraAvailable
                }
                self.session.commitConfiguration()
                return
            }
            
            // 새 입력 추가
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.videoInput = input
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .inputSetupFailed(error)
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    // MARK: - Recording
    
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
    
    func startRecording() {
        guard let movieOutput = movieOutput,
              !movieOutput.isRecording else {
            error = .alreadyRecording
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let videoURL = self.getVideoURL()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingDuration = 0
            }
            
            // 녹화 시간 추적 타이머 시작
            DispatchQueue.main.async {
                self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self,
                          let movieOutput = self.movieOutput,
                          movieOutput.isRecording else {
                        return
                    }
                    
                    let duration = movieOutput.recordedDuration.seconds
                    self.recordingDuration = duration
                }
            }
            
            movieOutput.startRecording(to: videoURL, recordingDelegate: self)
        }
    }
    
    func stopRecording() {
        guard let movieOutput = movieOutput,
              movieOutput.isRecording else {
            return
        }
        
        sessionQueue.async { [weak self] in
            movieOutput.stopRecording()
            
            DispatchQueue.main.async {
                self?.isRecording = false
                self?.recordingTimer?.invalidate()
                self?.recordingTimer = nil
            }
        }
    }
    
    deinit {
        stopRecording()
        stopSession()
    }
}

// MARK: - AVCaptureMovieFileOutputDelegate

extension VideoSessionManager: AVCaptureMovieFileOutputDelegate {
    func fileOutput(
        _ output: AVCaptureMovieFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isRecording = false
            self.recordingTimer?.invalidate()
            self.recordingTimer = nil
            self.recordingDuration = 0
            
            if let error = error {
                // 녹화 오류
                let nsError = error as NSError
                if nsError.domain == AVFoundationErrorDomain,
                   nsError.code == AVError.Code.recordingAlreadyInProgress.rawValue {
                    self.error = .alreadyRecording
                } else {
                    self.error = .recordingFailed(error)
                }
            } else {
                // 녹화 완료
                self.recordedVideoURL = outputFileURL
            }
        }
    }
}

// MARK: - VideoError

enum VideoError: LocalizedError {
    case noCameraAvailable
    case noMicrophoneAvailable
    case permissionDenied
    case inputSetupFailed(Error)
    case audioInputSetupFailed(Error)
    case noMovieOutput
    case alreadyRecording
    case cannotSwitchWhileRecording
    case recordingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "카메라를 사용할 수 없습니다."
        case .noMicrophoneAvailable:
            return "마이크를 사용할 수 없습니다."
        case .permissionDenied:
            return "카메라 또는 마이크 권한이 거부되었습니다."
        case .inputSetupFailed(let error):
            return "카메라 입력 설정 실패: \(error.localizedDescription)"
        case .audioInputSetupFailed(let error):
            return "마이크 입력 설정 실패: \(error.localizedDescription)"
        case .noMovieOutput:
            return "동영상 출력을 사용할 수 없습니다."
        case .alreadyRecording:
            return "이미 녹화 중입니다."
        case .cannotSwitchWhileRecording:
            return "녹화 중에는 카메라를 전환할 수 없습니다."
        case .recordingFailed(let error):
            return "녹화 실패: \(error.localizedDescription)"
        }
    }
}

