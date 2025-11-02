//
//  ComparisonView.swift
//  day09
//
//  3개 라이브러리 성능 비교 및 벤치마크
//

import SwiftUI

struct ComparisonView: View {
    @State private var isRunning = false
    @State private var results: [String: BenchmarkResult] = [:]
    @State private var progress: Double = 0
    
    private let testURLs = (0..<10).map { index in
        URL(string: "https://picsum.photos/800/600?random=\(index + 1000)")!
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("라이브러리 비교")
                    .font(.largeTitle)
                    .bold()
                
                // 벤치마크 버튼
                VStack(spacing: 12) {
                    Button(action: runBenchmark) {
                        HStack {
                            if isRunning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isRunning ? "벤치마크 실행 중..." : "전체 벤치마크 시작")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isRunning)
                    
                    if isRunning {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal)
                    }
                    
                    Button(action: clearAllCaches) {
                        Text("모든 캐시 초기화")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isRunning)
                }
                .padding()
                
                // 결과 표시
                if !results.isEmpty {
                    ComparisonResultsView(results: results)
                }
            }
        }
    }
    
    private func runBenchmark() {
        isRunning = true
        progress = 0
        results = [:]
        
        Task {
            // SDWebImage 벤치마크
            progress = 0.1
            let sdResult = await benchmarkSDWebImage()
            results["SDWebImage"] = sdResult
            
            // Kingfisher 벤치마크
            progress = 0.4
            let kfResult = await benchmarkKingfisher()
            results["Kingfisher"] = kfResult
            
            // Nuke 벤치마크
            progress = 0.7
            let nukeResult = await benchmarkNuke()
            results["Nuke"] = nukeResult
            
            progress = 1.0
            isRunning = false
        }
    }
    
    private func benchmarkSDWebImage() async -> BenchmarkResult {
        var metrics: [PerformanceMetrics] = []
        
        for url in testURLs {
            await withCheckedContinuation { continuation in
                SDWebImageLoader.shared.loadImage(from: url) { _, metric in
                    metrics.append(metric)
                    continuation.resume()
                }
            }
        }
        
        let diskSize = await withCheckedContinuation { continuation in
            SDWebImageLoader.shared.getDiskCacheSize { size in
                continuation.resume(returning: size)
            }
        }
        
        let transformTime = await withCheckedContinuation { continuation in
            SDWebImageLoader.shared.transformImage(
                from: testURLs[0],
                targetSize: CGSize(width: 200, height: 200)
            ) { _, time in
                continuation.resume(returning: time)
            }
        }
        
        return BenchmarkResult(
            libraryName: "SDWebImage",
            metrics: metrics,
            diskCacheSize: diskSize,
            transformTime: transformTime
        )
    }
    
    private func benchmarkKingfisher() async -> BenchmarkResult {
        var metrics: [PerformanceMetrics] = []
        
        for url in testURLs {
            await withCheckedContinuation { continuation in
                KingfisherLoader.shared.loadImage(from: url) { _, metric in
                    metrics.append(metric)
                    continuation.resume()
                }
            }
        }
        
        let diskSize = await withCheckedContinuation { continuation in
            KingfisherLoader.shared.getDiskCacheSize { size in
                continuation.resume(returning: size)
            }
        }
        
        let transformTime = await withCheckedContinuation { continuation in
            KingfisherLoader.shared.transformImage(
                from: testURLs[0],
                targetSize: CGSize(width: 200, height: 200)
            ) { _, time in
                continuation.resume(returning: time)
            }
        }
        
        return BenchmarkResult(
            libraryName: "Kingfisher",
            metrics: metrics,
            diskCacheSize: diskSize,
            transformTime: transformTime
        )
    }
    
    private func benchmarkNuke() async -> BenchmarkResult {
        var metrics: [PerformanceMetrics] = []
        
        for url in testURLs {
            await withCheckedContinuation { continuation in
                NukeLoader.shared.loadImage(from: url) { _, metric in
                    metrics.append(metric)
                    continuation.resume()
                }
            }
        }
        
        let diskSize = await withCheckedContinuation { continuation in
            NukeLoader.shared.getDiskCacheSize { size in
                continuation.resume(returning: size)
            }
        }
        
        let transformTime = await withCheckedContinuation { continuation in
            NukeLoader.shared.transformImage(
                from: testURLs[0],
                targetSize: CGSize(width: 200, height: 200)
            ) { _, time in
                continuation.resume(returning: time)
            }
        }
        
        return BenchmarkResult(
            libraryName: "Nuke",
            metrics: metrics,
            diskCacheSize: diskSize,
            transformTime: transformTime
        )
    }
    
    private func clearAllCaches() {
        SDWebImageLoader.shared.clearCache()
        KingfisherLoader.shared.clearCache()
        NukeLoader.shared.clearCache()
        results = [:]
    }
}

