//
//  QualityBenchmarkView.swift
//  day05
//
//  품질별 파일 크기 벤치마크 뷰
//

import SwiftUI
import Charts

struct QualityBenchmarkView: View {
    @State private var results: [(quality: Double, size: Int, duration: TimeInterval)] = []
    @State private var isProcessing = false
    @State private var selectedFormat: ImageFormat = .jpeg(quality: 1.0)
    @State private var selectedImage: UIImage?
    
    private let qualities: [Double] = stride(from: 0.1, through: 1.0, by: 0.1).map { $0 }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                headerSection
                
                // 포맷 선택
                formatSelectionSection
                
                // 이미지 선택
                imageSection
                
                // 벤치마크 버튼
                benchmarkButton
                
                // 결과
                if !results.isEmpty {
                    resultsSection
                }
                
                // 설명
                descriptionSection
            }
            .padding()
        }
        .navigationTitle("품질 벤치마크")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedImage = UIImage(named: "sample")
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("품질 vs 파일 크기")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("압축 품질(10%~100%)에 따른 파일 크기 변화를 측정합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("포맷 선택")
                .font(.headline)
            
            HStack {
                FormatButton(title: "JPEG", isSelected: isJPEG) {
                    selectedFormat = .jpeg(quality: 1.0)
                }
                
                FormatButton(title: "HEIC", isSelected: isHEIC) {
                    selectedFormat = .heic(quality: 1.0)
                }
                
                Spacer()
            }
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("테스트 이미지")
                .font(.headline)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .cornerRadius(12)
                
                Text("크기: \(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var benchmarkButton: some View {
        Button(action: runBenchmark) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
                Text(isProcessing ? "측정 중..." : "품질별 측정 시작")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedImage == nil || isProcessing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(selectedImage == nil || isProcessing)
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("결과")
                .font(.title3)
                .fontWeight(.bold)
            
            // 그래프
            chartView
            
            // 데이터 테이블
            dataTable
            
            // 최적 포인트 추천
            recommendationView
        }
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("파일 크기 그래프")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(results, id: \.quality) { result in
                        LineMark(
                            x: .value("품질", result.quality * 100),
                            y: .value("크기", Double(result.size) / 1_000_000.0)
                        )
                        .foregroundStyle(isJPEG ? Color.blue : Color.purple)
                        
                        PointMark(
                            x: .value("품질", result.quality * 100),
                            y: .value("크기", Double(result.size) / 1_000_000.0)
                        )
                        .foregroundStyle(isJPEG ? Color.blue : Color.purple)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: [10, 30, 50, 70, 90, 100])
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let mb = value.as(Double.self) {
                                Text("\(String(format: "%.1f", mb)) MB")
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            } else {
                // iOS 15 이하 폴백
                VStack {
                    ForEach(results, id: \.quality) { result in
                        HStack {
                            Text("\(Int(result.quality * 100))%")
                                .frame(width: 40)
                            
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(isJPEG ? Color.blue : Color.purple)
                                    .frame(width: geometry.size.width * CGFloat(result.size) / CGFloat(results.map(\.size).max() ?? 1))
                            }
                            .frame(height: 20)
                            
                            Text(formatBytes(result.size))
                                .font(.caption)
                                .frame(width: 70, alignment: .trailing)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    private var dataTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("상세 데이터")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // 헤더
                    HStack {
                        Text("품질")
                            .frame(width: 60, alignment: .center)
                            .fontWeight(.semibold)
                        Text("파일 크기")
                            .frame(width: 100, alignment: .center)
                            .fontWeight(.semibold)
                        Text("시간")
                            .frame(width: 80, alignment: .center)
                            .fontWeight(.semibold)
                        Text("상대 크기")
                            .frame(width: 80, alignment: .center)
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // 데이터 행
                    ForEach(results, id: \.quality) { result in
                        HStack {
                            Text("\(Int(result.quality * 100))%")
                                .frame(width: 60, alignment: .center)
                            
                            Text(formatBytes(result.size))
                                .frame(width: 100, alignment: .center)
                            
                            Text(String(format: "%.0f ms", result.duration * 1000))
                                .frame(width: 80, alignment: .center)
                            
                            if let maxSize = results.map(\.size).max() {
                                Text(String(format: "%.0f%%", Double(result.size) / Double(maxSize) * 100))
                                    .frame(width: 80, alignment: .center)
                            }
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var recommendationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("추천")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                RecommendationRow(
                    quality: 0.9,
                    purpose: "고품질 저장",
                    description: "화질 손실 최소화"
                )
                
                RecommendationRow(
                    quality: 0.8,
                    purpose: "일반 저장",
                    description: "균형잡힌 크기와 품질"
                )
                
                RecommendationRow(
                    quality: 0.7,
                    purpose: "웹 업로드",
                    description: "빠른 업로드와 적당한 품질"
                )
                
                RecommendationRow(
                    quality: 0.5,
                    purpose: "썸네일",
                    description: "작은 크기 우선"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 팁")
                .font(.headline)
            
            Text("• Quality 0.8~0.9: 대부분의 사용 사례에 적합")
            Text("• Quality 0.7 이하: 눈에 띄는 화질 저하 가능")
            Text("• Quality 1.0: 파일 크기 대비 화질 개선 미미")
            Text("• HEIC가 동일 품질에서 JPEG보다 40~50% 작음")
        }
        .font(.caption)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Actions
    
    private func runBenchmark() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        results = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            var benchmarkResults: [(quality: Double, size: Int, duration: TimeInterval)] = []
            
            for quality in qualities {
                autoreleasepool {
                    let format: ImageFormat
                    if isJPEG {
                        format = .jpeg(quality: quality)
                    } else {
                        format = .heic(quality: quality)
                    }
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    if let data = FormatConverter.convert(image, to: format) {
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        benchmarkResults.append((quality: quality, size: data.count, duration: duration))
                    }
                }
            }
            
            DispatchQueue.main.async {
                results = benchmarkResults
                isProcessing = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isJPEG: Bool {
        if case .jpeg = selectedFormat {
            return true
        }
        return false
    }
    
    private var isHEIC: Bool {
        if case .heic = selectedFormat {
            return true
        }
        return false
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
}

// MARK: - Helper Views

struct FormatButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct RecommendationRow: View {
    let quality: Double
    let purpose: String
    let description: String
    
    var body: some View {
        HStack {
            Text("\(Int(quality * 100))%")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(purpose)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        QualityBenchmarkView()
    }
}

