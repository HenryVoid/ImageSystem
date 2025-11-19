//
//  SimpleImageLoader.swift
//  day08
//
//  캐시 없는 단순 이미지 로더 (completion handler 버전)

import UIKit
import Foundation

/// 캐시 없는 단순 이미지 로더
class SimpleImageLoader {
    static let shared = SimpleImageLoader()
    
    private init() {}
    
    // MARK: - completion handler 버전
    
    /// 이미지 로드 (캐시 없음, completion handler)
    /// - Parameters:
    ///   - url: 이미지 URL
    ///   - completion: 완료 핸들러 (메인 스레드에서 호출됨)
    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // 성능 측정 시작
        let signpostID = PerformanceLogger.shared.beginImageLoad(url: url.absoluteString)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // URLSession으로 다운로드
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // 에러 체크
            if let error = error {
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                PerformanceLogger.shared.error("네트워크 에러: \(error.localizedDescription)", category: "loading")
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // HTTP 응답 체크
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = ImageError.invalidResponse
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = ImageError.httpError(statusCode: httpResponse.statusCode)
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 데이터 체크
            guard let data = data, !data.isEmpty else {
                let error = ImageError.noData
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 이미지 변환
            guard let image = UIImage(data: data) else {
                let error = ImageError.invalidData
                PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: false)
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 성능 측정 종료
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            PerformanceLogger.shared.endImageLoad(id: signpostID, url: url.absoluteString, success: true)
            PerformanceLogger.shared.log("로딩 완료: \(String(format: "%.2f", duration * 1000))ms", category: "loading")
            
            // 네트워크 통계 추적
            if #available(iOS 12.0, *) {
                NetworkMonitor.shared.trackDownload(bytes: Int64(data.count))
            }
            
            // 메인 스레드에서 completion 호출
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }
        
        task.resume()
    }
    
    // MARK: - 간편 버전 (옵셔널)
    
    /// 이미지 로드 (옵셔널 반환)
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        loadImage(from: url) { result in
            switch result {
            case .success(let image):
                completion(image)
            case .failure:
                completion(nil)
            }
        }
    }
}

// MARK: - 에러 타입

enum ImageError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case noData
    case invalidData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "잘못된 서버 응답"
        case .httpError(let code):
            return "HTTP 에러: \(code)"
        case .noData:
            return "데이터 없음"
        case .invalidData:
            return "이미지 변환 실패"
        case .networkError(let error):
            return "네트워크 에러: \(error.localizedDescription)"
        }
    }
}































