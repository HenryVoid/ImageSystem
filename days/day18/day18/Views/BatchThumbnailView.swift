//
//  BatchThumbnailView.swift
//  day18
//
//  배치 썸네일 생성 데모
//

import SwiftUI

struct BatchThumbnailView: View {
    @State private var selectedVideoURL: URL?
    @State private var thumbnails: [UIImage?] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var videoDuration: TimeInterval?
    @State private var progress: Double = 0.0
    @State private var generationTime: TimeInterval?
    @State private var thumbnailCount: Int = 4
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text("배치 썸네일 생성")
                        .font(.title)
                        .bold()
                    
                    Text("동영상에서 여러 시간의 썸네일을 한 번에 생성합니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 동영상 선택
                Section {
                    VStack(spacing: 16) {
                        if let videoURL = selectedVideoURL {
                            HStack {
                                Image(systemName: "video.fill")
                                    .foregroundColor(.blue)
                                
                                Text(videoURL.lastPathComponent)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button("변경") {
                                    selectVideo()
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if let duration = videoDuration {
                                Text("동영상 길이: \(formatTime(duration))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: selectVideo) {
                                HStack {
                                    Image(systemName: "video.badge.plus")
                                    Text("동영상 선택")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                } header: {
                    Text("동영상 파일")
                }
                
                // 썸네일 개수 설정
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("썸네일 개수")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(thumbnailCount)개")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Stepper(value: $thumbnailCount, in: 2...20) {
                            Text("\(thumbnailCount)개의 썸네일 생성")
                        }
                    }
                } header: {
                    Text("생성 옵션")
                }
                
                // 생성 버튼
                Button(action: generateThumbnails) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "photo.badge.plus")
                        }
                        
                        Text(isLoading ? "생성 중..." : "배치 썸네일 생성")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedVideoURL != nil && !isLoading ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedVideoURL == nil || isLoading)
                
                // 진행률 표시
                if isLoading {
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("\(Int(progress * 100))% 완료")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 성능 정보
                if let genTime = generationTime {
                    HStack {
                        Image(systemName: "clock")
                        Text("총 생성 시간: \(String(format: "%.3f", genTime))초")
                        
                        Spacer()
                        
                        if !thumbnails.isEmpty {
                            Text("평균: \(String(format: "%.3f", genTime / Double(thumbnails.count)))초/개")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // 에러 메시지
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 썸네일 그리드
                if !thumbnails.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("생성된 썸네일 (\(thumbnails.compactMap { $0 }.count)/\(thumbnails.count))")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(Array(thumbnails.enumerated()), id: \.offset) { index, thumbnail in
                                ThumbnailCell(
                                    thumbnail: thumbnail,
                                    index: index,
                                    totalCount: thumbnails.count,
                                    videoDuration: videoDuration
                                )
                            }
                        }
                    }
                } else if !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("썸네일이 생성되지 않았습니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("배치 썸네일")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Actions
    
    private func selectVideo() {
        if let sampleVideoURL = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
            selectedVideoURL = sampleVideoURL
            loadVideoInfo()
        } else {
            errorMessage = "샘플 비디오를 찾을 수 없습니다. 실제 기기에서 동영상 파일을 선택하세요."
        }
    }
    
    private func loadVideoInfo() {
        guard let url = selectedVideoURL else { return }
        
        Task {
            do {
                let duration = try await ThumbnailGenerator.getDuration(from: url)
                await MainActor.run {
                    videoDuration = duration
                }
            } catch {
                await MainActor.run {
                    errorMessage = "동영상 정보를 불러올 수 없습니다: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func generateThumbnails() {
        guard let url = selectedVideoURL,
              let duration = videoDuration else {
            errorMessage = "동영상을 먼저 선택하세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        thumbnails = []
        progress = 0.0
        
        // 동영상 길이를 균등하게 나눠서 썸네일 생성
        let times = (0..<thumbnailCount).map { index in
            duration * Double(index) / Double(thumbnailCount - 1)
        }
        
        Task {
            let (result, duration) = await PerformanceMeasurer.measureTime {
                try await ThumbnailGenerator.generateThumbnails(
                    from: url,
                    at: times,
                    progressHandler: { progressValue in
                        Task { @MainActor in
                            progress = progressValue
                        }
                    }
                )
            }
            
            await MainActor.run {
                isLoading = false
                generationTime = duration
                
                do {
                    thumbnails = try result.get()
                    let successCount = thumbnails.compactMap { $0 }.count
                    PerformanceLogger.log("배치 썸네일 생성 완료: \(successCount)/\(thumbnailCount)개, \(duration)초", category: "benchmark")
                } catch {
                    errorMessage = "썸네일 생성 실패: \(error.localizedDescription)"
                    PerformanceLogger.error("배치 썸네일 생성 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

// MARK: - Thumbnail Cell

struct ThumbnailCell: View {
    let thumbnail: UIImage?
    let index: Int
    let totalCount: Int
    let videoDuration: TimeInterval?
    
    var body: some View {
        VStack(spacing: 8) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("실패")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            if let duration = videoDuration {
                let time = duration * Double(index) / Double(totalCount - 1)
                Text(formatTime(time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return String(format: "%.1fs", time)
        } else {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    NavigationView {
        BatchThumbnailView()
    }
}

