//
//  PrefetchListView.swift
//  day12
//
//  프리패칭을 적용한 이미지 리스트
//

import SwiftUI

struct PrefetchListView: View {
    @State private var imageCount = 100
    @State private var imageSize: ImageSize = .medium
    @State private var loadedCount = 0
    @State private var cacheStats = CacheStatistics()
    
    @StateObject private var performanceMonitor = PerformanceMonitor()
    @StateObject private var prefetchManager = PrefetchManager()
    
    let countOptions = [10, 100, 500, 1000]
    
    var body: some View {
        VStack(spacing: 0) {
            // 프리패치 통계 헤더
            prefetchStatsHeader
            
            // 캐시 통계
            cacheStatsHeader
            
            // 성능 정보
            performanceHeader
            
            // 컨트롤
            controls
            
            // 이미지 리스트
            imageList
        }
        .onAppear {
            performanceMonitor.startMonitoring()
            updateStats()
        }
        .onDisappear {
            performanceMonitor.stopMonitoring()
        }
    }
    
    // MARK: - Components
    
    private var prefetchStatsHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("프리패치됨")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(prefetchManager.prefetchedIndices.count)")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("진행 중")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(prefetchManager.inProgressCount)")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("활성화")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prefetchManager.isActive ? "ON" : "OFF")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(prefetchManager.isActive ? .green : .red)
                }
            }
            
            HStack {
                Toggle("프리패칭 활성화", isOn: Binding(
                    get: { prefetchManager.isActive },
                    set: { prefetchManager.setActive($0) }
                ))
                .font(.caption)
                
                Spacer()
                
                Button("리셋") {
                    prefetchManager.reset()
                    updateStats()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
    }
    
    private var cacheStatsHeader: some View {
        HStack {
            Text("캐시 히트율: \(cacheStats.formattedHitRate)")
                .font(.caption)
            
            Spacer()
            
            Text("캐시됨: \(cacheStats.cachedImagesCount)")
                .font(.caption)
        }
        .padding()
        .background(Color.green.opacity(0.05))
    }
    
    private var performanceHeader: some View {
        HStack {
            Text("FPS: \(String(format: "%.0f", performanceMonitor.metrics.fps))")
                .font(.system(.caption, design: .monospaced))
            
            Spacer()
            
            Text("메모리: \(performanceMonitor.metrics.formattedMemory)")
                .font(.system(.caption, design: .monospaced))
            
            Spacer()
            
            Text("로드됨: \(loadedCount)/\(imageCount)")
                .font(.system(.caption, design: .monospaced))
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
    
    private var controls: some View {
        VStack(spacing: 12) {
            // 이미지 개수 선택
            VStack(alignment: .leading, spacing: 4) {
                Text("이미지 개수")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(countOptions, id: \.self) { count in
                        Button(action: {
                            imageCount = count
                            loadedCount = 0
                            prefetchManager.reset()
                            performanceMonitor.resetStats()
                        }) {
                            Text("\(count)개")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(imageCount == count ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(imageCount == count ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 이미지 크기 선택
            VStack(alignment: .leading, spacing: 4) {
                Text("이미지 크기")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(ImageSize.allCases, id: \.self) { size in
                        Button(action: {
                            imageSize = size
                            loadedCount = 0
                            prefetchManager.reset()
                        }) {
                            Text(size.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(imageSize == size ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(imageSize == size ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Divider()
        }
        .padding(.horizontal)
    }
    
    private var imageList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<imageCount, id: \.self) { index in
                    imageRow(index: index)
                }
            }
            .padding()
        }
    }
    
    private func imageRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            CachedAsyncImage(
                url: ImageURLProvider.url(for: index, size: imageSize),
                size: CGSize(width: 400, height: 200)
            )
            .frame(height: 200)
            .clipped()
            .cornerRadius(10)
            .overlay(
                prefetchIndicator(for: index),
                alignment: .topTrailing
            )
            .onAppear {
                handleAppear(index: index)
            }
            
            HStack {
                Text("Image #\(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if prefetchManager.isPrefetched(index) {
                    Text("• Prefetched")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    private func prefetchIndicator(for index: Int) -> some View {
        Group {
            if prefetchManager.isPrefetched(index) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.purple)
                    .padding(8)
            }
        }
    }
    
    private func handleAppear(index: Int) {
        loadedCount += 1
        updateStats()
        
        // 다음 10개 프리패치
        let nextIndices = Array((index + 1)...min(index + 10, imageCount - 1))
        prefetchManager.prefetch(indices: nextIndices) { idx in
            ImageURLProvider.url(for: idx, size: imageSize)
        }
    }
    
    private func updateStats() {
        Task {
            cacheStats = await ImageCacheManager.shared.getStatistics()
        }
    }
}

#Preview {
    PrefetchListView()
}


