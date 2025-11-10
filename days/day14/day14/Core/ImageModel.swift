//
//  ImageModel.swift
//  day14
//
//  이미지 데이터 모델 및 카테고리 정의
//

import Foundation

/// 이미지 정보 모델
struct ImageModel: Identifiable, Codable, Hashable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let downloadURL: String
    
    /// 썸네일 URL (크기 지정)
    func thumbnailURL(size: Int = 300) -> String {
        return "https://picsum.photos/id/\(id)/\(size)/\(size)"
    }
    
    /// 원본 크기 URL
    var fullSizeURL: String {
        return downloadURL
    }
    
    /// 이미지 크기 카테고리
    var sizeCategory: ImageSizeCategory {
        let maxDimension = max(width, height)
        
        if maxDimension < 500 {
            return .small
        } else if maxDimension < 800 {
            return .medium
        } else {
            return .large
        }
    }
    
    /// 이미지 비율
    var aspectRatio: Double {
        return Double(width) / Double(height)
    }
}

/// 이미지 크기 카테고리
enum ImageSizeCategory: String, CaseIterable, Identifiable {
    case all = "전체"
    case small = "작은 이미지"
    case medium = "중간 이미지"
    case large = "큰 이미지"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .all: return "모든 크기"
        case .small: return "~500px"
        case .medium: return "500-800px"
        case .large: return "800px~"
        }
    }
}

/// Picsum Photos API 응답 모델
struct PicsumPhoto: Codable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let download_url: String
}

extension ImageModel {
    /// Picsum API 응답을 ImageModel로 변환
    static func from(picsumPhoto: PicsumPhoto) -> ImageModel {
        return ImageModel(
            id: picsumPhoto.id,
            author: picsumPhoto.author,
            width: picsumPhoto.width,
            height: picsumPhoto.height,
            url: picsumPhoto.url,
            downloadURL: picsumPhoto.download_url
        )
    }
}

