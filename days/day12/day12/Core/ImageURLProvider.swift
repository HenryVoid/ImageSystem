//
//  ImageURLProvider.swift
//  day12
//
//  Picsum Photos API를 사용한 이미지 URL 생성
//

import Foundation

/// 이미지 크기 옵션
enum ImageSize: String, CaseIterable {
    case small = "작게 (200px)"
    case medium = "중간 (400px)"
    case large = "크게 (600px)"
    
    var pixels: Int {
        switch self {
        case .small: return 200
        case .medium: return 400
        case .large: return 600
        }
    }
}

/// Picsum Photos API 기반 이미지 URL 제공자
struct ImageURLProvider {
    /// 기본 크기
    static let defaultSize = ImageSize.medium
    
    /// 지정된 인덱스와 크기로 이미지 URL 생성
    /// - Parameters:
    ///   - index: 이미지 인덱스 (0-based)
    ///   - size: 이미지 크기
    /// - Returns: Picsum Photos URL
    static func url(for index: Int, size: ImageSize = defaultSize) -> URL {
        let pixels = size.pixels
        // Picsum Photos API: 랜덤 시드로 고정된 이미지 제공
        return URL(string: "https://picsum.photos/\(pixels)/\(pixels)?random=\(index)")!
    }
    
    /// 여러 URL을 일괄 생성
    /// - Parameters:
    ///   - count: 생성할 URL 개수
    ///   - size: 이미지 크기
    /// - Returns: URL 배열
    static func urls(count: Int, size: ImageSize = defaultSize) -> [URL] {
        (0..<count).map { url(for: $0, size: size) }
    }
    
    /// 커스텀 크기로 URL 생성
    /// - Parameters:
    ///   - index: 이미지 인덱스
    ///   - width: 가로 픽셀
    ///   - height: 세로 픽셀
    /// - Returns: Picsum Photos URL
    static func customURL(for index: Int, width: Int, height: Int) -> URL {
        URL(string: "https://picsum.photos/\(width)/\(height)?random=\(index)")!
    }
}


