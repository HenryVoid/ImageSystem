//
//  SimpleVideoView.swift
//  day17
//
//  기본 비디오 미리보기 뷰
//

import SwiftUI

struct SimpleVideoView: View {
    @StateObject private var sessionManager = VideoSessionManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if permissionManager.isAllAuthorized {
                VideoPreview(session: sessionManager.session)
                    .ignoresSafeArea()
                    .onAppear {
                        sessionManager.startSession()
                    }
                    .onDisappear {
                        sessionManager.stopSession()
                    }
            } else if permissionManager.isAnyDenied {
                PermissionDeniedView(permissionManager: permissionManager)
            } else {
                PermissionRequestView(permissionManager: permissionManager)
            }
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            if let error = sessionManager.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: sessionManager.error) { _, newError in
            if newError != nil {
                showError = true
            }
        }
    }
}

// MARK: - Permission Views

struct PermissionRequestView: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "video.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("카메라 및 마이크 권한 필요")
                .font(.title)
                .bold()
            
            Text("동영상을 녹화하기 위해\n카메라와 마이크 접근 권한이 필요합니다.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("카메라: \(permissionManager.cameraStatusString)")
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "mic.fill")
                    Text("마이크: \(permissionManager.microphoneStatusString)")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            Button(action: {
                Task {
                    await permissionManager.requestAllPermissions()
                }
            }) {
                Text("권한 요청")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
    }
}

struct PermissionDeniedView: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("권한 거부됨")
                .font(.title)
                .bold()
            
            VStack(alignment: .leading, spacing: 12) {
                if permissionManager.isCameraDenied {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("카메라 권한이 거부되었습니다.")
                            .font(.subheadline)
                    }
                }
                
                if permissionManager.isMicrophoneDenied {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("마이크 권한이 거부되었습니다.")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            Text("설정 앱에서 권한을 허용해주세요.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                permissionManager.openSettings()
            }) {
                Text("설정으로 이동")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
    }
}

#Preview {
    SimpleVideoView()
}

