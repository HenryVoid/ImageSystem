//
//  RecordingView.swift
//  day17
//
//  동영상 녹화 기능 뷰
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var sessionManager = VideoSessionManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if permissionManager.isAllAuthorized {
                VideoPreview(session: sessionManager.session)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // 녹화 시간 표시
                    if sessionManager.isRecording {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .opacity(0.8)
                            
                            Text(formatTime(sessionManager.recordingDuration))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.top, 20)
                    }
                    
                    // 컨트롤 버튼들
                    HStack(spacing: 40) {
                        // 카메라 전환 버튼
                        Button(action: {
                            sessionManager.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .disabled(sessionManager.isRecording)
                        
                        // 녹화 버튼
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
                        
                        // 플레이스홀더 (균형을 위한 빈 버튼)
                        Color.clear
                            .frame(width: 60, height: 60)
                    }
                    .padding(.bottom, 40)
                }
            } else if permissionManager.isAnyDenied {
                PermissionDeniedView(permissionManager: permissionManager)
            } else {
                PermissionRequestView(permissionManager: permissionManager)
            }
        }
        .onAppear {
            sessionManager.startSession()
        }
        .onDisappear {
            sessionManager.stopSession()
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
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RecordingView()
}

