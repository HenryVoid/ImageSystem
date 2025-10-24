//
//  ResizeMethodsView.swift
//  day05
//
//  4가지 리사이즈 방법 비교 뷰
//

import SwiftUI

struct ResizeMethodsView: View {
    @State private var results: [ImageResizer.BenchmarkResult] = []
    @State private var isProcessing = false
    @State private var targetSize = CGSize(width: 1000, height: 1000)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                headerSection
                
                // 크기 설정
                sizeControlSection
                
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
        .navigationTitle("리사이즈 방법 비교")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("4가지 리사이즈 방법")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("동일한 이미지를 4가지 방법으로 리사이즈하여 성능을 비교합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var sizeControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("타겟 크기")
                .font(.headline)
            
            HStack {
                Text("너비:")
                Slider(value: Binding(
                    get: { targetSize.width },
                    set: { targetSize.width = $0 }
                ), in: 100...2000, step: 100)
                Text("\(Int(targetSize.width))px")
                    .frame(width: 60, alignment: .trailing)
            }
            
            HStack {
                Text("높이:")
                Slider(value: Binding(
                    get: { targetSize.height },
                    set: { targetSize.height = $0 }
                ), in: 100...2000, step: 100)
                Text("\(Int(targetSize.height))px")
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var benchmarkButton: some View {
        Button(action: runBenchmark) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "play.circle.fill")
                }
                Text(isProcessing ? "측정 중..." : "벤치마크 시작")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isProcessing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isProcessing)
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("결과")
                .font(.title3)
                .fontWeight(.bold)
            
            // 차트
            chartView
            
            // 상세 결과
            ForEach(results.sorted(by: { $0.duration < $1.duration }), id: \.method.rawValue) { result in
                resultCard(result)
            }
            
            // 결론
            conclusionView
        }
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("처리 시간 비교")
                .font(.headline)
            
            let maxDuration = results.map(\.duration).max() ?? 1.0
            
            ForEach(results.sorted(by: { $0.duration < $1.duration }), id: \.method.rawValue) { result in
                HStack {
                    Text(result.method.rawValue)
                        .frame(width: 120, alignment: .leading)
                        .font(.caption)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(colorForMethod(result.method))
                                .frame(width: geometry.size.width * CGFloat(result.duration / maxDuration))
                            
                            Spacer()
                        }
                    }
                    .frame(height: 20)
                    
                    Text(result.formattedDuration)
                        .font(.caption)
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func resultCard(_ result: ImageResizer.BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.method.rawValue)
                    .font(.headline)
                Spacer()
                if result.duration == results.map(\.duration).min() {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(result.method.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("시간", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.formattedDuration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("메모리", systemImage: "memorychip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.formattedMemory)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("크기", systemImage: "photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.formattedSize)
                        .font(.caption)
                }
            }
            
            // 이미지 미리보기
            if let image = result.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var conclusionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("결론")
                .font(.headline)
            
            if let fastest = results.min(by: { $0.duration < $1.duration }) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("가장 빠름: \(fastest.method.rawValue)")
                }
            }
            
            if let memEfficient = results.min(by: { $0.memoryUsed < $1.memoryUsed }) {
                HStack {
                    Image(systemName: "memorychip.fill")
                        .foregroundColor(.green)
                    Text("메모리 효율: \(memEfficient.method.rawValue)")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("방법별 특징")
                .font(.headline)
            
            ForEach(ResizeMethod.allCases, id: \.rawValue) { method in
                HStack(alignment: .top) {
                    Circle()
                        .fill(colorForMethod(method))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(method.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(method.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Actions
    
    private func runBenchmark() {
        isProcessing = true
        results = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 샘플 이미지 로드
            guard let sampleImage = UIImage(named: "sample") else {
                DispatchQueue.main.async {
                    isProcessing = false
                }
                return
            }
            
            var benchmarkResults: [ImageResizer.BenchmarkResult] = []
            
            // 각 방법별로 벤치마크
            for method in ResizeMethod.allCases {
                autoreleasepool {
                    let result = ImageResizer.benchmark(
                        sampleImage,
                        to: targetSize,
                        method: method
                    )
                    benchmarkResults.append(result)
                    
                    PerformanceLogger.log(
                        "[\(method.rawValue)] \(result.formattedDuration), \(result.formattedMemory)",
                        category: "benchmark"
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
    
    private func colorForMethod(_ method: ResizeMethod) -> Color {
        switch method {
        case .uiGraphics: return .blue
        case .coreGraphics: return .green
        case .vImage: return .orange
        case .imageIO: return .purple
        }
    }
}

#Preview {
    NavigationView {
        ResizeMethodsView()
    }
}