// MARK: - 결과 뷰

struct ComparisonResultsView: View {
    let results: [String: BenchmarkResult]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("벤치마크 결과")
                .font(.title2)
                .bold()
            
            // 비교 테이블
            VStack(spacing: 12) {
                ComparisonRow(
                    title: "평균 로딩 시간",
                    sdValue: results["SDWebImage"]?.metrics.averageLoadingTime ?? 0,
                    kfValue: results["Kingfisher"]?.metrics.averageLoadingTime ?? 0,
                    nukeValue: results["Nuke"]?.metrics.averageLoadingTime ?? 0,
                    formatter: { String(format: "%.1fms", $0 * 1000) },
                    lowerIsBetter: true
                )
                
                ComparisonRow(
                    title: "평균 메모리",
                    sdValue: Double(results["SDWebImage"]?.metrics.averageMemory ?? 0),
                    kfValue: Double(results["Kingfisher"]?.metrics.averageMemory ?? 0),
                    nukeValue: Double(results["Nuke"]?.metrics.averageMemory ?? 0),
                    formatter: { String(format: "%.1fMB", $0 / (1024 * 1024)) },
                    lowerIsBetter: true
                )
                
                ComparisonRow(
                    title: "캐시 히트율",
                    sdValue: results["SDWebImage"]?.metrics.cacheHitRate ?? 0,
                    kfValue: results["Kingfisher"]?.metrics.cacheHitRate ?? 0,
                    nukeValue: results["Nuke"]?.metrics.cacheHitRate ?? 0,
                    formatter: { String(format: "%.1f%%", $0) },
                    lowerIsBetter: false
                )
                
                ComparisonRow(
                    title: "디스크 캐시",
                    sdValue: Double(results["SDWebImage"]?.diskCacheSize ?? 0),
                    kfValue: Double(results["Kingfisher"]?.diskCacheSize ?? 0),
                    nukeValue: Double(results["Nuke"]?.diskCacheSize ?? 0),
                    formatter: { String(format: "%.1fMB", $0 / (1024 * 1024)) },
                    lowerIsBetter: true
                )
                
                ComparisonRow(
                    title: "리사이징 속도",
                    sdValue: results["SDWebImage"]?.transformTime ?? 0,
                    kfValue: results["Kingfisher"]?.transformTime ?? 0,
                    nukeValue: results["Nuke"]?.transformTime ?? 0,
                    formatter: { String(format: "%.1fms", $0 * 1000) },
                    lowerIsBetter: true
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            // 상세 통계
            ForEach(["SDWebImage", "Kingfisher", "Nuke"], id: \.self) { library in
                if let result = results[library] {
                    DetailedStatsView(result: result)
                }
            }
        }
    }
}

// MARK: - 비교 행

struct ComparisonRow<T: Comparable>: View {
    let title: String
    let sdValue: T
    let kfValue: T
    let nukeValue: T
    let formatter: (T) -> String
    let lowerIsBetter: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                ValueBadge(
                    label: "SD",
                    value: formatter(sdValue),
                    isBest: isBest(sdValue),
                    color: .blue
                )
                
                ValueBadge(
                    label: "KF",
                    value: formatter(kfValue),
                    isBest: isBest(kfValue),
                    color: .green
                )
                
                ValueBadge(
                    label: "Nuke",
                    value: formatter(nukeValue),
                    isBest: isBest(nukeValue),
                    color: .purple
                )
            }
        }
    }
    
    private func isBest(_ value: T) -> Bool {
        if lowerIsBetter {
            return value == min(sdValue, kfValue, nukeValue)
        } else {
            return value == max(sdValue, kfValue, nukeValue)
        }
    }
}

struct ValueBadge: View {
    let label: String
    let value: String
    let isBest: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(isBest ? color.opacity(0.3) : color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isBest ? color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - 상세 통계 뷰

struct DetailedStatsView: View {
    let result: BenchmarkResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.libraryName)
                .font(.headline)
            
            Text(result.summary)
                .font(.caption)
                .monospaced()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

