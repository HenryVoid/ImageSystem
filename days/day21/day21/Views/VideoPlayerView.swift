import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let asset: MediaAsset
    
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func loadVideo() {
        PhotoLibraryService.shared.requestPlayerItem(for: asset) { item in
            DispatchQueue.main.async {
                if let item = item {
                    self.player = AVPlayer(playerItem: item)
                }
            }
        }
    }
}

