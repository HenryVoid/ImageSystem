//
//  CacheAnalyzer.swift
//  day14
//
//  캐시 분석 도구
//

import Foundation

/// 캐시 분석 결과
struct CacheAnalysisResult {
    let hitRate: Double
    let missRate: Double
    let averageLoadTime: TimeInterval
    let memoryUsage: Double
    let diskUsage: Double
    let totalLoads: Int
    let cacheHits: Int
    let cacheMisses: Int
}

/// 캐시 분석기
@Observable
class CacheAnalyzer {
    /// Nuke 분석 결과
    private(set) var nukeAnalysis: CacheAnalysisResult?
    
    /// Kingfisher 분석 결과
    private(set) var kingfisherAnalysis: CacheAnalysisResult?
    
    /// Nuke 로더 분석
    func analyzeNuke(_ loader: NukeImageLoader) async {
        let result = CacheAnalysisResult(
            hitRate: loader.cacheHitRate,
            missRate: 100 - loader.cacheHitRate,
            averageLoadTime: loader.averageLoadTime,
            memoryUsage: loader.memoryUsage,
            diskUsage: loader.diskCacheSizeMB,
            totalLoads: loader.loadCount,
            cacheHits: loader.cacheHitCount,
            cacheMisses: loader.cacheMissCount
        )
        
        await MainActor.run {
            self.nukeAnalysis = result
        }
    }
    
    /// Kingfisher 로더 분석
    func analyzeKingfisher(_ loader: KingfisherImageLoader) async {
        let diskSize = await loader.diskCacheSizeMB()
        
        let result = CacheAnalysisResult(
            hitRate: loader.cacheHitRate,
            missRate: 100 - loader.cacheHitRate,
            averageLoadTime: loader.averageLoadTime,
            memoryUsage: loader.memoryUsage,
            diskUsage: diskSize,
            totalLoads: loader.loadCount,
            cacheHits: loader.cacheHitCount,
            cacheMisses: loader.cacheMissCount
        )
        
        await MainActor.run {
            self.kingfisherAnalysis = result
        }
    }
    
    /// 비교 결과
    var comparisonSummary: String {
        guard let nuke = nukeAnalysis,
              let kingfisher = kingfisherAnalysis else {
            return "분석 데이터가 없습니다."
        }
        
        var summary = "## 캐시 성능 비교\n\n"
        
        // 히트율
        summary += "### 캐시 히트율\n"
        summary += "- Nuke: \(String(format: "%.1f", nuke.hitRate))%\n"
        summary += "- Kingfisher: \(String(format: "%.1f", kingfisher.hitRate))%\n"
        summary += "- 승자: \(nuke.hitRate > kingfisher.hitRate ? "Nuke" : "Kingfisher")\n\n"
        
        // 로드 시간
        summary += "### 평균 로드 시간\n"
        summary += "- Nuke: \(String(format: "%.0f", nuke.averageLoadTime * 1000))ms\n"
        summary += "- Kingfisher: \(String(format: "%.0f", kingfisher.averageLoadTime * 1000))ms\n"
        summary += "- 승자: \(nuke.averageLoadTime < kingfisher.averageLoadTime ? "Nuke" : "Kingfisher")\n\n"
        
        // 메모리
        summary += "### 메모리 사용량\n"
        summary += "- Nuke: \(String(format: "%.1f", nuke.memoryUsage))MB\n"
        summary += "- Kingfisher: \(String(format: "%.1f", kingfisher.memoryUsage))MB\n"
        summary += "- 승자: \(nuke.memoryUsage < kingfisher.memoryUsage ? "Nuke" : "Kingfisher")\n\n"
        
        return summary
    }
    
    /// 초기화
    func reset() {
        nukeAnalysis = nil
        kingfisherAnalysis = nil
    }
}

