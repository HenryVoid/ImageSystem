//
//  NukeImageLoader.swift
//  day14
//
//  Nuke 이미지 로더 및 캐시 관리
//

import Foundation
import Nuke
import SwiftUI

/// Nuke 기반 이미지 로더
@Observable
class NukeImageLoader {
    /// 성능 메트릭
    private(set) var loadCount: Int = 0
    private(set) var cacheHitCount: Int = 0
    private(set) var cacheMissCount: Int = 0
    private(set) var totalLoadTime: TimeInterval = 0
    private(set) var memoryUsage: Double = 0 // MB
    
    /// 이미지 파이프라인
    private let pipeline: ImagePipeline
    
    /// 프리페처
    private let prefetcher: ImagePrefetcher
    
    init() {
        // 캐시 설정
        let dataCache = try? DataCache(name: "com.day14.nuke.datacache")
        dataCache?.sizeLimit = 500 * 1024 * 1024 // 500MB
        
        let imageCache = ImageCache()
        imageCache.costLimit = 100 * 1024 * 1024 // 100MB 메모리 캐시
        imageCache.countLimit = 100 // 최대 100개 이미지
        
        // 파이프라인 설정
        let configuration = ImagePipeline.Configuration()
        configuration.dataCache = dataCache
        configuration.imageCache = imageCache
        
        // 다운샘플링 활성화
        configuration.isDecompressionEnabled = true
        
        self.pipeline = ImagePipeline(configuration: configuration)
        self.prefetcher = ImagePrefetcher(pipeline: pipeline)
        
        // 기본 파이프라인으로 설정
        ImagePipeline.shared = pipeline
    }
    
    /// 이미지 로드 (URL)
    func loadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let startTime = Date()
        
        let request = ImageRequest(url: url)
        
        // 캐시 확인
        let isCached = pipeline.cache[request] != nil
        
        let imageResponse = try await pipeline.image(for: request)
        
        let loadTime = Date().timeIntervalSince(startTime)
        
        await MainActor.run {
            self.loadCount += 1
            self.totalLoadTime += loadTime
            
            if isCached {
                self.cacheHitCount += 1
            } else {
                self.cacheMissCount += 1
            }
            
            self.updateMemoryUsage()
        }
        
        return imageResponse.image
    }
    
    /// 이미지 프리페칭
    func prefetchImages(urls: [String]) {
        let imageURLs = urls.compactMap { URL(string: $0) }
        let requests = imageURLs.map { ImageRequest(url: $0) }
        prefetcher.startPrefetching(with: requests)
    }
    
    /// 프리페칭 중지
    func stopPrefetching() {
        prefetcher.stopPrefetching()
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
        if let cache = pipeline.configuration.imageCache {
            memoryUsage = Double(cache.totalCost) / 1024 / 1024 // MB로 변환
        }
    }
    
    /// 캐시 삭제
    func clearCache() {
        pipeline.cache.removeAll()
        
        loadCount = 0
        cacheHitCount = 0
        cacheMissCount = 0
        totalLoadTime = 0
        memoryUsage = 0
    }
    
    /// 메모리 캐시만 삭제
    func clearMemoryCache() {
        pipeline.configuration.imageCache?.removeAll()
        updateMemoryUsage()
    }
    
    /// 디스크 캐시 크기
    var diskCacheSize: Int64 {
        return pipeline.configuration.dataCache?.totalSize ?? 0
    }
    
    /// 디스크 캐시 크기 (MB)
    var diskCacheSizeMB: Double {
        return Double(diskCacheSize) / 1024 / 1024
    }
    
    /// 통계 초기화
    func resetStatistics() {
        loadCount = 0
        cacheHitCount = 0
        cacheMissCount = 0
        totalLoadTime = 0
    }
}

