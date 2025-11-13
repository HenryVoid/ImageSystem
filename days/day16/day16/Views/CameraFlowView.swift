//
//  CameraFlowView.swift
//  day16
//
//  전체 카메라 플로우 통합 뷰 (권한 → 세션 → 미리보기 → 캡처)
//

import SwiftUI

struct CameraFlowView: View {
    @StateObject private var sessionManager = CameraSessionManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var performanceMonitor = PerformanceMonitor()
    @State private var showCapturedImage = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // 카메라 미리보기 또는 권한 화면
            if permissionManager.isAuthorized {
                CameraPreview(session: sessionManager.session)
                    .ignoresSafeArea()
                
                // 성능 모니터 오버레이
                VStack {
                    HStack {
                        Spacer()
                        PerformanceStatsView(monitor: performanceMonitor)
                            .padding()
                    }
                    Spacer()
                }
                
                // 컨트롤 버튼들
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // 카메라 전환 버튼
                        Button(action: {
                            sessionManager.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        // 캡처 버튼
                        Button(action: {
                            sessionManager.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .stroke(Color.black, lineWidth: 3)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        // 플레이스홀더 (정렬용)
                        Color.clear
                            .frame(width: 50, height: 50)
                    }
                    .padding(.bottom, 50)
                }
            } else if permissionManager.isDenied {
                PermissionDeniedView(permissionManager: permissionManager)
            } else {
                PermissionRequestView(permissionManager: permissionManager)
            }
        }
        .onAppear {
            // 권한 확인 후 세션 시작
            if permissionManager.isAuthorized {
                sessionManager.startSession()
                performanceMonitor.startMonitoring()
            }
        }
        .onDisappear {
            sessionManager.stopSession()
            performanceMonitor.stopMonitoring()
        }
        .onChange(of: permissionManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorized {
                sessionManager.startSession()
                performanceMonitor.startMonitoring()
            } else {
                sessionManager.stopSession()
                performanceMonitor.stopMonitoring()
            }
        }
        .sheet(isPresented: $showCapturedImage) {
            if let image = sessionManager.capturedImage {
                CapturedImageView(image: image)
            }
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            if let error = sessionManager.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: sessionManager.capturedImage) { _, newImage in
            if newImage != nil {
                showCapturedImage = true
            }
        }
        .onChange(of: sessionManager.error) { _, newError in
            if newError != nil {
                showError = true
            }
        }
    }
}

#Preview {
    CameraFlowView()
}

