//
//  GIFComparisonView.swift
//  day19
//
//  세 가지 방법 비교 및 성능 측정
//

import SwiftUI
import Nuke

/// GIF 비교 뷰
struct GIFComparisonView: View {
    @State private var gifURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // 각 방법별 메트릭
    @State private var uiImageViewMetrics = PerformanceMetrics()
    @State private var swiftUIMetrics = PerformanceMetrics()
    @State private var nukeMetrics = PerformanceMetrics()
    
    // 성능 모니터
    @State private var uiImageViewMonitor = GIFPerformanceMonitor()
    @State private var swiftUIMonitor = GIFPerformanceMonitor()
    @State private var nukeMonitor = GIFPerformanceMonitor()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // GIF URL 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("GIF URL")
                        .font(.headline)
                    
                    if let url = gifURL {
                        Text(url.absoluteString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Button(action: loadSampleGIF) {
                        Label("샘플 GIF 로드", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                if let error = errorMessage {
                    Text("오류: \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // 비교 뷰
                if gifURL != nil {
                    ComparisonSection(
                        title: "UIImageView",
                        color: .blue,
                        metrics: uiImageViewMetrics,
                        gifURL: gifURL
                    )
                    
                    ComparisonSection(
                        title: "SwiftUI",
                        color: .green,
                        metrics: swiftUIMetrics,
                        gifURL: gifURL
                    )
                    
                    ComparisonSection(
                        title: "Nuke",
                        color: .purple,
                        metrics: nukeMetrics,
                        gifURL: gifURL
                    )
                    
                    // 성능 비교 차트
                    PerformanceComparisonChart(
                        uiImageView: uiImageViewMetrics,
                        swiftUI: swiftUIMetrics,
                        nuke: nukeMetrics
                    )
                }
            }
            .padding()
        }
        .navigationTitle("비교")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSampleGIF()
        }
    }
    
    private func loadSampleGIF() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://media.giphy.com/media/3o7aCTPPm4OHfRLSH6/giphy.gif") else {
            errorMessage = "유효하지 않은 URL"
            isLoading = false
            return
        }
        
        gifURL = url
        
        // 각 방법별 성능 측정
        Task {
            await measureUIImageViewPerformance(url: url)
            await measureSwiftUIPerformance(url: url)
            await measureNukePerformance(url: url)
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func measureUIImageViewPerformance(url: URL) async {
        let startTime = CACurrentMediaTime()
        uiImageViewMonitor.start(expectedFrameInterval: 0.1)
        
        do {
            let parser = GIFParser(url: url)
            let frames = try await parser.parseFrames()
            
            let loadTime = CACurrentMediaTime() - startTime
            
            await MainActor.run {
                uiImageViewMetrics = PerformanceMetrics(
                    memoryUsage: MemorySampler.getCurrentMemory(),
                    cpuUsage: 0,
                    frameRate: 0,
                    loadTime: loadTime,
                    droppedFrames: 0
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = "UIImageView 측정 실패: \(error.localizedDescription)"
            }
        }
    }
    
    private func measureSwiftUIPerformance(url: URL) async {
        let startTime = CACurrentMediaTime()
        swiftUIMonitor.start(expectedFrameInterval: 0.1)
        
        do {
            let parser = GIFParser(url: url)
            let frames = try await parser.parseFrames()
            
            let loadTime = CACurrentMediaTime() - startTime
            
            await MainActor.run {
                swiftUIMetrics = PerformanceMetrics(
                    memoryUsage: MemorySampler.getCurrentMemory(),
                    cpuUsage: 0,
                    frameRate: 0,
                    loadTime: loadTime,
                    droppedFrames: 0
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = "SwiftUI 측정 실패: \(error.localizedDescription)"
            }
        }
    }
    
    private func measureNukePerformance(url: URL) async {
        let startTime = CACurrentMediaTime()
        nukeMonitor.start(expectedFrameInterval: 0.1)
        
        await withCheckedContinuation { continuation in
            ImagePipeline.shared.loadImage(with: url) { result in
                let loadTime = CACurrentMediaTime() - startTime
                
                Task { @MainActor in
                    switch result {
                    case .success:
                        self.nukeMetrics = PerformanceMetrics(
                            memoryUsage: MemorySampler.getCurrentMemory(),
                            cpuUsage: 0,
                            frameRate: 0,
                            loadTime: loadTime,
                            droppedFrames: 0
                        )
                    case .failure(let error):
                        self.errorMessage = "Nuke 측정 실패: \(error.localizedDescription)"
                    }
                    continuation.resume()
                }
            }
        }
    }
}

/// 비교 섹션
struct ComparisonSection: View {
    let title: String
    let color: Color
    let metrics: PerformanceMetrics
    let gifURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            // 메트릭 표시
            VStack(alignment: .leading, spacing: 4) {
                MetricRow(label: "메모리", value: String(format: "%.2f MB", metrics.memoryUsage))
                MetricRow(label: "로딩 시간", value: String(format: "%.3f초", metrics.loadTime))
                MetricRow(label: "FPS", value: String(format: "%.1f", metrics.frameRate))
                MetricRow(label: "프레임 드롭", value: "\(metrics.droppedFrames)")
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

/// 메트릭 행
struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

/// 성능 비교 차트
struct PerformanceComparisonChart: View {
    let uiImageView: PerformanceMetrics
    let swiftUI: PerformanceMetrics
    let nuke: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("성능 비교")
                .font(.headline)
            
            // 메모리 비교
            ComparisonBar(
                label: "메모리 사용량",
                uiImageView: uiImageView.memoryUsage,
                swiftUI: swiftUI.memoryUsage,
                nuke: nuke.memoryUsage,
                unit: "MB",
                lowerIsBetter: true
            )
            
            // 로딩 시간 비교
            ComparisonBar(
                label: "로딩 시간",
                uiImageView: uiImageView.loadTime,
                swiftUI: swiftUI.loadTime,
                nuke: nuke.loadTime,
                unit: "초",
                lowerIsBetter: true
            )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

/// 비교 바
struct ComparisonBar: View {
    let label: String
    let uiImageView: Double
    let swiftUI: Double
    let nuke: Double
    let unit: String
    let lowerIsBetter: Bool
    
    private var maxValue: Double {
        max(uiImageView, max(swiftUI, nuke))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            
            BarItem(label: "UIImageView", value: uiImageView, maxValue: maxValue, color: .blue, unit: unit)
            BarItem(label: "SwiftUI", value: swiftUI, maxValue: maxValue, color: .green, unit: unit)
            BarItem(label: "Nuke", value: nuke, maxValue: maxValue, color: .purple, unit: unit)
        }
    }
}

/// 바 아이템
struct BarItem: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .frame(width: 100, alignment: .leading)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(color.opacity(0.2))
                            .frame(height: 20)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: maxValue > 0 ? geometry.size.width * CGFloat(value / maxValue) : 0, height: 20)
                    }
                }
                .frame(height: 20)
                
                Text(String(format: "%.2f %@", value, unit))
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .trailing)
            }
        }
    }
}

#Preview {
    NavigationView {
        GIFComparisonView()
    }
}

