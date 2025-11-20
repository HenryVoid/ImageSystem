//
//  NukeCacheManager.swift
//  day10
//
//  Nuke의 ImagePipeline을 활용한 캐시 관리자
//

import Foundation
import UIKit
import Nuke

/// Nuke 캐시 관리자
class NukeCacheManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = NukeCacheManager()
    
    // MARK: - Properties
    
    private var pipeline: ImagePipeline
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
        self.pipeline = ImagePipeline.shared
        
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
        
        // DataCache 생성
        let dataCache = try? DataCache(name: "com.day10.nuke.datacache")
        dataCache?.sizeLimit = config.diskCacheSizeBytes
        
        // ImagePipeline Configuration
        var pipelineConfig = ImagePipeline.Configuration()
        
        // 메모리 캐시 설정
        let imageCache = ImageCache()
        imageCache.costLimit = config.memoryCacheSizeBytes
        imageCache.countLimit = config.imageCountLimit
        imageCache.ttl = config.ttlSeconds
        pipelineConfig.imageCache = imageCache
        
        // 디스크 캐시 설정
        pipelineConfig.dataCache = dataCache
        
        // 새 Pipeline 생성
        self.pipeline = ImagePipeline(configuration: pipelineConfig)
        
        print("✅ Nuke 캐시 설정 완료")
        print(config.summary())
    }
    
    // MARK: - Cache Operations
    
    /// 이미지 저장
    func store(_ image: UIImage, forKey key: String) {
        let request = ImageRequest(url: URL(string: key)!)
        let container = ImageContainer(image: image)
        pipeline.cache[request] = container
        updateCacheUsage()
    }
    
    /// 이미지 조회 (동기)
    func retrieve(forKey key: String) -> UIImage? {
        guard let url = URL(string: key) else { return nil }
        let request = ImageRequest(url: url)
        
        // 메모리 캐시 확인
        if let container = pipeline.cache[request] {
            memoryHits += 1
            print("🎯 메모리 캐시 히트: \(key) (\(Int(memoryHitRate))%)")
            return container.image
        }
        
        // 디스크 캐시 확인 (동기 방식은 제한적)
        // Nuke는 비동기 API를 권장하므로 여기서는 메모리만 확인
        
        // 캐시 미스
        misses += 1
        print("❌ 캐시 미스: \(key) (히트율: \(Int(hitRate))%)")
        return nil
    }
    
    /// 이미지 로드 (비동기 - 권장)
    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let request = ImageRequest(url: url)
        
        // 캐시 확인
        if let container = pipeline.cache[request] {
            memoryHits += 1
            print("🎯 메모리 캐시 히트: \(url.absoluteString)")
            DispatchQueue.main.async {
                completion(.success(container.image))
            }
            return
        }
        
        // 네트워크 로드 (디스크 캐시 포함)
        let task = pipeline.loadImage(with: request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // 응답 확인
                if response.container != pipeline.cache[request] {
                    // 네트워크에서 로드됨
                    self.diskHits += 1
                    print("💿 디스크/네트워크 로드: \(url.absoluteString)")
                }
                DispatchQueue.main.async {
                    completion(.success(response.image))
                }
            case .failure(let error):
                self.misses += 1
                print("❌ 로드 실패: \(url.absoluteString)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
            
            self.updateCacheUsage()
        }
    }
    
    /// 이미지 삭제
    func removeImage(forKey key: String) {
        guard let url = URL(string: key) else { return }
        let request = ImageRequest(url: url)
        pipeline.cache.removeImage(for: request)
        
        // 디스크 캐시 삭제
        pipeline.cache.removeCachedData(for: request)
        
        updateCacheUsage()
    }
    
    // MARK: - Cache Management
    
    /// 메모리 캐시만 삭제
    func clearMemoryCache() {
        pipeline.cache.removeAll()
        print("🗑️ 메모리 캐시 삭제 완료")
        updateCacheUsage()
    }
    
    /// 디스크 캐시만 삭제
    func clearDiskCache() {
        guard let dataCache = pipeline.configuration.dataCache else { return }
        dataCache.removeAll()
        print("🗑️ 디스크 캐시 삭제 완료")
        updateCacheUsage()
    }
    
    /// 전체 캐시 삭제
    func clearAllCache() {
        pipeline.cache.removeAll()
        pipeline.configuration.dataCache?.removeAll()
        print("🗑️ 전체 캐시 삭제 완료")
        updateCacheUsage()
    }
    
    /// 만료된 캐시 정리
    func cleanExpiredCache() {
        // Nuke는 자동으로 TTL 기반 정리를 수행
        // 수동 정리는 제한적이므로 전체 sweep
        pipeline.cache.trim(toCost: 0)
        pipeline.cache.trim(toCount: 0)
        print("🧹 만료된 캐시 정리 완료")
        updateCacheUsage()
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
            let memoryBytes = self.pipeline.cache.totalCost
            self.currentMemoryUsageMB = Double(memoryBytes) / 1024 / 1024
            
            // 디스크 사용량
            if let dataCache = self.pipeline.configuration.dataCache {
                let diskBytes = dataCache.totalSize
                self.currentDiskUsageMB = Double(diskBytes) / 1024 / 1024
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
    
    // MARK: - Preheating
    
    /// 이미지 프리히팅
    func preheatImages(urls: [URL]) {
        let requests = urls.map { ImageRequest(url: $0) }
        let preheater = ImagePreheater(pipeline: pipeline)
        preheater.startPreheating(with: requests)
        print("🔥 프리히팅 시작: \(urls.count)개 이미지")
    }
    
    /// 프리히팅 중단
    func stopPreheating(urls: [URL]) {
        let requests = urls.map { ImageRequest(url: $0) }
        let preheater = ImagePreheater(pipeline: pipeline)
        preheater.stopPreheating(with: requests)
        print("⏸️ 프리히팅 중단: \(urls.count)개 이미지")
    }
    
    // MARK: - Statistics
    
    func summary() -> String {
        """
        📊 Nuke 캐시 통계
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






























