//
//  FormatComparisonView.swift
//  day05
//
//  포맷 비교 (JPEG/PNG/HEIC) 뷰
//

import SwiftUI

struct FormatComparisonView: View {
    @State private var results: [FormatConverter.BenchmarkResult] = []
    @State private var isProcessing = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    private let formats: [ImageFormat] = [
        .jpeg(quality: 1.0),
        .jpeg(quality: 0.9),
        .jpeg(quality: 0.8),
        .jpeg(quality: 0.7),
        .jpeg(quality: 0.5),
        .png,
        .heic(quality: 0.9),
        .heic(quality: 0.8),
        .heic(quality: 0.7)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                headerSection
                
                // 이미지 선택
                imageSelectionSection
                
                // 비교 버튼
                compareButton
                
                // 결과
                if !results.isEmpty {
                    resultsSection
                }
                
                // 설명
                descriptionSection
            }
            .padding()
        }
        .navigationTitle("포맷 비교")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("JPEG vs PNG vs HEIC")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("동일한 이미지를 여러 포맷과 품질로 변환하여 파일 크기와 시간을 비교합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("테스트 이미지")
                .font(.headline)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("크기: \(Int(image.size.width)) × \(Int(image.size.height))")
                            .font(.caption)
                        Text("원본 메모리: \(formatBytes(Int(image.size.width * image.size.height * 4)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } else {
                Button(action: loadSampleImage) {
                    HStack {
                        Image(systemName: "photo")
                        Text("샘플 이미지 로드")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var compareButton: some View {
        Button(action: runComparison) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(isProcessing ? "변환 중..." : "포맷 비교 시작")
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
            
            // 파일 크기 차트
            fileSizeChart
            
            // 상세 결과
            ForEach(results.sorted(by: { $0.fileSize < $1.fileSize }), id: \.format.displayName) { result in
                resultCard(result)
            }
            
            // 비교 요약
            comparisonSummary
        }
    }
    
    private var fileSizeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("파일 크기 비교")
                .font(.headline)
            
            let maxSize = results.map(\.fileSize).max() ?? 1
            let baseline = results.first(where: { 
                if case .jpeg(quality: 1.0) = $0.format { return true }
                return false
            })?.fileSize ?? maxSize
            
            ForEach(results.sorted(by: { $0.fileSize < $1.fileSize }), id: \.format.displayName) { result in
                HStack {
                    Text(result.format.displayName)
                        .frame(width: 100, alignment: .leading)
                        .font(.caption)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(colorForFormat(result.format))
                                .frame(width: geometry.size.width * CGFloat(Double(result.fileSize) / Double(maxSize)))
                            
                            Spacer()
                        }
                    }
                    .frame(height: 20)
                    
                    Text(result.formattedFileSize)
                        .font(.caption)
                        .frame(width: 70, alignment: .trailing)
                    
                    Text(String(format: "%.0f%%", result.sizeRatio(baseline: baseline) * 100))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func resultCard(_ result: FormatConverter.BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.format.displayName)
                    .font(.headline)
                Spacer()
                if result.fileSize == results.map(\.fileSize).min() {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("파일 크기", systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.formattedFileSize)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("변환 시간", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.formattedDuration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var comparisonSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("요약")
                .font(.headline)
            
            if let smallest = results.min(by: { $0.fileSize < $1.fileSize }) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    Text("가장 작음: \(smallest.format.displayName) (\(smallest.formattedFileSize))")
                }
            }
            
            if let fastest = results.min(by: { $0.duration < $1.duration }) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("가장 빠름: \(fastest.format.displayName) (\(fastest.formattedDuration))")
                }
            }
            
            // HEIC vs JPEG 비교
            if let jpegResult = results.first(where: { 
                if case .jpeg(quality: 0.9) = $0.format { return true }
                return false
            }),
               let heicResult = results.first(where: { 
                if case .heic(quality: 0.9) = $0.format { return true }
                return false
            }) {
                Divider()
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("HEIC가 JPEG보다 \(String(format: "%.0f%%", (1 - heicResult.sizeRatio(baseline: jpegResult.fileSize)) * 100)) 작음")
                        Text("동일 품질(90%)에서 비교")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("포맷 특징")
                .font(.headline)
            
            FormatDescriptionRow(
                icon: "photo",
                color: .blue,
                title: "JPEG",
                description: "손실 압축. 사진에 최적. 투명도 미지원."
            )
            
            FormatDescriptionRow(
                icon: "square.stack",
                color: .green,
                title: "PNG",
                description: "무손실 압축. 투명도 지원. 파일 크기 큼."
            )
            
            FormatDescriptionRow(
                icon: "sparkles",
                color: .purple,
                title: "HEIC",
                description: "고효율 압축. JPEG보다 40~50% 작음. iOS 11+."
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Actions
    
    private func loadSampleImage() {
        selectedImage = UIImage(named: "sample")
    }
    
    private func runComparison() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        results = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            var benchmarkResults: [FormatConverter.BenchmarkResult] = []
            
            for format in formats {
                autoreleasepool {
                    let result = FormatConverter.benchmark(image, format: format)
                    benchmarkResults.append(result)
                    
                    PerformanceLogger.log(
                        "[\(format.displayName)] \(result.formattedFileSize), \(result.formattedDuration)",
                        category: "format"
                    )
                }
            }
            
            DispatchQueue.main.async {
                results = benchmarkResults
                isProcessing = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private func colorForFormat(_ format: ImageFormat) -> Color {
        switch format {
        case .jpeg: return .blue
        case .png: return .green
        case .heic: return .purple
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Helper Views

struct FormatDescriptionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
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
        FormatComparisonView()
    }
}

