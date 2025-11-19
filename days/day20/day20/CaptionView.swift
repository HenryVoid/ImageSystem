//
//  CaptionView.swift
//  day20
//
//  Created by 송형욱 on 11/19/25.
//

import SwiftUI
import AVFoundation

struct CaptionView: View {
    @Bindable var viewModel: VideoPlayerViewModel
    
    var body: some View {
        // AVPlayer는 자동으로 자막을 표시하므로,
        // 여기서는 자막이 활성화되었는지만 확인합니다.
        // 실제 커스텀 자막 뷰가 필요한 경우 AVAssetReader를 사용하여
        // 자막 트랙을 읽고 표시해야 합니다.
        EmptyView()
    }
}

// MARK: - Caption Settings View
struct CaptionSettingsView: View {
    @Bindable var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 자막 켜기/끄기
            Toggle("자막 표시", isOn: Binding(
                get: { viewModel.isSubtitlesEnabled },
                set: { viewModel.enableSubtitles($0) }
            ))
            .font(.headline)
            
            if viewModel.isSubtitlesEnabled && !viewModel.availableSubtitles.isEmpty {
                Divider()
                
                Text("자막 선택")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(Array(viewModel.availableSubtitles.enumerated()), id: \.offset) { index, subtitle in
                    Button(action: {
                        viewModel.selectSubtitle(subtitle)
                    }) {
                        HStack {
                            Text(subtitle.displayName)
                            Spacer()
                            if viewModel.selectedSubtitle == subtitle {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            } else if viewModel.isSubtitlesEnabled {
                Text("사용 가능한 자막이 없습니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

