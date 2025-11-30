//
//  ContentView.swift
//  day23
//
//  Created by 송형욱 on 11/30/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var classifier = ImageClassifier()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. 이미지 표시 영역
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    ContentUnavailableView(
                        "이미지를 선택해주세요",
                        systemImage: "photo.on.rectangle",
                        description: Text("분류할 사진을 앨범에서 골라보세요.")
                    )
                    .frame(height: 300)
                }
                
                // 2. 분류 결과 표시 영역
                VStack(alignment: .leading, spacing: 10) {
                    Text("분류 결과")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    if !classifier.results.isEmpty {
                        ForEach(classifier.results) { result in
                            HStack {
                                Text(result.identifier)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(result.formattedConfidence)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    } else if let errorMessage = classifier.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("결과가 여기에 표시됩니다.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // 3. 이미지 선택 버튼
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("사진 선택하기", systemImage: "photo.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("CoreML 이미지 분류")
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        // 이미지가 변경되면 바로 분류 시작
                        classifier.classify(image: uiImage)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
