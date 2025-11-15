//
//  KingfisherCacheManager.swift
//  day10
//
//  Kingfisher의 ImageCache를 활용한 캐시 관리자
//

import Foundation
import UIKit
import Kingfisher

/// Kingfisher 캐시 관리자
class KingfisherCacheManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = KingfisherCacheManager()
    
    // MARK: - Properties
    
    private let cache: ImageCache
    private var configuration: CacheConfiguration
    
    // 통계
    @Published private(set) var memoryHits = 0
    @Published private(set) var diskHits = 0
    @Published private(set) var misses = 0
    @Published private(set) var currentMemoryUsageMB: Double = 0
    @Published private(set) var currentDiskUsageMB: Double = 0
    
    private var observers: [NSObjectProtocol] = []
    
    // MARK: - Computed Properties
    
    var totalRequests: Int {
        memoryHits + diskHits + misses
    }
    
    var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits + diskHits) / Double(totalRequests) * 100
    }
    
    var memoryHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(memoryHits) / Double(totalRequests) * 100
    }
    
    var diskHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(diskHits) / Double(totalRequests) * 100
    }
    
    // MARK: - Initialization
    
    init(configuration: CacheConfiguration = .recommended()) {
        self.configuration = configuration
        self.cache = ImageCache.default
        
        configure(with: configuration)
        setupNotifications()
        updateCacheUsage()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Configuration
    
    func configure(with config: CacheConfiguration) {
        self.configuration = config
        
        // 메모리 캐시 설정
        cache.memoryStorage.config.totalCostLimit = config.memoryCacheSizeBytes
        cache.memoryStorage.config.countLimit = config.imageCountLimit
        cache.memoryStorage.config.expiration = .seconds(config.ttlSeconds)
        
        // 디스크 캐시 설정
        cache.diskStorage.config.sizeLimit = UInt(config.diskCacheSizeBytes)
        cache.diskStorage.config.expiration = .seconds(config.ttlSeconds)
        
        print("✅ Kingfisher 캐시 설정 완료")
        print(config.summary())
    }
    
    // MARK: - Cache Operations
    
    /// 이미지 저장
    func store(_ image: UIImage, forKey key: String) {
        cache.store(image, forKey: key)
        updateCacheUsage()
    }
    
    /// 이미지 조회 (동기)
    func retrieve(forKey key: String) -> UIImage? {
        // 메모리 캐시 확인
        if let image = cache.memoryStorage.value(forKey: key) {
            memoryHits += 1
            print("🎯 메모리 캐시 히트: \(key) (\(Int(memoryHitRate))%)")
            return image
        }
        
        // 디스크 캐시 확인
        if let image = try? cache.diskStorage.value(forKey: key) {
            diskHits += 1
            print("💿 디스크 캐시 히트: \(key) (\(Int(diskHitRate))%)")
            
            // 메모리에 저장
            cache.memoryStorage.store(value: image, forKey: key)
            return image
        }
        
        // 캐시 미스
        misses += 1
        print("❌ 캐시 미스: \(key) (히트율: \(Int(hitRate))%)")
        return nil
    }
    
    /// 이미지 조회 (비동기)
    func retrieve(forKey key: String, completion: @escaping (UIImage?) -> Void) {
        cache.retrieveImage(forKey: key) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let value):
                if let image = value.image {
                    switch value.cacheType {
                    case .memory:
                        self.memoryHits += 1
                        print("🎯 메모리 캐시 히트: \(key)")
                    case .disk:
                        self.diskHits += 1
                        print("💿 디스크 캐시 히트: \(key)")
                    case .none:
                        self.misses += 1
                        print("❌ 캐시 미스: \(key)")
                    }
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    self.misses += 1
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            case .failure:
                self.misses += 1
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            
            self.updateCacheUsage()
        }
    }
    
    /// 이미지 삭제
    func removeImage(forKey key: String) {
        cache.removeImage(forKey: key)
        updateCacheUsage()
    }
    
    // MARK: - Cache Management
    
    /// 메모리 캐시만 삭제
    func clearMemoryCache() {
        cache.clearMemoryCache()
        print("🗑️ 메모리 캐시 삭제 완료")
        updateCacheUsage()
    }
    
    /// 디스크 캐시만 삭제
    func clearDiskCache() {
        cache.clearDiskCache {
            print("🗑️ 디스크 캐시 삭제 완료")
            self.updateCacheUsage()
        }
    }
    
    /// 전체 캐시 삭제
    func clearAllCache() {
        cache.clearCache {
            print("🗑️ 전체 캐시 삭제 완료")
            self.updateCacheUsage()
        }
    }
    
    /// 만료된 디스크 캐시 삭제
    func cleanExpiredCache() {
        cache.cleanExpiredDiskCache {
            print("🧹 만료된 캐시 정리 완료")
            self.updateCacheUsage()
        }
    }
    
    /// 통계 초기화
    func resetStatistics() {
        memoryHits = 0
        diskHits = 0
        misses = 0
        print("📊 통계 초기화 완료")
    }
    
    // MARK: - Cache Usage
    
    private func updateCacheUsage() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 메모리 사용량
            let memoryBytes = self.cache.memoryStorage.totalCost
            self.currentMemoryUsageMB = Double(memoryBytes) / 1024 / 1024
            
            // 디스크 사용량 (비동기)
            self.cache.diskStorage.totalSize { [weak self] result in
                if case .success(let size) = result {
                    DispatchQueue.main.async {
                        self?.currentDiskUsageMB = Double(size) / 1024 / 1024
                    }
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // 메모리 경고
        if configuration.clearOnMemoryWarning {
            let observer = NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                print("⚠️ 메모리 경고 감지")
                self?.clearMemoryCache()
            }
            observers.append(observer)
        }
        
        // 백그라운드 진입
        if configuration.clearMemoryOnBackground {
            let observer = NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                print("🌙 백그라운드 진입 - 메모리 캐시 정리")
                self?.clearMemoryCache()
            }
            observers.append(observer)
        }
    }
    
    // MARK: - Statistics
    
    func summary() -> String {
        """
        📊 Kingfisher 캐시 통계
        ────────────────────────
        총 요청: \(totalRequests)회
        메모리 히트: \(memoryHits)회 (\(String(format: "%.1f", memoryHitRate))%)
        디스크 히트: \(diskHits)회 (\(String(format: "%.1f", diskHitRate))%)
        캐시 미스: \(misses)회
        전체 히트율: \(String(format: "%.1f", hitRate))%
        
        메모리 사용: \(String(format: "%.1f", currentMemoryUsageMB)) MB / \(configuration.memoryCacheSizeMB) MB
        디스크 사용: \(String(format: "%.1f", currentDiskUsageMB)) MB / \(configuration.diskCacheSizeMB) MB
        """
    }
}






















