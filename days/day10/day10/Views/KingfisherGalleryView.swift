//
//  KingfisherGalleryView.swift
//  day10
//
//  Kingfisher를 사용한 이미지 갤러리 (100+ 이미지)
//

import SwiftUI
import Kingfisher

struct KingfisherGalleryView: View {
    // MARK: - Properties
    
    @StateObject private var cacheManager = KingfisherCacheManager.shared
    @StateObject private var memoryMonitor = MemorySampler.shared
    @StateObject private var performanceLogger = PerformanceLogger.shared
    
    @State private var imageCount = 100
    @State private var isLoading = false
    @State private var loadedCount = 0
    
    // MARK: - Grid Configuration
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 8)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 통계 헤더
                statsHeader
                    .padding()
                    .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // 갤러리
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<imageCount, id: \.self) { index in
                            KingfisherImageCell(
                                index: index,
                                onLoad: {
                                    loadedCount += 1
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // 컨트롤
                controls
                    .padding()
                    .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Kingfisher 갤러리")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            memoryMonitor.startMonitoring(interval: 2.0)
        }
        .onDisappear {
            memoryMonitor.stopMonitoring()
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("메모리 캐시")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", cacheManager.currentMemoryUsageMB)) MB")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("디스크 캐시")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", cacheManager.currentDiskUsageMB)) MB")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("히트율")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", cacheManager.hitRate))%")
                        .font(.headline)
                        .foregroundColor(hitRateColor)
                }
            }
            
            HStack {
                Label("\(loadedCount)/\(imageCount) 로드됨", systemImage: "photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(String(format: "%.0f", memoryMonitor.currentMemoryUsageMB() ?? 0)) MB", systemImage: "memorychip")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var hitRateColor: Color {
        let rate = cacheManager.hitRate
        if rate >= 90 { return .green }
        if rate >= 70 { return .orange }
        return .red
    }
    
    // MARK: - Controls
    
    private var controls: some View {
        VStack(spacing: 12) {
            // 이미지 개수 선택
            HStack {
                Text("이미지 개수:")
                    .font(.caption)
                
                Picker("", selection: $imageCount) {
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                }
                .pickerStyle(.segmented)
            }
            
            // 액션 버튼
            HStack(spacing: 12) {
                Button(action: reloadImages) {
                    Label("다시 로드", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: clearCache) {
                    Label("캐시 삭제", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            HStack(spacing: 12) {
                Button(action: resetStats) {
                    Label("통계 초기화", systemImage: "chart.bar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: showSummary) {
                    Label("요약 보기", systemImage: "info.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Actions
    
    private func reloadImages() {
        loadedCount = 0
        // 뷰를 강제로 새로고침하기 위해 ID 변경
        imageCount += 0
    }
    
    private func clearCache() {
        cacheManager.clearAllCache()
        loadedCount = 0
    }
    
    private func resetStats() {
        cacheManager.resetStatistics()
        loadedCount = 0
    }
    
    private func showSummary() {
        print(cacheManager.summary())
    }
}

// MARK: - Image Cell

struct KingfisherImageCell: View {
    let index: Int
    let onLoad: () -> Void
    
    @State private var isLoaded = false
    @State private var loadTime: TimeInterval = 0
    
    private var imageURL: URL {
        URL(string: "https://picsum.photos/300/300?random=\(index)")!
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            KFImage(imageURL)
                .placeholder {
                    ProgressView()
                        .frame(width: 150, height: 150)
                }
                .onSuccess { result in
                    isLoaded = true
                    onLoad()
                    
                    // 캐시 타입 확인
                    let cacheType = result.cacheType
                    switch cacheType {
                    case .memory:
                        print("🎯 메모리 히트: \(index)")
                    case .disk:
                        print("💿 디스크 히트: \(index)")
                    case .none:
                        print("🌐 네트워크 로드: \(index)")
                    }
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
                .clipped()
                .cornerRadius(8)
            
            // 인덱스 표시
            Text("#\(index)")
                .font(.caption2)
                .padding(4)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(4)
                .padding(4)
        }
    }
}

// MARK: - Preview

#Preview {
    KingfisherGalleryView()
}













