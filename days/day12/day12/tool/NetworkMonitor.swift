//
//  NetworkMonitor.swift
//  day12
//
//  네트워크 요청 및 트래픽 모니터링
//

import Foundation
import SwiftUI

/// 네트워크 요청 정보
struct NetworkRequest: Identifiable {
    let id = UUID()
    let url: URL
    let timestamp: Date
    let bytes: Int64
    let duration: TimeInterval
    let success: Bool
}

/// 네트워크 모니터
@MainActor
class NetworkMonitor: ObservableObject {
    @Published private(set) var totalRequests: Int = 0
    @Published private(set) var successfulRequests: Int = 0
    @Published private(set) var failedRequests: Int = 0
    @Published private(set) var totalBytes: Int64 = 0
    @Published private(set) var averageRequestTime: TimeInterval = 0
    @Published private(set) var recentRequests: [NetworkRequest] = []
    
    private var requestTimes: [TimeInterval] = []
    private let maxRecentRequests = 10
    
    // MARK: - Public Methods
    
    /// 네트워크 요청 기록
    /// - Parameters:
    ///   - url: 요청 URL
    ///   - bytes: 다운로드 바이트 수
    ///   - duration: 요청 시간
    ///   - success: 성공 여부
    func recordRequest(url: URL, bytes: Int64, duration: TimeInterval, success: Bool) {
        totalRequests += 1
        
        if success {
            successfulRequests += 1
            totalBytes += bytes
        } else {
            failedRequests += 1
        }
        
        // 요청 시간 기록
        requestTimes.append(duration)
        if requestTimes.count > 100 {
            requestTimes.removeFirst()
        }
        
        // 평균 요청 시간 계산
        averageRequestTime = requestTimes.reduce(0, +) / Double(requestTimes.count)
        
        // 최근 요청 기록
        let request = NetworkRequest(
            url: url,
            timestamp: Date(),
            bytes: bytes,
            duration: duration,
            success: success
        )
        
        recentRequests.insert(request, at: 0)
        if recentRequests.count > maxRecentRequests {
            recentRequests.removeLast()
        }
    }
    
    /// 통계 리셋
    func resetStats() {
        totalRequests = 0
        successfulRequests = 0
        failedRequests = 0
        totalBytes = 0
        averageRequestTime = 0
        requestTimes.removeAll()
        recentRequests.removeAll()
    }
}

// MARK: - Extensions

extension NetworkMonitor {
    /// 성공률 계산
    var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(successfulRequests) / Double(totalRequests) * 100
    }
    
    /// 포맷된 성공률
    var formattedSuccessRate: String {
        String(format: "%.1f%%", successRate)
    }
    
    /// 포맷된 총 다운로드 크기
    var formattedTotalBytes: String {
        let mb = Double(totalBytes) / 1024 / 1024
        if mb < 1 {
            let kb = Double(totalBytes) / 1024
            return String(format: "%.1f KB", kb)
        } else {
            return String(format: "%.2f MB", mb)
        }
    }
    
    /// 포맷된 평균 요청 시간
    var formattedAverageTime: String {
        String(format: "%.0f ms", averageRequestTime * 1000)
    }
    
    /// 초당 요청 수 추정 (최근 요청 기반)
    var requestsPerSecond: Double {
        guard recentRequests.count >= 2 else { return 0 }
        
        let first = recentRequests.last?.timestamp ?? Date()
        let last = recentRequests.first?.timestamp ?? Date()
        let duration = last.timeIntervalSince(first)
        
        guard duration > 0 else { return 0 }
        return Double(recentRequests.count) / duration
    }
    
    /// 네트워크 상태 색상
    var statusColor: Color {
        switch successRate {
        case 90...100:
            return .green
        case 70..<90:
            return .yellow
        case 50..<70:
            return .orange
        default:
            return .red
        }
    }
    
    /// 네트워크 상태 텍스트
    var statusText: String {
        switch successRate {
        case 90...100:
            return "매우 좋음"
        case 70..<90:
            return "양호"
        case 50..<70:
            return "보통"
        default:
            return "불안정"
        }
    }
    
    /// 통계 요약
    var statistics: String {
        """
        Network Statistics:
        - Total Requests: \(totalRequests)
        - Successful: \(successfulRequests)
        - Failed: \(failedRequests)
        - Success Rate: \(formattedSuccessRate)
        - Total Downloaded: \(formattedTotalBytes)
        - Average Time: \(formattedAverageTime)
        - Requests/sec: \(String(format: "%.1f", requestsPerSecond))
        """
    }
    
    /// 대역폭 추정 (MB/s)
    var estimatedBandwidthMBps: Double {
        guard averageRequestTime > 0, totalRequests > 0 else { return 0 }
        
        let avgBytesPerRequest = Double(totalBytes) / Double(successfulRequests)
        let bytesPerSecond = avgBytesPerRequest / averageRequestTime
        return bytesPerSecond / 1024 / 1024
    }
    
    var formattedBandwidth: String {
        String(format: "%.2f MB/s", estimatedBandwidthMBps)
    }
}

// MARK: - URLSession Extension

extension URLSession {
    /// 모니터링이 포함된 데이터 다운로드
    /// - Parameters:
    ///   - url: 다운로드 URL
    ///   - monitor: 네트워크 모니터 (옵션)
    /// - Returns: (Data, URLResponse)
    func monitoredData(from url: URL, monitor: NetworkMonitor? = nil) async throws -> (Data, URLResponse) {
        let startTime = Date()
        
        do {
            let (data, response) = try await self.data(from: url)
            let duration = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                monitor?.recordRequest(
                    url: url,
                    bytes: Int64(data.count),
                    duration: duration,
                    success: true
                )
            }
            
            return (data, response)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                monitor?.recordRequest(
                    url: url,
                    bytes: 0,
                    duration: duration,
                    success: false
                )
            }
            
            throw error
        }
    }
}


