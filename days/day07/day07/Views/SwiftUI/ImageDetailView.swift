//
//  ImageDetailView.swift
//  day07
//
//  SwiftUI 이미지 상세보기 (줌/패닝 지원)
//

import SwiftUI

/// 이미지 상세 뷰
struct ImageDetailView: View {
    let imageName: String
    let format: String
    
    @State private var image: UIImage?
    @State private var metadata: ImageMetadata?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showMetadata = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale *= delta
                                    // 최소/최대 스케일 제한
                                    scale = min(max(scale, 0.5), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            // 더블탭으로 리셋
                            withAnimation(.spring()) {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                } else {
                    ProgressView()
                        .tint(.white)
                }
                
                // 메타데이터 오버레이
                if showMetadata, let metadata = metadata {
                    VStack {
                        Spacer()
                        MetadataOverlay(metadata: metadata)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle(imageName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showMetadata.toggle()
                } label: {
                    Image(systemName: showMetadata ? "info.circle.fill" : "info.circle")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button("리셋") {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let signpost = Signpost.imageLoad(label: imageName)
        signpost.begin()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageLoader.shared.loadUIImage(named: imageName)
            let loadedMetadata = ImageLoader.shared.extractMetadata(named: imageName)
            
            DispatchQueue.main.async {
                signpost.end()
                self.image = loadedImage
                self.metadata = loadedMetadata
                
                if let img = loadedImage {
                    PerformanceLogger.log("이미지 로드 완료: \(imageName) (\(Int(img.size.width))x\(Int(img.size.height)))", category: "loading")
                }
            }
        }
    }
}

/// 메타데이터 오버레이
struct MetadataOverlay: View {
    let metadata: ImageMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("메타데이터", systemImage: "info.circle.fill")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            MetadataRow(label: "포맷", value: metadata.format.rawValue)
            MetadataRow(label: "크기", value: "\(Int(metadata.size.width)) × \(Int(metadata.size.height)) px")
            
            if let fileSize = metadata.fileSize {
                MetadataRow(label: "파일 크기", value: ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
            }
            
            MetadataRow(label: "알파 채널", value: metadata.hasAlpha ? "있음" : "없음")
            
            if let colorSpace = metadata.colorSpace {
                MetadataRow(label: "색공간", value: colorSpace)
            }
            
            if let dpi = metadata.dpi {
                MetadataRow(label: "DPI", value: "\(dpi.x) × \(dpi.y)")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 메타데이터 행
struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .bold()
        }
    }
}

#Preview {
    NavigationStack {
        ImageDetailView(imageName: "sample", format: "PNG")
    }
}

