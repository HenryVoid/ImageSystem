//
//  UIImageViewGIFView.swift
//  day19
//
//  UIKit 기반 GIF 재생 뷰
//

import SwiftUI
import UIKit

/// UIImageView를 사용한 GIF 뷰 (UIKit)
struct UIImageViewGIFView: View {
    @State private var gifURL: URL?
    @State private var isPlaying = false
    @State private var frameCount: Int = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // GIF 표시 영역
            if let url = gifURL {
                GIFImageView(url: url, isPlaying: $isPlaying)
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
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
                Button(action: selectGIF) {
                    Label("GIF 선택", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                if gifURL != nil {
                    Button(action: { isPlaying.toggle() }) {
                        Label(isPlaying ? "일시정지" : "재생", systemImage: isPlaying ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            
            // 설명
            VStack(alignment: .leading, spacing: 4) {
                Text("UIImageView + UIImage.animatedImage")
                    .font(.headline)
                Text("• 모든 프레임을 메모리에 로드")
                    .font(.caption)
                Text("• 간단한 구현")
                    .font(.caption)
                Text("• 작은 GIF에 적합")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("UIImageView")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSampleGIF()
        }
    }
    
    private func selectGIF() {
        // 실제 앱에서는 파일 선택기 사용
        // 여기서는 샘플 GIF 로드
        loadSampleGIF()
    }
    
    private func loadSampleGIF() {
        // 샘플 GIF URL (실제로는 프로젝트에 포함된 GIF 사용)
        // 예시: 네트워크 GIF URL
        if let url = URL(string: "https://media.giphy.com/media/3o7aCTPPm4OHfRLSH6/giphy.gif") {
            gifURL = url
            loadGIFInfo(from: url)
        }
    }
    
    private func loadGIFInfo(from url: URL) {
        Task {
            do {
                let parser = GIFParser(url: url)
                let metadata = try await parser.extractMetadata()
                
                await MainActor.run {
                    self.frameCount = metadata.frameCount
                    self.totalDuration = metadata.totalDuration
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

/// UIImageView 래퍼
struct GIFImageView: UIViewRepresentable {
    let url: URL
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // GIF 로드
        loadGIF(into: imageView)
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        if isPlaying {
            // 애니메이션 시작
            if let images = uiView.animationImages, images.count > 0 {
                uiView.startAnimating()
            }
        } else {
            uiView.stopAnimating()
        }
    }
    
    private func loadGIF(into imageView: UIImageView) {
        Task {
            do {
                let parser = GIFParser(url: url)
                let frames = try await parser.parseFrames()
                
                let images = frames.map { $0.image }
                let totalDuration = frames.map { $0.delay }.reduce(0, +)
                
                await MainActor.run {
                    imageView.animationImages = images
                    imageView.animationDuration = totalDuration
                    imageView.animationRepeatCount = 0 // 무한 반복
                    imageView.image = images.first
                    
                    if isPlaying {
                        imageView.startAnimating()
                    }
                }
            } catch {
                await MainActor.run {
                    print("GIF 로드 실패: \(error)")
                }
            }
        }
    }
}

/// 플레이스홀더 뷰
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.artframe")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("GIF를 선택하세요")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
}

/// 정보 행
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationView {
        UIImageViewGIFView()
    }
}

