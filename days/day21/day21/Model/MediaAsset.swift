import Foundation
import Photos

struct MediaAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    
    var mediaType: PHAssetMediaType {
        asset.mediaType
    }
    
    var duration: TimeInterval {
        asset.duration
    }
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }
}

