//
//  VideoPlayerViewModel.swift
//  day20
//
//  Created by 송형욱 on 11/19/25.
//

import Foundation
import AVFoundation
import Combine

@Observable
class VideoPlayerViewModel {
    // MARK: - Properties
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var volume: Float = 1.0
    var isLoading: Bool = false
    var playbackRate: Float = 1.0
    
    // 자막 관련
    var availableSubtitles: [AVMediaSelectionOption] = []
    var selectedSubtitle: AVMediaSelectionOption?
    var isSubtitlesEnabled: Bool = false
    
    // MARK: - Private Properties
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(url: URL? = nil) {
        if let url = url {
            setupPlayer(with: url)
        }
    }
    
    // MARK: - Setup
    func setupPlayer(with url: URL) {
        // 기존 관찰자 제거
        removeObservers()
        
        // 새 플레이어 아이템 생성
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // 볼륨 설정
        player?.volume = volume
        
        // 관찰자 설정
        setupObservers()
        
        // 자막 트랙 확인
        checkAvailableSubtitles()
    }
    
    func setupPlayer(with playerItem: AVPlayerItem) {
        removeObservers()
        
        self.playerItem = playerItem
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume
        
        setupObservers()
        checkAvailableSubtitles()
    }
    
    // MARK: - Observers
    private func setupObservers() {
        guard let player = player, let playerItem = playerItem else { return }
        
        // 시간 관찰자 (1초마다 업데이트)
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // 플레이어 아이템 상태 관찰
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handlePlayerItemStatus(status)
            }
            .store(in: &cancellables)
        
        // 로딩 상태 관찰
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReady in
                self?.isLoading = !isReady
            }
            .store(in: &cancellables)
        
        // 재생 시간 관찰
        playerItem.publisher(for: \.duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                if duration.isValid && !duration.isIndefinite {
                    self?.duration = duration.seconds
                }
            }
            .store(in: &cancellables)
        
        // 재생 종료 알림
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPlaying = false
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        cancellables.removeAll()
    }
    
    private func handlePlayerItemStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            isLoading = false
            if let duration = playerItem?.duration, duration.isValid && !duration.isIndefinite {
                self.duration = duration.seconds
            }
        case .failed:
            isLoading = false
            print("Player item failed: \(playerItem?.error?.localizedDescription ?? "Unknown error")")
        case .unknown:
            isLoading = true
        @unknown default:
            break
        }
    }
    
    // MARK: - Playback Control
    func play() {
        player?.play()
        player?.rate = playbackRate
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // MARK: - Seek Control
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime) { [weak self] completed in
            if completed {
                self?.currentTime = time
            }
        }
    }
    
    func skipForward(seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    // MARK: - Volume Control
    func setVolume(_ volume: Float) {
        self.volume = max(0, min(1, volume))
        player?.volume = self.volume
    }
    
    // MARK: - Playback Rate Control
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }
    
    // MARK: - Subtitles
    private func checkAvailableSubtitles() {
        guard let playerItem = playerItem else {
            availableSubtitles = []
            return
        }
        
        guard let asset = playerItem.asset as? AVURLAsset else {
            availableSubtitles = []
            return
        }
        
        // 자막 트랙 찾기
        let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        availableSubtitles = subtitleGroup?.options ?? []
    }
    
    func enableSubtitles(_ enabled: Bool) {
        isSubtitlesEnabled = enabled
        guard let playerItem = playerItem,
              let asset = playerItem.asset as? AVURLAsset else { return }
        
        let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        
        if enabled, let subtitle = selectedSubtitle ?? availableSubtitles.first {
            playerItem.select(subtitle, in: subtitleGroup!)
        } else {
            playerItem.select(nil, in: subtitleGroup!)
        }
    }
    
    func selectSubtitle(_ subtitle: AVMediaSelectionOption) {
        selectedSubtitle = subtitle
        if isSubtitlesEnabled {
            guard let playerItem = playerItem,
                  let asset = playerItem.asset as? AVURLAsset else { return }
            
            let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
            playerItem.select(subtitle, in: subtitleGroup!)
        }
    }
    
    // MARK: - Cleanup
    deinit {
        removeObservers()
        player?.pause()
        player = nil
        playerItem = nil
    }
}


