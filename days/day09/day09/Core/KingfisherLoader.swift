//
//  KingfisherLoader.swift
//  day09
//
//  Kingfisher 래퍼 및 메트릭 수집
//

import Foundation
import UIKit
import Kingfisher

/// Kingfisher를 래핑하여 성능 메트릭을 수집
class KingfisherLoader {
    static let shared = KingfisherLoader()
    
    private init() {}
    
    /// 이미지 로드 및 메트릭 수집
    func loadImage(
        from url: URL,
        completion: @escaping (UIImage?, PerformanceMetrics) -> Void
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let memoryBefore = getMemoryUsage()
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            let endTime = CFAbsoluteTimeGetCurrent()
            let memoryAfter = self.getMemoryUsage()
            
            switch result {
            case .success(let value):
                let metrics = PerformanceMetrics(
                    loadingTime: endTime - startTime,
                    memoryUsed: memoryAfter > memoryBefore ? memoryAfter - memoryBefore : 0,
                    cacheHit: value.cacheType != .none,
                    diskCacheUsed: value.cacheType == .disk,
                    imageSize: value.image.size,
                    fileSize: UInt64(value.data?.count ?? 0),
                    timestamp: Date()
                )
                completion(value.image, metrics)
                
            case .failure(let error):
                print("Kingfisher 로드 실패: \(error)")
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
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }
    
    /// 메모리 캐시만 초기화
    func clearMemoryCache() {
        ImageCache.default.clearMemoryCache()
    }
    
    /// 디스크 캐시 크기 가져오기
    func getDiskCacheSize(completion: @escaping (UInt64) -> Void) {
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                completion(size)
            case .failure:
                completion(0)
            }
        }
    }
    
    /// 캐시 확인
    func isCached(url: URL, completion: @escaping (Bool, Bool) -> Void) {
        let key = url.cacheKey
        ImageCache.default.isCached(forKey: key) { result in
            switch result {
            case .success(let cached):
                if cached.cached {
                    let inMemory = cached.cacheType == .memory
                    completion(true, inMemory)
                } else {
                    completion(false, false)
                }
            case .failure:
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
        let processor = DownsamplingImageProcessor(size: targetSize)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        KingfisherManager.shared.retrieveImage(
            with: url,
            options: [.processor(processor)]
        ) { result in
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            switch result {
            case .success(let value):
                completion(value.image, duration)
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

