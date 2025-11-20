//
//  BenchmarkView.swift
//  day08
//
//  성능 벤치마크 및 통계

import SwiftUI

struct BenchmarkView: View {
    @State private var isRunning = false
    @State private var currentTest = ""
    @State private var progress = 0.0
    
    @State private var noCacheStats = PerformanceStats()
    @State private var cachedStats = PerformanceStats()
    
    // 테스트 설정
    private let iterations = 20
    private let testURL = URL(string: "https://picsum.photos/800/600?random=100")!
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 진행 상황
                    if isRunning {
                        progressSection
                    }
                    
                    // 결과 카드들
                    resultCards
                    
                    // 비교 차트
                    if noCacheStats.count > 0 && cachedStats.count > 0 {
                        comparisonSection
                    }
                    
                    // 버튼
                    buttonSection
                    
                    // 설명
                    descriptionSection
                }
                .padding()
            }
            .navigationTitle("벤치마크")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 섹션들
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            Text(currentTest)
                .font(.headline)
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(progress * 100))% 완료")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var resultCards: some View {
        VStack(spacing: 16) {
            // 캐시 없음 결과
            resultCard(
                title: "캐시 없음",
                stats: noCacheStats,
                color: .red,
                icon: "network"
            )
            
            // 캐시 적용 결과
            resultCard(
                title: "캐시 적용",
                stats: cachedStats,
                color: .green,
                icon: "bolt.fill"
            )
        }
    }
    
    private func resultCard(title: String, stats: PerformanceStats, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                if stats.count > 0 {
                    Text("\(stats.count)회")
                        .font(.caption)
                        .padding(4)
                        .background(color.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if stats.count > 0 {
                Divider()
                
                // 통계
                statRow(label: "평균", value: String(format: "%.2f ms", stats.average * 1000), color: color)
                statRow(label: "최소", value: String(format: "%.2f ms", stats.minimum * 1000), color: .green)
                statRow(label: "최대", value: String(format: "%.2f ms", stats.maximum * 1000), color: .orange)
                statRow(label: "총합", value: String(format: "%.2f s", stats.total), color: .blue)
            } else {
                Text("테스트 데이터 없음")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(color)
        }
    }
    
    private var comparisonSection: some View {
        VStack(spacing: 16) {
            Text("📊 종합 비교")
                .font(.headline)
            
            // 평균 속도 개선
            let avgImprovement = noCacheStats.average / cachedStats.average
            comparisonRow(
                label: "평균 속도",
                value: String(format: "%.1f배 빠름", avgImprovement),
                color: .green
            )
            
            // 최소 시간 개선
            let minImprovement = noCacheStats.minimum / cachedStats.minimum
            comparisonRow(
                label: "최고 속도",
                value: String(format: "%.1f배 빠름", minImprovement),
                color: .blue
            )
            
            // 총 시간 절약
            let totalSaved = (noCacheStats.total - cachedStats.total)
            comparisonRow(
                label: "시간 절약",
                value: String(format: "%.2f s", totalSaved),
                color: .purple
            )
            
            // 캐시 히트율
            comparisonRow(
                label: "캐시 히트율",
                value: String(format: "%.1f%%", CachedImageLoader.shared.hitRate),
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func comparisonRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(color)
                .fontWeight(.bold)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button(action: runFullBenchmark) {
                HStack {
                    if isRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(isRunning ? "테스트 중..." : "전체 벤치마크 실행")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRunning ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isRunning)
            
            HStack(spacing: 12) {
                Button(action: { benchmarkNoCache() }) {
                    Text("캐시 없음만")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isRunning)
                
                Button(action: { benchmarkCached() }) {
                    Text("캐시 적용만")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isRunning)
            }
            
            Button(action: reset) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("초기화")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📝 벤치마크 정보")
                .font(.headline)
            
            Text("• 반복 횟수: \(iterations)회")
                .font(.caption)
            Text("• 측정 항목: 평균, 최소, 최대, 총합")
                .font(.caption)
            Text("• 캐시 히트율 추적")
                .font(.caption)
            
            Divider()
            
            Text("💡 팁")
                .font(.headline)
            Text("• 전체 벤치마크: 순차적으로 모든 테스트 실행")
                .font(.caption)
            Text("• 개별 테스트: 원하는 테스트만 실행")
                .font(.caption)
            Text("• 2회 이상 실행 시 캐시 효과 극대화")
                .font(.caption)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 액션
    
    private func runFullBenchmark() {
        reset()
        
        Task {
            isRunning = true
            
            // 1단계: 캐시 없음 테스트
            currentTest = "캐시 없음 테스트 중... (1/2)"
            await benchmarkNoCacheAsync()
            
            // 2단계: 캐시 적용 테스트
            currentTest = "캐시 적용 테스트 중... (2/2)"
            await benchmarkCachedAsync()
            
            currentTest = "완료!"
            isRunning = false
        }
    }
    
    private func benchmarkNoCache() {
        Task {
            isRunning = true
            currentTest = "캐시 없음 테스트 중..."
            noCacheStats.reset()
            await benchmarkNoCacheAsync()
            isRunning = false
        }
    }
    
    private func benchmarkCached() {
        Task {
            isRunning = true
            currentTest = "캐시 적용 테스트 중..."
            cachedStats.reset()
            await benchmarkCachedAsync()
            isRunning = false
        }
    }
    
    private func benchmarkNoCacheAsync() async {
        for i in 0..<iterations {
            let duration = await measureAsync {
                await withCheckedContinuation { continuation in
                    SimpleImageLoader.shared.loadImage(from: testURL) { _ in
                        continuation.resume()
                    }
                }
            }
            
            noCacheStats.addSample(duration)
            progress = Double(i + 1) / Double(iterations) / 2.0  // 전체의 50%
        }
    }
    
    private func benchmarkCachedAsync() async {
        for i in 0..<iterations {
            let duration = await measureAsync {
                await withCheckedContinuation { continuation in
                    CachedImageLoader.shared.loadImage(from: testURL) { _ in
                        continuation.resume()
                    }
                }
            }
            
            cachedStats.addSample(duration)
            progress = 0.5 + Double(i + 1) / Double(iterations) / 2.0  // 50% ~ 100%
        }
    }
    
    private func measureAsync(block: () async -> Void) async -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        await block()
        return CFAbsoluteTimeGetCurrent() - start
    }
    
    private func reset() {
        noCacheStats.reset()
        cachedStats.reset()
        progress = 0
        currentTest = ""
        CachedImageLoader.shared.clearCache()
        CachedImageLoader.shared.resetStats()
    }
}

#Preview {
    BenchmarkView()
}

































