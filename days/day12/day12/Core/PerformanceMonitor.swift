//
//  PerformanceMonitor.swift
//  day12
//
//  실시간 성능 모니터링 (FPS, 메모리, 네트워크)
//

import Foundation
import Combine

/// 성능 메트릭
struct PerformanceMetrics {
    var fps: Double = 0
    var memoryMB: Double = 0
    var networkRequests: Int = 0
    var networkBytes: Int64 = 0
    
    var formattedMemory: String {
        String(format: "%.1f MB", memoryMB)
    }
    
    var formattedNetwork: String {
        let mb = Double(networkBytes) / 1024 / 1024
        return String(format: "%.2f MB", mb)
    }
}

/// 통합 성능 모니터
@MainActor
class PerformanceMonitor: ObservableObject {
    @Published var metrics = PerformanceMetrics()
    
    private var cancellables = Set<AnyCancellable>()
    private var isMonitoring = false
    
    /// 모니터링 시작
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // 1초마다 메트릭 업데이트
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateMetrics()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 모니터링 중지
    func stopMonitoring() {
        isMonitoring = false
        cancellables.removeAll()
    }
    
    /// 네트워크 요청 기록
    func recordNetworkRequest(bytes: Int64) {
        metrics.networkRequests += 1
        metrics.networkBytes += bytes
    }
    
    /// 통계 리셋
    func resetStats() {
        metrics = PerformanceMetrics()
    }
    
    // MARK: - Private
    
    private func updateMetrics() async {
        // 메모리 사용량 측정
        metrics.memoryMB = getMemoryUsage()
        
        // FPS는 FPSMonitor에서 가져옴 (실제 구현에서는 tool/FPSMonitor 사용)
        // 여기서는 추정값 사용
        metrics.fps = estimateFPS()
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
    
    private func estimateFPS() -> Double {
        // 실제로는 CADisplayLink를 사용해야 함
        // 여기서는 간단한 추정값 반환
        return 60.0
    }
}


