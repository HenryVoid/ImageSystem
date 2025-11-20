import SwiftUI

struct MediaDetailView: View {
    let assets: [MediaAsset]
    @State private var selectedIndex: Int
    
    init(assets: [MediaAsset], initialIndex: Int) {
        self.assets = assets
        _selectedIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(assets.enumerated()), id: \.element.id) { index, asset in
                MediaDetailItemView(asset: asset)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 상단 툴바가 컨텐츠를 가리지 않도록 설정하거나 배경색 지정 가능
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// 개별 상세 아이템 뷰 (이미지 로딩 분리)
struct MediaDetailItemView: View {
    let asset: MediaAsset
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if asset.mediaType == .video {
                    VideoPlayerView(asset: asset)
                } else {
                    if let image = image {
                        ZoomableImageView(image: image)
                    } else {
                        ProgressView()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                if asset.mediaType == .image {
                    loadImage()
                }
            }
        }
    }
    
    private func loadImage() {
        PhotoLibraryService.shared.requestHighQualityImage(for: asset) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

