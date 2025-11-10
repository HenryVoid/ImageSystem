//
//  PerformanceLogger.swift
//  day14
//
//  성능 로깅 (os_signpost)
//

import Foundation
import os.signpost

/// 성능 로거
class PerformanceLogger {
    static let shared = PerformanceLogger()
    
    private let subsystem = "com.day14.performance"
    private let log: OSLog
    
    private init() {
        self.log = OSLog(subsystem: subsystem, category: .pointsOfInterest)
    }
    
    /// 이미지 로드 시작
    func logImageLoadStart(imageID: String) {
        os_signpost(.begin, log: log, name: "Image Load", "Loading image: %{public}@", imageID)
    }
    
    /// 이미지 로드 완료
    func logImageLoadEnd(imageID: String) {
        os_signpost(.end, log: log, name: "Image Load", "Loaded image: %{public}@", imageID)
    }
    
    /// 캐시 히트
    func logCacheHit(imageID: String) {
        os_signpost(.event, log: log, name: "Cache Hit", "Cache hit for: %{public}@", imageID)
    }
    
    /// 캐시 미스
    func logCacheMiss(imageID: String) {
        os_signpost(.event, log: log, name: "Cache Miss", "Cache miss for: %{public}@", imageID)
    }
    
    /// 프리페칭 시작
    func logPrefetchStart(count: Int) {
        os_signpost(.begin, log: log, name: "Prefetch", "Prefetching %d images", count)
    }
    
    /// 프리페칭 완료
    func logPrefetchEnd(count: Int) {
        os_signpost(.end, log: log, name: "Prefetch", "Prefetched %d images", count)
    }
}

