//
//  ThumbnailGalleryView.swift
//  day18
//
//  썸네일 갤러리 뷰 (캐싱 활용)
//

import SwiftUI

struct ThumbnailGalleryView: View {
    @State private var videoURLs: [URL] = []
    @State private var thumbnails: [URL: UIImage?] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cacheInfo: CacheInfo?
    
    struct CacheInfo {
        let memoryCount: Int
        let diskCount: Int
        let diskSize: Int64
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text("썸네일 갤러리")
                        .font(.title)
                        .bold()
                    
                    Text("여러 동영상의 썸네일을 자동 생성하고 캐싱합니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 캐시 정보
                if let info = cacheInfo {
                    Section {
                        VStack(spacing: 12) {
                            HStack {
                                Text("메모리 캐시")
                                Spacer()
                                Text("\(info.memoryCount)개")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("디스크 캐시")
                                Spacer()
                                Text("\(info.diskCount)개")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("디스크 크기")
                                Spacer()
                                Text(PerformanceMeasurer.formatMemoryUsage(info.diskSize))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("캐시 비우기") {
                                clearCache()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                        .font(.caption)
                    } header: {
                        Text("캐시 정보")
                    }
                }
                
                // 동영상 추가 버튼
                Section {
                    Button(action: addVideos) {
                        HStack {
                            Image(systemName: "video.badge.plus")
                            Text("동영상 추가")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if !videoURLs.isEmpty {
                        Button(action: generateAllThumbnails) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                } else {
                                    Image(systemName: "photo.badge.plus")
                                }
                                
                                Text(isLoading ? "생성 중..." : "모든 썸네일 생성")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isLoading ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                } header: {
                    Text("동영상 관리")
                }
                
                // 에러 메시지
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 썸네일 그리드
                if !videoURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("동영상 썸네일 (\(videoURLs.count)개)")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(videoURLs, id: \.self) { url in
                                VideoThumbnailCell(
                                    videoURL: url,
                                    thumbnail: thumbnails[url]
                                )
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("동영상을 추가하세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("썸네일 갤러리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateCacheInfo()
        }
    }
    
    // MARK: - Actions
    
    private func addVideos() {
        // 실제 구현에서는 DocumentPicker 사용
        // 여기서는 샘플 비디오 추가
        if let sampleVideoURL = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
            if !videoURLs.contains(sampleVideoURL) {
                videoURLs.append(sampleVideoURL)
                // 캐시에서 먼저 확인
                loadThumbnailFromCache(for: sampleVideoURL)
            }
        } else {
            errorMessage = "샘플 비디오를 찾을 수 없습니다."
        }
    }
    
    private func loadThumbnailFromCache(for url: URL) {
        let cacheKey = ThumbnailCacheKey(videoURL: url, time: 1.0)
        if let cachedThumbnail = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
            thumbnails[url] = cachedThumbnail
        }
    }
    
    private func generateAllThumbnails() {
        guard !videoURLs.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            var newThumbnails: [URL: UIImage?] = [:]
            
            for url in videoURLs {
                // 캐시 확인
                let cacheKey = ThumbnailCacheKey(videoURL: url, time: 1.0)
                if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
                    newThumbnails[url] = cached
                    continue
                }
                
                // 캐시에 없으면 생성
                do {
                    let thumbnail = try await ThumbnailGenerator.generateThumbnail(from: url, at: 1.0)
                    ThumbnailCache.shared.storeThumbnail(thumbnail, for: cacheKey)
                    newThumbnails[url] = thumbnail
                } catch {
                    newThumbnails[url] = nil
                    PerformanceLogger.error("썸네일 생성 실패: \(url.lastPathComponent) - \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                thumbnails = newThumbnails
                isLoading = false
                updateCacheInfo()
            }
        }
    }
    
    private func clearCache() {
        ThumbnailCache.shared.clearAllCache()
        updateCacheInfo()
        
        // 썸네일 다시 로드 (캐시에서)
        for url in videoURLs {
            thumbnails[url] = nil
        }
    }
    
    private func updateCacheInfo() {
        let diskCount = ThumbnailCache.shared.getDiskCacheCount()
        let diskSize = ThumbnailCache.shared.getDiskCacheSize()
        // 메모리 캐시 개수는 직접 확인 불가능하므로 대략적인 값 사용
        cacheInfo = CacheInfo(
            memoryCount: thumbnails.compactMap { $0.value }.count,
            diskCount: diskCount,
            diskSize: diskSize
        )
    }
}

// MARK: - Video Thumbnail Cell

struct VideoThumbnailCell: View {
    let videoURL: URL
    let thumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 8) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        ProgressView()
                    )
            }
            
            Text(videoURL.lastPathComponent)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationView {
        ThumbnailGalleryView()
    }
}

