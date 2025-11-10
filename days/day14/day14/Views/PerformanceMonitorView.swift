//
//  PerformanceMonitorView.swift
//  day14
//
//  실시간 성능 모니터 뷰
//

import SwiftUI
import Charts

struct PerformanceMonitorView: View {
    @State private var nukeLoader = NukeImageLoader()
    @State private var kingfisherLoader = KingfisherImageLoader()
    @State private var memoryTracker = MemoryTracker()
    @State private var cacheAnalyzer = CacheAnalyzer()
    
    @State private var selectedLibrary: MonitorLibrary = .nuke
    
    enum MonitorLibrary: String, CaseIterable {
        case nuke = "Nuke"
        case kingfisher = "Kingfisher"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 라이브러리 선택
                    Picker("라이브러리", selection: $selectedLibrary) {
                        ForEach(MonitorLibrary.allCases, id: \.self) { library in
                            Text(library.rawValue).tag(library)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 현재 선택된 라이브러리 통계
                    if selectedLibrary == .nuke {
                        NukeStatisticsView(loader: nukeLoader)
                    } else {
                        KingfisherStatisticsView(loader: kingfisherLoader)
                    }
                    
                    // 시스템 메모리
                    SystemMemoryView(tracker: memoryTracker)
                    
                    // 비교 분석
                    ComparisonAnalysisView(
                        nukeLoader: nukeLoader,
                        kingfisherLoader: kingfisherLoader,
                        cacheAnalyzer: cacheAnalyzer
                    )
                }
                .padding()
            }
            .navigationTitle("성능 모니터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            nukeLoader.clearCache()
                        } label: {
                            Label("Nuke 캐시 삭제", systemImage: "trash")
                        }
                        
                        Button {
                            kingfisherLoader.clearCache()
                        } label: {
                            Label("Kingfisher 캐시 삭제", systemImage: "trash")
                        }
                        
                        Divider()
                        
                        Button {
                            resetAll()
                        } label: {
                            Label("모두 초기화", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func resetAll() {
        nukeLoader.clearCache()
        kingfisherLoader.clearCache()
        memoryTracker.reset()
        cacheAnalyzer.reset()
    }
}

/// Nuke 통계 뷰
struct NukeStatisticsView: View {
    let loader: NukeImageLoader
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nuke 통계")
                .font(.headline)
            
            MetricCard(
                title: "로딩 통계",
                metrics: [
                    ("총 로드 횟수", "\(loader.loadCount)회"),
                    ("캐시 히트", "\(loader.cacheHitCount)회"),
                    ("캐시 미스", "\(loader.cacheMissCount)회"),
                    ("캐시 히트율", String(format: "%.1f%%", loader.cacheHitRate))
                ],
                color: .blue
            )
            
            MetricCard(
                title: "성능",
                metrics: [
                    ("평균 로드 시간", String(format: "%.0fms", loader.averageLoadTime * 1000)),
                    ("총 로드 시간", String(format: "%.2fs", loader.totalLoadTime))
                ],
                color: .green
            )
            
            MetricCard(
                title: "메모리 사용량",
                metrics: [
                    ("메모리 캐시", String(format: "%.1fMB", loader.memoryUsage)),
                    ("디스크 캐시", String(format: "%.1fMB", loader.diskCacheSizeMB))
                ],
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

/// Kingfisher 통계 뷰
struct KingfisherStatisticsView: View {
    let loader: KingfisherImageLoader
    @State private var diskSize: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kingfisher 통계")
                .font(.headline)
            
            MetricCard(
                title: "로딩 통계",
                metrics: [
                    ("총 로드 횟수", "\(loader.loadCount)회"),
                    ("캐시 히트", "\(loader.cacheHitCount)회"),
                    ("캐시 미스", "\(loader.cacheMissCount)회"),
                    ("캐시 히트율", String(format: "%.1f%%", loader.cacheHitRate))
                ],
                color: .orange
            )
            
            MetricCard(
                title: "성능",
                metrics: [
                    ("평균 로드 시간", String(format: "%.0fms", loader.averageLoadTime * 1000)),
                    ("총 로드 시간", String(format: "%.2fs", loader.totalLoadTime))
                ],
                color: .green
            )
            
            MetricCard(
                title: "메모리 사용량",
                metrics: [
                    ("메모리 캐시", String(format: "%.1fMB", loader.memoryUsage)),
                    ("디스크 캐시", String(format: "%.1fMB", diskSize))
                ],
                color: .purple
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .task {
            diskSize = await loader.diskCacheSizeMB()
        }
    }
}

/// 시스템 메모리 뷰
struct SystemMemoryView: View {
    let tracker: MemoryTracker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시스템 메모리")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("현재 사용량")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.1f MB", tracker.currentMemoryUsage))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("최대 사용량")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.1f MB", tracker.peakMemoryUsage))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 메모리 게이지
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(tracker.currentMemoryUsage / tracker.peakMemoryUsage, 1))
                }
            }
            .frame(height: 20)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

/// 비교 분석 뷰
struct ComparisonAnalysisView: View {
    let nukeLoader: NukeImageLoader
    let kingfisherLoader: KingfisherImageLoader
    let cacheAnalyzer: CacheAnalyzer
    
