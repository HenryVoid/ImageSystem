//
//  BenchmarkRunner.swift
//  day07
//
//  SwiftUI vs UIKit 성능 비교 및 벤치마크 실행
//

import Foundation
import UIKit
import SwiftUI

/// 벤치마크 결과
struct BenchmarkResult: Identifiable {
    let id = UUID()
    let name: String
    let averageTime: TimeInterval
    let minTime: TimeInterval
    let maxTime: TimeInterval
    let iterations: Int
    let memoryUsed: Int64
    
    var formattedAverageTime: String {
        String(format: "%.2f ms", averageTime * 1000)
    }
    
    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: memoryUsed, countStyle: .memory)
    }
}

/// 벤치마크 러너
class BenchmarkRunner: ObservableObject {
    @Published var results: [BenchmarkResult] = []
    @Published var isRunning = false
    
    // MARK: - 이미지 로딩 벤치마크
    
    /// 포맷별 로딩 시간 측정
    func benchmarkImageLoading(imageNames: [String], iterations: Int = 10) {
        isRunning = true
        results.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for imageName in imageNames {
                var times: [TimeInterval] = []
                let memoryBefore = MemorySampler.currentUsage()
                
                for _ in 0..<iterations {
                    let start = CFAbsoluteTimeGetCurrent()
                    _ = ImageLoader.shared.loadUIImage(named: imageName)
                    let end = CFAbsoluteTimeGetCurrent()
                    times.append(end - start)
                }
                
                let memoryAfter = MemorySampler.currentUsage()
                let memoryUsed = max(0, memoryAfter - memoryBefore)
                
                let result = BenchmarkResult(
                    name: "로딩: \(imageName)",
                    averageTime: times.reduce(0, +) / Double(iterations),
                    minTime: times.min() ?? 0,
                    maxTime: times.max() ?? 0,
                    iterations: iterations,
                    memoryUsed: memoryUsed
                )
                
                DispatchQueue.main.async {
                    self?.results.append(result)
                    PerformanceLogger.log("[\(imageName)] 평균: \(result.formattedAverageTime)", category: "benchmark")
                }
            }
            
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }
    
    // MARK: - 필터 체인 벤치마크
    
    /// 필터 체인별 처리 시간 측정
    func benchmarkFilterChains(imageName: String, filterChains: [[FilterType]], iterations: Int = 5) {
        isRunning = true
        results.removeAll()
        
        guard let ciImage = ImageLoader.shared.loadCIImage(named: imageName) else {
            isRunning = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for (index, filters) in filterChains.enumerated() {
                var times: [TimeInterval] = []
                let memoryBefore = MemorySampler.currentUsage()
                
                for _ in 0..<iterations {
                    let start = CFAbsoluteTimeGetCurrent()
                    _ = FilterEngine.shared.applyFilterChain(filters, to: ciImage)
                    let end = CFAbsoluteTimeGetCurrent()
                    times.append(end - start)
                }
                
                let memoryAfter = MemorySampler.currentUsage()
                let memoryUsed = max(0, memoryAfter - memoryBefore)
                
                let filterNames = filters.map { $0.rawValue }.joined(separator: " → ")
                let result = BenchmarkResult(
                    name: "필터 \(index + 1): \(filterNames)",
                    averageTime: times.reduce(0, +) / Double(iterations),
                    minTime: times.min() ?? 0,
                    maxTime: times.max() ?? 0,
                    iterations: iterations,
                    memoryUsed: memoryUsed
                )
                
                DispatchQueue.main.async {
                    self?.results.append(result)
                    PerformanceLogger.log("[\(filterNames)] 평균: \(result.formattedAverageTime)", category: "benchmark")
                }
            }
            
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }
    
    // MARK: - 썸네일 생성 벤치마크
    
    /// 썸네일 생성 시간 측정
    func benchmarkThumbnailGeneration(imageNames: [String], sizes: [CGFloat], iterations: Int = 10) {
        isRunning = true
        results.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for imageName in imageNames {
                for size in sizes {
                    var times: [TimeInterval] = []
                    let memoryBefore = MemorySampler.currentUsage()
                    
                    for _ in 0..<iterations {
                        let start = CFAbsoluteTimeGetCurrent()
                        _ = ImageLoader.shared.generateThumbnail(named: imageName, maxSize: size)
                        let end = CFAbsoluteTimeGetCurrent()
                        times.append(end - start)
                    }
                    
                    let memoryAfter = MemorySampler.currentUsage()
                    let memoryUsed = max(0, memoryAfter - memoryBefore)
                    
                    let result = BenchmarkResult(
                        name: "\(imageName) @ \(Int(size))px",
                        averageTime: times.reduce(0, +) / Double(iterations),
                        minTime: times.min() ?? 0,
                        maxTime: times.max() ?? 0,
                        iterations: iterations,
                        memoryUsed: memoryUsed
                    )
                    
                    DispatchQueue.main.async {
                        self?.results.append(result)
                        PerformanceLogger.log("썸네일[\(imageName)@\(Int(size))px] 평균: \(result.formattedAverageTime)", category: "benchmark")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }
    
    // MARK: - 전체 벤치마크 실행
    
    /// 모든 벤치마크 실행
    func runAllBenchmarks() {
        let imageNames = ["sample", "sample2"]
        let filterChains: [[FilterType]] = [
            [.blur],
            [.sepia],
            [.sepia, .vignette],
            [.colorControls, .sharpen]
        ]
        let thumbnailSizes: [CGFloat] = [100, 200, 300]
        
        // 순차적으로 실행
        benchmarkImageLoading(imageNames: imageNames)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.benchmarkFilterChains(imageName: "sample", filterChains: filterChains)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.benchmarkThumbnailGeneration(imageNames: imageNames, sizes: thumbnailSizes)
        }
    }
}

