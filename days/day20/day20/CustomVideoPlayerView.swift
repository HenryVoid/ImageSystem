//
//  CustomVideoPlayerView.swift
//  day20
//
//  Created by 송형욱 on 11/19/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct CustomVideoPlayerView: UIViewRepresentable {
    @Bindable var viewModel: VideoPlayerViewModel
    
    func makeUIView(context: Context) -> PlayerView {
        let playerView = PlayerView()
        playerView.setupPlayer(viewModel.player)
        return playerView
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
        // 플레이어가 변경되면 업데이트
        if uiView.player !== viewModel.player {
            uiView.setupPlayer(viewModel.player)
        }
    }
}

// MARK: - PlayerView
class PlayerView: UIView {
    private var playerLayer: AVPlayerLayer?
    var player: AVPlayer? {
        didSet {
            setupPlayerLayer()
        }
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayerLayer()
    }
    
    func setupPlayer(_ player: AVPlayer?) {
        self.player = player
    }
    
    private func setupPlayerLayer() {
        if let playerLayer = self.layer as? AVPlayerLayer {
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
            self.playerLayer = playerLayer
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

