//
//  ContentView.swift
//  day20
//
//  Created by 송형욱 on 11/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedVideoIndex: Int = 0
    
    // 샘플 비디오 URL들 (공개 테스트 비디오)
    private let sampleVideos: [VideoInfo] = [
        VideoInfo(
            name: "Big Buck Bunny",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
        ),
        VideoInfo(
            name: "Elephant's Dream",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!
        ),
        VideoInfo(
            name: "For Bigger Blazes",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!
        ),
        VideoInfo(
            name: "Sintel",
            url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")!
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 비디오 플레이어
                CustomVideoPlayer(
                    url: sampleVideos[selectedVideoIndex].url,
                    autoPlay: false,
                    showControlsByDefault: true
                )
                .frame(maxHeight: .infinity)
                
                // 비디오 선택 및 설정
                VStack(spacing: 16) {
                    // 비디오 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("비디오 선택")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(sampleVideos.enumerated()), id: \.offset) { index, video in
                                    Button(action: {
                                        selectedVideoIndex = index
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.title)
                                            Text(video.name)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(selectedVideoIndex == index ? .blue : .primary)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedVideoIndex == index ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                    
                    // 기능 설명
                    VStack(alignment: .leading, spacing: 8) {
                        Text("사용 방법")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            FeatureRow(icon: "hand.tap", text: "탭: 컨트롤 표시/숨김")
                            FeatureRow(icon: "hand.tap.fill", text: "더블탭 왼쪽: 10초 뒤로")
                            FeatureRow(icon: "hand.tap.fill", text: "더블탭 오른쪽: 10초 앞으로")
                            FeatureRow(icon: "slider.horizontal.3", text: "시크바 드래그: 원하는 시간으로 이동")
                            FeatureRow(icon: "speaker.wave.3", text: "볼륨 슬라이더: 볼륨 조절")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
            }
            .navigationTitle("VideoPlayer 커스터마이징")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark) // 다크모드 대응
        }
    }
}

// MARK: - Supporting Views
struct VideoInfo {
    let name: String
    let url: URL
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
