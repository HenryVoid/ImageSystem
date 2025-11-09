//
//  MemoryTracker.swift
//  day12
//
//  메모리 사용량 추적
//

import Foundation
import SwiftUI

/// 메모리 추적기
@MainActor
class MemoryTracker: ObservableObject {
    @Published private(set) var usedMemoryMB: Double = 0
    @Published private(set) var peakMemoryMB: Double = 0
    @Published private(set) var averageMemoryMB: Double = 0
    @Published private(set) var didReceiveMemoryWarning: Bool = false
    
    private var timer: Timer?
    private var memoryValues: [Double] = []
    private var isMonitoring = false
    
    init() {
        setupMemoryWarningObserver()
    }
    
    // MARK: - Public Methods
    
    /// 메모리 추적 시작
    func startTracking() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
        
        resetStats()
    }
    
    /// 메모리 추적 중지
    func stopTracking() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    /// 통계 리셋
    func resetStats() {
        memoryValues.removeAll()
        peakMemoryMB = 0
        averageMemoryMB = 0
        didReceiveMemoryWarning = false
        updateMemoryUsage()
    }
    
    // MARK: - Private Methods
    
    private func updateMemoryUsage() {
        let memoryMB = getMemoryUsage()
        usedMemoryMB = memoryMB
        
        // 메모리 값 저장 (최근 60개만)
        memoryValues.append(memoryMB)
        if memoryValues.count > 60 {
            memoryValues.removeFirst()
        }
        
        // 피크 메모리
        peakMemoryMB = max(peakMemoryMB, memoryMB)
        
        // 평균 메모리
        averageMemoryMB = memoryValues.reduce(0, +) / Double(memoryValues.count)
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedBytes = Double(info.resident_size)
            return usedBytes / 1024 / 1024 // MB로 변환
        }
        
        return 0
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.didReceiveMemoryWarning = true
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTracking()
    }
}

// MARK: - Extensions

extension MemoryTracker {
    /// 메모리 상태를 색상으로 표현
    var memoryColor: Color {
        switch usedMemoryMB {
        case 0..<150:
            return .green  // 낮음
        case 150..<250:
            return .yellow // 중간
        case 250..<350:
            return .orange // 높음
        default:
            return .red    // 매우 높음
        }
    }
    
    /// 메모리 상태 텍스트
    var memoryStatus: String {
        switch usedMemoryMB {
        case 0..<150:
            return "낮음"
        case 150..<250:
            return "보통"
        case 250..<350:
            return "높음"
        default:
            return "매우 높음"
        }
    }
    
    /// 포맷된 메모리 값들
    var formattedUsed: String {
        String(format: "%.1f MB", usedMemoryMB)
    }
    
    var formattedPeak: String {
        String(format: "%.1f MB", peakMemoryMB)
    }
    
    var formattedAverage: String {
        String(format: "%.1f MB", averageMemoryMB)
    }
    
    /// 통계 요약
    var statistics: String {
        """
        Memory Statistics:
        - Used: \(formattedUsed)
        - Peak: \(formattedPeak)
        - Average: \(formattedAverage)
        - Status: \(memoryStatus)
        - Memory Warning: \(didReceiveMemoryWarning ? "Yes" : "No")
        """
    }
    
    /// 메모리 변화 추세
    var trend: String {
        guard memoryValues.count >= 2 else { return "안정" }
        
        let recent = memoryValues.suffix(5)
        let first = recent.first ?? 0
        let last = recent.last ?? 0
        let diff = last - first
        
        if abs(diff) < 5 {
            return "안정"
        } else if diff > 0 {
            return "증가 중"
        } else {
            return "감소 중"
        }
    }
}


