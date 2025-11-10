//
//  LibraryComparisonView.swift
//  day14
//
//  Nuke vs Kingfisher 성능 비교 뷰
//

import SwiftUI
import NukeUI

struct LibraryComparisonView: View {
    @State private var imageProvider = ImageProvider()
    @State private var nukeLoader = NukeImageLoader()
    @State private var kingfisherLoader = KingfisherImageLoader()
    @State private var cacheAnalyzer = CacheAnalyzer()
    @State private var memoryTracker = MemoryTracker()
    
    @State private var imageCount = 50
    @State private var isLoading = false
    @State private var showAnalysis = false
    
    private let imageCounts = [25, 50, 100]
    
    var testImages: [ImageModel] {
        Array(imageProvider.allImages.prefix(imageCount))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 설정
                    VStack(alignment: .leading, spacing: 12) {
                        Text("테스트 설정")
                            .font(.headline)
                        
                        HStack {
                            Text("이미지 개수:")
                            Picker("이미지 개수", selection: $imageCount) {
                                ForEach(imageCounts, id: \.self) { count in
                                    Text("\(count)개").tag(count)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await runComparison()
                                }
                            } label: {
                                Label("비교 시작", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isLoading)
                            
                            Button {
                                clearAll()
                            } label: {
                                Label("초기화", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    if isLoading {
                        ProgressView("비교 진행 중...")
                            .padding()
                    }
                    
                    // 좌우 비교
                    HStack(spacing: 8) {
                        // Nuke
                        VStack(spacing: 8) {
                            Text("Nuke")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                                ForEach(testImages) { image in
                                    LazyImage(url: URL(string: image.thumbnailURL(size: 150))) { state in
                                        if let image = state.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else if state.isLoading {
                                            ProgressView()
                                        } else {
                                            Color.gray.opacity(0.3)
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            // Nuke 통계
                            VStack(alignment: .leading, spacing: 8) {
                                StatRow(label: "로드 횟수", value: "\(nukeLoader.loadCount)")
                                StatRow(label: "캐시 히트", value: String(format: "%.1f%%", nukeLoader.cacheHitRate))
                                StatRow(label: "평균 시간", value: String(format: "%.0fms", nukeLoader.averageLoadTime * 1000))
                                StatRow(label: "메모리", value: String(format: "%.1fMB", nukeLoader.memoryUsage))
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Kingfisher
                        VStack(spacing: 8) {
                            Text("Kingfisher")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                                ForEach(testImages) { image in
                                    KFImageView(urlString: image.thumbnailURL(size: 150))
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            // Kingfisher 통계
                            VStack(alignment: .leading, spacing: 8) {
                                StatRow(label: "로드 횟수", value: "\(kingfisherLoader.loadCount)")
                                StatRow(label: "캐시 히트", value: String(format: "%.1f%%", kingfisherLoader.cacheHitRate))
                                StatRow(label: "평균 시간", value: String(format: "%.0fms", kingfisherLoader.averageLoadTime * 1000))
                                StatRow(label: "메모리", value: String(format: "%.1fMB", kingfisherLoader.memoryUsage))
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // 분석 결과
                    if showAnalysis {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("분석 결과")
                                .font(.headline)
                            
                            if let nukeAnalysis = cacheAnalyzer.nukeAnalysis,
                               let kfAnalysis = cacheAnalyzer.kingfisherAnalysis {
                                
                                ComparisonRow(
                                    title: "캐시 히트율",
                                    nukeValue: String(format: "%.1f%%", nukeAnalysis.hitRate),
                                    kfValue: String(format: "%.1f%%", kfAnalysis.hitRate),
                                    nukeWins: nukeAnalysis.hitRate > kfAnalysis.hitRate
                                )
                                
                                ComparisonRow(
                                    title: "평균 로드 시간",
                                    nukeValue: String(format: "%.0fms", nukeAnalysis.averageLoadTime * 1000),
                                    kfValue: String(format: "%.0fms", kfAnalysis.averageLoadTime * 1000),
                                    nukeWins: nukeAnalysis.averageLoadTime < kfAnalysis.averageLoadTime
                                )
                                
                                ComparisonRow(
                                    title: "메모리 사용량",
                                    nukeValue: String(format: "%.1fMB", nukeAnalysis.memoryUsage),
                                    kfValue: String(format: "%.1fMB", kfAnalysis.memoryUsage),
                                    nukeWins: nukeAnalysis.memoryUsage < kfAnalysis.memoryUsage
                                )
                                
                                Divider()
                                
                                Text(cacheAnalyzer.comparisonSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    // 시스템 메모리
                    VStack(alignment: .leading, spacing: 8) {
                        Text("시스템 메모리")
                            .font(.headline)
                        
                        HStack {
                            Text("현재:")
                            Text(String(format: "%.1fMB", memoryTracker.currentMemoryUsage))
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("최대:")
                            Text(String(format: "%.1fMB", memoryTracker.peakMemoryUsage))
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("라이브러리 비교")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func runComparison() async {
        isLoading = true
        showAnalysis = false
        
        // 캐시 초기화
        nukeLoader.clearCache()
        kingfisherLoader.clearCache()
        
        // 잠시 대기
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // 이미지 로드 (Nuke와 Kingfisher 동시에)
        await withTaskGroup(of: Void.self) { group in
            // Nuke 로드
            for image in testImages {
                group.addTask {
                    _ = try? await nukeLoader.loadImage(from: image.thumbnailURL(size: 150))
                }
            }
            
            // Kingfisher 로드
            for image in testImages {
                group.addTask {
                    _ = try? await kingfisherLoader.loadImage(from: image.thumbnailURL(size: 150))
                }
            }
        }
        
        // 분석
        await cacheAnalyzer.analyzeNuke(nukeLoader)
        await cacheAnalyzer.analyzeKingfisher(kingfisherLoader)
        
        await MainActor.run {
            isLoading = false
            showAnalysis = true
        }
    }
    
    private func clearAll() {
        nukeLoader.clearCache()
        kingfisherLoader.clearCache()
        cacheAnalyzer.reset()
        memoryTracker.reset()
        showAnalysis = false
    }
}

/// 통계 행
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

/// 비교 행
struct ComparisonRow: View {
    let title: String
    let nukeValue: String
    let kfValue: String
    let nukeWins: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                HStack {
                    Text("Nuke:")
                        .foregroundStyle(.blue)
                    Text(nukeValue)
                        .fontWeight(nukeWins ? .bold : .regular)
                    if nukeWins {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("KF:")
                        .foregroundStyle(.orange)
                    Text(kfValue)
                        .fontWeight(!nukeWins ? .bold : .regular)
                    if !nukeWins {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LibraryComparisonView()
}

