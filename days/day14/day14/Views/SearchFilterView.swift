//
//  SearchFilterView.swift
//  day14
//
//  검색 및 필터링 뷰
//

import SwiftUI
import NukeUI

struct SearchFilterView: View {
    @State private var imageProvider = ImageProvider()
    @State private var searchManager = SearchManager()
    @State private var nukeLoader = NukeImageLoader()
    
    @State private var selectedImageID: String?
    @State private var showBookmarksOnly = false
    @State private var showLikesOnly = false
    
    var filteredImages: [ImageModel] {
        var images = searchManager.filterImages(imageProvider.allImages)
        
        if showBookmarksOnly {
            images = images.filter { searchManager.isBookmarked($0.id) }
        }
        
        if showLikesOnly {
            images = images.filter { searchManager.isLiked($0.id) }
        }
        
        return images
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색 바
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    
                    TextField("작가명으로 검색", text: $searchManager.searchText)
                    
                    if !searchManager.searchText.isEmpty {
                        Button {
                            searchManager.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                
                // 필터 옵션
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 카테고리 필터
                        ForEach(ImageSizeCategory.allCases) { category in
                            FilterChip(
                                title: category.rawValue,
                                isSelected: searchManager.selectedCategory == category
                            ) {
                                searchManager.selectedCategory = category
                            }
                        }
                        
                        Divider()
                            .frame(height: 30)
                        
                        // 북마크 필터
                        FilterChip(
                            title: "북마크",
                            icon: "bookmark.fill",
                            isSelected: showBookmarksOnly
                        ) {
                            showBookmarksOnly.toggle()
                        }
                        
                        // 좋아요 필터
                        FilterChip(
                            title: "좋아요",
                            icon: "heart.fill",
                            isSelected: showLikesOnly
                        ) {
                            showLikesOnly.toggle()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // 결과 정보
                HStack {
                    Text("\(filteredImages.count)개 결과")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if searchManager.searchText.isEmpty && 
                       searchManager.selectedCategory == .all && 
                       !showBookmarksOnly && 
                       !showLikesOnly {
                        // 필터 없음
                    } else {
                        Button {
                            resetFilters()
                        } label: {
                            Text("필터 초기화")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                Divider()
                
                // 결과 리스트
                if filteredImages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        
                        Text("검색 결과가 없습니다")
                            .font(.headline)
                            .foregroundStyle(.gray)
                        
                        Text("다른 검색어나 필터를 시도해보세요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredImages) { image in
                                SearchResultRow(
                                    image: image,
                                    searchManager: searchManager,
                                    nukeLoader: nukeLoader
                                )
                                .onTapGesture {
                                    selectedImageID = image.id
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("검색 & 필터")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedImageID) { imageID in
                if let image = imageProvider.getImage(by: imageID) {
                    ImageDetailView(
                        image: image,
                        searchManager: searchManager,
                        library: .nuke,
                        nukeLoader: nukeLoader,
                        kingfisherLoader: KingfisherImageLoader()
                    )
                }
            }
        }
    }
    
    private func resetFilters() {
        searchManager.resetSearch()
        showBookmarksOnly = false
        showLikesOnly = false
    }
}

/// 필터 칩
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

/// 검색 결과 행
struct SearchResultRow: View {
    let image: ImageModel
    let searchManager: SearchManager
    let nukeLoader: NukeImageLoader
    
    var body: some View {
        HStack(spacing: 12) {
            // 썸네일
            LazyImage(url: URL(string: image.thumbnailURL(size: 100))) { state in
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
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(image.author)
                    .font(.headline)
                
                Text("\(image.width) × \(image.height)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Text(image.sizeCategory.description)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    if searchManager.isBookmarked(image.id) {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    
                    if searchManager.isLiked(image.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    SearchFilterView()
}

