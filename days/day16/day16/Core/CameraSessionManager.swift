//
//  CameraSessionManager.swift
//  day16
//
//  AVCaptureSession 관리
//

import AVFoundation
import UIKit
import Combine

/// 카메라 세션을 관리하는 클래스
class CameraSessionManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    @Published var isSessionRunning = false
    @Published var error: CameraError?
    @Published var capturedImage: UIImage?
    
    private var videoInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    
    var currentCameraPosition: AVCaptureDevice.Position = .back
    
    override init() {
        super.init()
        setupSession()
    }
    
    // MARK: - Session Setup
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
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
            
            // 입력 추가
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
            
            // 출력 추가
            let photoOutput = AVCapturePhotoOutput()
            if self.session.canAddOutput(photoOutput) {
                self.session.addOutput(photoOutput)
                self.photoOutput = photoOutput
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
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    // MARK: - Camera Switching
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // 기존 입력 제거
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
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else {
            error = .noPhotoOutput
            return
        }
        
        // HEIF 포맷 지원 확인
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        sessionQueue.async {
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    deinit {
        stopSession()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = .captureFailed(error)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.error = .imageProcessingFailed
            }
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

// MARK: - CameraError

enum CameraError: LocalizedError {
    case noCameraAvailable
    case permissionDenied
    case inputSetupFailed(Error)
    case noPhotoOutput
    case captureFailed(Error)
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "카메라를 사용할 수 없습니다."
        case .permissionDenied:
            return "카메라 권한이 거부되었습니다."
        case .inputSetupFailed(let error):
            return "카메라 입력 설정 실패: \(error.localizedDescription)"
        case .noPhotoOutput:
            return "사진 출력을 사용할 수 없습니다."
        case .captureFailed(let error):
            return "사진 촬영 실패: \(error.localizedDescription)"
        case .imageProcessingFailed:
            return "이미지 처리에 실패했습니다."
        }
    }
}

