//
//  ContentView.swift
//  day17
//
//  AVFoundation 동영상 녹화 학습 - 메인 네비게이션
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                // 헤더
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AVFoundation 동영상 녹화")
                            .font(.title)
                            .bold()
                        
                        Text("카메라 + 마이크 권한 → 세션 구성 → 녹화 → 저장 → 재생을 학습합니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 기본 학습
                Section(header: Text("📚 기본 학습")) {
                    NavigationLink(destination: SimpleVideoView()) {
                        MenuRow(
                            icon: "video.fill",
                            iconColor: .blue,
                            title: "기본 비디오 미리보기",
                            description: "카메라 + 마이크 권한 요청 및 미리보기 표시"
                        )
                    }
                    
                    NavigationLink(destination: RecordingView()) {
                        MenuRow(
                            icon: "record.circle.fill",
                            iconColor: .red,
                            title: "동영상 녹화",
                            description: "녹화 시작/중지 및 카메라 전환"
                        )
                    }
                    
                    NavigationLink(destination: PlaybackView()) {
                        MenuRow(
                            icon: "play.rectangle.fill",
                            iconColor: .green,
                            title: "동영상 재생",
                            description: "저장된 동영상 목록 및 재생"
                        )
                    }
                }
                
                // 실전 응용
                Section(header: Text("🚀 실전 응용")) {
                    NavigationLink(destination: VideoFlowView()) {
                        MenuRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .purple,
                            title: "전체 플로우",
                            description: "권한 → 세션 → 녹화 → 재생 통합 + 성능 모니터"
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
            .navigationTitle("Day 17")
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
