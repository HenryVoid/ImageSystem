//
//  SignpostHelper.swift
//  day04
//
//  Instruments와 연동하기 위한 Signpost 헬퍼
//

import Foundation
import os.signpost

/// Signpost 헬퍼
class SignpostHelper {
    
    /// Signpost 타입
    enum SignpostType {
        case exifRead
        case imageLoad
        case thumbnailGeneration
        case metadataParse
        
        var name: StaticString {
            switch self {
            case .exifRead: return "EXIF Read"
            case .imageLoad: return "Image Load"
            case .thumbnailGeneration: return "Thumbnail Generation"
            case .metadataParse: return "Metadata Parse"
            }
        }
    }
    
    /// 작업 측정
    static func measure<T>(_ type: SignpostType, _ block: () -> T) -> T {
        let signpostID = OSSignpostID(log: PerformanceLogger.exifLog)
        os_signpost(.begin, log: PerformanceLogger.exifLog, name: type.name, signpostID: signpostID)
        
        let result = block()
        
        os_signpost(.end, log: PerformanceLogger.exifLog, name: type.name, signpostID: signpostID)
        
        return result
    }
    
    /// 비동기 작업 시작
    static func begin(_ type: SignpostType) -> OSSignpostID {
        let signpostID = OSSignpostID(log: PerformanceLogger.exifLog)
        os_signpost(.begin, log: PerformanceLogger.exifLog, name: type.name, signpostID: signpostID)
        return signpostID
    }
    
    /// 비동기 작업 종료
    static func end(_ type: SignpostType, signpostID: OSSignpostID) {
        os_signpost(.end, log: PerformanceLogger.exifLog, name: type.name, signpostID: signpostID)
    }
    
    /// 이벤트 기록
    static func event(_ type: SignpostType, message: String) {
        os_signpost(.event, log: PerformanceLogger.exifLog, name: type.name, "%{public}s", message)
    }
}

// MARK: - Usage Example

/*
 // 동기 작업
 let exifData = SignpostHelper.measure(.exifRead) {
     EXIFReader.loadEXIFData(from: url)
 }
 
 // 비동기 작업
 let signpostID = SignpostHelper.begin(.imageLoad)
 loadImageAsync { image in
     SignpostHelper.end(.imageLoad, signpostID: signpostID)
 }
 
 // 이벤트 기록
 SignpostHelper.event(.metadataParse, message: "GPS 좌표 파싱 시작")
 */

