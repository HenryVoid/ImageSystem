//
//  NetworkMonitor.swift
//  day08
//
//  네트워크 연결 상태 모니터링

import Foundation
import Network
import os.log

/// 네트워크 연결 상태
enum NetworkStatus {
    case satisfied
    case unsatisfied
    case requiresConnection
    
    var description: String {
        switch self {
        case .satisfied:
            return "연결됨"
        case .unsatisfied:
            return "연결 끊김"
        case .requiresConnection:
            return "연결 필요"
        }
    }
}

/// 네트워크 타입
enum NetworkType {
    case wifi
    case cellular
    case wired
    case unknown
    
    var description: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "셀룰러"
        case .wired:
            return "유선"
        case .unknown:
            return "알 수 없음"
        }
    }
}

/// 네트워크 모니터
@available(iOS 12.0, *)
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.study.day08.network-monitor")
    private let log = OSLog(subsystem: "com.study.day08", category: "network")
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: NetworkType = .unknown
    @Published private(set) var status: NetworkStatus = .satisfied
    
    // 통계
    private(set) var totalDownloaded: Int64 = 0
    private(set) var downloadCount: Int = 0
    
    private init() {
        monitor = NWPathMonitor()
    }
    
    // MARK: - 모니터링
    
    /// 모니터링 시작
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.status = self.mapStatus(path.status)
                self.connectionType = self.determineConnectionType(path)
                
                self.logNetworkChange()
            }
        }
        
        monitor.start(queue: queue)
        
        os_log(.info, log: log, "네트워크 모니터링 시작")
    }
    
    /// 모니터링 중지
    func stop() {
        monitor.cancel()
        os_log(.info, log: log, "네트워크 모니터링 중지")
    }
    
    // MARK: - 통계
    
    /// 다운로드 추적
    func trackDownload(bytes: Int64) {
        totalDownloaded += bytes
        downloadCount += 1
        
        os_log(.info, log: log, "다운로드: %{public}s (총 %d회, %{public}s)", 
               formatBytes(bytes), 
               downloadCount, 
               formatBytes(totalDownloaded))
    }
    
    /// 통계 초기화
    func resetStats() {
        totalDownloaded = 0
        downloadCount = 0
        
        os_log(.info, log: log, "통계 초기화")
    }
    
    // MARK: - 상태 확인
    
    /// 현재 연결 가능한지
    var canDownload: Bool {
        return isConnected
    }
    
    /// Wi-Fi 연결 여부
    var isOnWiFi: Bool {
        return connectionType == .wifi
    }
    
    /// 셀룰러 연결 여부
    var isOnCellular: Bool {
        return connectionType == .cellular
    }
    
    // MARK: - Private
    
    private func mapStatus(_ status: NWPath.Status) -> NetworkStatus {
        switch status {
        case .satisfied:
            return .satisfied
        case .unsatisfied:
            return .unsatisfied
        case .requiresConnection:
            return .requiresConnection
        @unknown default:
            return .unsatisfied
        }
    }
    
    private func determineConnectionType(_ path: NWPath) -> NetworkType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else {
            return .unknown
        }
    }
    
    private func logNetworkChange() {
        let message = "네트워크 상태: \(status.description), 타입: \(connectionType.description)"
        os_log(.info, log: log, "%{public}s", message)
        print("🌐 \(message)")
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - 네트워크 통계

class NetworkStats {
    private(set) var downloadedBytes: Int64 = 0
    private(set) var downloadCount: Int = 0
    private(set) var failedCount: Int = 0
    
    func recordDownload(bytes: Int64) {
        downloadedBytes += bytes
        downloadCount += 1
    }
    
    func recordFailure() {
        failedCount += 1
    }
    
    func reset() {
        downloadedBytes = 0
        downloadCount = 0
        failedCount = 0
    }
    
    var averageSize: Int64 {
        guard downloadCount > 0 else { return 0 }
        return downloadedBytes / Int64(downloadCount)
    }
    
    var successRate: Double {
        let total = downloadCount + failedCount
        guard total > 0 else { return 0 }
        return Double(downloadCount) / Double(total) * 100
    }
    
    var description: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        
        return """
        다운로드 성공: \(downloadCount)회
        다운로드 실패: \(failedCount)회
        성공률: \(String(format: "%.1f", successRate))%
        총 다운로드: \(formatter.string(fromByteCount: downloadedBytes))
        평균 크기: \(formatter.string(fromByteCount: averageSize))
        """
    }
}

// MARK: - 편의 함수

extension NetworkMonitor {
    /// 네트워크 상태 요약
    var statusSummary: String {
        if !isConnected {
            return "❌ 연결 끊김"
        }
        
        switch connectionType {
        case .wifi:
            return "✅ Wi-Fi 연결"
        case .cellular:
            return "📱 셀룰러 연결"
        case .wired:
            return "🔌 유선 연결"
        case .unknown:
            return "✅ 연결됨"
        }
    }
    
    /// 다운로드 통계 요약
    var downloadSummary: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        
        return """
        다운로드 횟수: \(downloadCount)회
        총 다운로드: \(formatter.string(fromByteCount: totalDownloaded))
        """
    }
}





















