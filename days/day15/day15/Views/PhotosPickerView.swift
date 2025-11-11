//
//  PhotosPickerView.swift
//  day15
//
//  SwiftUI PhotosPicker 기본 이미지 선택기
//

import SwiftUI
import PhotosUI

struct PhotosPickerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("📸 SwiftUI PhotosPicker")
                        .font(.title2)
                        .bold()
                    
                    Text("iOS 16+ SwiftUI 네이티브 이미지 선택기입니다. 간단한 API로 사진을 선택할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // 단일 선택
                VStack(spacing: 12) {
                    Text("단일 선택")
                        .font(.headline)
                    
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        Label("사진 선택하기", systemImage: "photo.on.rectangle.angled")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            await loadImage(from: newItem)
                        }
                    }
                }
                
                // 다중 선택 예제
                VStack(spacing: 12) {
                    Text("다중 선택 (예제)")
                        .font(.headline)
                    
                    Text("PhotosPicker는 selection을 [PhotosPickerItem] 배열로 설정하면 다중 선택이 가능합니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 로딩 인디케이터
                if isLoading {
                    ProgressView("이미지 로딩 중...")
                        .padding()
                }
                
                // 선택된 이미지 표시
                if let image = selectedImage {
                    VStack(spacing: 12) {
                        Text("선택된 이미지")
                            .font(.headline)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        
                        Text("크기: \(Int(image.size.width)) × \(Int(image.size.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("PhotosPicker")
    }
    
    // MARK: - Functions
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        } catch {
            print("❌ 이미지 로드 실패: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        PhotosPickerView()
    }
}
