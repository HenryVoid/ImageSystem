//
//  PhotoLibraryManager.swift
//  day15
//
//  PHPhotoLibrary 래퍼 - PHAsset fetch 및 이미지 로딩
//

import Foundation
import Photos
import UIKit
import Combine

/// PHAsset을 감싸는 Identifiable 모델
struct PhotoAsset: Identifiable {
    let id: String
    let asset: PHAsset
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }
}

/// 사진 라이브러리 관리자
@MainActor
class PhotoLibraryManager: ObservableObject {
    @Published var assets: [PhotoAsset] = []
    @Published var isLoading = false
    
    private let imageManager = PHImageManager.default()
    
    /// 모든 이미지 asset 가져오기
    func fetchAllPhotos() {
        guard PermissionManager.currentStatus().isAuthorized else {
            print("⚠️ 권한이 없습니다")
            return
        }
        
        isLoading = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var photoAssets: [PhotoAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            photoAssets.append(PhotoAsset(asset: asset))
        }
        
        assets = photoAssets
        isLoading = false
    }
    
    /// 썸네일 이미지 로드
    func loadThumbnail(
        for asset: PHAsset,
        targetSize: CGSize = CGSize(width: 200, height: 200),
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        
        let requestID = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            // 취소된 경우 무시
            if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                return
            }
            
            completion(image)
        }
        
        return requestID
    }
    
    /// 풀사이즈 이미지 로드
    func loadFullSizeImage(
        for asset: PHAsset,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true  // iCloud 동기화 허용
        
        let requestID = imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            // 취소된 경우 무시
            if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                return
            }
            
            completion(image)
        }
        
        return requestID
    }
    
    /// 이미지 데이터 로드 (EXIF 포함)
    func loadImageData(
        for asset: PHAsset,
        completion: @escaping (Data?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImageDataAndOrientation(
            for: asset,
            options: options
        ) { data, _, _, info in
            // 취소된 경우 무시
            if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                return
            }
            
            completion(data)
        }
    }
    
    /// 이미지 요청 취소
    func cancelImageRequest(_ requestID: PHImageRequestID) {
        imageManager.cancelImageRequest(requestID)
    }
}
