//
//  KingfisherImageLoader.swift
//  day14
//
//  Kingfisher 이미지 로더 및 캐시 관리
//

import Foundation
import Kingfisher
import SwiftUI

/// Kingfisher 기반 이미지 로더
@Observable
class KingfisherImageLoader {
    /// 성능 메트릭
    private(set) var loadCount: Int = 0
    private(set) var cacheHitCount: Int = 0
    private(set) var cacheMissCount: Int = 0
    private(set) var totalLoadTime: TimeInterval = 0
    private(set) var memoryUsage: Double = 0 // MB
    
    /// 캐시 매니저
    private let cache: ImageCache
    
    /// 다운로더
    private let downloader: ImageDownloader
    
    init() {
        self.cache = ImageCache.default
        self.downloader = ImageDownloader.default
        
        // 캐시 설정
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100MB
        cache.memoryStorage.config.countLimit = 100 // 최대 100개
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024 // 500MB
        
        // 만료 시간 설정 (7일)
        cache.diskStorage.config.expiration = .days(7)
    }
    
    /// 이미지 로드 (URL)
    func loadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let startTime = Date()
        
        // 캐시 확인
        let cacheKey = url.cacheKey
        let isCached = cache.isCached(forKey: cacheKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                let loadTime = Date().timeIntervalSince(startTime)
                
                Task { @MainActor in
                    self?.loadCount += 1
                    self?.totalLoadTime += loadTime
                    
                    if isCached {
                        self?.cacheHitCount += 1
                    } else {
                        self?.cacheMissCount += 1
                    }
                    
                    self?.updateMemoryUsage()
                }
                
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult.image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 이미지 프리페칭
    func prefetchImages(urls: [String]) {
        let imageURLs = urls.compactMap { URL(string: $0) }
        ImagePrefetcher(urls: imageURLs).start()
    }
    
    /// 캐시 통계
    var cacheHitRate: Double {
        guard loadCount > 0 else { return 0 }
        return Double(cacheHitCount) / Double(loadCount) * 100
    }
    
    var averageLoadTime: TimeInterval {
        guard loadCount > 0 else { return 0 }
        return totalLoadTime / Double(loadCount)
    }
    
    /// 메모리 사용량 업데이트
    private func updateMemoryUsage() {
        memoryUsage = Double(cache.memoryStorage.totalSize()) / 1024 / 1024
    }
    
    /// 캐시 삭제
    func clearCache() {
        cache.clearMemoryCache()
        cache.clearDiskCache()
        
        loadCount = 0
        cacheHitCount = 0
        cacheMissCount = 0
        totalLoadTime = 0
        memoryUsage = 0
    }
    
    /// 메모리 캐시만 삭제
    func clearMemoryCache() {
        cache.clearMemoryCache()
        updateMemoryUsage()
    }
    
    /// 디스크 캐시 크기
    func diskCacheSize() async -> UInt {
        return await withCheckedContinuation { continuation in
            cache.calculateDiskStorageSize { result in
                switch result {
                case .success(let size):
                    continuation.resume(returning: size)
                case .failure:
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    /// 디스크 캐시 크기 (MB)
    func diskCacheSizeMB() async -> Double {
        let size = await diskCacheSize()
        return Double(size) / 1024 / 1024
    }
    
    /// 통계 초기화
    func resetStatistics() {
        loadCount = 0
        cacheHitCount = 0
        cacheMissCount = 0
        totalLoadTime = 0
    }
}

