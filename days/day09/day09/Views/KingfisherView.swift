//
//  KingfisherView.swift
//  day09
//
//  Kingfisher 데모 및 성능 측정
//

import SwiftUI
import Kingfisher

struct KingfisherView: View {
    @State private var currentMetrics: PerformanceMetrics?
    @State private var isLoading = false
    @State private var diskCacheSize: UInt64 = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Kingfisher")
                    .font(.largeTitle)
                    .bold()
                
                // 테스트 이미지 그리드 (KFImage 사용)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        KFImage(URL(string: "https://picsum.photos/400/400?random=\(index + 100)"))
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
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
                        .background(Color.green)
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
        
        KingfisherLoader.shared.loadImage(from: url) { image, metrics in
            currentMetrics = metrics
            isLoading = false
            updateCacheSize()
        }
    }
    
    private func clearCache() {
        KingfisherLoader.shared.clearCache()
        currentMetrics = nil
        updateCacheSize()
    }
    
    private func updateCacheSize() {
        KingfisherLoader.shared.getDiskCacheSize { size in
            diskCacheSize = size
        }
    }
}

