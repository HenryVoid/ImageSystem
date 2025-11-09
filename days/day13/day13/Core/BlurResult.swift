//
//  BlurResult.swift
//  day13
//
//  Created on 11/10/25.
//

import UIKit

/// 블러 처리 결과를 담는 모델
struct BlurResult {
    let image: UIImage
    let processingTime: Double  // 밀리초
    let method: BlurMethod
    let radius: Int
    
    enum BlurMethod: String, CaseIterable {
        case metal = "Metal"
        case coreImage = "Core Image"
        
        var icon: String {
            switch self {
            case .metal: return "cpu"
            case .coreImage: return "camera.filters"
            }
        }
    }
    
    var formattedTime: String {
        return String(format: "%.2f ms", processingTime)
    }
}

/// 벤치마크 결과
struct BenchmarkResult: Identifiable {
    let id = UUID()
    let imageSize: ImageSize
    let radius: Int
    let metalTime: Double
    let coreImageTime: Double
    
    var speedup: Double {
        return coreImageTime / metalTime
    }
    
    var winner: String {
        return metalTime < coreImageTime ? "Metal" : "Core Image"
    }
    
    enum ImageSize: String, CaseIterable {
        case small = "500×500"
        case medium = "1000×1000"
        case large = "2000×2000"
        
        var pixels: Int {
            switch self {
            case .small: return 500
            case .medium: return 1000
            case .large: return 2000
            }
        }
    }
}

