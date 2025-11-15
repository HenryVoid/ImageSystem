//
//  SimpleThumbnailView.swift
//  day18
//
//  기본 썸네일 생성 데모
//

import SwiftUI
import UniformTypeIdentifiers

struct SimpleThumbnailView: View {
    @State private var selectedVideoURL: URL?
    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var timeInput: String = "5.0"
    @State private var videoDuration: TimeInterval?
    @State private var generationTime: TimeInterval?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text("기본 썸네일 생성")
                        .font(.title)
                        .bold()
                    
                    Text("동영상에서 특정 시간의 썸네일을 추출합니다.")
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
                
                // 시간 입력
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("시간 (초)")
                                .font(.headline)
                            
                            Spacer()
                            
                            if let duration = videoDuration {
                                Text("최대: \(formatTime(duration))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        TextField("예: 5.0", text: $timeInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        
                        // 빠른 시간 선택 버튼
                        if let duration = videoDuration {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    QuickTimeButton(time: 0, duration: duration, action: { time in
                                        timeInput = String(format: "%.1f", time)
                                    })
                                    
                                    QuickTimeButton(time: duration / 4, duration: duration, action: { time in
                                        timeInput = String(format: "%.1f", time)
                                    })
                                    
                                    QuickTimeButton(time: duration / 2, duration: duration, action: { time in
                                        timeInput = String(format: "%.1f", time)
                                    })
                                    
                                    QuickTimeButton(time: duration * 3 / 4, duration: duration, action: { time in
                                        timeInput = String(format: "%.1f", time)
                                    })
                                    
                                    QuickTimeButton(time: duration - 1, duration: duration, action: { time in
                                        timeInput = String(format: "%.1f", time)
                                    })
                                }
                            }
                        }
                    }
                } header: {
                    Text("썸네일 추출 시간")
                }
                
                // 생성 버튼
                Button(action: generateThumbnail) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "photo.badge.plus")
                        }
                        
                        Text(isLoading ? "생성 중..." : "썸네일 생성")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedVideoURL != nil && !isLoading ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedVideoURL == nil || isLoading)
                
                // 성능 정보
                if let genTime = generationTime {
                    HStack {
                        Image(systemName: "clock")
                        Text("생성 시간: \(String(format: "%.3f", genTime))초")
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
                
                // 썸네일 표시
                if let thumbnail = thumbnail {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("생성된 썸네일")
                            .font(.headline)
                        
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        Text("크기: \(Int(thumbnail.size.width)) × \(Int(thumbnail.size.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
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
        .navigationTitle("기본 썸네일")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: .constant(false),
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                selectedVideoURL = url
                loadVideoInfo()
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectVideo() {
        // DocumentPicker를 사용하려면 UIViewControllerRepresentable 필요
        // 여기서는 간단히 샘플 비디오 URL 사용
        // 실제 구현에서는 DocumentPicker 사용 권장
        if let sampleVideoURL = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
            selectedVideoURL = sampleVideoURL
            loadVideoInfo()
        } else {
            // 샘플 비디오가 없으면 사용자에게 알림
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
    
    private func generateThumbnail() {
        guard let url = selectedVideoURL,
              let time = Double(timeInput) else {
            errorMessage = "유효한 시간을 입력하세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        thumbnail = nil
        
        Task {
            let (result, duration) = await PerformanceMeasurer.measureTime {
                try await ThumbnailGenerator.generateThumbnail(from: url, at: time)
            }
            
            await MainActor.run {
                isLoading = false
                generationTime = duration
                
                do {
                    thumbnail = try result.get()
                    PerformanceLogger.log("썸네일 생성 완료: \(duration)초", category: "benchmark")
                } catch {
                    errorMessage = "썸네일 생성 실패: \(error.localizedDescription)"
                    PerformanceLogger.error("썸네일 생성 실패: \(error.localizedDescription)")
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

// MARK: - Quick Time Button

struct QuickTimeButton: View {
    let time: TimeInterval
    let duration: TimeInterval
    let action: (TimeInterval) -> Void
    
    var body: some View {
        Button(action: {
            action(time)
        }) {
            Text(formatTime(time))
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
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
        SimpleThumbnailView()
    }
}

