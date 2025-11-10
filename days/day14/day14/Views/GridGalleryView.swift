//
//  GridGalleryView.swift
//  day14
//
//  그리드 갤러리 뷰 (LazyVGrid)
//

import SwiftUI
import NukeUI

struct GridGalleryView: View {
    @State private var imageProvider = ImageProvider()
    @State private var searchManager = SearchManager()
    @State private var nukeLoader = NukeImageLoader()
    @State private var kingfisherLoader = KingfisherImageLoader()
    
    @State private var selectedLibrary: ImageLibrary = .nuke
    @State private var selectedImageID: String?
    @State private var isLoading = false
    
    enum ImageLibrary: String, CaseIterable {
        case nuke = "Nuke"
        case kingfisher = "Kingfisher"
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var filteredImages: [ImageModel] {
        searchManager.filterImages(imageProvider.allImages)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 라이브러리 선택
                Picker("라이브러리", selection: $selectedLibrary) {
                    ForEach(ImageLibrary.allCases, id: \.self) { library in
                        Text(library.rawValue).tag(library)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 검색 및 필터
                HStack {
                    TextField("작가명 검색", text: $searchManager.searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("카테고리", selection: $searchManager.selectedCategory) {
                        ForEach(ImageSizeCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .frame(width: 120)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // 결과 개수
                Text("\(filteredImages.count)개 이미지")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                
                // 그리드
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(filteredImages) { image in
                            ThumbnailCell(
                                image: image,
                                library: selectedLibrary,
                                nukeLoader: nukeLoader,
                                kingfisherLoader: kingfisherLoader
                            )
                            .aspectRatio(1, contentMode: .fill)
                            .onTapGesture {
                                selectedImageID = image.id
                            }
                        }
                    }
                    .padding(2)
                }
                .refreshable {
                    await imageProvider.refresh()
                }
            }
            .navigationTitle("그리드 갤러리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            clearCache()
                        } label: {
                            Label("캐시 삭제", systemImage: "trash")
                        }
                        
                        Button {
                            resetStatistics()
                        } label: {
                            Label("통계 초기화", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationDestination(item: $selectedImageID) { imageID in
                if let image = imageProvider.getImage(by: imageID) {
                    ImageDetailView(
                        image: image,
                        searchManager: searchManager,
                        library: selectedLibrary,
                        nukeLoader: nukeLoader,
                        kingfisherLoader: kingfisherLoader
                    )
                }
            }
        }
    }
    
    private func clearCache() {
        switch selectedLibrary {
        case .nuke:
            nukeLoader.clearCache()
        case .kingfisher:
            kingfisherLoader.clearCache()
        }
    }
    
    private func resetStatistics() {
        nukeLoader.resetStatistics()
        kingfisherLoader.resetStatistics()
    }
}

/// 썸네일 셀
struct ThumbnailCell: View {
    let image: ImageModel
    let library: GridGalleryView.ImageLibrary
    let nukeLoader: NukeImageLoader
    let kingfisherLoader: KingfisherImageLoader
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch library {
                case .nuke:
                    LazyImage(url: URL(string: image.thumbnailURL())) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if state.isLoading {
                            ProgressView()
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                    
                case .kingfisher:
                    KFImageView(urlString: image.thumbnailURL())
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }
}

/// Kingfisher 이미지 뷰
struct KFImageView: View {
    let urlString: String
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        do {
            let loader = KingfisherImageLoader()
            let loadedImage = try await loader.loadImage(from: urlString)
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

#Preview {
    GridGalleryView()
}

