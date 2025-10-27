//
//  GalleryGridView.swift
//  day07
//
//  SwiftUI 썸네일 그리드 뷰
//

import SwiftUI

/// 이미지 아이템
struct ImageItem: Identifiable {
    let id = UUID()
    let name: String
    let format: String
    
    static let samples: [ImageItem] = [
        ImageItem(name: "sample", format: "PNG"),
        ImageItem(name: "sample2", format: "PNG"),
        ImageItem(name: "sample3", format: "WebP")
    ]
}

/// 갤러리 그리드 뷰
struct GalleryGridView: View {
    let items = ImageItem.samples
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    @State private var selectedItem: ImageItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        NavigationLink {
                            ImageDetailView(imageName: item.name, format: item.format)
                        } label: {
                            ThumbnailCell(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("SwiftUI 갤러리")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 썸네일 셀
struct ThumbnailCell: View {
    let item: ImageItem
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 4) {
            // 썸네일 이미지
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                // 포맷 뱃지
                VStack {
                    HStack {
                        Text(item.format)
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(formatColor(item.format))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(6)
            }
            
            // 이미지 이름
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let signpost = Signpost.thumbnail(label: item.name)
        signpost.begin()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let thumb = ImageCache.shared.getThumbnailOrCreate(forKey: item.name, maxSize: 200)
            
            DispatchQueue.main.async {
                signpost.end()
                self.thumbnail = thumb
            }
        }
    }
    
    private func formatColor(_ format: String) -> Color {
        switch format {
        case "JPEG": return .orange
        case "PNG": return .blue
        case "WebP": return .green
        default: return .gray
        }
    }
}

#Preview {
    GalleryGridView()
}

