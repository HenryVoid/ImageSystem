import Foundation
import Photos
import UIKit

class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    private let imageManager = PHCachingImageManager()
    
    private init() {}
    
    // 권한 상태 확인 및 요청
    func checkAuthorizationStatus() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        return status
    }
    
    // 모든 미디어 에셋 가져오기 (최신순)
    func fetchMediaAssets() -> [MediaAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        // 이미지와 비디오만 포함 (predicate로 필터링 가능하지만, 기본적으로 allMedia 타입 사용시 주의)
        // 여기서는 심플하게 fetchAssets(with: options) 사용
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var assets: [MediaAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            if asset.mediaType == .image || asset.mediaType == .video {
                assets.append(MediaAsset(asset: asset))
            }
        }
        return assets
    }
    
    // 썸네일 이미지 요청
    func requestImage(for asset: MediaAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        
        imageManager.requestImage(for: asset.asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, info in
            completion(image)
        }
    }
    
    // 고해상도 이미지 요청 (상세 보기용)
    func requestHighQualityImage(for asset: MediaAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: asset.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
            completion(image)
        }
    }
    
    // 비디오 AVPlayerItem 요청
    func requestPlayerItem(for asset: MediaAsset, completion: @escaping (AVPlayerItem?) -> Void) {
        guard asset.mediaType == .video else {
            completion(nil)
            return
        }
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        imageManager.requestPlayerItem(forVideo: asset.asset, options: options) { item, _ in
            completion(item)
        }
    }
}

