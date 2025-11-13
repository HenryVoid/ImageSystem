//
//  SimpleCameraView.swift
//  day16
//
//  기본 카메라 미리보기 뷰
//

import SwiftUI

struct SimpleCameraView: View {
    @StateObject private var sessionManager = CameraSessionManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if permissionManager.isAuthorized {
                CameraPreview(session: sessionManager.session)
                    .ignoresSafeArea()
                    .onAppear {
                        sessionManager.startSession()
                    }
                    .onDisappear {
                        sessionManager.stopSession()
                    }
            } else if permissionManager.isDenied {
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
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("카메라 권한 필요")
                .font(.title)
                .bold()
            
            Text("사진을 촬영하기 위해\n카메라 접근 권한이 필요합니다.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await permissionManager.requestPermission()
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
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("카메라 권한 거부됨")
                .font(.title)
                .bold()
            
            Text("설정 앱에서 카메라 권한을\n허용해주세요.")
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
    SimpleCameraView()
}

