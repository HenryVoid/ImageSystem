import SwiftUI

struct BenchmarkView: View {
    @StateObject private var downloader = ImageDownloader()
    @State private var benchmarkResults: [CompressionResult] = []
    @State private var isRunning = false
    @State private var progress: Double = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 이미지 로드 섹션
                    if downloader.downloadedImage == nil {
                        loadImageSection
                    } else {
                        // 벤치마크 컨트롤
                        benchmarkControlSection
                        
                        // 결과 표시
                        if !benchmarkResults.isEmpty {
                            resultsSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("벤치마크")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !benchmarkResults.isEmpty {
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
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("벤치마크를 시작하려면\n이미지를 로드하세요")
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
    
    // MARK: - Benchmark Control Section
    
    private var benchmarkControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 원본 이미지
            if let image = downloader.downloadedImage {
                VStack(alignment: .leading) {
                    Text("테스트 이미지")
                        .font(.headline)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            // 벤치마크 정보
            VStack(alignment: .leading, spacing: 8) {
                Text("벤치마크 구성")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 4가지 포맷 (JPEG, PNG, HEIC, WebP)")
                    Text("• 3가지 품질 (High 90%, Medium 70%, Low 50%)")
                    Text("• 총 12개 조합 테스트")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // 벤치마크 버튼
            Button(action: runBenchmark) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text(isRunning ? "실행 중..." : "벤치마크 시작")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRunning ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isRunning)
            
            // 진행률
            if isRunning {
                VStack(spacing: 8) {
                    ProgressView(value: progress) {
                        Text("진행률")
                    }
                    Text("\(Int(progress * 100))% 완료")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("벤치마크 결과")
                .font(.headline)
                .padding(.horizontal)
            
            // 포맷별 그룹화
            let groupedResults = Dictionary(grouping: benchmarkResults) { $0.format }
            
            ForEach(ImageFormat.allCases, id: \.self) { format in
                if let results = groupedResults[format] {
                    formatResultCard(format: format, results: results)
                }
            }
            
            // 요약 통계
            summarySection
        }
    }
    
    // MARK: - Format Result Card
    
    private func formatResultCard(format: ImageFormat, results: [CompressionResult]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: format.icon)
                    .foregroundColor(Color(format.color))
                Text(format.rawValue)
                    .font(.headline)
                Spacer()
            }
            
            // 품질별 결과
            ForEach(results.sorted(by: { $0.quality > $1.quality })) { result in
                HStack {
                    // 품질
                    VStack(alignment: .leading) {
                        Text(qualityLabel(result.quality))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(Int(result.quality * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 60, alignment: .leading)
                    
                    Divider()
                    
                    // 크기
                    VStack(alignment: .leading) {
                        Text("크기")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(result.formattedCompressedSize)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 압축률
                    VStack(alignment: .leading) {
                        Text("압축")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(result.formattedCompressionRatio)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 시간
                    VStack(alignment: .leading) {
                        Text("시간")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(result.formattedCompressionTime)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("종합 분석")
                .font(.headline)
            
            let comparison = CompressionAnalyzer.shared.compareFormats(results: benchmarkResults)
            
            if !comparison.isEmpty {
                VStack(spacing: 8) {
                    // 최고 효율
                    if let best = comparison.first {
                        summaryRow(
                            title: "최고 압축 효율",
                            value: best.format.rawValue,
                            detail: "평균 \(String(format: "%.1f%%", best.averageCompression)) 압축",
                            color: .green
                        )
                    }
                    
                    // 최고 속도
                    let fastest = comparison.min(by: { $0.averageTime < $1.averageTime })
                    if let fastest = fastest {
                        summaryRow(
                            title: "최고 속도",
                            value: fastest.format.rawValue,
                            detail: "평균 \(String(format: "%.1f ms", fastest.averageTime * 1000))",
                            color: .blue
                        )
                    }
                    
                    // 최소 크기
                    let smallest = comparison.min(by: { $0.averageSize < $1.averageSize })
                    if let smallest = smallest {
                        summaryRow(
                            title: "최소 파일 크기",
                            value: smallest.format.rawValue,
                            detail: "평균 \(ByteCountFormatter.string(fromByteCount: Int64(smallest.averageSize), countStyle: .file))",
                            color: .orange
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func summaryRow(title: String, value: String, detail: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func qualityLabel(_ quality: Double) -> String {
        if quality >= 0.85 {
            return "High"
        } else if quality >= 0.65 {
            return "Medium"
        } else {
            return "Low"
        }
    }
    
    // MARK: - Actions
    
    private func loadSampleImage() {
        if let sample = downloader.loadSampleImage() {
            downloader.downloadedImage = sample
        }
    }
    
    private func runBenchmark() {
        guard let image = downloader.downloadedImage else { return }
        
        isRunning = true
        progress = 0
        benchmarkResults = []
        
        Task {
            let formats = ImageFormat.allCases
            let qualities = [0.9, 0.7, 0.5] // High, Medium, Low
            let total = formats.count * qualities.count
            var completed = 0
            
            for format in formats {
                for quality in qualities {
                    if let result = await Task.detached(priority: .userInitiated) {
                        return ImageCompressor.shared.compress(image, format: format, quality: quality)
                    }.value {
                        await MainActor.run {
                            benchmarkResults.append(result)
                            completed += 1
                            progress = Double(completed) / Double(total)
                        }
                    }
                }
            }
            
            await MainActor.run {
                isRunning = false
                progress = 1.0
            }
        }
    }
    
    private func reset() {
        downloader.clear()
        benchmarkResults = []
        progress = 0
    }
}

#Preview {
    BenchmarkView()
}


