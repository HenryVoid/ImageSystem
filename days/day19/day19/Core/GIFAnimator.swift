//
//  GIFAnimator.swift
//  day19
//
//  GIF 애니메이션 재생 로직
//

import Foundation
import UIKit
import QuartzCore

/// GIF 애니메이션 재생 상태
enum GIFAnimationState {
    case stopped
    case playing
    case paused
}

/// GIF 애니메이션 재생기
class GIFAnimator: ObservableObject {
    /// 현재 프레임
    @Published var currentFrame: UIImage?
    
    /// 현재 프레임 인덱스
    @Published var currentFrameIndex: Int = 0
    
    /// 재생 상태
    @Published var state: GIFAnimationState = .stopped
    
    /// 루프 횟수 (0 = 무한)
    @Published var loopCount: Int = 0
    
    /// 현재 루프 횟수
    @Published var currentLoop: Int = 0
    
    /// 프레임들
    private let frames: [GIFFrame]
    
    /// Display Link
    private var displayLink: CADisplayLink?
    
    /// 누적 시간
    private var accumulatedTime: TimeInterval = 0
    
    /// 마지막 프레임 시간
    private var lastFrameTime: CFTimeInterval = 0
    
    /// 애니메이션 완료 콜백
    var onAnimationComplete: (() -> Void)?
    
    /// 초기화
    init(frames: [GIFFrame], loopCount: Int = 0) {
        self.frames = frames
        self.loopCount = loopCount
        
        // 첫 프레임 표시
        if !frames.isEmpty {
            self.currentFrame = frames[0].image
        }
    }
    
    /// 애니메이션 시작
    @MainActor
    func start() {
        guard state != .playing else { return }
        guard !frames.isEmpty else { return }
        
        state = .playing
        
        // Display Link 생성
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
        
        lastFrameTime = CACurrentMediaTime()
    }
    
    /// 애니메이션 일시정지
    @MainActor
    func pause() {
        guard state == .playing else { return }
        
        state = .paused
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// 애니메이션 재개
    @MainActor
    func resume() {
        guard state == .paused else { return }
        
        state = .playing
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
        
        lastFrameTime = CACurrentMediaTime()
    }
    
    /// 애니메이션 정지
    @MainActor
    func stop() {
        state = .stopped
        displayLink?.invalidate()
        displayLink = nil
        
        currentFrameIndex = 0
        currentLoop = 0
        accumulatedTime = 0
        
        // 첫 프레임으로 리셋
        if !frames.isEmpty {
            currentFrame = frames[0].image
        }
    }
    
    /// 프레임 업데이트
    @objc nonisolated private func updateFrame(_ displayLink: CADisplayLink) {
        Task { @MainActor in
            guard self.state == .playing else { return }
            guard !self.frames.isEmpty else { return }
            
            let currentTime = displayLink.timestamp
            let deltaTime = currentTime - self.lastFrameTime
            self.lastFrameTime = currentTime
            
            // 누적 시간 업데이트
            self.accumulatedTime += deltaTime
            
            // 현재 프레임의 딜레이 확인
            let currentDelay = self.frames[self.currentFrameIndex].delay
            
            if self.accumulatedTime >= currentDelay {
                // 다음 프레임으로 이동
                self.moveToNextFrame()
                self.accumulatedTime = 0
            }
        }
    }
    
    /// 다음 프레임으로 이동
    @MainActor
    private func moveToNextFrame() {
        currentFrameIndex += 1
        
        // 마지막 프레임인지 확인
        if currentFrameIndex >= frames.count {
            currentLoop += 1
            
            // 루프 제한 확인
            if loopCount > 0 && currentLoop >= loopCount {
                stop()
                onAnimationComplete?()
                return
            }
            
            // 처음으로 돌아가기
            currentFrameIndex = 0
        }
        
        // 현재 프레임 업데이트
        currentFrame = frames[currentFrameIndex].image
    }
    
    /// 특정 프레임으로 이동
    @MainActor
    func seek(to index: Int) {
        guard index >= 0 && index < frames.count else { return }
        
        let wasPlaying = state == .playing
        
        if wasPlaying {
            pause()
        }
        
        currentFrameIndex = index
        currentFrame = frames[index].image
        accumulatedTime = 0
        
        if wasPlaying {
            resume()
        }
    }
    
    /// 특정 시간으로 이동
    @MainActor
    func seek(to time: TimeInterval) {
        var accumulated: TimeInterval = 0
        
        for (index, frame) in frames.enumerated() {
            accumulated += frame.delay
            
            if accumulated >= time {
                seek(to: index)
                return
            }
        }
        
        // 시간이 총 길이를 초과하면 마지막 프레임으로
        seek(to: frames.count - 1)
    }
    
    /// 현재 애니메이션 시간
    var currentTime: TimeInterval {
        var time: TimeInterval = 0
        for i in 0..<currentFrameIndex {
            time += frames[i].delay
        }
        time += accumulatedTime
        return time
    }
    
    /// 총 애니메이션 길이
    var totalDuration: TimeInterval {
        frames.map { $0.delay }.reduce(0, +)
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

/// 간단한 GIF 애니메이션 (Timer 기반)
class SimpleGIFAnimator: ObservableObject {
    @Published var currentFrame: UIImage?
    @Published var currentFrameIndex: Int = 0
    
    private let frames: [GIFFrame]
    private var timer: Timer?
    private var currentIndex = 0
    
    init(frames: [GIFFrame]) {
        self.frames = frames
        
        if !frames.isEmpty {
            self.currentFrame = frames[0].image
        }
    }
    
    func start() {
        guard timer == nil else { return }
        guard !frames.isEmpty else { return }
        
        scheduleNextFrame()
    }
    
    private func scheduleNextFrame() {
        guard currentIndex < frames.count else {
            // 루프: 처음으로 돌아가기
            currentIndex = 0
            scheduleNextFrame()
            return
        }
        
        let frame = frames[currentIndex]
        currentFrame = frame.image
        currentFrameIndex = currentIndex
        
        timer = Timer.scheduledTimer(withTimeInterval: frame.delay, repeats: false) { [weak self] _ in
            self?.currentIndex += 1
            self?.scheduleNextFrame()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        currentIndex = 0
        currentFrameIndex = 0
        
        if !frames.isEmpty {
            currentFrame = frames[0].image
        }
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        scheduleNextFrame()
    }
    
    deinit {
        timer?.invalidate()
    }
}

