import SwiftUI
import Charts

struct ComparisonResultView: View {
    @StateObject private var downloader = ImageDownloader()
    @State private var comparisonResults: [CompressionResult] = []
    @State private var isGenerating = false
    @State private var selectedMetric: ComparisonMetric = .size
    
    enum ComparisonMetric: String, CaseIterable {
        case size = "파일 크기"
        case compression = "압축률"
        case time = "처리 시간"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if downloader.downloadedImage == nil {
                        loadImageSection
                    } else if comparisonResults.isEmpty {
                        generateSection
                    } else {
                        comparisonSection
                    }
                }
                .padding()
            }
            .navigationTitle("결과 비교")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !comparisonResults.isEmpty {
                        Button("초기화") {
                            reset()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Load Image Section
    
    private var loadImageSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("비교 분석을 시작하려면\n이미지를 로드하세요")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button(action: loadSampleImage) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("샘플 이미지 로드")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Generate Section
    
    private var generateSection: some View {
        VStack(spacing: 16) {
            if let image = downloader.downloadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(8)
            }
            
            Text("다양한 설정으로 압축하여\n비교 분석을 생성합니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: generateComparison) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text(isGenerating ? "생성 중..." : "비교 데이터 생성")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isGenerating ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isGenerating)
            
            if isGenerating {
                ProgressView("데이터 생성 중...")
            }
        }
    }
    
    // MARK: - Comparison Section
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 메트릭 선택
            Picker("비교 항목", selection: $selectedMetric) {
                ForEach(ComparisonMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // 차트
            chartSection
            
            Divider()
            
            // 분석 결과
            analysisSection
            
            Divider()
            
            // 추천
            recommendationSection
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedMetric.rawValue + " 비교")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(comparisonResults) { result in
                        BarMark(
                            x: .value("포맷", result.format.rawValue),
                            y: .value("값", metricValue(for: result))
                        )
                        .foregroundStyle(Color(result.format.color))
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // iOS 16 미만 폴백
                simpleBarChart
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Simple Bar Chart (Fallback)
    
    private var simpleBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(comparisonResults) { result in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(result.format.rawValue)
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        
                        GeometryReader { geometry in
                            let maxValue = comparisonResults.map { metricValue(for: $0) }.max() ?? 1
                            let width = geometry.size.width * (metricValue(for: result) / maxValue)
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color(result.format.color))
                                    .frame(width: width)
                                
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(height: 20)
                        
                        Text(metricValueString(for: result))
                            .font(.caption)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    
    // MARK: - Analysis Section
    
    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 비교")
                .font(.headline)
            
            VStack(spacing: 8) {
                // 헤더
                HStack {
                    Text("포맷")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 60, alignment: .leading)
                    
                    Text("크기")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("압축")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("시간")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(.secondary)
                
                Divider()
                
                // 데이터 행
                ForEach(comparisonResults.sorted(by: { $0.compressedSize < $1.compressedSize })) { result in
                    HStack {
                        Text(result.format.rawValue)
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(result.formattedCompressedSize)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(result.formattedCompressionRatio)
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(result.formattedCompressionTime)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Recommendation Section
    
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("추천")
                .font(.headline)
            
            if let analysis = CompressionAnalyzer.shared.analyze(results: comparisonResults).insights.first {
                Text(analysis)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("주요 인사이트:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(CompressionAnalyzer.shared.analyze(results: comparisonResults).insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(insight)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func metricValue(for result: CompressionResult) -> Double {
        switch selectedMetric {
        case .size:
            return Double(result.compressedSize)
        case .compression:
            return result.compressionPercentage
        case .time:
            return result.compressionTime * 1000 // ms
        }
    }
    
    private func metricValueString(for result: CompressionResult) -> String {
        switch selectedMetric {
        case .size:
            return result.formattedCompressedSize
        case .compression:
            return result.formattedCompressionRatio
        case .time:
            return result.formattedCompressionTime
        }
    }
    
    // MARK: - Actions
    
    private func loadSampleImage() {
        if let sample = downloader.loadSampleImage() {
            downloader.downloadedImage = sample
        }
    }
    
    private func generateComparison() {
        guard let image = downloader.downloadedImage else { return }
        
        isGenerating = true
        comparisonResults = []
        
        Task {
            let quality = 0.8 // 고정 품질로 포맷 비교
            
            for format in ImageFormat.allCases {
                if let result = await Task.detached(priority: .userInitiated) {
                    return ImageCompressor.shared.compress(image, format: format, quality: quality)
                }.value {
                    await MainActor.run {
                        comparisonResults.append(result)
                    }
                }
            }
            
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    private func reset() {
        downloader.clear()
        comparisonResults = []
    }
}

#Preview {
    ComparisonResultView()
}


