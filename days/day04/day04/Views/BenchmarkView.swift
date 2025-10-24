//
//  BenchmarkView.swift
//  day04
//
//  EXIF 읽기 성능을 측정하는 뷰
//

import SwiftUI
import ImageIO

struct BenchmarkView: View {
    @State private var results: [BenchmarkResult] = []
    @State private var isRunning = false
    @State private var progress: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚡ 성능 벤치마크")
                        .font(.title2)
                        .bold()
                    
                    Text("Image I/O의 EXIF 읽기 성능을 다양한 방법으로 측정합니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // 벤치마크 실행 버튼
                Button(action: runBenchmark) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isRunning ? "측정 중..." : "벤치마크 시작")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRunning)
                
                // 진행률
                if isRunning {
                    ProgressView(value: progress, total: 1.0)
                        .tint(.orange)
                }
                
                // 결과 표시
                if !results.isEmpty {
                    VStack(spacing: 16) {
                        Text("📊 측정 결과")
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(results) { result in
                            BenchmarkCard(result: result)
                        }
                        
                        // 비교 차트
                        ComparisonChart(results: results)
                        
                        // 결론
                        ConclusionCard(results: results)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("성능 벤치마크")
    }
    
    // MARK: - Benchmark
    
    private func runBenchmark() {
        isRunning = true
        progress = 0
        results = []
        
        Task {
            var newResults: [BenchmarkResult] = []
            
            // 샘플 이미지 준비
            guard let sampleURL = Bundle.main.url(forResource: "sample-exif", withExtension: "jpg") else {
                print("⚠️ 샘플 이미지 없음")
                await MainActor.run {
                    isRunning = false
                }
                return
            }
            
            // 1. Image I/O - 메타데이터만 읽기
            await updateProgress(0.2)
            let result1 = await measureMetadataOnly(url: sampleURL)
            newResults.append(result1)
            await MainActor.run { results = newResults }
            
            // 2. Image I/O - 썸네일 생성
            await updateProgress(0.4)
            let result2 = await measureThumbnailGeneration(url: sampleURL)
            newResults.append(result2)
            await MainActor.run { results = newResults }
            
            // 3. UIImage - 전체 이미지 로드
            await updateProgress(0.6)
            let result3 = await measureFullImageLoad(url: sampleURL)
            newResults.append(result3)
            await MainActor.run { results = newResults }
            
            // 4. Image I/O - 원본 이미지 생성
            await updateProgress(0.8)
            let result4 = await measureFullCGImage(url: sampleURL)
            newResults.append(result4)
            await MainActor.run { results = newResults }
            
            // 5. 반복 측정 (100회)
            await updateProgress(0.9)
            let result5 = await measureRepeatedAccess(url: sampleURL, count: 100)
            newResults.append(result5)
            
            await MainActor.run {
                results = newResults
                progress = 1.0
                isRunning = false
            }
        }
    }
    
    @MainActor
    private func updateProgress(_ value: Double) {
        progress = value
    }
    
    // MARK: - Measurements
    
    private func measureMetadataOnly(url: URL) async -> BenchmarkResult {
        let startMemory = MemoryMonitor.currentUsage()
        let start = CFAbsoluteTimeGetCurrent()
        
        _ = EXIFReader.loadEXIFData(from: url)
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        let endMemory = MemoryMonitor.currentUsage()
        let memoryUsed = endMemory - startMemory
        
        return BenchmarkResult(
            name: "메타데이터만 읽기",
            description: "EXIF, GPS 등 메타데이터만 추출",
            duration: duration,
            memoryUsed: memoryUsed,
            icon: "doc.text.magnifyingglass",
            color: .green
        )
    }
    
    private func measureThumbnailGeneration(url: URL) async -> BenchmarkResult {
        let startMemory = MemoryMonitor.currentUsage()
        let start = CFAbsoluteTimeGetCurrent()
        
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
            let options: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: 200,
                kCGImageSourceCreateThumbnailFromImageAlways: true
            ]
            _ = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        let endMemory = MemoryMonitor.currentUsage()
        let memoryUsed = endMemory - startMemory
        
        return BenchmarkResult(
            name: "썸네일 생성 (200px)",
            description: "Image I/O로 효율적인 썸네일 생성",
            duration: duration,
            memoryUsed: memoryUsed,
            icon: "photo",
            color: .blue
        )
    }
    
    private func measureFullImageLoad(url: URL) async -> BenchmarkResult {
        let startMemory = MemoryMonitor.currentUsage()
        let start = CFAbsoluteTimeGetCurrent()
        
        _ = UIImage(contentsOfFile: url.path)
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        let endMemory = MemoryMonitor.currentUsage()
        let memoryUsed = endMemory - startMemory
        
        return BenchmarkResult(
            name: "UIImage 전체 로드",
            description: "UIImage로 전체 이미지 메모리 로드",
            duration: duration,
            memoryUsed: memoryUsed,
            icon: "photo.fill",
            color: .red
        )
    }
    
    private func measureFullCGImage(url: URL) async -> BenchmarkResult {
        let startMemory = MemoryMonitor.currentUsage()
        let start = CFAbsoluteTimeGetCurrent()
        
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
            _ = CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        let endMemory = MemoryMonitor.currentUsage()
        let memoryUsed = endMemory - startMemory
        
        return BenchmarkResult(
            name: "CGImage 원본 생성",
            description: "Image I/O로 원본 CGImage 생성",
            duration: duration,
            memoryUsed: memoryUsed,
            icon: "rectangle.portrait",
            color: .purple
        )
    }
    
    private func measureRepeatedAccess(url: URL, count: Int) async -> BenchmarkResult {
        let start = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<count {
            _ = EXIFReader.loadEXIFData(from: url)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        let avgDuration = duration / Double(count)
        
        return BenchmarkResult(
            name: "반복 접근 (\(count)회)",
            description: "평균 \(String(format: "%.2f", avgDuration * 1000))ms",
            duration: duration,
            memoryUsed: 0,
            icon: "arrow.triangle.2.circlepath",
            color: .orange
        )
    }
}

