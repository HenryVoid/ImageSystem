//
//  ImageDetailView.swift
//  day14
//
//  이미지 상세보기 뷰 (줌, 공유, 북마크)
//

import SwiftUI
import NukeUI

struct ImageDetailView: View {
    let image: ImageModel
    let searchManager: SearchManager
    let library: ImageLibraryType
    let nukeLoader: NukeImageLoader
    let kingfisherLoader: KingfisherImageLoader
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    @State private var showShareSheet = false
    @State private var imageToShare: UIImage?
    
    enum ImageLibraryType {
        case nuke, kingfisher
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 이미지 (줌 가능)
                ZoomableImageView(
                    urlString: image.fullSizeURL,
                    library: library
                )
                .frame(height: 400)
                
                // 정보 카드
                VStack(alignment: .leading, spacing: 16) {
                    // 작가 정보
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("작가")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(image.author)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // 좋아요 & 북마크
                        HStack(spacing: 20) {
                            Button {
                                searchManager.toggleLike(for: image.id)
                            } label: {
                                VStack {
                                    Image(systemName: searchManager.isLiked(image.id) ? "heart.fill" : "heart")
                                        .font(.title2)
                                        .foregroundStyle(searchManager.isLiked(image.id) ? .red : .gray)
                                    Text("좋아요")
                                        .font(.caption2)
                                }
                            }
                            
                            Button {
                                searchManager.toggleBookmark(for: image.id)
                            } label: {
                                VStack {
                                    Image(systemName: searchManager.isBookmarked(image.id) ? "bookmark.fill" : "bookmark")
                                        .font(.title2)
                                        .foregroundStyle(searchManager.isBookmarked(image.id) ? .yellow : .gray)
                                    Text("북마크")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 이미지 정보
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "크기", value: "\(image.width) × \(image.height) px")
                        InfoRow(label: "비율", value: String(format: "%.2f:1", image.aspectRatio))
                        InfoRow(label: "카테고리", value: image.sizeCategory.description)
                        InfoRow(label: "ID", value: image.id)
                    }
                    
                    Divider()
                    
                    // 액션 버튼
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await shareImage()
                            }
                        } label: {
                            Label("공유", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            if let url = URL(string: image.url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("웹에서 보기", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding()
            }
        }
        .navigationTitle("이미지 상세")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let imageToShare = imageToShare {
                ShareSheet(items: [imageToShare])
            }
        }
    }
    
    private func shareImage() async {
        do {
            let loadedImage: UIImage
            switch library {
            case .nuke:
                loadedImage = try await nukeLoader.loadImage(from: image.fullSizeURL)
            case .kingfisher:
                loadedImage = try await kingfisherLoader.loadImage(from: image.fullSizeURL)
            }
            
            await MainActor.run {
                self.imageToShare = loadedImage
                self.showShareSheet = true
            }
        } catch {
            print("이미지 로드 실패: \(error)")
        }
    }
}

/// 정보 행
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

/// 줌 가능한 이미지 뷰
struct ZoomableImageView: View {
    let urlString: String
    let library: ImageDetailView.ImageLibraryType
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        Group {
            switch library {
            case .nuke:
                LazyImage(url: URL(string: urlString)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state.isLoading {
                        ProgressView()
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                
            case .kingfisher:
                KFImageView(urlString: urlString)
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastScale
                    lastScale = value
                    scale = min(max(scale * delta, 1), 5)
                }
                .onEnded { _ in
                    lastScale = 1.0
                    if scale < 1 {
                        withAnimation {
                            scale = 1
                            offset = .zero
                        }
                    }
                }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    if scale > 1 {
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
        .onTapGesture(count: 2) {
            withAnimation {
                if scale > 1 {
                    scale = 1
                    offset = .zero
                    lastOffset = .zero
                } else {
                    scale = 2
                }
            }
        }
    }
}

/// 공유 시트
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ImageDetailView(
            image: ImageModel(
                id: "1",
                author: "Test Author",
                width: 1920,
                height: 1080,
                url: "https://picsum.photos/id/1/info",
                downloadURL: "https://picsum.photos/id/1/1920/1080"
            ),
            searchManager: SearchManager(),
            library: .nuke,
            nukeLoader: NukeImageLoader(),
            kingfisherLoader: KingfisherImageLoader()
        )
    }
}

