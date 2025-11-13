//
//  AsyncImageLoader.swift
//  day08
//
//  async/await 버전 이미지 로더

import UIKit
import Foundation

/// async/await 버전 이미지 로더
@available(iOS 15.0, *)
class AsyncImageLoader {
    static let shared = AsyncImageLoader()
    
    // NSCache: 메모리 기반 캐시
    private let cache = NSCache<NSString, UIImage>()
    
    // 진행 중인 Task 추적
    private var runningTasks = [String: Task<UIImage, Error>]()
    private let taskQueue = DispatchQueue(label: "com.study.day08.async-loader")
    
    // 캐시 통계
    private(set) var cacheHits = 0
    private(set) var cacheMisses = 0
    
    private init() {
        // 캐시 설정
        cache.totalCostLimit = 100 * 1024 * 1024  // 100MB
        cache.countLimit = 50  // 최대 50개 이미지
        
        // 메모리 경고 옵저버
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        PerformanceLogger.shared.log("AsyncImageLoader 초기화", category: "cache")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - async/await 버전
    
    /// 이미지 로드 (async/await)
    /// - Parameter url: 이미지 URL
    /// - Returns: UIImage
    /// - Throws: ImageError
    func loadImage(from url: URL) async throws -> UIImage {
        let key = url.absoluteString
        
        // 1. 캐시 확인
        if let cachedImage = cache.object(forKey: key as NSString) {
            await MainActor.run {
                self.cacheHits += 1
            }
            PerformanceLogger.shared.logCacheHit(url: url.absoluteString)
            return cachedImage
        }
        
        await MainActor.run {
            self.cacheMisses += 1
        }
        PerformanceLogger.shared.logCacheMiss(url: url.absoluteString)
        
        // 2. 이미 다운로드 중인지 확인
        if let existingTask = taskQueue.sync(execute: { runningTasks[key] }) {
            PerformanceLogger.shared.log("진행 중인 Task 재사용: \(key)", category: "loading")
            return try await existingTask.value
        }
        
        // 3. 새 Task 생성
        let task = Task<UIImage, Error> {
            try await self.downloadImage(from: url)
        }
        
        taskQueue.sync {
            runningTasks[key] = task
        }
        
        defer {
            taskQueue.sync {
                runningTasks.removeValue(forKey: key)
            }
        }
        
        return try await task.value
    }
    
    // MARK: - Private
    
    private func downloadImage(from url: URL) async throws -> UIImage {
        let signpostID = PerformanceLogger.shared.beginImageLoad(url: url.absoluteString)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // URLSession data 다운로드 (async/await)
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // HTTP 응답 체크
        guard let httpResponse = response as? HTTPURLResponse else {
            PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
            throw ImageError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
            throw ImageError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 이미지 변환
        guard let image = UIImage(data: data) else {
            PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
            throw ImageError.invalidData
        }
        
        // 캐시에 저장
        let cost = Int(image.size.width * image.size.height * 4)  // RGBA
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
        
        // 성능 측정 종료
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: true)
        PerformanceLogger.shared.log("다운로드 완료: \(String(format: "%.2f", duration * 1000))ms", category: "loading")
        
        // 네트워크 통계
        if #available(iOS 12.0, *) {
            await NetworkMonitor.shared.trackDownload(bytes: Int64(data.count))
        }
        
        return image
    }
    
    // MARK: - 캐시 관리
    
    /// 특정 이미지 캐시 삭제
    func removeCache(for url: URL) {
        let key = url.absoluteString as NSString
        cache.removeObject(forKey: key)
        PerformanceLogger.shared.log("캐시 삭제: \(url.absoluteString)", category: "cache")
    }
    
    /// 전체 캐시 삭제
    func clearCache() {
        cache.removeAllObjects()
        PerformanceLogger.shared.log("전체 캐시 삭제", category: "cache")
    }
    
    /// 캐시 통계 초기화
    func resetStats() {
        cacheHits = 0
        cacheMisses = 0
        PerformanceLogger.shared.log("캐시 통계 초기화", category: "cache")
    }
    
    // MARK: - 통계
    
    /// 캐시 히트율 (%)
    var hitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total) * 100
    }
    
    /// 통계 요약
    var statsSummary: String {
        """
        캐시 히트: \(cacheHits)회
        캐시 미스: \(cacheMisses)회
        히트율: \(String(format: "%.1f", hitRate))%
        """
    }
    
    @objc private func handleMemoryWarning() {
        PerformanceLogger.shared.log("⚠️ 메모리 경고 - 캐시 정리", category: "memory")
        cache.removeAllObjects()
    }
}

// MARK: - 병렬 다운로드

@available(iOS 15.0, *)
extension AsyncImageLoader {
    /// 여러 이미지를 병렬로 다운로드
    func loadImages(from urls: [URL]) async throws -> [UIImage] {
        try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            // 각 URL에 대해 Task 추가
            for (index, url) in urls.enumerated() {
                group.addTask {
                    let image = try await self.loadImage(from: url)
                    return (index, image)
                }
            }
            
            // 결과 수집 (순서 유지)
            var results: [(Int, UIImage)] = []
            for try await result in group {
                results.append(result)
            }
            
            // 인덱스 순으로 정렬
            results.sort { $0.0 < $1.0 }
            
            return results.map { $0.1 }
        }
    }
    
    /// 프리로드 (백그라운드에서 미리 다운로드)
    func prefetchImages(urls: [URL]) {
        Task(priority: .low) {
            for url in urls {
                _ = try? await loadImage(from: url)
            }
            PerformanceLogger.shared.log("프리로드 완료: \(urls.count)개", category: "cache")
        }
    }
}

// MARK: - Task 취소

@available(iOS 15.0, *)
extension AsyncImageLoader {
    /// 진행 중인 모든 Task 취소
    func cancelAll() {
        taskQueue.sync {
            for (_, task) in runningTasks {
                task.cancel()
            }
            runningTasks.removeAll()
        }
        PerformanceLogger.shared.log("모든 다운로드 취소", category: "loading")
    }
    
    /// 특정 URL의 Task 취소
    func cancel(url: URL) {
        taskQueue.sync {
            runningTasks[url.absoluteString]?.cancel()
            runningTasks.removeValue(forKey: url.absoluteString)
        }
        PerformanceLogger.shared.log("다운로드 취소: \(url.absoluteString)", category: "loading")
    }
}




















