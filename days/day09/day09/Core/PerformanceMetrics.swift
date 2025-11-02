//
//  PerformanceMetrics.swift
//  day09
//
//  성능 측정 데이터 모델
//

import Foundation
import UIKit

/// 이미지 로딩 성능 메트릭
struct PerformanceMetrics {
    /// 로딩 시간 (초)
    var loadingTime: TimeInterval
    
    /// 메모리 사용량 (바이트)
    var memoryUsed: UInt64
    
    /// 캐시 히트 여부
    var cacheHit: Bool
    
    /// 디스크 캐시 사용 여부
    var diskCacheUsed: Bool
    
    /// 이미지 크기
    var imageSize: CGSize
    
    /// 파일 크기 (바이트)
    var fileSize: UInt64
    
    /// 로딩 완료 시각
    var timestamp: Date
    
    init(
        loadingTime: TimeInterval = 0,
        memoryUsed: UInt64 = 0,
        cacheHit: Bool = false,
        diskCacheUsed: Bool = false,
        imageSize: CGSize = .zero,
        fileSize: UInt64 = 0,
        timestamp: Date = Date()
    ) {
        self.loadingTime = loadingTime
        self.memoryUsed = memoryUsed
        self.cacheHit = cacheHit
        self.diskCacheUsed = diskCacheUsed
        self.imageSize = imageSize
        self.fileSize = fileSize
        self.timestamp = timestamp
    }
}

// MARK: - 편의 메서드
extension PerformanceMetrics {
    /// 로딩 시간을 밀리초로
    var loadingTimeInMs: Double {
        return loadingTime * 1000
    }
    
    /// 메모리를 MB로
    var memoryInMB: Double {
        return Double(memoryUsed) / (1024 * 1024)
    }
    
    /// 파일 크기를 KB로
    var fileSizeInKB: Double {
        return Double(fileSize) / 1024
    }
    
    /// 캐시 타입 문자열
    var cacheTypeString: String {
        if !cacheHit {
            return "네트워크"
        } else if diskCacheUsed {
            return "디스크 캐시"
        } else {
            return "메모리 캐시"
        }
    }
}

// MARK: - 통계 계산
extension Array where Element == PerformanceMetrics {
    /// 평균 로딩 시간
    var averageLoadingTime: TimeInterval {
        guard !isEmpty else { return 0 }
        return reduce(0) { $0 + $1.loadingTime } / Double(count)
    }
    
    /// 평균 메모리 사용량
    var averageMemory: UInt64 {
        guard !isEmpty else { return 0 }
        return reduce(0) { $0 + $1.memoryUsed } / UInt64(count)
    }
    
    /// 캐시 히트율 (%)
    var cacheHitRate: Double {
        guard !isEmpty else { return 0 }
        let hits = filter { $0.cacheHit }.count
        return Double(hits) / Double(count) * 100
    }
    
    /// 최소 로딩 시간
    var minLoadingTime: TimeInterval {
        return map { $0.loadingTime }.min() ?? 0
    }
    
    /// 최대 로딩 시간
    var maxLoadingTime: TimeInterval {
        return map { $0.loadingTime }.max() ?? 0
    }
    
    /// 총 메모리 사용량
    var totalMemory: UInt64 {
        return reduce(0) { $0 + $1.memoryUsed }
    }
}

/// 벤치마크 결과
struct BenchmarkResult {
    let libraryName: String
    let metrics: [PerformanceMetrics]
    let diskCacheSize: UInt64
    let transformTime: TimeInterval
    
    /// 요약 통계
    var summary: String {
        """
        📊 \(libraryName) 결과
        평균 로딩 시간: \(String(format: "%.1f", metrics.averageLoadingTime * 1000))ms
        메모리 사용량: \(String(format: "%.1f", Double(metrics.averageMemory) / (1024 * 1024)))MB
        캐시 히트율: \(String(format: "%.1f", metrics.cacheHitRate))%
        디스크 캐시: \(String(format: "%.1f", Double(diskCacheSize) / (1024 * 1024)))MB
        변환 속도: \(String(format: "%.1f", transformTime * 1000))ms
        """
    }
}

