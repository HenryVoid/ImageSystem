//
//  ContentView.swift
//  day16
//
//  AVFoundation 카메라 세션 학습 - 메인 네비게이션
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                // 헤더
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AVFoundation 카메라 세션")
                            .font(.title)
                            .bold()
                        
                        Text("권한 요청 → 세션 구성 → 미리보기 → 사진 캡처를 학습합니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 기본 학습
                Section(header: Text("📚 기본 학습")) {
                    NavigationLink(destination: SimpleCameraView()) {
                        MenuRow(
                            icon: "camera.fill",
                            iconColor: .blue,
                            title: "기본 카메라 미리보기",
                            description: "카메라 권한 요청 및 미리보기 표시"
                        )
                    }
                    
                    NavigationLink(destination: CaptureView()) {
                        MenuRow(
                            icon: "camera.shutter.button",
                            iconColor: .green,
                            title: "사진 캡처",
                            description: "사진 촬영 및 저장 기능"
                        )
                    }
                }
                
                // 실전 응용
                Section(header: Text("🚀 실전 응용")) {
                    NavigationLink(destination: CameraFlowView()) {
                        MenuRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .purple,
                            title: "전체 플로우",
                            description: "권한 → 세션 → 미리보기 → 캡처 통합"
                        )
                    }
                }
                
                // 학습 가이드
                Section(header: Text("📖 학습 가이드")) {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/avfoundation")!) {
                        MenuRow(
                            icon: "book.fill",
                            iconColor: .indigo,
                            title: "Apple 공식 문서",
                            description: "AVFoundation Framework Reference"
                        )
                    }
                }
            }
            .navigationTitle("Day 16")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Components

struct MenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
