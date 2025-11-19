//
//  DiskMonitor.swift
//  day10
//
//  디스크 사용량 모니터링 도구
//

import Foundation

/// 디스크 샘플
struct DiskSample {
    let timestamp: Date
    let usedMB: Double
    let freeMB: Double
    let totalMB: Double
    
    var usagePercentage: Double {
        guard totalMB > 0 else { return 0 }
        return (usedMB / totalMB) * 100
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

/// 디스크 모니터
class DiskMonitor: ObservableObject {
    // MARK: - Singleton
    
    static let shared = DiskMonitor()
    
    // MARK: - Properties
    
    @Published private(set) var currentSample: DiskSample?
    @Published private(set) var samples: [DiskSample] = []
    @Published private(set) var cacheDiskUsageMB: Double = 0
    
    private let fileManager = FileManager.default
    private let maxSampleCount = 100
    
    // MARK: - Initialization
    
    init() {
        updateCurrentSample()
    }
    
    // MARK: - Disk Space
    
    /// 전체 디스크 용량
    func totalDiskSpaceMB() -> Double {
        guard let attributes = try? fileManager.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) else { return 0 }
        
        if let total = attributes[.systemSize] as? NSNumber {
            return total.doubleValue / 1024 / 1024
        }
        return 0
    }
    
    /// 사용 가능한 디스크 공간
    func freeDiskSpaceMB() -> Double {
        guard let attributes = try? fileManager.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) else { return 0 }
        
        if let free = attributes[.systemFreeSize] as? NSNumber {
            return free.doubleValue / 1024 / 1024
        }
        return 0
    }
    
    /// 사용 중인 디스크 공간
    func usedDiskSpaceMB() -> Double {
        return totalDiskSpaceMB() - freeDiskSpaceMB()
    }
    
    // MARK: - Cache Directory Size
    
    /// 캐시 디렉토리 크기 측정
    func cacheDiskUsage() -> Double {
        guard let cacheURL = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else { return 0 }
        
        return directorySize(at: cacheURL)
    }
    
    /// 특정 디렉토리 크기 측정
    func directorySize(at url: URL) -> Double {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(
                forKeys: [.isRegularFileKey, .fileSizeKey]
            ),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            
            totalSize += Int64(fileSize)
        }
        
        return Double(totalSize) / 1024 / 1024  // MB로 변환
    }
    
    // MARK: - Sampling
    
    /// 현재 샘플 업데이트
    func updateCurrentSample() {
        let cacheSizeMB = cacheDiskUsage()
        
        let sample = DiskSample(
            timestamp: Date(),
            usedMB: usedDiskSpaceMB(),
            freeMB: freeDiskSpaceMB(),
            totalMB: totalDiskSpaceMB()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.currentSample = sample
            self?.cacheDiskUsageMB = cacheSizeMB
        }
    }
    
    /// 샘플 추가
    func addSample() {
        updateCurrentSample()
        
        if let sample = currentSample {
            samples.append(sample)
            
            // 최대 개수 유지
            if samples.count > maxSampleCount {
                samples.removeFirst()
            }
        }
    }
    
    /// 샘플 초기화
    func clearSamples() {
        samples.removeAll()
        print("🗑️ 디스크 샘플 삭제 완료")
    }
    
    // MARK: - Statistics
    
    /// 평균 디스크 사용량
    func averageDiskUsage() -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + $1.usedMB }
        return sum / Double(samples.count)
    }
    
    /// 최대 디스크 사용량
    func maxDiskUsage() -> Double {
        return samples.map { $0.usedMB }.max() ?? 0
    }
    
    /// 디스크 사용량 트렌드
    func usageTrend() -> [Double] {
        return samples.map { $0.usedMB }
    }
    
    /// 디스크 공간 부족 경고
    func isLowDiskSpace() -> Bool {
        let freeMB = freeDiskSpaceMB()
        return freeMB < 500  // 500MB 미만
    }
    
    // MARK: - Cache Management
    
    /// 캐시 디렉토리 정보
    func cacheDirectoryInfo() -> String {
        guard let cacheURL = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else { return "캐시 디렉토리 없음" }
        
        let size = directorySize(at: cacheURL)
        
        // 파일 개수 세기
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheURL,
            includingPropertiesForKeys: nil
        ) else {
            return "캐시 정보 읽기 실패"
        }
        
        return """
        📁 캐시 디렉토리
        ────────────────────────
        경로: \(cacheURL.path)
        크기: \(String(format: "%.1f", size)) MB
        파일 개수: \(files.count)개
        """
    }
    
    // MARK: - Report
    
    func summary() -> String {
        guard let current = currentSample else {
            return "디스크 데이터 없음"
        }
        
        return """
        💿 디스크 사용량
        ────────────────────────
        전체: \(String(format: "%.0f", current.totalMB)) MB
        사용 중: \(String(format: "%.0f", current.usedMB)) MB
        여유: \(String(format: "%.0f", current.freeMB)) MB
        사용률: \(String(format: "%.1f", current.usagePercentage))%
        
        캐시: \(String(format: "%.1f", cacheDiskUsageMB)) MB
        
        \(isLowDiskSpace() ? "⚠️ 디스크 공간 부족!" : "")
        \(samples.isEmpty ? "" : statisticsReport())
        """
    }
    
    private func statisticsReport() -> String {
        """
        📈 통계 (샘플 \(samples.count)개)
        ────────────────────────
        평균 사용: \(String(format: "%.0f", averageDiskUsage())) MB
        최대 사용: \(String(format: "%.0f", maxDiskUsage())) MB
        """
    }
}




























