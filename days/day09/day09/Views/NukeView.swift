//
//  NukeView.swift
//  day09
//
//  Nuke 데모 및 성능 측정
//

import SwiftUI
import Nuke
import NukeUI

struct NukeView: View {
    @State private var currentMetrics: PerformanceMetrics?
    @State private var isLoading = false
    @State private var diskCacheSize: UInt64 = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Nuke")
                    .font(.largeTitle)
                    .bold()
                
                // 테스트 이미지 그리드 (LazyImage 사용)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        LazyImage(url: URL(string: "https://picsum.photos/400/400?random=\(index + 200)")) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                ProgressView()
                            }
                        }
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
                        .background(Color.purple)
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
        
        NukeLoader.shared.loadImage(from: url) { image, metrics in
            currentMetrics = metrics
            isLoading = false
            updateCacheSize()
        }
    }
    
    private func clearCache() {
        NukeLoader.shared.clearCache()
        currentMetrics = nil
        updateCacheSize()
    }
    
    private func updateCacheSize() {
        NukeLoader.shared.getDiskCacheSize { size in
            diskCacheSize = size
        }
    }
}

