//
//  ContentView.swift
//  day15
//
//  PHPhotoLibrary 이미지 선택기 학습 - 메인 네비게이션
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                // 헤더
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PHPhotoLibrary 이미지 선택기")
                            .font(.title)
                            .bold()
                        
                        Text("사진 라이브러리 접근, 권한 관리, EXIF 메타데이터를 학습합니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 기본 학습
                Section(header: Text("📚 기본 학습")) {
                    NavigationLink(destination: PhotosPickerView()) {
                        MenuRow(
                            icon: "photo.on.rectangle.angled",
                            iconColor: .blue,
                            title: "PhotosPicker 기본",
                            description: "SwiftUI PhotosPicker로 이미지 선택하기"
                        )
                    }
                    
                    NavigationLink(destination: PHAssetGalleryView()) {
                        MenuRow(
                            icon: "square.grid.2x2",
                            iconColor: .green,
                            title: "PHAsset 갤러리",
                            description: "PHAsset으로 갤러리 그리드 구현"
                        )
                    }
                    
                    NavigationLink(destination: PermissionFlowView()) {
                        MenuRow(
                            icon: "lock.shield",
                            iconColor: .orange,
                            title: "권한 흐름 테스트",
                            description: "iOS 14+ 권한 시스템 이해"
                        )
                    }
                }
                
                // 실전 응용
                Section(header: Text("🚀 실전 응용")) {
                    NavigationLink(destination: MetadataView()) {
                        MenuRow(
                            icon: "doc.text.magnifyingglass",
                            iconColor: .purple,
                            title: "EXIF 메타데이터",
                            description: "선택한 이미지의 촬영 정보 확인"
                        )
                    }
                    
                    NavigationLink(destination: ComparisonView()) {
                        MenuRow(
                            icon: "arrow.left.arrow.right",
                            iconColor: .red,
                            title: "비교",
                            description: "PhotosPicker vs UIImagePicker"
                        )
                    }
                }
                
                // 학습 가이드
                Section(header: Text("📖 학습 가이드")) {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/photos")!) {
                        MenuRow(
                            icon: "book.fill",
                            iconColor: .indigo,
                            title: "Apple 공식 문서",
                            description: "Photos Framework Reference"
                        )
                    }
                }
            }
            .navigationTitle("Day 15")
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
