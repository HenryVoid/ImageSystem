//
//  NukeGIFView.swift
//  day19
//
//  Nuke를 활용한 GIF 로딩 및 재생
//

import SwiftUI
import Nuke

/// Nuke를 사용한 GIF 뷰
struct NukeGIFView: View {
    @State private var gifURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var frameCount: Int = 0
    @State private var totalDuration: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // GIF 표시 영역
            if let url = gifURL {
                AsyncGIFImage(url: url)
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 400)
            } else {
                PlaceholderView()
            }
            
            // 정보 표시
            VStack(alignment: .leading, spacing: 8) {
                if frameCount > 0 {
                    InfoRow(label: "프레임 수", value: "\(frameCount)")
                    InfoRow(label: "애니메이션 길이", value: String(format: "%.2f초", totalDuration))
                }
                
                if let error = errorMessage {
                    Text("오류: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // 컨트롤 버튼
            HStack(spacing: 16) {
                Button(action: loadGIF) {
                    Label("GIF 로드", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            // 설명
            VStack(alignment: .leading, spacing: 4) {
                Text("Nuke 라이브러리")
                    .font(.headline)
                Text("• 네트워크 GIF 지원")
                    .font(.caption)
                Text("• 자동 캐싱")
                    .font(.caption)
                Text("• 최적화된 디코딩")
                    .font(.caption)
                Text("• 프로덕션 레벨 성능")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Nuke")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGIF()
        }
    }
    
    private func loadGIF() {
        isLoading = true
        errorMessage = nil
        
        // 샘플 GIF URL
        guard let url = URL(string: "https://media.giphy.com/media/3o7aCTPPm4OHfRLSH6/giphy.gif") else {
            isLoading = false
            errorMessage = "유효하지 않은 URL"
            return
        }
        
        gifURL = url
        
        // 메타데이터 로드
        Task {
            do {
                let parser = GIFParser(url: url)
                let metadata = try await parser.extractMetadata()
                
                await MainActor.run {
                    self.frameCount = metadata.frameCount
                    self.totalDuration = metadata.totalDuration
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

/// Nuke를 사용한 비동기 GIF 이미지
struct AsyncGIFImage: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.gray)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Nuke로 이미지 로드
        await withCheckedContinuation { continuation in
            ImagePipeline.shared.loadImage(with: url) { result in
                switch result {
                case .success(let response):
                    Task { @MainActor in
                        // Nuke는 애니메이션 GIF를 UIImage로 반환
                        // UIImage.animatedImage가 자동으로 처리됨
                        self.image = response.image
                        self.isLoading = false
                        continuation.resume()
                    }
                case .failure(let error):
                    Task { @MainActor in
                        self.isLoading = false
                        print("이미지 로드 실패: \(error)")
                        continuation.resume()
                    }
                }
            }
        }
    }
}

/// Nuke를 사용한 GIF 뷰 (UIImageView 래퍼)
struct NukeGIFImageView: UIViewRepresentable {
    let url: URL
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // Nuke로 이미지 로드
        loadImage(into: imageView)
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        if isPlaying {
            if let images = uiView.animationImages, images.count > 0 {
                uiView.startAnimating()
            }
        } else {
            uiView.stopAnimating()
        }
    }
    
    private func loadImage(into imageView: UIImageView) {
        // Nuke 옵션 설정
        let options = ImageLoadingOptions(
            placeholder: UIImage(systemName: "photo"),
            failureImage: UIImage(systemName: "exclamationmark.triangle"),
            contentModes: .init(success: .scaleAspectFit, failure: .scaleAspectFit, placeholder: .scaleAspectFit)
        )
        
        // 이미지 로드
        Nuke.loadImage(with: url, options: options, into: imageView) { result in
            switch result {
            case .success(let response):
                // 애니메이션 GIF인 경우 자동으로 처리됨
                if let animatedImage = response.image as? UIImage,
                   let images = animatedImage.images,
                   images.count > 1 {
                    // 애니메이션 이미지 설정
                    imageView.animationImages = images
                    imageView.animationDuration = animatedImage.duration
                    imageView.animationRepeatCount = 0
                    imageView.image = images.first
                    
                    if isPlaying {
                        imageView.startAnimating()
                    }
                } else {
                    imageView.image = response.image
                }
            case .failure(let error):
                print("이미지 로드 실패: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        NukeGIFView()
    }
}

