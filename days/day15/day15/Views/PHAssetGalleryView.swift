//
//  PHAssetGalleryView.swift
//  day15
//
//  PHAsset으로 갤러리 그리드 구현
//

import SwiftUI
import Photos

struct PHAssetGalleryView: View {
    @StateObject private var libraryManager = PhotoLibraryManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var selectedAsset: PhotoAsset?
    @State private var showingFullImage = false
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 4)
    ]
    
    var body: some View {
        VStack {
            if !permissionManager.isAuthorized {
                // 권한 없음
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("사진 접근 권한이 필요합니다")
                        .font(.headline)
                    
                    Button("권한 요청") {
                        Task {
                            await permissionManager.requestPermission()
                            if permissionManager.isAuthorized {
                                libraryManager.fetchAllPhotos()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if libraryManager.isLoading {
                // 로딩 중
                ProgressView("사진 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if libraryManager.assets.isEmpty {
                // 사진 없음
                VStack(spacing: 20) {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("사진이 없습니다")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 갤러리 그리드
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(libraryManager.assets) { photoAsset in
                            ThumbnailCell(
                                asset: photoAsset.asset,
                                libraryManager: libraryManager
                            )
                            .onTapGesture {
                                selectedAsset = photoAsset
                                showingFullImage = true
                            }
                        }
                    }
                    .padding(4)
                }
            }
        }
        .navigationTitle("PHAsset 갤러리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if permissionManager.isAuthorized {
                libraryManager.fetchAllPhotos()
            }
        }
        .sheet(item: $selectedAsset) { photoAsset in
            FullImageView(asset: photoAsset.asset, libraryManager: libraryManager)
        }
    }
}

// MARK: - Thumbnail Cell

struct ThumbnailCell: View {
    let asset: PHAsset
    let libraryManager: PhotoLibraryManager
    
    @State private var thumbnail: UIImage?
    @State private var requestID: PHImageRequestID?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .cornerRadius(4)
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            cancelLoading()
        }
    }
    
    private func loadThumbnail() {
        let screenScale = UIScreen.main.scale
        let targetSize = CGSize(width: 200 * screenScale, height: 200 * screenScale)
        
        requestID = libraryManager.loadThumbnail(for: asset, targetSize: targetSize) { image in
            thumbnail = image
        }
    }
    
    private func cancelLoading() {
        if let requestID = requestID {
            libraryManager.cancelImageRequest(requestID)
        }
    }
}

// MARK: - Full Image View

struct FullImageView: View {
    let asset: PHAsset
    let libraryManager: PhotoLibraryManager
    
    @State private var fullImage: UIImage?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if let fullImage = fullImage {
                    ScrollView {
                        Image(uiImage: fullImage)
                            .resizable()
                            .scaledToFit()
                    }
                } else if isLoading {
                    ProgressView("이미지 로딩 중...")
                } else {
                    Text("이미지를 불러올 수 없습니다")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("이미지 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadFullImage()
        }
    }
    
    private func loadFullImage() {
        libraryManager.loadFullSizeImage(for: asset) { image in
            fullImage = image
            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        PHAssetGalleryView()
    }
}
