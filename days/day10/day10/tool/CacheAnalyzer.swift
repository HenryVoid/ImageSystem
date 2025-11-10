//
//  CacheAnalyzer.swift
//  day10
//
//  캐시 분석 및 통계 도구
//

import Foundation
import UIKit

/// 캐시 분석 결과
struct CacheAnalysisResult {
    let timestamp: Date
    let memoryUsageMB: Double
    let diskUsageMB: Double
    let hitRate: Double
    let memoryHitRate: Double
    let diskHitRate: Double
    let totalRequests: Int
    
    var summary: String {
        """
        📊 캐시 분석 결과 (\(formattedTimestamp))
        ────────────────────────────────────
        메모리 사용: \(String(format: "%.1f", memoryUsageMB)) MB
        디스크 사용: \(String(format: "%.1f", diskUsageMB)) MB
        전체 히트율: \(String(format: "%.1f", hitRate))%
        메모리 히트율: \(String(format: "%.1f", memoryHitRate))%
        디스크 히트율: \(String(format: "%.1f", diskHitRate))%
        총 요청 수: \(totalRequests)회
        """
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

/// 캐시 분석기
class CacheAnalyzer: ObservableObject {
    // MARK: - Singleton
    
    static let shared = CacheAnalyzer()
    
    // MARK: - Properties
    
    @Published private(set) var analysisHistory: [CacheAnalysisResult] = []
    @Published private(set) var isAnalyzing = false
    
    private let maxHistoryCount = 100
    
    // MARK: - Analysis
    
    /// Kingfisher 캐시 분석
    func analyzeKingfisher() -> CacheAnalysisResult {
        let manager = KingfisherCacheManager.shared
        
        let result = CacheAnalysisResult(
            timestamp: Date(),
            memoryUsageMB: manager.currentMemoryUsageMB,
            diskUsageMB: manager.currentDiskUsageMB,
            hitRate: manager.hitRate,
            memoryHitRate: manager.memoryHitRate,
            diskHitRate: manager.diskHitRate,
            totalRequests: manager.totalRequests
        )
        
        addToHistory(result)
        return result
    }
    
    /// Nuke 캐시 분석
    func analyzeNuke() -> CacheAnalysisResult {
        let manager = NukeCacheManager.shared
        
        let result = CacheAnalysisResult(
            timestamp: Date(),
            memoryUsageMB: manager.currentMemoryUsageMB,
            diskUsageMB: manager.currentDiskUsageMB,
            hitRate: manager.hitRate,
            memoryHitRate: manager.memoryHitRate,
            diskHitRate: manager.diskHitRate,
            totalRequests: manager.totalRequests
        )
        
        addToHistory(result)
        return result
    }
    
    /// 비교 분석
    func compareLibraries() -> String {
        let kingfisher = analyzeKingfisher()
        let nuke = analyzeNuke()
        
        return """
        🔍 라이브러리 비교 분석
        ═══════════════════════════════════
        
        📚 Kingfisher
        ────────────────────────
        메모리: \(String(format: "%.1f", kingfisher.memoryUsageMB)) MB
        디스크: \(String(format: "%.1f", kingfisher.diskUsageMB)) MB
        히트율: \(String(format: "%.1f", kingfisher.hitRate))%
        요청 수: \(kingfisher.totalRequests)회
        
        🚀 Nuke
        ────────────────────────
        메모리: \(String(format: "%.1f", nuke.memoryUsageMB)) MB
        디스크: \(String(format: "%.1f", nuke.diskUsageMB)) MB
        히트율: \(String(format: "%.1f", nuke.hitRate))%
        요청 수: \(nuke.totalRequests)회
        
        📈 비교 결과
        ────────────────────────
        메모리 효율: \(compareEfficiency(kingfisher.memoryUsageMB, nuke.memoryUsageMB))
        디스크 효율: \(compareEfficiency(kingfisher.diskUsageMB, nuke.diskUsageMB))
        히트율 차이: \(String(format: "%.1f", nuke.hitRate - kingfisher.hitRate))%p
        """
    }
    
    private func compareEfficiency(_ value1: Double, _ value2: Double) -> String {
        if value1 < value2 {
            let diff = ((value2 - value1) / value2) * 100
            return "Kingfisher가 \(String(format: "%.1f", diff))% 더 효율적"
        } else if value2 < value1 {
            let diff = ((value1 - value2) / value1) * 100
            return "Nuke가 \(String(format: "%.1f", diff))% 더 효율적"
        } else {
            return "동일"
        }
    }
    
    // MARK: - History Management
    
    private func addToHistory(_ result: CacheAnalysisResult) {
        analysisHistory.append(result)
        
        // 최대 개수 유지
        if analysisHistory.count > maxHistoryCount {
            analysisHistory.removeFirst()
        }
    }
    
    func clearHistory() {
        analysisHistory.removeAll()
        print("🗑️ 분석 히스토리 삭제 완료")
    }
    
    // MARK: - Trend Analysis
    
    /// 히트율 트렌드
    func hitRateTrend() -> [Double] {
        return analysisHistory.map { $0.hitRate }
    }
    
    /// 메모리 사용량 트렌드
    func memoryUsageTrend() -> [Double] {
        return analysisHistory.map { $0.memoryUsageMB }
    }
    
    /// 디스크 사용량 트렌드
    func diskUsageTrend() -> [Double] {
        return analysisHistory.map { $0.diskUsageMB }
    }
    
    /// 평균 히트율
    func averageHitRate() -> Double {
        guard !analysisHistory.isEmpty else { return 0 }
        let sum = analysisHistory.reduce(0.0) { $0 + $1.hitRate }
        return sum / Double(analysisHistory.count)
    }
    
    /// 최대 메모리 사용량
    func maxMemoryUsage() -> Double {
        return analysisHistory.map { $0.memoryUsageMB }.max() ?? 0
    }
    
    /// 최대 디스크 사용량
    func maxDiskUsage() -> Double {
        return analysisHistory.map { $0.diskUsageMB }.max() ?? 0
    }
    
    // MARK: - Performance Grade
    
    func performanceGrade(hitRate: Double) -> String {
        switch hitRate {
        case 95...:
            return "S (최고)"
        case 90..<95:
            return "A (우수)"
        case 80..<90:
            return "B (양호)"
        case 70..<80:
            return "C (보통)"
        case 60..<70:
            return "D (나쁨)"
        default:
            return "F (매우 나쁨)"
        }
    }
    
    func performanceReport() -> String {
        guard !analysisHistory.isEmpty else {
            return "분석 데이터가 없습니다."
        }
        
        let avgHitRate = averageHitRate()
        let grade = performanceGrade(hitRate: avgHitRate)
        
        return """
        📊 성능 리포트
        ═══════════════════════════════════
        평균 히트율: \(String(format: "%.1f", avgHitRate))%
        성능 등급: \(grade)
        
        최대 메모리 사용: \(String(format: "%.1f", maxMemoryUsage())) MB
        최대 디스크 사용: \(String(format: "%.1f", maxDiskUsage())) MB
        
        총 분석 횟수: \(analysisHistory.count)회
        """
    }
}











