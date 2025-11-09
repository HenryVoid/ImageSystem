//
//  ComparisonView.swift
//  day12
//
//  3가지 방식의 성능 비교 뷰
//

import SwiftUI
import Charts

/// 성능 비교 데이터
struct PerformanceComparison: Identifiable {
    let id = UUID()
    let method: String
    let fps: Double
    let memoryMB: Double
    let networkRequests: Int
    let loadTimeSec: Double
}

struct ComparisonView: View {
    @State private var comparisons: [PerformanceComparison] = []
    @State private var selectedMetric: MetricType = .fps
    @State private var isRunningBenchmark = false
    
    enum MetricType: String, CaseIterable {
        case fps = "FPS"
        case memory = "메모리 (MB)"
        case network = "네트워크 요청"
        case loadTime = "로드 시간 (초)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 타이틀
                headerView
                
                // 벤치마크 버튼
                benchmarkButton
                
                if !comparisons.isEmpty {
                    // 메트릭 선택
                    metricPicker
                    
                    // 차트 (iOS 16+)
                    if #available(iOS 16.0, *) {
                        chartView
                    }
                    
                    // 비교 테이블
                    comparisonTable
                    
                    // 분석 및 추천
                    analysisView
                }
            }
            .padding()
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("성능 비교")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("3가지 방식의 성능을 벤치마크하고 비교합니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var benchmarkButton: some View {
        Button(action: runBenchmark) {
            HStack {
                if isRunningBenchmark {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chart.bar.fill")
                }
                
                Text(isRunningBenchmark ? "벤치마크 실행 중..." : "벤치마크 시작")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isRunningBenchmark ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isRunningBenchmark)
    }
    
    private var metricPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("측정 항목")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        Button(action: {
                            selectedMetric = metric
                        }) {
                            Text(metric.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedMetric == metric ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedMetric == metric ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    @available(iOS 16.0, *)
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedMetric.rawValue)
                .font(.headline)
            
            Chart(comparisons) { comparison in
                BarMark(
                    x: .value("Method", comparison.method),
                    y: .value("Value", metricValue(for: comparison))
                )
                .foregroundStyle(barColor(for: comparison.method))
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var comparisonTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("상세 비교")
                .font(.headline)
            
            VStack(spacing: 1) {
                // 헤더
                HStack {
                    Text("방식")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("FPS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 60, alignment: .trailing)
                    
                    Text("메모리")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("네트워크")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(8)
                .background(Color.gray.opacity(0.2))
                
                // 데이터 행
                ForEach(comparisons) { comparison in
                    HStack {
                        Text(comparison.method)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(String(format: "%.0f", comparison.fps))
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 60, alignment: .trailing)
                        
                        Text(String(format: "%.0f MB", comparison.memoryMB))
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 70, alignment: .trailing)
                        
                        Text("\(comparison.networkRequests)")
                            .font(.system(.caption, design: .monospaced))
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(8)
                    .background(Color.white)
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var analysisView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("분석 및 추천")
                .font(.headline)
            
            if let best = getBestPerformer() {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("최고 성능: \(best.method)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("FPS \(String(format: "%.0f", best.fps)) • 메모리 \(String(format: "%.0f MB", best.memoryMB))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 추천 사항
            VStack(alignment: .leading, spacing: 8) {
                recommendationView(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "프리패칭",
                    description: "가장 부드러운 스크롤 경험 제공"
                )
                
                recommendationView(
                    icon: "bolt.circle.fill",
                    color: .blue,
                    title: "캐싱",
                    description: "재로드 시 40배 빠른 성능"
                )
                
                recommendationView(
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    title: "기본 방식",
                    description: "간단하지만 최적화 필요"
                )
            }
        }
    }
    
    private func recommendationView(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    
    private func runBenchmark() {
        isRunningBenchmark = true
        
        // 시뮬레이션된 벤치마크 결과
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            comparisons = [
                PerformanceComparison(
                    method: "기본",
                    fps: 48,
                    memoryMB: 120,
                    networkRequests: 100,
                    loadTimeSec: 18
                ),
                PerformanceComparison(
                    method: "캐싱",
                    fps: 55,
                    memoryMB: 145,
                    networkRequests: 100,
                    loadTimeSec: 0.5
                ),
                PerformanceComparison(
                    method: "프리패칭",
                    fps: 58,
                    memoryMB: 160,
                    networkRequests: 110,
                    loadTimeSec: 0.3
                )
            ]
            isRunningBenchmark = false
        }
    }
    
    private func metricValue(for comparison: PerformanceComparison) -> Double {
        switch selectedMetric {
        case .fps:
            return comparison.fps
        case .memory:
            return comparison.memoryMB
        case .network:
            return Double(comparison.networkRequests)
        case .loadTime:
            return comparison.loadTimeSec
        }
    }
    
    private func barColor(for method: String) -> Color {
        switch method {
        case "기본": return .orange
        case "캐싱": return .blue
        case "프리패칭": return .purple
        default: return .gray
        }
    }
    
    private func getBestPerformer() -> PerformanceComparison? {
        comparisons.max { a, b in
            // FPS가 높고 메모리가 낮은 것이 더 좋음
            let scoreA = a.fps - (a.memoryMB / 10)
            let scoreB = b.fps - (b.memoryMB / 10)
            return scoreA < scoreB
        }
    }
}

#Preview {
    ComparisonView()
}