    @State private var showComparison = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("비교 분석")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    Task {
                        await analyzeAndCompare()
                    }
                } label: {
                    Label("분석", systemImage: "chart.bar")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            
            if showComparison {
                VStack(spacing: 12) {
                    ComparisonBar(
                        title: "캐시 히트율",
                        nukeValue: nukeLoader.cacheHitRate,
                        kfValue: kingfisherLoader.cacheHitRate,
                        unit: "%",
                        higherIsBetter: true
                    )
                    
                    ComparisonBar(
                        title: "평균 로드 시간",
                        nukeValue: nukeLoader.averageLoadTime * 1000,
                        kfValue: kingfisherLoader.averageLoadTime * 1000,
                        unit: "ms",
                        higherIsBetter: false
                    )
                    
                    ComparisonBar(
                        title: "메모리 사용량",
                        nukeValue: nukeLoader.memoryUsage,
                        kfValue: kingfisherLoader.memoryUsage,
                        unit: "MB",
                        higherIsBetter: false
                    )
                }
            } else {
                Text("'분석' 버튼을 눌러 비교 결과를 확인하세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func analyzeAndCompare() async {
        await cacheAnalyzer.analyzeNuke(nukeLoader)
        await cacheAnalyzer.analyzeKingfisher(kingfisherLoader)
        
        await MainActor.run {
            showComparison = true
        }
    }
}

/// 메트릭 카드
struct MetricCard: View {
    let title: String
    let metrics: [(String, String)]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            
            ForEach(metrics, id: \.0) { metric in
                HStack {
                    Text(metric.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(metric.1)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 비교 바
struct ComparisonBar: View {
    let title: String
    let nukeValue: Double
    let kfValue: Double
    let unit: String
    let higherIsBetter: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                // Nuke
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Nuke")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        if isNukeWinner {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * nukeRatio)
                        }
                    }
                    .frame(height: 8)
                    
                    Text(String(format: "%.1f %@", nukeValue, unit))
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                
                // Kingfisher
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("KF")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        if !isNukeWinner {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * kfRatio)
                        }
                    }
                    .frame(height: 8)
                    
                    Text(String(format: "%.1f %@", kfValue, unit))
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var maxValue: Double {
        max(nukeValue, kfValue)
    }
    
    private var nukeRatio: Double {
        guard maxValue > 0 else { return 0 }
        return nukeValue / maxValue
    }
    
    private var kfRatio: Double {
        guard maxValue > 0 else { return 0 }
        return kfValue / maxValue
    }
    
    private var isNukeWinner: Bool {
        if higherIsBetter {
            return nukeValue > kfValue
        } else {
            return nukeValue < kfValue
        }
    }
}

#Preview {
    PerformanceMonitorView()
}

