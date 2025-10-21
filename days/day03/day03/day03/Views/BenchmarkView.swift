//
//  BenchmarkView.swift
//  day03
//
//  Created on 2025-10-21.
//

import SwiftUI
import CoreImage
import Metal

/// 성능 비교 벤치마크 뷰
/// 필터 체인 vs 개별 렌더링 성능 측정
struct BenchmarkView: View {
    
    // MARK: - State
    
    @State private var results: [BenchmarkResult] = []
    @State private var isRunning = false
    @State private var currentTest = ""
    
    private let sampleImage = UIImage(named: "sample") ?? UIImage(systemName: "photo")!
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                explanationCard
                
                // 실행 버튼
                runButton
                
                // 진행 상태
                if isRunning {
                    progressView
                }
                
                // 결과 표시
                if !results.isEmpty {
                    resultsSection
                }
                
                // 테스트 설명
                testDescriptions
            }
            .padding()
        }
        .navigationTitle("벤치마크")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.blue)
                Text("성능 측정")
                    .font(.headline)
            }
            
            Text("다양한 시나리오에서 필터 체인의 성능을 측정합니다.")
                .font(.subheadline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("📊 측정 항목:")
                    .font(.caption)
                    .bold()
                Text("• Context 재사용 vs 매번 생성")
                    .font(.caption)
                Text("• Metal vs CPU 렌더링")
                    .font(.caption)
                Text("• 필터 체인 vs 개별 렌더링")
                    .font(.caption)
                Text("• 필터 개수별 성능")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var runButton: some View {
        Button(action: {
            Task {
                await runBenchmarks()
            }
        }) {
            HStack {
                if isRunning {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isRunning ? "측정 중..." : "벤치마크 시작")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isRunning ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isRunning)
    }
    
    private var progressView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text(currentTest)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var resultsSection: some View {
        VStack(spacing: 16) {
            Text("📊 측정 결과")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(results) { result in
                ResultCard(result: result)
            }
            
            // 요약
            summaryCard
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 핵심 발견")
                .font(.headline)
            
            if let contextResult = results.first(where: { $0.name.contains("Context") }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Context 재사용이 \(String(format: "%.1f", contextResult.improvement))배 빠름")
                        .font(.subheadline)
                }
            }
            
            if let chainResult = results.first(where: { $0.name.contains("필터 체인") }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("필터 체인이 \(String(format: "%.1f", chainResult.improvement))배 빠름")
                        .font(.subheadline)
                }
            }
            
            if let metalResult = results.first(where: { $0.name.contains("Metal") }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Metal이 \(String(format: "%.1f", metalResult.improvement))배 빠름")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var testDescriptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📖 테스트 설명")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TestDescriptionRow(
                    icon: "recycle",
                    title: "Context 재사용",
                    description: "CIContext 생성 비용이 매우 높으므로 재사용 필수"
                )
                
                TestDescriptionRow(
                    icon: "cpu",
                    title: "Metal vs CPU",
                    description: "Metal은 GPU 가속으로 CPU보다 5배 이상 빠름"
                )
                
                TestDescriptionRow(
                    icon: "link",
                    title: "필터 체인",
                    description: "여러 필터를 연결하여 한번에 렌더링하면 10배 이상 빠름"
                )
                
                TestDescriptionRow(
                    icon: "number",
                    title: "필터 개수",
                    description: "필터가 많을수록 체인의 성능 이점이 커짐"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    // MARK: - Benchmark Methods
    
    @MainActor
    private func runBenchmarks() async {
        isRunning = true
        results.removeAll()
        
        // 1. Context 재사용 테스트
        await testContextReuse()
        
        // 2. Metal vs CPU 테스트
        await testMetalVsCPU()
        
        // 3. 필터 체인 테스트
        await testFilterChain()
        
        // 4. 필터 개수별 성능
        await testFilterCount()
        
        isRunning = false
        currentTest = ""
    }
    
    @MainActor
    private func testContextReuse() async {
        currentTest = "Context 재사용 테스트 중..."
        
        guard let ciImage = CIImage(image: sampleImage) else { return }
        
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(10, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return }
        
        // 매번 생성
        let timeWithoutReuse = await measureTime(iterations: 10) {
            let context = CIContext()
            _ = context.createCGImage(output, from: ciImage.extent)
        }
        
        // 재사용
        let reusedContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        let timeWithReuse = await measureTime(iterations: 10) {
            _ = reusedContext.createCGImage(output, from: ciImage.extent)
        }
        
        results.append(BenchmarkResult(
            name: "Context 재사용",
            baseTime: timeWithoutReuse,
            optimizedTime: timeWithReuse,
            improvement: timeWithoutReuse / timeWithReuse
        ))
    }
    
    @MainActor
    private func testMetalVsCPU() async {
        currentTest = "Metal vs CPU 테스트 중..."
        
        guard let ciImage = CIImage(image: sampleImage) else { return }
        
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(10, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return }
        
        // CPU
        let cpuContext = CIContext(options: [.useSoftwareRenderer: true])
        let cpuTime = await measureTime(iterations: 10) {
            _ = cpuContext.createCGImage(output, from: ciImage.extent)
        }
        
        // Metal
        let metalContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        let metalTime = await measureTime(iterations: 10) {
            _ = metalContext.createCGImage(output, from: ciImage.extent)
        }
        
        results.append(BenchmarkResult(
            name: "Metal vs CPU",
            baseTime: cpuTime,
            optimizedTime: metalTime,
            improvement: cpuTime / metalTime
        ))
    }
    
    @MainActor
    private func testFilterChain() async {
        currentTest = "필터 체인 테스트 중..."
        
        guard let ciImage = CIImage(image: sampleImage) else { return }
        let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        // 매번 렌더링
        let individualTime = await measureTime(iterations: 10) {
            // 블러
            let blur = CIFilter(name: "CIGaussianBlur")!
            blur.setValue(ciImage, forKey: kCIInputImageKey)
            blur.setValue(10, forKey: kCIInputRadiusKey)
            guard let blurred = blur.outputImage,
                  let cgBlurred = context.createCGImage(blurred, from: ciImage.extent) else { return }
            let uiBlurred = UIImage(cgImage: cgBlurred)
            
            // 밝기
            guard let ciBlurred = CIImage(image: uiBlurred) else { return }
            let brightness = CIFilter(name: "CIColorControls")!
            brightness.setValue(ciBlurred, forKey: kCIInputImageKey)
            brightness.setValue(0.3, forKey: kCIInputBrightnessKey)
            guard let brightened = brightness.outputImage,
                  let cgBrightened = context.createCGImage(brightened, from: ciBlurred.extent) else { return }
            let uiBrightened = UIImage(cgImage: cgBrightened)
            
            // 채도
            guard let ciBrightened = CIImage(image: uiBrightened) else { return }
            let saturation = CIFilter(name: "CIColorControls")!
            saturation.setValue(ciBrightened, forKey: kCIInputImageKey)
            saturation.setValue(1.5, forKey: kCIInputSaturationKey)
            guard let saturated = saturation.outputImage else { return }
            _ = context.createCGImage(saturated, from: ciBrightened.extent)
        }
        
        // 필터 체인
        let chainTime = await measureTime(iterations: 10) {
            let blur = CIFilter(name: "CIGaussianBlur")!
            blur.setValue(ciImage, forKey: kCIInputImageKey)
            blur.setValue(10, forKey: kCIInputRadiusKey)
            
            let brightness = CIFilter(name: "CIColorControls")!
            brightness.setValue(blur.outputImage, forKey: kCIInputImageKey)
            brightness.setValue(0.3, forKey: kCIInputBrightnessKey)
            
            let saturation = CIFilter(name: "CIColorControls")!
            saturation.setValue(brightness.outputImage, forKey: kCIInputImageKey)
            saturation.setValue(1.5, forKey: kCIInputSaturationKey)
            
            guard let final = saturation.outputImage else { return }
            _ = context.createCGImage(final, from: ciImage.extent)
        }
        
        results.append(BenchmarkResult(
            name: "필터 체인 vs 개별 렌더링",
            baseTime: individualTime,
            optimizedTime: chainTime,
            improvement: individualTime / chainTime
        ))
    }
    
    @MainActor
    private func testFilterCount() async {
        currentTest = "필터 개수별 성능 테스트 중..."
        
        guard let ciImage = CIImage(image: sampleImage) else { return }
        let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        // 1개 필터
        let time1 = await measureTime(iterations: 10) {
            let filter = CIFilter(name: "CIGaussianBlur")!
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(10, forKey: kCIInputRadiusKey)
            guard let output = filter.outputImage else { return }
            _ = context.createCGImage(output, from: ciImage.extent)
        }
        
        // 3개 필터 (체인)
        let time3 = await measureTime(iterations: 10) {
            let filter1 = CIFilter(name: "CIGaussianBlur")!
            filter1.setValue(ciImage, forKey: kCIInputImageKey)
            filter1.setValue(10, forKey: kCIInputRadiusKey)
            
            let filter2 = CIFilter(name: "CIColorControls")!
            filter2.setValue(filter1.outputImage, forKey: kCIInputImageKey)
            filter2.setValue(0.3, forKey: kCIInputBrightnessKey)
            
            let filter3 = CIFilter(name: "CIColorControls")!
            filter3.setValue(filter2.outputImage, forKey: kCIInputImageKey)
            filter3.setValue(1.5, forKey: kCIInputSaturationKey)
            
            guard let output = filter3.outputImage else { return }
            _ = context.createCGImage(output, from: ciImage.extent)
        }
        
        // 5개 필터 (체인)
        let time5 = await measureTime(iterations: 10) {
            var current = ciImage
            
            for i in 0..<5 {
                let filter = CIFilter(name: i % 2 == 0 ? "CIGaussianBlur" : "CIColorControls")!
                filter.setValue(current, forKey: kCIInputImageKey)
                if i % 2 == 0 {
                    filter.setValue(5, forKey: kCIInputRadiusKey)
                } else {
                    filter.setValue(1.2, forKey: kCIInputSaturationKey)
                }
                guard let output = filter.outputImage else { break }
                current = output
            }
            
            _ = context.createCGImage(current, from: ciImage.extent)
        }
        
        results.append(BenchmarkResult(
            name: "필터 개수 (1개 → 3개)",
            baseTime: time1,
            optimizedTime: time3,
            improvement: time1 / time3,
            isInverse: true
        ))
        
        results.append(BenchmarkResult(
            name: "필터 개수 (1개 → 5개)",
            baseTime: time1,
            optimizedTime: time5,
            improvement: time1 / time5,
            isInverse: true
        ))
    }
    
    private func measureTime(iterations: Int, block: () -> Void) async -> TimeInterval {
        let start = Date()
        for _ in 0..<iterations {
            block()
        }
        let end = Date()
        return end.timeIntervalSince(start) / Double(iterations)
    }
}

// MARK: - Benchmark Result

struct BenchmarkResult: Identifiable {
    let id = UUID()
    let name: String
    let baseTime: TimeInterval
    let optimizedTime: TimeInterval
    let improvement: Double
    var isInverse: Bool = false // 역비교 (많아질수록 나빠지는 경우)
}

// MARK: - Result Card

struct ResultCard: View {
    let result: BenchmarkResult
    
    var body: some View {
        VStack(spacing: 12) {
            Text(result.name)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text(result.isInverse ? "기준" : "Before")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", result.baseTime * 1000))ms")
                        .font(.title3)
                        .bold()
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text(result.isInverse ? "비교" : "After")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", result.optimizedTime * 1000))ms")
                        .font(.title3)
                        .bold()
                        .foregroundColor(result.isInverse ? (result.improvement > 1 ? .orange : .green) : .green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(result.isInverse ? "증가율" : "개선율")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1fx", result.improvement))")
                        .font(.title2)
                        .bold()
                        .foregroundColor(result.isInverse ? (result.improvement > 1 ? .orange : .green) : .green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Test Description Row

struct TestDescriptionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        BenchmarkView()
    }
}

