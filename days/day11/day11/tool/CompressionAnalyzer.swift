import Foundation
import UIKit

class CompressionAnalyzer {
    
    // MARK: - Singleton
    
    static let shared = CompressionAnalyzer()
    
    private init() {}
    
    // MARK: - Analysis Result
    
    struct AnalysisResult {
        let results: [CompressionResult]
        let bestFormat: ImageFormat
        let bestQuality: Double
        let recommendation: String
        let insights: [String]
    }
    
    // MARK: - Analysis Methods
    
    func analyze(results: [CompressionResult]) -> AnalysisResult {
        guard !results.isEmpty else {
            return AnalysisResult(
                results: [],
                bestFormat: .jpeg,
                bestQuality: 0.8,
                recommendation: "데이터가 없습니다.",
                insights: []
            )
        }
        
        // 최적 포맷 찾기 (크기와 품질의 균형)
        let scoredResults = results.map { result -> (result: CompressionResult, score: Double) in
            let sizeScore = 1.0 - result.compressionRatio // 작을수록 좋음
            let qualityScore = result.quality // 높을수록 좋음
            let speedScore = 1.0 / (result.compressionTime + 0.001) // 빠를수록 좋음
            
            // 가중치 적용
            let score = sizeScore * 0.5 + qualityScore * 0.3 + speedScore * 0.2
            
            return (result, score)
        }
        
        let bestResult = scoredResults.max(by: { $0.score < $1.score })?.result ?? results[0]
        
        // 인사이트 생성
        let insights = generateInsights(from: results)
        
        // 추천 메시지
        let recommendation = generateRecommendation(from: bestResult, allResults: results)
        
        return AnalysisResult(
            results: results,
            bestFormat: bestResult.format,
            bestQuality: bestResult.quality,
            recommendation: recommendation,
            insights: insights
        )
    }
    
    // MARK: - Insights Generation
    
    private func generateInsights(from results: [CompressionResult]) -> [String] {
        var insights: [String] = []
        
        // 포맷별 그룹화
        let byFormat = Dictionary(grouping: results) { $0.format }
        
        // 1. 최고 압축률 포맷
        if let bestCompression = byFormat.max(by: { 
            let avg1 = $0.value.map { $0.compressionPercentage }.reduce(0, +) / Double($0.value.count)
            let avg2 = $1.value.map { $0.compressionPercentage }.reduce(0, +) / Double($1.value.count)
            return avg1 < avg2
        }) {
            let avgCompression = bestCompression.value.map { $0.compressionPercentage }.reduce(0, +) / Double(bestCompression.value.count)
            insights.append("📊 \(bestCompression.key.rawValue)가 평균 \(String(format: "%.1f%%", avgCompression)) 압축률로 가장 효율적입니다.")
        }
        
        // 2. 최고 속도 포맷
        if let fastestFormat = byFormat.min(by: {
            let avg1 = $0.value.map { $0.compressionTime }.reduce(0, +) / Double($0.value.count)
            let avg2 = $1.value.map { $0.compressionTime }.reduce(0, +) / Double($1.value.count)
            return avg1 < avg2
        }) {
            let avgTime = fastestFormat.value.map { $0.compressionTime * 1000 }.reduce(0, +) / Double(fastestFormat.value.count)
            insights.append("⚡ \(fastestFormat.key.rawValue)가 평균 \(String(format: "%.1f ms", avgTime))로 가장 빠릅니다.")
        }
        
        // 3. 품질-크기 밸런스
        let balancedResults = results.filter { $0.quality >= 0.7 && $0.quality <= 0.85 }
        if !balancedResults.isEmpty {
            let avgSize = balancedResults.map { $0.compressedSize }.reduce(0, +) / balancedResults.count
            insights.append("⚖️ 품질 70-85% 범위에서 평균 \(ByteCountFormatter.string(fromByteCount: Int64(avgSize), countStyle: .file)) 크기를 유지합니다.")
        }
        
        // 4. HEIC vs JPEG 비교
        if let heicResults = byFormat[.heic], let jpegResults = byFormat[.jpeg] {
            let heicAvgSize = heicResults.map { $0.compressedSize }.reduce(0, +) / heicResults.count
            let jpegAvgSize = jpegResults.map { $0.compressedSize }.reduce(0, +) / jpegResults.count
            
            if heicAvgSize < jpegAvgSize {
                let saving = Double(jpegAvgSize - heicAvgSize) / Double(jpegAvgSize) * 100
                insights.append("🎯 HEIC는 JPEG 대비 평균 \(String(format: "%.1f%%", saving)) 더 작습니다.")
            }
        }
        
        return insights
    }
    
    // MARK: - Recommendation Generation
    
