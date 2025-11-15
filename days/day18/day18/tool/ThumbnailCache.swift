//
//  ThumbnailCache.swift
//  day18
//
//  썸네일 캐싱 시스템 (메모리 + 디스크)
//

import UIKit
import Foundation

/// 썸네일 캐시 키
struct ThumbnailCacheKey: Hashable {
    let videoURL: URL
    let time: TimeInterval
    let maximumSize: CGSize
    
    init(videoURL: URL, time: TimeInterval, maximumSize: CGSize = CGSize(width: 200, height: 200)) {
        self.videoURL = videoURL
        self.time = time
        self.maximumSize = maximumSize
    }
}

/// 썸네일 캐시 매니저
class ThumbnailCache {
    static let shared = ThumbnailCache()
    
    // MARK: - Properties
    
    /// 메모리 캐시 (NSCache 사용)
    private let memoryCache = NSCache<NSString, UIImage>()
    
    /// 최대 메모리 캐시 개수
    var maxMemoryCacheCount: Int {
        get { memoryCache.countLimit }
        set { memoryCache.countLimit = newValue }
    }
    
    /// 최대 메모리 캐시 비용 (바이트)
    var maxMemoryCacheCost: Int {
        get { memoryCache.totalCostLimit }
        set { memoryCache.totalCostLimit = newValue }
    }
    
    /// 디스크 캐시 디렉토리
    private let diskCacheDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        // 메모리 캐시 기본 설정
        memoryCache.countLimit = 100 // 최대 100개
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // 디스크 캐시 디렉토리 설정
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = cacheDir.appendingPathComponent("ThumbnailCache", isDirectory: true)
        
        // 디렉토리 생성
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        // 메모리 부족 시 자동 정리
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearMemoryCache()
        }
    }
    
    // MARK: - Cache Operations
    
    /// 썸네일 가져오기 (메모리 → 디스크 순서)
    func getThumbnail(for key: ThumbnailCacheKey) -> UIImage? {
        // 1. 메모리 캐시 확인
        if let cachedImage = memoryCache.object(forKey: cacheKeyString(key) as NSString) {
            PerformanceLogger.debug("썸네일 메모리 캐시 히트: \(key.videoURL.lastPathComponent) @ \(key.time)s", category: "cache")
            return cachedImage
        }
        
        // 2. 디스크 캐시 확인
        if let diskImage = loadFromDisk(key: key) {
            // 메모리 캐시에도 저장
            storeInMemory(image: diskImage, key: key)
            PerformanceLogger.debug("썸네일 디스크 캐시 히트: \(key.videoURL.lastPathComponent) @ \(key.time)s", category: "cache")
            return diskImage
        }
        
        PerformanceLogger.debug("썸네일 캐시 미스: \(key.videoURL.lastPathComponent) @ \(key.time)s", category: "cache")
        return nil
    }
    
    /// 썸네일 저장 (메모리 + 디스크)
    func storeThumbnail(_ image: UIImage, for key: ThumbnailCacheKey) {
        storeInMemory(image: image, key: key)
        storeToDisk(image: image, key: key)
    }
    
    /// 메모리 캐시에 저장
    private func storeInMemory(image: UIImage, key: ThumbnailCacheKey) {
        let keyString = cacheKeyString(key)
        
        // 이미지 크기를 비용으로 사용
        let cost = Int(image.size.width * image.size.height * 4) // RGBA
        memoryCache.setObject(image, forKey: keyString as NSString, cost: cost)
    }
    
    /// 디스크 캐시에 저장
    private func storeToDisk(image: UIImage, key: ThumbnailCacheKey) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = diskCacheURL(for: key)
        try? data.write(to: fileURL)
    }
    
    /// 디스크 캐시에서 로드
    private func loadFromDisk(key: ThumbnailCacheKey) -> UIImage? {
        let fileURL = diskCacheURL(for: key)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    /// 디스크 캐시 파일 URL 생성
    private func diskCacheURL(for key: ThumbnailCacheKey) -> URL {
        let fileName = cacheKeyString(key).replacingOccurrences(of: "/", with: "_")
        return diskCacheDirectory.appendingPathComponent("\(fileName).jpg")
    }
    
    /// 캐시 키 문자열 생성
    private func cacheKeyString(_ key: ThumbnailCacheKey) -> String {
        let urlString = key.videoURL.absoluteString
        let sizeString = "\(Int(key.maximumSize.width))x\(Int(key.maximumSize.height))"
        return "\(urlString)_\(key.time)_\(sizeString)"
    }
    
    // MARK: - Cache Management
    
    /// 메모리 캐시 비우기
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        PerformanceLogger.log("메모리 캐시 비움", category: "cache")
    }
    
    /// 디스크 캐시 비우기
    func clearDiskCache() {
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        PerformanceLogger.log("디스크 캐시 비움", category: "cache")
    }
    
    /// 전체 캐시 비우기
    func clearAllCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    /// 디스크 캐시 크기 계산
    func getDiskCacheSize() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: []
        ) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
    
    /// 디스크 캐시 파일 개수
    func getDiskCacheCount() -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil) else {
            return 0
        }
        return files.count
    }
}

