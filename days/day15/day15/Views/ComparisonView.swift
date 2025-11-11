//
//  ComparisonView.swift
//  day15
//
//  PhotosPicker vs UIImagePickerController 비교
//

import SwiftUI
import PhotosUI
import UIKit

struct ComparisonView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 탭 선택
            Picker("방식 선택", selection: $selectedTab) {
                Text("PhotosPicker").tag(0)
                Text("UIImagePicker").tag(1)
                Text("비교").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 컨텐츠
            TabView(selection: $selectedTab) {
                PhotosPickerExample()
                    .tag(0)
                
                UIImagePickerExample()
                    .tag(1)
                
                ComparisonTable()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("비교")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - PhotosPicker Example

struct PhotosPickerExample: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PhotosPicker (SwiftUI)")
                        .font(.title2)
                        .bold()
                    
                    Text("iOS 16+ SwiftUI 네이티브 방식")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Label("사진 선택", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImage = UIImage(data: data)
                        }
                    }
                }
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("장점")
                        .font(.headline)
                    
                    FeatureList(features: [
                        "간단한 API",
                        "SwiftUI 네이티브 통합",
                        "권한 자동 처리",
                        "최신 iOS 방식"
                    ], color: .green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - UIImagePicker Example

struct UIImagePickerExample: View {
    @State private var selectedImage: UIImage?
    @State private var showingPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UIImagePickerController (UIKit)")
                        .font(.title2)
                        .bold()
                    
                    Text("전통적인 UIKit 방식")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                Button {
                    showingPicker = true
                } label: {
                    Label("사진 선택", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("장점")
                        .font(.headline)
                    
                    FeatureList(features: [
                        "iOS 2.0+ 지원",
                        "카메라 직접 촬영 가능",
                        "완전한 커스터마이징"
                    ], color: .orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .sheet(isPresented: $showingPicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

// MARK: - UIImagePicker Wrapper

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Comparison Table

struct ComparisonTable: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("비교표")
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                VStack(spacing: 16) {
                    ComparisonRow(
                        feature: "최소 iOS 버전",
                        photosPicker: "iOS 16+",
                        uiImagePicker: "iOS 2.0+"
                    )
                    
                    ComparisonRow(
                        feature: "SwiftUI 통합",
                        photosPicker: "✅ 네이티브",
                        uiImagePicker: "❌ UIViewControllerRepresentable 필요"
                    )
                    
                    ComparisonRow(
                        feature: "권한 처리",
                        photosPicker: "✅ 자동",
                        uiImagePicker: "⚠️ 수동 처리 필요"
                    )
                    
                    ComparisonRow(
                        feature: "카메라 촬영",
                        photosPicker: "❌ 불가",
                        uiImagePicker: "✅ 가능"
                    )
                    
                    ComparisonRow(
                        feature: "다중 선택",
                        photosPicker: "✅ 가능",
                        uiImagePicker: "❌ 단일 선택만"
                    )
                    
                    ComparisonRow(
                        feature: "커스터마이징",
                        photosPicker: "⚠️ 제한적",
                        uiImagePicker: "✅ 완전한 제어"
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("권장 사용")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        RecommendationRow(
                            title: "PhotosPicker 사용",
                            description: "iOS 16+ 타겟, SwiftUI 프로젝트, 간단한 이미지 선택"
                        )
                        
                        RecommendationRow(
                            title: "UIImagePicker 사용",
                            description: "하위 버전 지원 필요, 카메라 촬영 필요, 커스텀 UI 필요"
                        )
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let feature: String
    let photosPicker: String
    let uiImagePicker: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feature)
                .font(.subheadline)
                .bold()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PhotosPicker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(photosPicker)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("UIImagePicker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(uiImagePicker)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Feature List

struct FeatureList: View {
    let features: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .font(.caption)
                    Text(feature)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .bold()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        ComparisonView()
    }
}
