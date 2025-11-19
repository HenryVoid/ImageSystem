//
//  CacheConfiguration.swift
//  day10
//
//  캐시 정책을 정의하는 설정 모델
//

import Foundation

/// 캐시 교체 정책
enum CacheEvictionPolicy: String, CaseIterable {
    case lru = "LRU (Least Recently Used)"
    case fifo = "FIFO (First In First Out)"
    case lfu = "LFU (Least Frequently Used)"
}

/// 캐시 설정 프리셋
enum CachePreset: String, CaseIterable {
    case minimal = "최소"
    case balanced = "균형"
    case aggressive = "공격적"
    case custom = "커스텀"
    
    var configuration: CacheConfiguration {
        switch self {
        case .minimal:
            return CacheConfiguration(
                memoryCacheSizeMB: 30,
                diskCacheSizeMB: 100,
                imageCountLimit: 30,
                ttlSeconds: 3600,  // 1시간
                evictionPolicy: .lru
            )
        case .balanced:
            return CacheConfiguration(
                memoryCacheSizeMB: 100,
                diskCacheSizeMB: 500,
                imageCountLimit: 100,
                ttlSeconds: 86400,  // 1일
                evictionPolicy: .lru
            )
        case .aggressive:
            return CacheConfiguration(
                memoryCacheSizeMB: 200,
                diskCacheSizeMB: 1000,
                imageCountLimit: 200,
                ttlSeconds: 604800,  // 7일
                evictionPolicy: .lru
            )
        case .custom:
            return CacheConfiguration()
        }
    }
}

/// 캐시 설정 구조체
struct CacheConfiguration {
    /// 메모리 캐시 용량 (MB)
    var memoryCacheSizeMB: Int
    
    /// 디스크 캐시 용량 (MB)
    var diskCacheSizeMB: Int
    
    /// 이미지 개수 제한
    var imageCountLimit: Int
    
    /// TTL (Time To Live) - 초 단위
    var ttlSeconds: TimeInterval
    
    /// 교체 정책
    var evictionPolicy: CacheEvictionPolicy
    
    /// 자동 정리 활성화 여부
    var autoCleanupEnabled: Bool
    
    /// 메모리 경고 시 자동 삭제
    var clearOnMemoryWarning: Bool
    
    /// 백그라운드 진입 시 메모리 캐시 정리
    var clearMemoryOnBackground: Bool
    
    // MARK: - 계산 속성
    
    /// 메모리 캐시 크기 (bytes)
    var memoryCacheSizeBytes: Int {
        memoryCacheSizeMB * 1024 * 1024
    }
    
    /// 디스크 캐시 크기 (bytes)
    var diskCacheSizeBytes: Int {
        diskCacheSizeMB * 1024 * 1024
    }
    
    /// TTL을 일 단위로 표시
    var ttlDays: Double {
        ttlSeconds / 86400
    }
    
    /// TTL을 시간 단위로 표시
    var ttlHours: Double {
        ttlSeconds / 3600
    }
    
    // MARK: - 초기화
    
    init(
        memoryCacheSizeMB: Int = 100,
        diskCacheSizeMB: Int = 500,
        imageCountLimit: Int = 100,
        ttlSeconds: TimeInterval = 86400,  // 1일
        evictionPolicy: CacheEvictionPolicy = .lru,
        autoCleanupEnabled: Bool = true,
        clearOnMemoryWarning: Bool = true,
        clearMemoryOnBackground: Bool = true
    ) {
        self.memoryCacheSizeMB = memoryCacheSizeMB
        self.diskCacheSizeMB = diskCacheSizeMB
        self.imageCountLimit = imageCountLimit
        self.ttlSeconds = ttlSeconds
        self.evictionPolicy = evictionPolicy
        self.autoCleanupEnabled = autoCleanupEnabled
        self.clearOnMemoryWarning = clearOnMemoryWarning
        self.clearMemoryOnBackground = clearMemoryOnBackground
    }
    
    // MARK: - 유틸리티
    
    /// 기기 메모리에 기반한 권장 설정
    static func recommended() -> CacheConfiguration {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryGB = physicalMemory / (1024 * 1024 * 1024)
        
        switch memoryGB {
        case ..<2:  // 2GB 미만
            return CachePreset.minimal.configuration
        case ..<4:  // 4GB 미만
            return CachePreset.balanced.configuration
        default:    // 4GB 이상
            return CachePreset.aggressive.configuration
        }
    }
    
    /// 설정 요약 문자열
    func summary() -> String {
        """
        📊 캐시 설정
        ────────────────────────
        메모리: \(memoryCacheSizeMB) MB
        디스크: \(diskCacheSizeMB) MB
        이미지 개수: 최대 \(imageCountLimit)개
        TTL: \(formattedTTL())
        교체 정책: \(evictionPolicy.rawValue)
        자동 정리: \(autoCleanupEnabled ? "활성화" : "비활성화")
        메모리 경고 대응: \(clearOnMemoryWarning ? "활성화" : "비활성화")
        백그라운드 정리: \(clearMemoryOnBackground ? "활성화" : "비활성화")
        """
    }
    
    private func formattedTTL() -> String {
        if ttlSeconds < 3600 {
            return "\(Int(ttlSeconds / 60))분"
        } else if ttlSeconds < 86400 {
            return "\(Int(ttlSeconds / 3600))시간"
        } else {
            return "\(Int(ttlSeconds / 86400))일"
        }
    }
}

// MARK: - Codable

extension CacheConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case memoryCacheSizeMB
        case diskCacheSizeMB
        case imageCountLimit
        case ttlSeconds
        case evictionPolicy
        case autoCleanupEnabled
        case clearOnMemoryWarning
        case clearMemoryOnBackground
    }
}

// MARK: - Equatable

extension CacheConfiguration: Equatable {
    static func == (lhs: CacheConfiguration, rhs: CacheConfiguration) -> Bool {
        lhs.memoryCacheSizeMB == rhs.memoryCacheSizeMB &&
        lhs.diskCacheSizeMB == rhs.diskCacheSizeMB &&
        lhs.imageCountLimit == rhs.imageCountLimit &&
        lhs.ttlSeconds == rhs.ttlSeconds &&
        lhs.evictionPolicy == rhs.evictionPolicy
    }
}




























