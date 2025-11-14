//
//  CachedImageLoader.swift
//  day08
//
//  NSCache를 활용한 이미지 로더

import UIKit
import Foundation

/// NSCache를 활용한 이미지 로더
class CachedImageLoader {
    static let shared = CachedImageLoader()
    
    // NSCache: 메모리 기반 캐시
    private let cache = NSCache<NSString, UIImage>()
    
    // 진행 중인 요청 추적 (중복 방지)
    private var runningRequests = [String: [(Result<UIImage, Error>) -> Void]]()
    
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
        
        PerformanceLogger.shared.log("CachedImageLoader 초기화 (100MB, 50개)", category: "cache")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 이미지 로드
    
    /// 이미지 로드 (캐시 적용)
    /// - Parameters:
    ///   - url: 이미지 URL
    ///   - completion: 완료 핸들러 (메인 스레드에서 호출됨)
    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let key = url.absoluteString as NSString
        
        // 1. 캐시 확인
        if let cachedImage = cache.object(forKey: key) {
            cacheHits += 1
            PerformanceLogger.shared.logCacheHit(url: url.absoluteString)
            PerformanceLogger.shared.log("캐시 히트율: \(String(format: "%.1f", hitRate))%", category: "cache")
            
            // 즉시 반환 (메인 스레드로 전환)
            DispatchQueue.main.async {
                completion(.success(cachedImage))
            }
            return
        }
        
        cacheMisses += 1
        PerformanceLogger.shared.logCacheMiss(url: url.absoluteString)
        
        // 2. 이미 다운로드 중인지 확인 (중복 요청 방지)
        if runningRequests[url.absoluteString] != nil {
            PerformanceLogger.shared.log("진행 중인 요청에 합류: \(url.absoluteString)", category: "loading")
            runningRequests[url.absoluteString]?.append(completion)
            return
        }
        
        // 3. 새 다운로드 시작
        runningRequests[url.absoluteString] = [completion]
        
        let signpostID = PerformanceLogger.shared.beginImageLoad(url: url.absoluteString)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                // 완료 후 요청 목록에서 제거
                self.runningRequests.removeValue(forKey: url.absoluteString)
            }
            
            // 에러 체크
            if let error = error {
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                // 모든 대기 중인 completion에 에러 전달
                DispatchQueue.main.async {
                    self.runningRequests[url.absoluteString]?.forEach { $0(.failure(error)) }
                }
                return
            }
            
            // HTTP 응답 체크
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let error = ImageError.invalidResponse
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                DispatchQueue.main.async {
                    self.runningRequests[url.absoluteString]?.forEach { $0(.failure(error)) }
                }
                return
            }
            
            // 데이터 체크
            guard let data = data, !data.isEmpty else {
                let error = ImageError.noData
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                DispatchQueue.main.async {
                    self.runningRequests[url.absoluteString]?.forEach { $0(.failure(error)) }
                }
                return
            }
            
            // 이미지 변환
            guard let image = UIImage(data: data) else {
                let error = ImageError.invalidData
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                DispatchQueue.main.async {
                    self.runningRequests[url.absoluteString]?.forEach { $0(.failure(error)) }
                }
                return
            }
            
            // 캐시에 저장
            let cost = Int(image.size.width * image.size.height * 4)  // RGBA
            self.cache.setObject(image, forKey: key, cost: cost)
            
            // 성능 측정 종료
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: true)
            PerformanceLogger.shared.log("다운로드 완료 (캐시 저장): \(String(format: "%.2f", duration * 1000))ms", category: "loading")
            
            // 네트워크 통계
            if #available(iOS 12.0, *) {
                NetworkMonitor.shared.trackDownload(bytes: Int64(data.count))
            }
            
            // 모든 대기 중인 completion에 이미지 전달
            DispatchQueue.main.async {
                self.runningRequests[url.absoluteString]?.forEach { $0(.success(image)) }
            }
        }.resume()
    }
    
    // MARK: - 간편 버전
    
    /// 이미지 로드 (옵셔널 반환)
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        loadImage(from: url) { result in
            switch result {
            case .success(let image):
                completion(image)
            case .failure:
                completion(nil)
            }
        }
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
    
    // MARK: - Private
    
    @objc private func handleMemoryWarning() {
        PerformanceLogger.shared.log("⚠️ 메모리 경고 - 캐시 정리", category: "memory")
        cache.removeAllObjects()
    }
}

// MARK: - 캐시 프리로딩

extension CachedImageLoader {
    /// 여러 이미지 프리로드
    func prefetchImages(urls: [URL], completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        
        for url in urls {
            group.enter()
            loadImage(from: url) { _ in
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            PerformanceLogger.shared.log("프리로드 완료: \(urls.count)개", category: "cache")
            completion?()
        }
    }
}





