    private func generateRecommendation(from best: CompressionResult, allResults: [CompressionResult]) -> String {
        let format = best.format
        let quality = best.quality
        let compressionRatio = best.compressionPercentage
        
        var recommendation = "🎯 추천: \(format.rawValue) 포맷, 품질 \(Int(quality * 100))%\n\n"
        
        // 이유 설명
        recommendation += "이유:\n"
        
        if compressionRatio > 70 {
            recommendation += "• 높은 압축률 (\(String(format: "%.1f%%", compressionRatio)))\n"
        }
        
        if quality >= 0.8 {
            recommendation += "• 우수한 품질 유지\n"
        }
        
        if best.compressionTime < 0.1 {
            recommendation += "• 빠른 처리 속도 (\(best.formattedCompressionTime))\n"
        }
        
        // 사용 시나리오
        recommendation += "\n적합한 용도:\n"
        
        switch format {
        case .jpeg:
            recommendation += "• 일반 사진, 웹 이미지\n• 높은 호환성이 필요한 경우"
        case .png:
            recommendation += "• 로고, 아이콘\n• 투명도가 필요한 경우"
        case .heic:
            recommendation += "• iOS 전용 앱\n• 저장 공간 절약이 중요한 경우"
        case .webp:
            recommendation += "• 웹 최적화\n• 모던 브라우저 타겟"
        }
        
        return recommendation
    }
    
    // MARK: - Quality Curve Analysis
    
    struct QualityCurve {
        let format: ImageFormat
        let dataPoints: [(quality: Double, size: Int, time: TimeInterval)]
        
        var sweetSpot: (quality: Double, size: Int)? {
            // 품질-크기의 최적점 찾기 (2차 미분이 최대인 지점)
            guard dataPoints.count >= 3 else { return nil }
            
            let sorted = dataPoints.sorted { $0.quality < $1.quality }
            
            // 간단한 방법: 품질 80% 근처
            if let point = sorted.first(where: { abs($0.quality - 0.8) < 0.1 }) {
                return (point.quality, point.size)
            }
            
            return nil
        }
    }
    
    func analyzeQualityCurve(results: [CompressionResult]) -> [QualityCurve] {
        let byFormat = Dictionary(grouping: results) { $0.format }
        
        return byFormat.map { format, results in
            let dataPoints = results.map { result in
                (quality: result.quality, size: result.compressedSize, time: result.compressionTime)
            }
            
            return QualityCurve(format: format, dataPoints: dataPoints)
        }
    }
    
    // MARK: - Format Comparison
    
    struct FormatComparison {
        let format: ImageFormat
        let averageSize: Int
        let averageTime: TimeInterval
        let averageCompression: Double
        
        var score: Double {
            // 종합 점수 (작을수록, 빠를수록, 높을수록 좋음)
            let sizeScore = 1.0 / Double(averageSize + 1)
            let timeScore = 1.0 / (averageTime + 0.001)
            let compressionScore = averageCompression / 100.0
            
            return sizeScore * 0.4 + timeScore * 0.3 + compressionScore * 0.3
        }
    }
    
    func compareFormats(results: [CompressionResult]) -> [FormatComparison] {
        let byFormat = Dictionary(grouping: results) { $0.format }
        
        return byFormat.map { format, results in
            let avgSize = results.map { $0.compressedSize }.reduce(0, +) / results.count
            let avgTime = results.map { $0.compressionTime }.reduce(0, +) / Double(results.count)
            let avgCompression = results.map { $0.compressionPercentage }.reduce(0, +) / Double(results.count)
            
            return FormatComparison(
                format: format,
                averageSize: avgSize,
                averageTime: avgTime,
                averageCompression: avgCompression
            )
        }.sorted { $0.score > $1.score }
    }
    
    // MARK: - Optimal Settings
    
    func findOptimalSettings(
        for format: ImageFormat,
        targetSize: Int? = nil,
        minQuality: Double = 0.6
    ) -> (quality: Double, estimatedSize: Int)? {
        // 실제로는 여러 샘플을 기반으로 회귀 분석
        // 여기서는 간단한 추정
        
        if let targetSize = targetSize {
            // 목표 크기에 맞는 품질 추정
            let quality = estimateQuality(for: format, targetSize: targetSize)
            return (max(quality, minQuality), targetSize)
        }
        
        // 기본 권장 설정
        let recommendedQuality: Double
        switch format {
        case .jpeg: recommendedQuality = 0.8
        case .png: recommendedQuality = 1.0
        case .heic: recommendedQuality = 0.85
        case .webp: recommendedQuality = 0.8
        }
        
        return (recommendedQuality, 0)
    }
    
    private func estimateQuality(for format: ImageFormat, targetSize: Int) -> Double {
        // 간단한 선형 추정 (실제로는 더 복잡한 모델 필요)
        // 큰 목표 크기 = 높은 품질
        let baseQuality: Double
        
        switch format {
        case .jpeg, .webp: baseQuality = 0.7
        case .heic: baseQuality = 0.8
        case .png: return 1.0
        }
        
        return baseQuality
    }
}


