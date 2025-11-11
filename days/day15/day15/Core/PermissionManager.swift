//
//  PermissionManager.swift
//  day15
//
//  사진 라이브러리 권한 관리
//

import Foundation
import Photos
import Combine

/// 권한 상태를 관리하는 ObservableObject
@MainActor
class PermissionManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus
    
    init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        registerForChanges()
    }
    
    /// 현재 권한 상태 확인
    static func currentStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    /// 권한 요청
    func requestPermission() async {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch currentStatus {
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            authorizationStatus = newStatus
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
            return "전체 접근 허용"
        case .limited:
            return "제한적 접근 허용"
        @unknown default:
            return "알 수 없음"
        }
    }
    
    /// 권한이 허용되었는지 확인 (limited 또는 authorized)
    var isAuthorized: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .limited
    }
    
    /// 전체 접근 권한인지 확인
    var isFullyAuthorized: Bool {
        return authorizationStatus == .authorized
    }
    
    /// 권한 변경 감지 등록
    private func registerForChanges() {
        PHPhotoLibrary.shared().register(self)
    }
    
    /// 권한 변경 감지 해제
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension PermissionManager: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            // 권한 상태 업데이트
            authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        }
    }
}
