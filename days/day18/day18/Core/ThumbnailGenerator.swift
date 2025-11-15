//
//  ThumbnailGenerator.swift
//  day18
//
//  AVAssetImageGenerator를 사용한 썸네일 생성
//

import AVFoundation
import UIKit

/// 썸네일 생성 옵션
struct ThumbnailOptions {
    /// 최대 썸네일 크기 (비율 유지)
    var maximumSize: CGSize = CGSize(width: 200, height: 200)
    
    /// 시간 허용 오차 (이전)
    var timeToleranceBefore: CMTime = CMTime(seconds: 0.1, preferredTimescale: 600)
    
    /// 시간 허용 오차 (이후)
    var timeToleranceAfter: CMTime = CMTime(seconds: 0.1, preferredTimescale: 600)
    
    /// 트랙 변환 적용 여부 (회전 등)
    var appliesPreferredTrackTransform: Bool = true
    
    /// 요청된 시간의 정확도
    var requestedTimeToleranceBefore: CMTime = .zero
    var requestedTimeToleranceAfter: CMTime = .zero
    
    static let `default` = ThumbnailOptions()
}

/// 썸네일 생성 에러
enum ThumbnailError: LocalizedError {
    case invalidAsset
    case invalidTime
    case imageGenerationFailed
    case assetNotLoadable
    
    var errorDescription: String? {
        switch self {
        case .invalidAsset:
            return "유효하지 않은 동영상 파일입니다."
        case .invalidTime:
            return "유효하지 않은 시간입니다."
        case .imageGenerationFailed:
            return "이미지 생성에 실패했습니다."
        case .assetNotLoadable:
            return "동영상을 로드할 수 없습니다."
        }
    }
}

/// AVAssetImageGenerator를 사용한 썸네일 생성기
class ThumbnailGenerator {
    
    /// 단일 타임라인에서 썸네일 생성
    /// - Parameters:
    ///   - assetURL: 동영상 파일 URL
    ///   - time: 썸네일을 추출할 시간 (초)
    ///   - options: 썸네일 생성 옵션
    /// - Returns: 생성된 썸네일 이미지
    static func generateThumbnail(
        from assetURL: URL,
        at time: TimeInterval,
        options: ThumbnailOptions = .default
    ) async throws -> UIImage {
        // AVAsset 생성
        let asset = AVAsset(url: assetURL)
        
        // Asset 로드 가능 여부 확인
        let loadable = try await asset.load(.isPlayable)
        guard loadable else {
            throw ThumbnailError.assetNotLoadable
        }
        
        // CMTime 변환
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        
        // 유효한 시간인지 확인
        let duration = try await asset.load(.duration)
        guard cmTime >= .zero && cmTime <= duration else {
            throw ThumbnailError.invalidTime
        }
        
        // AVAssetImageGenerator 생성
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = options.appliesPreferredTrackTransform
        generator.maximumSize = options.maximumSize
        
        // 시간 허용 오차 설정
        if options.requestedTimeToleranceBefore != .zero || options.requestedTimeToleranceAfter != .zero {
            generator.requestedTimeToleranceBefore = options.requestedTimeToleranceBefore
            generator.requestedTimeToleranceAfter = options.requestedTimeToleranceAfter
        } else {
            generator.requestedTimeToleranceBefore = options.timeToleranceBefore
            generator.requestedTimeToleranceAfter = options.timeToleranceAfter
        }
        
        // 이미지 생성
        do {
            let cgImage = try await generator.image(at: cmTime).image
            return UIImage(cgImage: cgImage)
        } catch {
            throw ThumbnailError.imageGenerationFailed
        }
    }
    
    /// 여러 타임라인에서 배치 썸네일 생성
    /// - Parameters:
    ///   - assetURL: 동영상 파일 URL
    ///   - times: 썸네일을 추출할 시간 배열 (초)
    ///   - options: 썸네일 생성 옵션
    ///   - progressHandler: 진행률 업데이트 핸들러 (0.0 ~ 1.0)
    /// - Returns: 생성된 썸네일 이미지 배열 (실패한 항목은 nil)
    static func generateThumbnails(
        from assetURL: URL,
        at times: [TimeInterval],
        options: ThumbnailOptions = .default,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> [UIImage?] {
        // AVAsset 생성
        let asset = AVAsset(url: assetURL)
        
        // Asset 로드 가능 여부 확인
        let loadable = try await asset.load(.isPlayable)
        guard loadable else {
            throw ThumbnailError.assetNotLoadable
        }
        
        // AVAssetImageGenerator 생성
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = options.appliesPreferredTrackTransform
        generator.maximumSize = options.maximumSize
        
        // 시간 허용 오차 설정
        if options.requestedTimeToleranceBefore != .zero || options.requestedTimeToleranceAfter != .zero {
            generator.requestedTimeToleranceBefore = options.requestedTimeToleranceBefore
            generator.requestedTimeToleranceAfter = options.requestedTimeToleranceAfter
        } else {
            generator.requestedTimeToleranceBefore = options.timeToleranceBefore
            generator.requestedTimeToleranceAfter = options.timeToleranceAfter
        }
        
        // CMTime 배열로 변환
        let cmTimes = times.map { CMTime(seconds: $0, preferredTimescale: 600) }
        
        // 병렬 처리로 썸네일 생성
        var results: [UIImage?] = []
        var completedCount = 0
        
        try await withThrowingTaskGroup(of: (Int, UIImage?).self) { group in
            // 각 시간에 대해 태스크 추가
            for (index, cmTime) in cmTimes.enumerated() {
                group.addTask {
                    do {
                        let cgImage = try await generator.image(at: cmTime).image
                        return (index, UIImage(cgImage: cgImage))
                    } catch {
                        return (index, nil)
                    }
                }
            }
            
            // 결과 수집
            results = Array(repeating: nil, count: cmTimes.count)
            
            for try await (index, thumbnail) in group {
                results[index] = thumbnail
                completedCount += 1
                
                // 진행률 업데이트
                let progress = Double(completedCount) / Double(cmTimes.count)
                progressHandler?(progress)
            }
        }
        
        return results
    }
    
    /// 동영상의 지속 시간 가져오기
    static func getDuration(from assetURL: URL) async throws -> TimeInterval {
        let asset = AVAsset(url: assetURL)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }
    
    /// 동영상의 자연 크기 가져오기
    static func getNaturalSize(from assetURL: URL) async throws -> CGSize {
        let asset = AVAsset(url: assetURL)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard let videoTrack = tracks.first else {
            throw ThumbnailError.invalidAsset
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        return naturalSize
    }
}

