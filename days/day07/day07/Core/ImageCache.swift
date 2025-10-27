//
//  ImageCache.swift
//  day07
//
//  메모리 캐시 관리 및 썸네일 자동 생성
//

import UIKit

/// 이미지 캐시 관리자
class ImageCache {
    static let shared = ImageCache()
    
    // 원본 이미지 캐시
    private let imageCache = NSCache<NSString, UIImage>()
    
    // 썸네일 캐시
    private let thumbnailCache = NSCache<NSString, UIImage>()
    
    // 캐시 크기 제한 (MB)
    private let maxImageCacheSize = 100 * 1024 * 1024  // 100MB
    private let maxThumbnailCacheSize = 20 * 1024 * 1024  // 20MB
    
    private init() {
        // 캐시 크기 제한 설정
        imageCache.totalCostLimit = maxImageCacheSize
        thumbnailCache.totalCostLimit = maxThumbnailCacheSize
        
        // 메모리 경고 시 캐시 정리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 원본 이미지 캐싱
    
    /// 이미지 캐시에서 가져오기
    func getImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    /// 이미지 캐시에 저장
    func setImage(_ image: UIImage, forKey key: String) {
        // 이미지 크기 계산 (대략적)
        let cost = estimateImageSize(image)
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    /// 캐시된 이미지 삭제
    func removeImage(forKey key: String) {
        imageCache.removeObject(forKey: key as NSString)
    }
    
    // MARK: - 썸네일 캐싱
    
    /// 썸네일 캐시에서 가져오기
    func getThumbnail(forKey key: String) -> UIImage? {
        return thumbnailCache.object(forKey: key as NSString)
    }
    
    /// 썸네일 캐시에 저장
    func setThumbnail(_ thumbnail: UIImage, forKey key: String) {
        let cost = estimateImageSize(thumbnail)
        thumbnailCache.setObject(thumbnail, forKey: key as NSString, cost: cost)
    }
    
    /// 썸네일 가져오기 또는 생성
    func getThumbnailOrCreate(forKey key: String, maxSize: CGFloat = 200) -> UIImage? {
        // 캐시 확인
        if let cached = getThumbnail(forKey: key) {
            return cached
        }
        
        // 원본 이미지에서 썸네일 생성
        guard let original = getImage(forKey: key) else {
            // Asset에서 로드
            guard let thumbnail = ImageLoader.shared.generateThumbnail(named: key, maxSize: maxSize) else {
                return nil
            }
            setThumbnail(thumbnail, forKey: key)
            return thumbnail
        }
        
        guard let thumbnail = ImageLoader.shared.generateThumbnail(from: original, maxSize: maxSize) else {
            return nil
        }
        
        setThumbnail(thumbnail, forKey: key)
        return thumbnail
    }
    
    // MARK: - 캐시 관리
    
    /// 전체 캐시 삭제
    @objc func clearCache() {
        imageCache.removeAllObjects()
        thumbnailCache.removeAllObjects()
    }
    
    /// 썸네일 캐시만 삭제
    func clearThumbnailCache() {
        thumbnailCache.removeAllObjects()
    }
    
    /// 이미지 캐시만 삭제
    func clearImageCache() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - 유틸리티
    
    /// 이미지 메모리 크기 추정
    private func estimateImageSize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4  // RGBA
        return width * height * bytesPerPixel
    }
    
    /// 캐시 통계
    func getCacheStats() -> (imageCount: Int, thumbnailCount: Int) {
        // NSCache는 현재 항목 수를 직접 제공하지 않음
        // 대략적인 정보만 제공
        return (imageCount: 0, thumbnailCount: 0)
    }
}

