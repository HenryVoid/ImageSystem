//
//  CustomVideoPlayer.swift
//  day20
//
//  Created by 송형욱 on 11/19/25.
//

import SwiftUI
import AVFoundation

struct CustomVideoPlayer: View {
    @State private var viewModel: VideoPlayerViewModel
    @State private var showControls: Bool = true
    @State private var controlsTimer: Timer?
    @State private var tapLocation: CGPoint = .zero
    
    let url: URL?
    let autoPlay: Bool
    let showControlsByDefault: Bool
    
    // MARK: - Initialization
    init(url: URL?, autoPlay: Bool = false, showControlsByDefault: Bool = true) {
        self.url = url
        self.autoPlay = autoPlay
        self.showControlsByDefault = showControlsByDefault
        _viewModel = State(initialValue: VideoPlayerViewModel(url: url))
    }
    
    init(playerItem: AVPlayerItem?, autoPlay: Bool = false, showControlsByDefault: Bool = true) {
        self.url = nil
        self.autoPlay = autoPlay
        self.showControlsByDefault = showControlsByDefault
        _viewModel = State(initialValue: VideoPlayerViewModel())
        if let playerItem = playerItem {
            viewModel.setupPlayer(with: playerItem)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 비디오 플레이어
                CustomVideoPlayerView(viewModel: viewModel)
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.black)
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                handleDoubleTap(at: tapLocation, screenWidth: geometry.size.width)
                            }
                            .exclusively(before: TapGesture(count: 1)
                                .onEnded { _ in
                                    handleSingleTap()
                                })
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                tapLocation = value.location
                            }
                            .onEnded { value in
                                tapLocation = value.location
                            }
                    )
            
            // 컨트롤 오버레이
            if showControls {
                VideoPlayerControlsView(viewModel: viewModel)
                    .transition(.opacity)
            }
            
            // 자막 뷰
            CaptionView(viewModel: viewModel)
            
            // 로딩 인디케이터
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            }
        }
        .onAppear {
            showControls = showControlsByDefault
            if autoPlay {
                viewModel.play()
            }
            startControlsTimer()
        }
        .onDisappear {
            stopControlsTimer()
            viewModel.pause()
        }
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if isPlaying {
                startControlsTimer()
            }
        }
    }
    
    // MARK: - Gesture Handlers
    private func handleSingleTap() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            startControlsTimer()
        } else {
            stopControlsTimer()
        }
    }
    
    private func handleDoubleTap(at location: CGPoint, screenWidth: CGFloat) {
        let tapX = location.x
        
        // 화면 왼쪽 절반: 10초 뒤로
        // 화면 오른쪽 절반: 10초 앞으로
        if tapX < screenWidth / 2 {
            viewModel.skipBackward(seconds: 10)
        } else {
            viewModel.skipForward(seconds: 10)
        }
        
        // 컨트롤 표시
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = true
        }
        startControlsTimer()
    }
    
    // MARK: - Controls Timer
    private func startControlsTimer() {
        stopControlsTimer()
        
        // 재생 중일 때만 자동 숨김
        guard viewModel.isPlaying else { return }
        
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func stopControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
    
}

