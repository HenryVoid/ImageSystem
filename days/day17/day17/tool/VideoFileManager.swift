//
//  VideoFileManager.swift
//  day17
//
//  동영상 파일 관리 유틸리티
//

import Foundation
import AVFoundation

/// 동영상 파일 관리 클래스
class VideoFileManager {
    
    /// Documents 디렉토리 경로
    static var documentsDirectory: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }
    
    /// 저장된 동영상 파일 목록 조회
    static func getRecordedVideos() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            return files.filter { $0.pathExtension == "mov" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            print("파일 목록 조회 실패: \(error)")
            return []
        }
    }
    
    /// 파일 크기 조회
    static func getFileSize(url: URL) -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }
        return fileSize
    }
    
    /// 파일 크기를 사람이 읽기 쉬운 형태로 포맷
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// 파일 생성 날짜 조회
    static func getCreationDate(url: URL) -> Date? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let creationDate = attributes[.creationDate] as? Date else {
            return nil
        }
        return creationDate
    }
    
    /// 동영상 지속 시간 조회
    static func getDuration(url: URL) -> TimeInterval? {
        let asset = AVAsset(url: url)
        return try? asset.load(.duration).seconds
    }
    
    /// 파일 삭제
    static func deleteFile(url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("파일 삭제 실패: \(error)")
            return false
        }
    }
    
    /// 모든 동영상 파일 삭제
    static func deleteAllVideos() -> Int {
        let videos = getRecordedVideos()
        var deletedCount = 0
        
        for video in videos {
            if deleteFile(url: video) {
                deletedCount += 1
            }
        }
        
        return deletedCount
    }
    
    /// 파일 이름 생성
    static func generateFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "video_\(formatter.string(from: Date())).mov"
    }
    
    /// 전체 저장 공간 사용량 계산
    static func getTotalStorageUsed() -> Int64 {
        let videos = getRecordedVideos()
        return videos.reduce(0) { total, url in
            total + getFileSize(url: url)
        }
    }
}

