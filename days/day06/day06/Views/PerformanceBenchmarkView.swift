//
//  PerformanceBenchmarkView.swift
//  day06
//
//  성능 벤치마크 뷰 - 렌더링 옵션별 성능 측정
//

import SwiftUI

struct PerformanceBenchmarkView: View {
    @State private var benchmarkResults: [BenchmarkResult] = []
    @State private var isRunning = false
    @State private var currentMemory = ""
    @State private var showGrid = false
    @State private var gridInterpolation: Image.Interpolation = .medium
    
    private let imageCount = 100
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 제목 및 설명
                headerSection
                
                // 메모리 사용량
                memorySection
                
                // 벤치마크 실행 버튼
                runBenchmarkButton
                
                // 결과 테이블
                if !benchmarkResults.isEmpty {
                    resultsSection
                }
                
                // 그리드 테스트
                gridTestSection
                
                // 성능 팁
                performanceTips
            }
            .padding()
        }
        .navigationTitle("성능 벤치마크")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateMemory()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("⚡ 성능 벤치마크")
                .font(.largeTitle)
                .bold()
            
            Text("렌더링 옵션별 성능 측정")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Memory Section
    
    private var memorySection: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.blue)
                Text("현재 메모리 사용량")
                    .font(.headline)
                Spacer()
                Text(currentMemory)
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            Button("메모리 업데이트") {
                updateMemory()
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Run Benchmark Button
    
    private var runBenchmarkButton: some View {
        Button(action: runBenchmark) {
            HStack {
                if isRunning {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isRunning ? "측정 중..." : "벤치마크 실행")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isRunning ? Color.gray : Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(isRunning)
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("측정 결과")
                .font(.title2)
                .bold()
            
            Text("100개 이미지 렌더링 시간")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 1) {
                // 헤더
                HStack {
                    Text("보간 품질")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("시간")
                        .font(.caption)
                        .frame(width: 80, alignment: .trailing)
                    Text("상대")
                        .font(.caption)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                
                ForEach(benchmarkResults) { result in
                    resultRow(result)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            Divider()
            
            // 요약
            if let fastest = benchmarkResults.min(by: { $0.time < $1.time }),
               let slowest = benchmarkResults.max(by: { $0.time < $1.time }) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("⚡ 가장 빠름:")
                        Spacer()
                        Text("\(fastest.interpolation.name) (\(String(format: "%.0f", fastest.time))ms)")
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Text("🐢 가장 느림:")
                        Spacer()
                        Text("\(slowest.interpolation.name) (\(String(format: "%.0f", slowest.time))ms)")
                            .foregroundStyle(.red)
                    }
                    
                    HStack {
                        Text("📊 속도 차이:")
                        Spacer()
                        Text("\(String(format: "%.1f", slowest.time / fastest.time))배")
                            .foregroundStyle(.blue)
                    }
                }
                .font(.caption)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func resultRow(_ result: BenchmarkResult) -> some View {
        let fastest = benchmarkResults.min(by: { $0.time < $1.time })?.time ?? 1
        let ratio = result.time / fastest
        
        return HStack {
            HStack {
                Circle()
                    .fill(colorForRatio(ratio))
                    .frame(width: 8, height: 8)
                Text(result.interpolation.name)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(String(format: "%.0fms", result.time))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            Text(String(format: "%.1fx", ratio))
                .font(.caption)
                .foregroundStyle(colorForRatio(ratio))
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private func colorForRatio(_ ratio: Double) -> Color {
        switch ratio {
        case 1.0...1.5: return .green
        case 1.5...3.0: return .yellow
        default: return .red
        }
    }
    
    // MARK: - Grid Test Section
    
    private var gridTestSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("스크롤 그리드 테스트")
                .font(.title2)
                .bold()
            
            Text("실제 스크롤 성능 확인")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("Interpolation", selection: $gridInterpolation) {
                ForEach(InterpolationHelper.allInterpolations, id: \.self) { interpolation in
                    Text(interpolation.name).tag(interpolation)
                }
            }
            .pickerStyle(.segmented)
            
            Toggle(isOn: $showGrid) {
                Text("그리드 표시 (\(imageCount)개 이미지)")
                    .font(.headline)
            }
            
            if showGrid {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(0..<imageCount, id: \.self) { index in
                            Image(systemName: "photo.fill")
                                .resizable()
                                .interpolation(gridInterpolation)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                }
                .frame(height: 400)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                Text("💡 스크롤해보며 끊김 현상을 확인하세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Performance Tips
    
    private var performanceTips: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("💡 성능 최적화 팁")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "1.circle.fill", text: "스크롤 뷰는 .medium 권장")
                tipRow(icon: "2.circle.fill", text: "정적 화면은 .high 사용 가능")
                tipRow(icon: "3.circle.fill", text: "LazyVStack/LazyHStack 사용")
                tipRow(icon: "4.circle.fill", text: "clipped()로 넘친 부분 제거")
                tipRow(icon: "5.circle.fill", text: "실기기에서 테스트 필수")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
    
    // MARK: - Functions
    
    private func updateMemory() {
        currentMemory = MemorySampler.formattedUsage()
    }
    
    private func runBenchmark() {
        isRunning = true
        benchmarkResults.removeAll()
        
        // 백그라운드 스레드에서 실행
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [BenchmarkResult] = []
            
            for interpolation in InterpolationHelper.allInterpolations {
                let helper = Signpost.interpolation(label: interpolation.name)
                
                let startTime = Date()
                helper.begin()
                
                // 100개 이미지 렌더링 시뮬레이션
                for _ in 0..<imageCount {
                    // 실제로는 렌더링이 일어나야 하지만
                    // 여기서는 시뮬레이션
                    Thread.sleep(forTimeInterval: interpolation.estimatedRenderTime / 100000.0)
                }
                
                helper.end()
                let elapsed = Date().timeIntervalSince(startTime) * 1000 // ms
                
                results.append(BenchmarkResult(
                    interpolation: interpolation,
                    time: elapsed
                ))
                
                PerformanceLogger.log(
                    "[\(interpolation.name)] \(imageCount)개 렌더링: \(String(format: "%.0f", elapsed))ms",
                    category: "benchmark"
                )
            }
            
            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                benchmarkResults = results
                isRunning = false
                updateMemory()
            }
        }
    }
}

// MARK: - Benchmark Result

struct BenchmarkResult: Identifiable {
    let id = UUID()
    let interpolation: Image.Interpolation
    let time: Double  // milliseconds
}

#Preview {
    NavigationStack {
        PerformanceBenchmarkView()
    }
}


