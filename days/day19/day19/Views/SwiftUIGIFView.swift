//
//  SwiftUIGIFView.swift
//  day19
//
//  SwiftUI 네이티브 GIF 재생 뷰
//

import SwiftUI

/// SwiftUI 커스텀 GIF 뷰
struct SwiftUIGIFView: View {
    @State private var animator: GIFAnimator?
    @State private var gifURL: URL?
    @State private var frameCount: Int = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            // GIF 표시 영역
            if let animator = animator, let frame = animator.currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .drawingGroup() // 메탈 렌더링 최적화
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 400)
            } else {
                PlaceholderView()
            }
            
            // 정보 표시
            VStack(alignment: .leading, spacing: 8) {
                if frameCount > 0, let animator = animator {
                    InfoRow(label: "프레임 수", value: "\(frameCount)")
                    InfoRow(label: "애니메이션 길이", value: String(format: "%.2f초", totalDuration))
                    InfoRow(label: "현재 프레임", value: "\(animator.currentFrameIndex + 1)/\(frameCount)")
                    InfoRow(label: "현재 루프", value: "\(animator.currentLoop)")
                    InfoRow(label: "상태", value: animator.state.description)
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
                
                if gifURL != nil, let animator = animator {
                    Button(action: { togglePlayPause(animator: animator) }) {
                        Label(
                            animator.state == .playing ? "일시정지" : "재생",
                            systemImage: animator.state == .playing ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { resetAnimation(animator: animator) }) {
                        Label("리셋", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            
            // 설명
            VStack(alignment: .leading, spacing: 4) {
                Text("SwiftUI 커스텀 구현")
                    .font(.headline)
                Text("• 지연 로딩 지원")
                    .font(.caption)
                Text("• 프레임 캐싱")
                    .font(.caption)
                Text("• 메모리 효율적")
                    .font(.caption)
                Text("• 큰 GIF 처리 가능")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("SwiftUI")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSampleGIF()
        }
    }
    
    private func selectGIF() {
        loadSampleGIF()
    }
    
    private func loadSampleGIF() {
        isLoading = true
        errorMessage = nil
        
        // 샘플 GIF URL
        guard let url = URL(string: "https://media.giphy.com/media/3o7aCTPPm4OHfRLSH6/giphy.gif") else {
            isLoading = false
            return
        }
        
        gifURL = url
        
        Task {
            do {
                let parser = GIFParser(url: url)
                
                // 메타데이터 로드
                let metadata = try await parser.extractMetadata()
                
                // 프레임 파싱
                let frames = try await parser.parseFrames()
                
                await MainActor.run {
                    self.frameCount = metadata.frameCount
                    self.totalDuration = metadata.totalDuration
                    
                    // 애니메이터 생성
                    let newAnimator = GIFAnimator(frames: frames, loopCount: 0)
                    newAnimator.onAnimationComplete = {
                        // 애니메이션 완료 처리
                    }
                    
                    // 애니메이션 시작
                    newAnimator.start()
                    
                    self.animator = newAnimator
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
    
    private func togglePlayPause(animator: GIFAnimator) {
        switch animator.state {
        case .playing:
            animator.pause()
        case .paused, .stopped:
            animator.resume()
        }
    }
    
    private func resetAnimation(animator: GIFAnimator) {
        animator.stop()
        animator.start()
    }
}

/// 애니메이션 상태 설명
extension GIFAnimationState {
    var description: String {
        switch self {
        case .stopped:
            return "정지"
        case .playing:
            return "재생 중"
        case .paused:
            return "일시정지"
        }
    }
}

#Preview {
    NavigationView {
        SwiftUIGIFView()
    }
}

