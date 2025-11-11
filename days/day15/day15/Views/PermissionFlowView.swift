//
//  PermissionFlowView.swift
//  day15
//
//  권한 흐름 테스트 UI
//

import SwiftUI
import Photos

struct PermissionFlowView: View {
    @StateObject private var permissionManager = PermissionManager()
    @State private var showingSettingsAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 현재 상태 표시
                VStack(spacing: 16) {
                    Text("현재 권한 상태")
                        .font(.title2)
                        .bold()
                    
                    StatusCard(status: permissionManager.authorizationStatus)
                }
                
                Divider()
                
                // 권한 흐름 설명
                VStack(alignment: .leading, spacing: 12) {
                    Text("권한 흐름")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FlowStep(
                            status: .notDetermined,
                            title: "1. 아직 요청하지 않음",
                            description: "앱을 처음 실행했을 때의 상태"
                        )
                        
                        FlowStep(
                            status: .limited,
                            title: "2. 제한적 접근 허용 (iOS 14+)",
                            description: "사용자가 선택한 사진만 접근 가능"
                        )
                        
                        FlowStep(
                            status: .authorized,
                            title: "3. 전체 접근 허용",
                            description: "모든 사진에 접근 가능"
                        )
                        
                        FlowStep(
                            status: .denied,
                            title: "4. 거부됨",
                            description: "접근 불가, 설정에서 변경 필요"
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 액션 버튼
                VStack(spacing: 12) {
                    if permissionManager.authorizationStatus == .notDetermined {
                        Button("권한 요청하기") {
                            Task {
                                await permissionManager.requestPermission()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    
                    if permissionManager.authorizationStatus == .limited {
                        VStack(spacing: 12) {
                            Text("제한적 접근 상태입니다")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("더 많은 사진 선택") {
                                // iOS 14+ 시스템 UI 표시
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootViewController = windowScene.windows.first?.rootViewController {
                                    PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: rootViewController)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    if permissionManager.authorizationStatus == .denied {
                        Button("설정으로 이동") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    
                    if permissionManager.isAuthorized {
                        Button("권한 상태 새로고침") {
                            // 권한 변경 감지는 자동으로 됨
                            // 수동 새로고침은 필요 없지만 예제로 제공
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // 정보 카드
                InfoCard(
                    icon: "info.circle.fill",
                    title: "권한 변경 감지",
                    description: "권한 상태가 변경되면 자동으로 UI가 업데이트됩니다."
                )
            }
            .padding()
        }
        .navigationTitle("권한 흐름 테스트")
        .alert("설정으로 이동하시겠습니까?", isPresented: $showingSettingsAlert) {
            Button("이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let status: PHAuthorizationStatus
    
    var statusInfo: (color: Color, icon: String, title: String, description: String) {
        switch status {
        case .notDetermined:
            return (.gray, "questionmark.circle.fill", "아직 요청하지 않음", "권한을 요청해주세요")
        case .restricted:
            return (.orange, "exclamationmark.triangle.fill", "제한됨", "부모 제어 등으로 제한됨")
        case .denied:
            return (.red, "xmark.circle.fill", "거부됨", "설정에서 권한을 허용해주세요")
        case .authorized:
            return (.green, "checkmark.circle.fill", "전체 접근 허용", "모든 사진에 접근 가능")
        case .limited:
            return (.blue, "checkmark.circle.fill", "제한적 접근 허용", "선택한 사진만 접근 가능")
        @unknown default:
            return (.gray, "questionmark.circle.fill", "알 수 없음", "")
        }
    }
    
    var body: some View {
        let info = statusInfo
        
        HStack(spacing: 16) {
            Image(systemName: info.icon)
                .font(.system(size: 40))
                .foregroundColor(info.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(info.title)
                    .font(.headline)
                
                Text(info.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(info.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(info.color.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Flow Step

struct FlowStep: View {
    let status: PHAuthorizationStatus
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var statusColor: Color {
        switch status {
        case .notDetermined: return .gray
        case .limited: return .blue
        case .authorized: return .green
        case .denied: return .red
        case .restricted: return .orange
        @unknown default: return .gray
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        PermissionFlowView()
    }
}
