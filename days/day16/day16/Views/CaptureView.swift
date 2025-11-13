//
//  CaptureView.swift
//  day16
//
//  사진 캡처 기능이 있는 카메라 뷰
//

import SwiftUI

struct CaptureView: View {
    @StateObject private var sessionManager = CameraSessionManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var showCapturedImage = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if permissionManager.isAuthorized {
                CameraPreview(session: sessionManager.session)
                    .ignoresSafeArea()
                
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
            if permissionManager.isAuthorized {
                sessionManager.startSession()
            }
        }
        .onDisappear {
            sessionManager.stopSession()
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

// MARK: - Captured Image View

struct CapturedImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                HStack(spacing: 20) {
                    Button(action: {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        dismiss()
                    }) {
                        Label("저장", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Label("공유", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("촬영한 사진")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [image])
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 업데이트 불필요
    }
}

#Preview {
    CaptureView()
}

