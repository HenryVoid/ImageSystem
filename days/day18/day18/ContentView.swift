//
//  ContentView.swift
//  day18
//
//  AVAsset 썸네일 생성 학습 - 메인 네비게이션
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                // 헤더
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AVAsset 썸네일 생성")
                            .font(.title)
                            .bold()
                        
                        Text("동영상에서 특정 타임의 이미지를 추출해 썸네일을 자동 생성하는 기능을 학습합니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 기본 학습
                Section(header: Text("📚 기본 학습")) {
                    NavigationLink(destination: SimpleThumbnailView()) {
                        MenuRow(
                            icon: "photo.badge.plus",
                            iconColor: .blue,
                            title: "기본 썸네일 생성",
                            description: "동영상에서 특정 시간의 썸네일 추출"
                        )
                    }
                    
                    NavigationLink(destination: BatchThumbnailView()) {
                        MenuRow(
                            icon: "photo.on.rectangle",
                            iconColor: .green,
                            title: "배치 썸네일 생성",
                            description: "여러 타임라인에서 썸네일 한 번에 생성"
                        )
                    }
                    
                    NavigationLink(destination: ThumbnailGalleryView()) {
                        MenuRow(
                            icon: "photo.on.rectangle.angled",
                            iconColor: .purple,
                            title: "썸네일 갤러리",
                            description: "캐싱을 활용한 썸네일 갤러리"
                        )
                    }
                }
                
                // 학습 가이드
                Section(header: Text("📖 학습 가이드")) {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/avfoundation/avassetimagegenerator")!) {
                        MenuRow(
                            icon: "book.fill",
                            iconColor: .indigo,
                            title: "Apple 공식 문서",
                            description: "AVAssetImageGenerator Reference"
                        )
                    }
                }
            }
            .navigationTitle("Day 18")
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
