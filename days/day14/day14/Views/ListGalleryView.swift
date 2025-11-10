//
//  ListGalleryView.swift
//  day14
//
//  리스트 갤러리 뷰 (LazyVStack)
//

import SwiftUI
import NukeUI

struct ListGalleryView: View {
    @State private var imageProvider = ImageProvider()
    @State private var searchManager = SearchManager()
    @State private var nukeLoader = NukeImageLoader()
    @State private var kingfisherLoader = KingfisherImageLoader()
    
    @State private var selectedLibrary: ImageLibrary = .nuke
    @State private var selectedImageID: String?
    
    enum ImageLibrary: String, CaseIterable {
        case nuke = "Nuke"
        case kingfisher = "Kingfisher"
    }
    
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
                
                // 리스트
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredImages) { image in
                            ListImageRow(
                                image: image,
                                library: selectedLibrary,
                                nukeLoader: nukeLoader,
                                kingfisherLoader: kingfisherLoader,
                                searchManager: searchManager
                            )
                            .onTapGesture {
                                selectedImageID = image.id
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await imageProvider.refresh()
                }
            }
            .navigationTitle("리스트 갤러리")
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
                        library: selectedLibrary == .nuke ? .nuke : .kingfisher,
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

/// 리스트 이미지 행
struct ListImageRow: View {
    let image: ImageModel
    let library: ListGalleryView.ImageLibrary
    let nukeLoader: NukeImageLoader
    let kingfisherLoader: KingfisherImageLoader
    let searchManager: SearchManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 이미지
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
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 정보
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(image.author)
                        .font(.headline)
                    
                    Text("\(image.width) × \(image.height)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(image.sizeCategory.description)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                // 좋아요 & 북마크
                HStack(spacing: 16) {
                    Button {
                        searchManager.toggleLike(for: image.id)
                    } label: {
                        Image(systemName: searchManager.isLiked(image.id) ? "heart.fill" : "heart")
                            .foregroundStyle(searchManager.isLiked(image.id) ? .red : .gray)
                    }
                    
                    Button {
                        searchManager.toggleBookmark(for: image.id)
                    } label: {
                        Image(systemName: searchManager.isBookmarked(image.id) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(searchManager.isBookmarked(image.id) ? .yellow : .gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ListGalleryView()
}

