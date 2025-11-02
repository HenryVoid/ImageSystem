//
//  NukeLoader.swift
//  day09
//
//  Nuke 래퍼 및 메트릭 수집
//

import Foundation
import UIKit
import Nuke

/// Nuke를 래핑하여 성능 메트릭을 수집
class NukeLoader {
    static let shared = NukeLoader()
    
    private let pipeline = ImagePipeline.shared
    
    private init() {}
    
    /// 이미지 로드 및 메트릭 수집
    func loadImage(
        from url: URL,
        completion: @escaping (UIImage?, PerformanceMetrics) -> Void
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let memoryBefore = getMemoryUsage()
        
        let request = ImageRequest(url: url)
        
        // 캐시 확인 (동기적)
        let wasCached = pipeline.cache[request] != nil
        
        pipeline.loadImage(with: request) { result in
            let endTime = CFAbsoluteTimeGetCurrent()
            let memoryAfter = self.getMemoryUsage()
            
            switch result {
            case .success(let response):
                // Nuke는 cacheType을 직접 제공하지 않으므로 추론
                let cacheHit = wasCached || response.cacheType != nil
                
                let metrics = PerformanceMetrics(
                    loadingTime: endTime - startTime,
                    memoryUsed: memoryAfter > memoryBefore ? memoryAfter - memoryBefore : 0,
                    cacheHit: cacheHit,
                    diskCacheUsed: response.cacheType == .disk,
                    imageSize: response.image.size,
                    fileSize: UInt64(response.container.data?.count ?? 0),
                    timestamp: Date()
                )
                completion(response.image, metrics)
                
            case .failure(let error):
                print("Nuke 로드 실패: \(error)")
                let metrics = PerformanceMetrics(
                    loadingTime: endTime - startTime,
                    memoryUsed: 0,
                    cacheHit: false,
                    diskCacheUsed: false,
                    imageSize: .zero,
                    fileSize: 0,
                    timestamp: Date()
                )
                completion(nil, metrics)
            }
        }
    }
    
    /// 캐시 초기화
    func clearCache() {
        pipeline.cache.removeAll()
        if let dataCache = pipeline.configuration.dataCache as? DataCache {
            dataCache.removeAll()
        }
    }
    
    /// 메모리 캐시만 초기화
    func clearMemoryCache() {
        pipeline.cache.removeAll()
    }
    
    /// 디스크 캐시 크기 가져오기
    func getDiskCacheSize(completion: @escaping (UInt64) -> Void) {
        if let dataCache = pipeline.configuration.dataCache as? DataCache {
            DispatchQueue.global(qos: .utility).async {
                let size = dataCache.totalSize
                DispatchQueue.main.async {
                    completion(UInt64(size))
                }
            }
        } else {
            completion(0)
        }
    }
    
    /// 캐시 확인
    func isCached(url: URL, completion: @escaping (Bool, Bool) -> Void) {
        let request = ImageRequest(url: url)
        let inMemory = pipeline.cache[request] != nil
        
        // 디스크 캐시는 비동기 확인 필요
        if inMemory {
            completion(true, true)
        } else {
            // 디스크 캐시 확인
            if let dataCache = pipeline.configuration.dataCache as? DataCache {
                let key = request.makeDataCacheKey()
                DispatchQueue.global(qos: .utility).async {
                    let exists = dataCache.containsData(for: key)
                    DispatchQueue.main.async {
                        completion(exists, false)
                    }
                }
            } else {
                completion(false, false)
            }
        }
    }
    
    /// 이미지 변환 (리사이징) 속도 측정
    func transformImage(
        from url: URL,
        targetSize: CGSize,
        completion: @escaping (UIImage?, TimeInterval) -> Void
    ) {
        let request = ImageRequest(
            url: url,
            processors: [
                .resize(size: targetSize, contentMode: .aspectFill)
            ]
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        pipeline.loadImage(with: request) { result in
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            switch result {
            case .success(let response):
                completion(response.image, duration)
            case .failure:
                completion(nil, duration)
            }
        }
    }
    
    // MARK: - Helper
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        return kr == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - ImageRequest Extension
extension ImageRequest {
    /// DataCache 키 생성
    func makeDataCacheKey() -> String {
        return url?.absoluteString ?? ""
    }
}

