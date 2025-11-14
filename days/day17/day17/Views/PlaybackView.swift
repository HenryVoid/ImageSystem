//
//  PlaybackView.swift
//  day17
//
//  저장된 동영상 재생 뷰
//

import SwiftUI
import AVKit

struct PlaybackView: View {
    @State private var videos: [URL] = []
    @State private var selectedVideo: URL?
    @State private var showPlayer = false
    @State private var showDeleteAlert = false
    @State private var videoToDelete: URL?
    
    var body: some View {
        NavigationView {
            List {
                if videos.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("저장된 동영상이 없습니다")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("녹화한 동영상이 여기에 표시됩니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(videos, id: \.self) { videoURL in
                        VideoRow(
                            videoURL: videoURL,
                            onTap: {
                                selectedVideo = videoURL
                                showPlayer = true
                            },
                            onDelete: {
                                videoToDelete = videoURL
                                showDeleteAlert = true
                            }
                        )
                    }
                }
            }
            .navigationTitle("저장된 동영상")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadVideos()
            }
            .refreshable {
                loadVideos()
            }
            .sheet(isPresented: $showPlayer) {
                if let videoURL = selectedVideo {
                    VideoPlayerView(videoURL: videoURL)
                }
            }
            .alert("동영상 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let videoURL = videoToDelete {
                        deleteVideo(videoURL)
                    }
                }
            } message: {
                Text("이 동영상을 삭제하시겠습니까?")
            }
        }
    }
    
    private func loadVideos() {
        videos = VideoFileManager.getRecordedVideos()
    }
    
    private func deleteVideo(_ url: URL) {
        if VideoFileManager.deleteFile(url: url) {
            loadVideos()
        }
    }
}

// MARK: - Video Row

struct VideoRow: View {
    let videoURL: URL
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var duration: TimeInterval?
    @State private var fileSize: String = ""
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 썸네일
                ZStack {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "video.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 80, height: 60)
                .cornerRadius(8)
                .clipped()
                
                // 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(videoURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        if let duration = duration {
                            Label(formatTime(duration), systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(fileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let creationDate = VideoFileManager.getCreationDate(url: videoURL) {
                        Text(formatDate(creationDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 삭제 버튼
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
            loadMetadata()
        }
    }
    
    private func loadThumbnail() {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        
        Task {
            do {
                let cgImage = try await imageGenerator.image(at: time).image
                await MainActor.run {
                    thumbnail = UIImage(cgImage: cgImage)
                }
            } catch {
                print("썸네일 생성 실패: \(error)")
            }
        }
    }
    
    private func loadMetadata() {
        // 파일 크기
        let size = VideoFileManager.getFileSize(url: videoURL)
        fileSize = VideoFileManager.formatFileSize(size)
        
        // 지속 시간
        Task {
            if let duration = VideoFileManager.getDuration(url: videoURL) {
                await MainActor.run {
                    self.duration = duration
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .navigationTitle("동영상 재생")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("완료") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    player = AVPlayer(url: videoURL)
                    player?.play()
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
        }
    }
}

#Preview {
    PlaybackView()
}

