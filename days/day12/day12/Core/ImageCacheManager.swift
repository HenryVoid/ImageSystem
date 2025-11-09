//
//  ImageCacheManager.swift
//  day12
//
//  NSCache 기반 이미지 캐싱 및 통계
//

import UIKit
import Foundation

/// 캐시 통계
struct CacheStatistics {
    var hitCount: Int = 0
    var missCount: Int = 0
    var cachedImagesCount: Int = 0
    
    var totalRequests: Int {
        hitCount + missCount
    }
    
    var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(hitCount) / Double(totalRequests) * 100
    }
    
    var formattedHitRate: String {
        String(format: "%.1f%%", hitRate)
    }
}

/// 이미지 캐시 관리자
actor ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSURL, UIImage>()
    private var statistics = CacheStatistics()
    
    private init() {
        configureCache()
    }
    
    // MARK: - Configuration
    
    private func configureCache() {
        // 메모리 제한 설정
        cache.countLimit = 100 // 최대 100개 이미지
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        // 메모리 부족 시 자동 제거
        cache.evictsObjectsWithDiscardedContent = true
    }
    
    // MARK: - Cache Operations
    
    /// 캐시에서 이미지 가져오기
    /// - Parameter url: 이미지 URL
    /// - Returns: 캐시된 이미지 또는 nil
    func image(for url: URL) -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            statistics.hitCount += 1
            return cached
        } else {
            statistics.missCount += 1
            return nil
        }
    }
    
    /// 이미지를 캐시에 저장
    /// - Parameters:
    ///   - image: 저장할 이미지
    ///   - url: 이미지 URL (캐시 키)
    func setImage(_ image: UIImage, for url: URL) {
        // 비용 계산: 픽셀 수 × 4 bytes (RGBA)
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
        statistics.cachedImagesCount += 1
    }
    
    /// 특정 이미지를 캐시에서 제거
    /// - Parameter url: 제거할 이미지 URL
    func removeImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
    
    /// 모든 캐시 클리어
    func clearCache() {
        cache.removeAllObjects()
        statistics.cachedImagesCount = 0
    }
    
    // MARK: - Statistics
    
    /// 캐시 통계 가져오기
    /// - Returns: 현재 캐시 통계
    func getStatistics() -> CacheStatistics {
        statistics
    }
    
    /// 통계 리셋
    func resetStatistics() {
        statistics = CacheStatistics()
    }
    
    /// 캐시 크기 추정 (MB)
    func estimatedCacheSizeMB() -> Double {
        // NSCache는 정확한 크기를 제공하지 않음
        // 캐시된 이미지 수로 추정
        let avgImageSizeMB = 0.64 // 400x400 이미지 약 640KB
        return Double(statistics.cachedImagesCount) * avgImageSizeMB
    }
}

// MARK: - Extensions

extension ImageCacheManager {
    /// 캐시 상태 정보
    var cacheInfo: String {
        """
        Cache Statistics:
        - Hit: \(statistics.hitCount)
        - Miss: \(statistics.missCount)
        - Hit Rate: \(statistics.formattedHitRate)
        - Cached Images: \(statistics.cachedImagesCount)
        - Estimated Size: \(String(format: "%.1f MB", estimatedCacheSizeMB()))
        """
    }
}


