//
//  PermissionManager.swift
//  day17
//
//  카메라 + 마이크 권한 관리
//

import Foundation
import AVFoundation
import Combine

/// 카메라 및 마이크 권한 상태를 관리하는 ObservableObject
@MainActor
class PermissionManager: ObservableObject {
    @Published var cameraAuthorizationStatus: AVAuthorizationStatus
    @Published var microphoneAuthorizationStatus: AVAuthorizationStatus
    
    init() {
        self.cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        self.microphoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        registerForChanges()
    }
    
    /// 현재 카메라 권한 상태 확인
    static func currentCameraStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// 현재 마이크 권한 상태 확인
    static func currentMicrophoneStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    /// 카메라 권한 요청
    func requestCameraPermission() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch currentStatus {
        case .notDetermined:
            // 권한 요청
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorizationStatus = granted ? .authorized : .denied
        default:
            cameraAuthorizationStatus = currentStatus
        }
    }
    
    /// 마이크 권한 요청
    func requestMicrophonePermission() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch currentStatus {
        case .notDetermined:
            // 권한 요청
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            microphoneAuthorizationStatus = granted ? .authorized : .denied
        default:
            microphoneAuthorizationStatus = currentStatus
        }
    }
    
    /// 모든 권한 요청 (카메라 + 마이크)
    func requestAllPermissions() async {
        await requestCameraPermission()
        await requestMicrophonePermission()
    }
    
    /// 모든 권한 상태 확인
    func checkAllPermissions() {
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        microphoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    /// 카메라 권한 상태 문자열
    var cameraStatusString: String {
        switch cameraAuthorizationStatus {
        case .notDetermined:
            return "아직 요청하지 않음"
        case .restricted:
            return "제한됨"
        case .denied:
            return "거부됨"
        case .authorized:
            return "허용됨"
        @unknown default:
            return "알 수 없음"
        }
    }
    
    /// 마이크 권한 상태 문자열
    var microphoneStatusString: String {
        switch microphoneAuthorizationStatus {
        case .notDetermined:
            return "아직 요청하지 않음"
        case .restricted:
            return "제한됨"
        case .denied:
            return "거부됨"
        case .authorized:
            return "허용됨"
        @unknown default:
            return "알 수 없음"
        }
    }
    
    /// 카메라 권한이 허용되었는지 확인
    var isCameraAuthorized: Bool {
        return cameraAuthorizationStatus == .authorized
    }
    
    /// 마이크 권한이 허용되었는지 확인
    var isMicrophoneAuthorized: Bool {
        return microphoneAuthorizationStatus == .authorized
    }
    
    /// 모든 권한이 허용되었는지 확인
    var isAllAuthorized: Bool {
        return isCameraAuthorized && isMicrophoneAuthorized
    }
    
    /// 카메라 권한이 거부되었는지 확인
    var isCameraDenied: Bool {
        return cameraAuthorizationStatus == .denied || cameraAuthorizationStatus == .restricted
    }
    
    /// 마이크 권한이 거부되었는지 확인
    var isMicrophoneDenied: Bool {
        return microphoneAuthorizationStatus == .denied || microphoneAuthorizationStatus == .restricted
    }
    
    /// 권한이 거부되었는지 확인 (카메라 또는 마이크)
    var isAnyDenied: Bool {
        return isCameraDenied || isMicrophoneDenied
    }
    
    /// 설정 앱으로 이동하는 URL
    var settingsURL: URL? {
        return URL(string: UIApplication.openSettingsURLString)
    }
    
    /// 설정 앱 열기
    func openSettings() {
        guard let url = settingsURL else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// 권한 변경 감지 등록
    private func registerForChanges() {
        // 앱이 포그라운드로 돌아올 때 권한 상태 재확인
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkAllPermissions()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

