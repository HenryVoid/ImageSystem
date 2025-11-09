//
//  CachedListView.swift
//  day12
//
//  NSCache 기반 캐싱을 적용한 이미지 리스트
//

import SwiftUI

/// 캐시를 사용하는 AsyncImage 대체
struct CachedAsyncImage: View {
    let url: URL
    let size: CGSize
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // 1. 캐시 확인
        if let cached = await ImageCacheManager.shared.image(for: url) {
            self.image = cached
            return
        }
        
        // 2. 네트워크 로드
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 3. 백그라운드에서 디코딩
            if let uiImage = await decodeImage(data) {
                // 4. 캐시에 저장
                await ImageCacheManager.shared.setImage(uiImage, for: url)
                self.image = uiImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
    
    private func decodeImage(_ data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value
    }
}

struct CachedListView: View {
    @State private var imageCount = 100
    @State private var imageSize: ImageSize = .medium
    @State private var loadedCount = 0
    @State private var cacheStats = CacheStatistics()
    
    @StateObject private var performanceMonitor = PerformanceMonitor()
    
    let countOptions = [10, 100, 500, 1000]
    
    var body: some View {
        VStack(spacing: 0) {
            // 캐시 통계 헤더
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
            updateCacheStats()
        }
        .onDisappear {
            performanceMonitor.stopMonitoring()
        }
    }
    
    // MARK: - Components
    
    private var cacheStatsHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("캐시 히트")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(cacheStats.hitCount)")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("히트율")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cacheStats.formattedHitRate)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(cacheStats.hitRate > 80 ? .green : .orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("캐시 미스")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(cacheStats.missCount)")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                }
            }
            
            HStack {
                Text("캐시된 이미지: \(cacheStats.cachedImagesCount)")
                    .font(.caption)
                
                Spacer()
                
                Button("캐시 클리어") {
                    Task {
                        await ImageCacheManager.shared.clearCache()
                        await ImageCacheManager.shared.resetStatistics()
                        updateCacheStats()
                    }
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
        .background(Color.green.opacity(0.1))
    }
    
    private var performanceHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("FPS: \(String(format: "%.0f", performanceMonitor.metrics.fps))")
                    .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                Text("메모리: \(performanceMonitor.metrics.formattedMemory)")
                    .font(.system(.body, design: .monospaced))
            }
            
            HStack {
                Text("로드됨: \(loadedCount)/\(imageCount)")
                    .font(.system(.caption, design: .monospaced))
                
                Spacer()
                
                Button("통계 리프레시") {
                    updateCacheStats()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
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
            .onAppear {
                loadedCount += 1
                updateCacheStats()
            }
            
            Text("Image #\(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func updateCacheStats() {
        Task {
            cacheStats = await ImageCacheManager.shared.getStatistics()
        }
    }
}

#Preview {
    CachedListView()
}


