//
//  BenchmarkView.swift
//  day13
//
//  Created on 11/10/25.
//

import SwiftUI
import Charts

struct BenchmarkView: View {
    @EnvironmentObject var imageLoader: ImageLoader
    @State private var isRunning = false
    @State private var results: [BenchmarkResult] = []
    @State private var progress: Double = 0
    
    private let metalProcessor = MetalBlurProcessor()
    private let coreImageProcessor = CoreImageBlurProcessor()
    
    // 테스트 조합
    private let imageSizes: [BenchmarkResult.ImageSize] = [.small, .medium, .large]
    private let radii: [Int] = [5, 10, 15, 20]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 벤치마크 시작 버튼
                VStack(spacing: 15) {
                    Text("성능 벤치마크")
                        .font(.headline)
                    
                    Text("다양한 이미지 크기와 블러 반경에 대해\nMetal과 Core Image의 성능을 비교합니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if isRunning {
                        VStack(spacing: 10) {
                            ProgressView(value: progress)
                            Text("\(Int(progress * 100))% 완료")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: runBenchmark) {
                            HStack {
                                Image(systemName: "speedometer")
                                Text("벤치마크 시작")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(imageLoader.currentImage == nil)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 결과 표시
                if !results.isEmpty {
                    resultsSection
                }
                
                // 안내 메시지
                if imageLoader.currentImage == nil {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("이미지를 먼저 로드해주세요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                }
            }
            .padding()
        }
        .navigationTitle("벤치마크")
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 차트
            if #available(iOS 16.0, *) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("처리 시간 비교")
                        .font(.headline)
                    
                    Chart {
                        ForEach(results) { result in
                            BarMark(
                                x: .value("설정", "\(result.imageSize.rawValue)\nr=\(result.radius)"),
                                y: .value("시간", result.metalTime)
                            )
                            .foregroundStyle(.blue)
                            .position(by: .value("방식", "Metal"))
                            
                            BarMark(
                                x: .value("설정", "\(result.imageSize.rawValue)\nr=\(result.radius)"),
                                y: .value("시간", result.coreImageTime)
                            )
                            .foregroundStyle(.orange)
                            .position(by: .value("방식", "Core Image"))
                        }
                    }
                    .chartYAxisLabel("처리 시간 (ms)")
                    .frame(height: 300)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            
            // 상세 결과 테이블
            VStack(alignment: .leading, spacing: 10) {
                Text("상세 결과")
                    .font(.headline)
                
                ForEach(imageSizes, id: \.self) { size in
                    sizeGroupView(size: size)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // 종합 분석
            summaryView
        }
    }
    
    private func sizeGroupView(size: BenchmarkResult.ImageSize) -> some View {
        let sizeResults = results.filter { $0.imageSize == size }
        
        return VStack(alignment: .leading, spacing: 10) {
            Text(size.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(sizeResults) { result in
                HStack {
                    Text("반경 \(result.radius)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("Metal")
                                .font(.caption2)
                            Spacer()
                            Text(String(format: "%.2f ms", result.metalTime))
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Core Image")
                                .font(.caption2)
                            Spacer()
                            Text(String(format: "%.2f ms", result.coreImageTime))
                                .font(.caption)
                                .monospacedDigit()
                        }
                    }
                    
                    VStack(alignment: .trailing) {
                        Text(result.winner)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(result.winner == "Metal" ? .blue : .orange)
                        Text(String(format: "%.1f×", result.speedup))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("종합 분석")
                .font(.headline)
            
            let metalAvg = results.map { $0.metalTime }.reduce(0, +) / Double(results.count)
            let coreImageAvg = results.map { $0.coreImageTime }.reduce(0, +) / Double(results.count)
            let avgSpeedup = coreImageAvg / metalAvg
            
            VStack(spacing: 10) {
                SummaryRow(
                    title: "Metal 평균",
                    value: String(format: "%.2f ms", metalAvg),
                    color: .blue
                )
                SummaryRow(
                    title: "Core Image 평균",
                    value: String(format: "%.2f ms", coreImageAvg),
                    color: .orange
                )
                SummaryRow(
                    title: "평균 속도 향상",
                    value: String(format: "%.1f배", avgSpeedup),
                    color: metalAvg < coreImageAvg ? .blue : .orange
                )
            }
            
            Text("💡 인사이트")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 8) {
                if metalAvg < coreImageAvg {
                    InsightText(text: "Metal이 Core Image보다 평균 \(String(format: "%.1f", avgSpeedup))배 빠릅니다")
                    InsightText(text: "GPU 기반 처리의 장점이 명확히 드러납니다")
                    InsightText(text: "이미지 크기가 클수록 Metal의 이점이 더 커집니다")
                } else {
                    InsightText(text: "Core Image가 더 빠른 결과를 보입니다")
                    InsightText(text: "하드웨어 가속 및 최적화가 잘 되어 있습니다")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func runBenchmark() {
        guard let baseImage = imageLoader.currentImage else { return }
        
        isRunning = true
        results = []
        progress = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let totalTests = imageSizes.count * radii.count
            var completed = 0
            var newResults: [BenchmarkResult] = []
            
            for size in imageSizes {
                // 이미지 리사이즈
                let resizedImage = resizeImage(baseImage, to: CGSize(
                    width: size.pixels,
                    height: size.pixels
                ))
                
                for radius in radii {
                    // Metal 테스트
                    let metalResult = metalProcessor?.blur(image: resizedImage, radius: radius)
                    let metalTime = metalResult?.processingTime ?? 0
                    
                    // Core Image 테스트
                    let coreImageResult = coreImageProcessor.blur(image: resizedImage, radius: radius)
                    let coreImageTime = coreImageResult?.processingTime ?? 0
                    
                    let result = BenchmarkResult(
                        imageSize: size,
                        radius: radius,
                        metalTime: metalTime,
                        coreImageTime: coreImageTime
                    )
                    newResults.append(result)
                    
                    completed += 1
                    DispatchQueue.main.async {
                        progress = Double(completed) / Double(totalTests)
                    }
                }
            }
            
            DispatchQueue.main.async {
                results = newResults
                isRunning = false
                progress = 1.0
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

struct InsightText: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

