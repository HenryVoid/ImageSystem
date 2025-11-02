//
//  SDWebImageView.swift
//  day09
//
//  SDWebImage 데모 및 성능 측정
//

import SwiftUI
import SDWebImage

struct SDWebImageView: View {
    @State private var testURLs: [URL] = []
    @State private var currentMetrics: PerformanceMetrics?
    @State private var isLoading = false
    @State private var diskCacheSize: UInt64 = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("SDWebImage")
                    .font(.largeTitle)
                    .bold()
                
                // 테스트 이미지 그리드
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        AsyncSDWebImageView(
                            url: URL(string: "https://picsum.photos/400/400?random=\(index)")!
                        )
                        .frame(height: 150)
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                // 성능 메트릭
                if let metrics = currentMetrics {
                    MetricsCard(metrics: metrics)
                }
                
                // 제어 버튼
                VStack(spacing: 12) {
                    Button(action: loadTestImages) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isLoading ? "로딩 중..." : "이미지 로드")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: clearCache) {
                        Text("캐시 초기화")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                // 캐시 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text("캐시 정보")
                        .font(.headline)
                    Text("디스크 캐시: \(DiskCacheMonitor.shared.formatBytes(diskCacheSize))")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
        }
        .onAppear {
            updateCacheSize()
        }
    }
    
    private func loadTestImages() {
        isLoading = true
        
        let url = URL(string: "https://picsum.photos/800/600?random=\(Int.random(in: 1...1000))")!
        
        SDWebImageLoader.shared.loadImage(from: url) { image, metrics in
            currentMetrics = metrics
            isLoading = false
            updateCacheSize()
        }
    }
    
    private func clearCache() {
        SDWebImageLoader.shared.clearCache()
        currentMetrics = nil
        updateCacheSize()
    }
    
    private func updateCacheSize() {
        SDWebImageLoader.shared.getDiskCacheSize { size in
            diskCacheSize = size
        }
    }
}

// MARK: - AsyncSDWebImageView

struct AsyncSDWebImageView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        SDWebImageLoader.shared.loadImage(from: url) { loadedImage, _ in
            image = loadedImage
            isLoading = false
        }
    }
}

// MARK: - 메트릭 카드

struct MetricsCard: View {
    let metrics: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("성능 메트릭")
                .font(.headline)
            
            HStack {
                Label("로딩 시간", systemImage: "clock")
                Spacer()
                Text(String(format: "%.1fms", metrics.loadingTimeInMs))
            }
            
            HStack {
                Label("메모리", systemImage: "memorychip")
                Spacer()
                Text(String(format: "%.2fMB", metrics.memoryInMB))
            }
            
            HStack {
                Label("캐시", systemImage: "square.stack")
                Spacer()
                Text(metrics.cacheTypeString)
                    .foregroundColor(metrics.cacheHit ? .green : .orange)
            }
            
            HStack {
                Label("파일 크기", systemImage: "doc")
                Spacer()
                Text(String(format: "%.1fKB", metrics.fileSizeInKB))
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
}

