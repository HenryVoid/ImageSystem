//
//  VideoPlayerControlsView.swift
//  day20
//
//  Created by 송형욱 on 11/19/25.
//

import SwiftUI

struct VideoPlayerControlsView: View {
    @Bindable var viewModel: VideoPlayerViewModel
    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            // 하단 컨트롤
            VStack(spacing: 12) {
                // 시크바
                seekBarView
                
                // 컨트롤 버튼들
                HStack(spacing: 20) {
                    // 10초 뒤로
                    Button(action: {
                        viewModel.skipBackward(seconds: 10)
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    // 플레이/일시정지
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    // 10초 앞으로
                    Button(action: {
                        viewModel.skipForward(seconds: 10)
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 볼륨 컨트롤
                    HStack(spacing: 8) {
                        Image(systemName: volumeIcon)
                            .foregroundColor(.white)
                            .frame(width: 20)
                        
                        Slider(value: Binding(
                            get: { viewModel.volume },
                            set: { viewModel.setVolume($0) }
                        ), in: 0...1)
                        .tint(.white)
                        .frame(width: 100)
                    }
                    
                    // 재생 속도
                    Menu {
                        Button("0.5x") { viewModel.setPlaybackRate(0.5) }
                        Button("1.0x") { viewModel.setPlaybackRate(1.0) }
                        Button("1.25x") { viewModel.setPlaybackRate(1.25) }
                        Button("1.5x") { viewModel.setPlaybackRate(1.5) }
                        Button("2.0x") { viewModel.setPlaybackRate(2.0) }
                    } label: {
                        Text(String(format: "%.2fx", viewModel.playbackRate))
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    // MARK: - Seek Bar View
    private var seekBarView: some View {
        HStack(spacing: 12) {
            // 현재 시간
            Text(timeString(from: isDragging ? dragValue : viewModel.currentTime))
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
            
            // 시크바 슬라이더
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 트랙
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // 진행 트랙
                    Rectangle()
                        .fill(Color.white)
                        .frame(
                            width: geometry.size.width * CGFloat(progress),
                            height: 4
                        )
                        .cornerRadius(2)
                    
                    // 드래그 핸들
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * CGFloat(progress) - 6)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let percentage = max(0, min(1, value.location.x / geometry.size.width))
                                    dragValue = percentage * viewModel.duration
                                }
                                .onEnded { value in
                                    isDragging = false
                                    let percentage = max(0, min(1, value.location.x / geometry.size.width))
                                    let seekTime = percentage * viewModel.duration
                                    viewModel.seek(to: seekTime)
                                }
                        )
                }
            }
            .frame(height: 44)
            
            // 총 시간
            Text(timeString(from: viewModel.duration))
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
                .frame(width: 50, alignment: .leading)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Computed Properties
    private var progress: Double {
        guard viewModel.duration > 0 else { return 0 }
        let current = isDragging ? dragValue : viewModel.currentTime
        return current / viewModel.duration
    }
    
    private var volumeIcon: String {
        if viewModel.volume == 0 {
            return "speaker.slash.fill"
        } else if viewModel.volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if viewModel.volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    // MARK: - Helper Methods
    private func timeString(from time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "00:00" }
        
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

