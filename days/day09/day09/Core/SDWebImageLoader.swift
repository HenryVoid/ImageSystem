//
//  SDWebImageLoader.swift
//  day09
//
//  SDWebImage 래퍼 및 메트릭 수집
//

import Foundation
import UIKit
import SDWebImage

/// SDWebImage를 래핑하여 성능 메트릭을 수집
class SDWebImageLoader {
    static let shared = SDWebImageLoader()
    
    private init() {}
    
    /// 이미지 로드 및 메트릭 수집
    func loadImage(
        from url: URL,
        completion: @escaping (UIImage?, PerformanceMetrics) -> Void
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let memoryBefore = getMemoryUsage()
        
        SDWebImageManager.shared.loadImage(
            with: url,
            options: [.retryFailed],
            progress: nil
        ) { image, data, error, cacheType, finished, imageURL in
            guard finished else { return }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let memoryAfter = self.getMemoryUsage()
            
            let metrics = PerformanceMetrics(
                loadingTime: endTime - startTime,
                memoryUsed: memoryAfter > memoryBefore ? memoryAfter - memoryBefore : 0,
                cacheHit: cacheType != .none,
                diskCacheUsed: cacheType == .disk,
                imageSize: image?.size ?? .zero,
                fileSize: UInt64(data?.count ?? 0),
                timestamp: Date()
            )
            
            completion(image, metrics)
        }
    }
    
    /// 캐시 초기화
    func clearCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
    }
    
    /// 메모리 캐시만 초기화
    func clearMemoryCache() {
        SDImageCache.shared.clearMemory()
    }
    
    /// 디스크 캐시 크기 가져오기
    func getDiskCacheSize(completion: @escaping (UInt64) -> Void) {
        SDImageCache.shared.calculateSize { fileCount, totalSize in
            completion(totalSize)
        }
    }
    
    /// 캐시 확인
    func isCached(url: URL, completion: @escaping (Bool, Bool) -> Void) {
        let key = url.absoluteString
        SDImageCache.shared.containsImage(forKey: key) { cacheType in
            let cached = cacheType != .none
            let inMemory = cacheType == .memory
            completion(cached, inMemory)
        }
    }
    
    /// 이미지 변환 (리사이징) 속도 측정
    func transformImage(
        from url: URL,
        targetSize: CGSize,
        completion: @escaping (UIImage?, TimeInterval) -> Void
    ) {
        let transformer = SDImageResizingTransformer(
            size: targetSize,
            scaleMode: .aspectFill
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        SDWebImageManager.shared.loadImage(
            with: url,
            options: [],
            context: [.imageTransformer: transformer],
            progress: nil
        ) { image, _, _, _, finished, _ in
            guard finished else { return }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            completion(image, duration)
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

