//
//  PermissionManager.swift
//  day16
//
//  카메라 권한 관리
//

import Foundation
import AVFoundation
import Combine

/// 카메라 권한 상태를 관리하는 ObservableObject
@MainActor
class PermissionManager: ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus
    
    init() {
        self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        registerForChanges()
    }
    
    /// 현재 권한 상태 확인
    static func currentStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// 권한 요청
    func requestPermission() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch currentStatus {
        case .notDetermined:
            // 권한 요청
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = granted ? .authorized : .denied
        default:
            authorizationStatus = currentStatus
        }
    }
    
    /// 권한 상태 문자열
    var statusString: String {
        switch authorizationStatus {
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
    
    /// 권한이 허용되었는지 확인
    var isAuthorized: Bool {
        return authorizationStatus == .authorized
    }
    
    /// 권한이 거부되었는지 확인
    var isDenied: Bool {
        return authorizationStatus == .denied || authorizationStatus == .restricted
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
            self?.checkStatus()
        }
    }
    
    /// 권한 상태 재확인
    private func checkStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

