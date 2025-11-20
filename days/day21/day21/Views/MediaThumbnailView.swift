import SwiftUI
import Photos

struct MediaThumbnailView: View {
    let asset: MediaAsset
    let targetSize: CGSize
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: targetSize.width, height: targetSize.height)
            }
            
            if asset.mediaType == .video {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // 썸네일 크기 최적화 (Retina 디스플레이 고려 scale 2.0 등 곱하기)
        let size = CGSize(width: targetSize.width * 2, height: targetSize.height * 2)
        
        PhotoLibraryService.shared.requestImage(for: asset, targetSize: size) { loadedImage in
            // PHCachingImageManager의 콜백은 메인 스레드 보장되지 않을 수 있으므로 확인 필요하나
            // 보통 requestImage의 resultHandler는 메인 스레드에서 호출될 수 있음.
            // 안전하게 MainActor 사용
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

