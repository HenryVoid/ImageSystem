//
//  ImageSelectorView.swift
//  day13
//
//  Created on 11/10/25.
//

import SwiftUI

struct ImageSelectorView: View {
    @EnvironmentObject var imageLoader: ImageLoader
    @State private var selectedSize: ImageSize = .medium
    @State private var selectedSeed: Int = 42
    
    enum ImageSize: String, CaseIterable {
        case small = "작게 (500×500)"
        case medium = "중간 (1000×1000)"
        case large = "크게 (2000×2000)"
        
        var pixels: Int {
            switch self {
            case .small: return 500
            case .medium: return 1000
            case .large: return 2000
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 샘플 이미지 생성
                VStack(alignment: .leading, spacing: 15) {
                    Text("샘플 이미지 생성")
                        .font(.headline)
                    
                    Text("테스트용 그라데이션 이미지를 생성합니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 크기 선택
                    VStack(alignment: .leading, spacing: 5) {
                        Text("이미지 크기")
                            .font(.subheadline)
                        Picker("크기", selection: $selectedSize) {
                            ForEach(ImageSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Button(action: generateSample) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("샘플 생성")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(imageLoader.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 온라인 이미지 다운로드
                VStack(alignment: .leading, spacing: 15) {
                    Text("온라인 이미지 다운로드")
                        .font(.headline)
                    
                    Text("Picsum Photos에서 랜덤 이미지를 다운로드합니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 크기 선택
                    VStack(alignment: .leading, spacing: 5) {
                        Text("이미지 크기")
                            .font(.subheadline)
                        Picker("크기", selection: $selectedSize) {
                            ForEach(ImageSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 시드 선택
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("시드 번호")
                                .font(.subheadline)
                            Spacer()
                            Text("\(selectedSeed)")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: Binding(
                            get: { Double(selectedSeed) },
                            set: { selectedSeed = Int($0) }
                        ), in: 1...1000, step: 1)
                    }
                    
                    Button(action: downloadImage) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("다운로드")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(imageLoader.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 현재 이미지 미리보기
                if let image = imageLoader.currentImage {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("현재 이미지")
                            .font(.headline)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                        
                        HStack {
                            Label("\(Int(image.size.width))×\(Int(image.size.height))", systemImage: "photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("이미지를 생성하거나 다운로드하세요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                }
                
                if imageLoader.isLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("로딩 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("이미지 선택")
    }
    
    private func generateSample() {
        let size = CGSize(width: selectedSize.pixels, height: selectedSize.pixels)
        imageLoader.generateSampleImage(size: size)
    }
    
    private func downloadImage() {
        imageLoader.downloadImage(
            width: selectedSize.pixels,
            height: selectedSize.pixels,
            seed: selectedSeed
        )
    }
}

