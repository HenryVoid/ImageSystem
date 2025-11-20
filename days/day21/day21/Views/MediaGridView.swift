import SwiftUI

struct MediaGridView: View {
    @StateObject private var viewModel = MediaListViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 2)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(Array(viewModel.assets.enumerated()), id: \.element.id) { index, asset in
                        NavigationLink(value: index) {
                            GeometryReader { geometry in
                                MediaThumbnailView(asset: asset, targetSize: geometry.size)
                            }
                            .aspectRatio(1, contentMode: .fill)
                        }
                        .buttonStyle(.plain) // 버튼 효과 제거
                    }
                }
            }
            .navigationTitle("Media Gallery")
            .navigationDestination(for: Int.self) { index in
                MediaDetailView(assets: viewModel.assets, initialIndex: index)
            }
            .task {
                await viewModel.requestPermissionAndLoadAssets()
            }
        }
    }
}

struct MediaGridView_Previews: PreviewProvider {
    static var previews: some View {
        MediaGridView()
    }
}