// MARK: - Models

struct BenchmarkResult: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let duration: TimeInterval  // 초
    let memoryUsed: Int64  // 바이트
    let icon: String
    let color: Color
    
    var formattedDuration: String {
        if duration < 0.001 {
            return String(format: "%.2f μs", duration * 1_000_000)
        } else if duration < 1 {
            return String(format: "%.2f ms", duration * 1000)
        } else {
            return String(format: "%.2f s", duration)
        }
    }
    
    var formattedMemory: String {
        if memoryUsed == 0 {
            return "N/A"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: memoryUsed)
    }
}

// MARK: - Components

struct BenchmarkCard: View {
    let result: BenchmarkResult
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: result.icon)
                .font(.system(size: 30))
                .foregroundColor(result.color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.headline)
                
                Text(result.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(result.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if result.memoryUsed > 0 {
                        Label(result.formattedMemory, systemImage: "memorychip")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(result.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ComparisonChart: View {
    let results: [BenchmarkResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏱️ 속도 비교")
                .font(.headline)
            
            let maxDuration = results.map { $0.duration }.max() ?? 1
            
            ForEach(results.filter { $0.memoryUsed > 0 }) { result in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(result.name)
                            .font(.caption)
                        Spacer()
                        Text(result.formattedDuration)
                            .font(.caption)
                            .bold()
                    }
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(result.color)
                                .frame(width: geometry.size.width * CGFloat(result.duration / maxDuration))
                            
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ConclusionCard: View {
    let results: [BenchmarkResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 결론")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Image I/O의 메타데이터 읽기는 매우 빠르고 메모리 효율적입니다")
                Text("• 썸네일 생성은 전체 이미지 로드보다 훨씬 적은 메모리를 사용합니다")
                Text("• UIImage는 편리하지만 전체 이미지를 메모리에 로드하여 비효율적입니다")
                Text("• 갤러리 앱처럼 많은 이미지를 다룰 때는 Image I/O를 사용하세요")
            }
            .font(.callout)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Memory Monitor

struct MemoryMonitor {
    static func currentUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

#Preview {
    NavigationView {
        BenchmarkView()
    }
}


