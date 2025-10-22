//
//  ContentView.swift
//  day04
//
//  Image I/O EXIF 학습 - 메인 네비게이션
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                // 헤더
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image I/O로 EXIF 읽기")
                            .font(.title)
                            .bold()
                        
                        Text("이미지 메타데이터를 효율적으로 읽고 활용하는 방법을 학습합니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 기본 학습
                Section(header: Text("📚 기본 학습")) {
                    NavigationLink(destination: BasicEXIFView()) {
                        MenuRow(
                            icon: "doc.text.magnifyingglass",
                            iconColor: .blue,
                            title: "기본 EXIF 정보",
                            description: "이미지에서 기본적인 EXIF 메타데이터 읽기"
                        )
                    }
                    
                    NavigationLink(destination: DetailedEXIFView()) {
                        MenuRow(
                            icon: "list.bullet.rectangle",
                            iconColor: .purple,
                            title: "상세 EXIF 정보",
                            description: "섹션별 상세 메타데이터 탐색"
                        )
                    }
                }
                
                // 실전 응용
                Section(header: Text("🚀 실전 응용")) {
                    NavigationLink(destination: PhotoLibraryView()) {
                        MenuRow(
                            icon: "photo.on.rectangle.angled",
                            iconColor: .green,
                            title: "사진 라이브러리",
                            description: "기기의 사진에서 EXIF 데이터 추출"
                        )
                    }
                    
                    NavigationLink(destination: GPSLocationView()) {
                        MenuRow(
                            icon: "location.fill",
                            iconColor: .red,
                            title: "GPS 위치 정보",
                            description: "GPS 태그를 지도에 표시하기"
                        )
                    }
                }
                
                // 성능 & 실험
                Section(header: Text("⚡ 성능 & 실험")) {
                    NavigationLink(destination: BenchmarkView()) {
                        MenuRow(
                            icon: "speedometer",
                            iconColor: .orange,
                            title: "성능 벤치마크",
                            description: "Image I/O vs UIImage 성능 비교"
                        )
                    }
                }
                
                // 학습 가이드
                Section(header: Text("📖 학습 가이드")) {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/imageio")!) {
                        MenuRow(
                            icon: "book.fill",
                            iconColor: .indigo,
                            title: "Apple 공식 문서",
                            description: "Image I/O Framework Reference"
                        )
                    }
                }
            }
            .navigationTitle("Day 4")
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
