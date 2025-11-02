//
//  DiskCacheMonitor.swift
//  day09
//
//  디스크 캐시 크기 및 성능 모니터링
//

import Foundation

/// 디스크 캐시 모니터
class DiskCacheMonitor {
    static let shared = DiskCacheMonitor()
    
    private init() {}
    
    // MARK: - 디렉토리 크기 측정
    
    /// 디렉토리의 총 크기 계산 (바이트)
    func calculateDirectorySize(at path: String) -> UInt64 {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return 0
        }
        
        var totalSize: UInt64 = 0
        
        for case let file as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file)
            
            if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
               let fileSize = attributes[.size] as? UInt64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    /// 디렉토리의 파일 개수
    func countFiles(at path: String) -> Int {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return 0
        }
        
        var count = 0
        
        for case _ as String in enumerator {
            count += 1
        }
        
        return count
    }
    
    // MARK: - 캐시 경로 가져오기
    
    /// SDWebImage 캐시 경로
    func sdwebImageCachePath() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard let cachePath = paths.first else { return nil }
        return (cachePath as NSString).appendingPathComponent("com.hackemist.SDImageCache/default")
    }
    
    /// Kingfisher 캐시 경로
    func kingfisherCachePath() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard let cachePath = paths.first else { return nil }
        return (cachePath as NSString).appendingPathComponent("com.onevcat.Kingfisher.ImageCache.default")
    }
    
    /// Nuke 캐시 경로
    func nukeCachePath() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard let cachePath = paths.first else { return nil }
        return (cachePath as NSString).appendingPathComponent("com.github.kean.Nuke.Cache")
    }
    
    // MARK: - 라이브러리별 캐시 크기
    
    /// SDWebImage 캐시 크기
    func getSDWebImageCacheSize() -> UInt64 {
        guard let path = sdwebImageCachePath() else { return 0 }
        return calculateDirectorySize(at: path)
    }
    
    /// Kingfisher 캐시 크기
    func getKingfisherCacheSize() -> UInt64 {
        guard let path = kingfisherCachePath() else { return 0 }
        return calculateDirectorySize(at: path)
    }
    
    /// Nuke 캐시 크기
    func getNukeCacheSize() -> UInt64 {
        guard let path = nukeCachePath() else { return 0 }
        return calculateDirectorySize(at: path)
    }
    
    // MARK: - 읽기/쓰기 속도 측정
    
    /// 디스크 쓰기 속도 측정
    func measureWriteSpeed(data: Data, to path: String) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        
        try? data.write(to: URL(fileURLWithPath: path))
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        return duration
    }
    
    /// 디스크 읽기 속도 측정
    func measureReadSpeed(from path: String) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        
        _ = try? Data(contentsOf: URL(fileURLWithPath: path))
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        return duration
    }
    
    // MARK: - 포맷팅
    
    /// 바이트를 읽기 쉬운 형식으로
    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// 캐시 정보 요약
    func summary(libraryName: String, size: UInt64, fileCount: Int) -> String {
        """
        📁 \(libraryName) 디스크 캐시
        크기: \(formatBytes(size))
        파일 수: \(fileCount)개
        """
    }
}

// MARK: - 캐시 정리 유틸리티

extension DiskCacheMonitor {
    /// 디렉토리 삭제
    func clearDirectory(at path: String) -> Bool {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            return true
        }
        
        do {
            try fileManager.removeItem(atPath: path)
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            return true
        } catch {
            print("디렉토리 정리 실패: \(error)")
            return false
        }
    }
    
    /// 오래된 파일 삭제 (일 단위)
    func cleanOldFiles(at path: String, olderThan days: Int) -> Int {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return 0
        }
        
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        var deletedCount = 0
        
        for case let file as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file)
            
            if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
               let modificationDate = attributes[.modificationDate] as? Date,
               modificationDate < cutoffDate {
                
                try? fileManager.removeItem(atPath: filePath)
                deletedCount += 1
            }
        }
        
        return deletedCount
    }
}

