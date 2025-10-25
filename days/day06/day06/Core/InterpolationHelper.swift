//
//  InterpolationHelper.swift
//  day06
//
//  보간 품질 헬퍼 - interpolation 옵션 설명 및 유틸리티
//

import SwiftUI

/// 보간 품질 헬퍼
enum InterpolationHelper {
    
    // MARK: - 보간 품질 설명
    
    /// 각 보간 품질의 설명
    static func description(for interpolation: Image.Interpolation) -> String {
        switch interpolation {
        case .none:
            return "보간 없음 - 가장 가까운 픽셀 사용 (Nearest Neighbor)"
        case .low:
            return "낮은 품질 - 빠른 렌더링, 기본적인 보간"
        case .medium:
            return "중간 품질 - 균형 잡힌 품질과 성능 (기본값)"
        case .high:
            return "높은 품질 - 최고 품질, 느린 렌더링"
        @unknown default:
            return "알 수 없는 품질"
        }
    }
    
    /// 보간 품질의 사용 사례
    static func useCase(for interpolation: Image.Interpolation) -> String {
        switch interpolation {
        case .none:
            return """
            • 픽셀 아트 (선명한 픽셀 경계)
            • 작은 아이콘 확대 (선명함 유지)
            • QR 코드, 바코드
            • 레트로 게임 그래픽
            """
        case .low:
            return """
            • 실시간 애니메이션
            • 스크롤 중 이미지
            • 일시적인 표시
            • 성능이 중요한 경우
            """
        case .medium:
            return """
            • 일반 사진 표시
            • 썸네일 그리드
            • 프로필 이미지
            • 대부분의 경우 (권장)
            """
        case .high:
            return """
            • 고품질 갤러리
            • 확대된 이미지
            • 프린트용 이미지
            • 정적 화면
            """
        @unknown default:
            return "해당 없음"
        }
    }
    
    /// 보간 품질별 성능 특성
    static func performanceNote(for interpolation: Image.Interpolation) -> String {
        switch interpolation {
        case .none:
            return "가장 빠름 (~15ms) - 보간 계산 없음, 픽셀 선택만"
        case .low:
            return "빠름 (~25ms) - 기본적인 선형 보간"
        case .medium:
            return "보통 (~45ms) - 바이리니어 보간, 대부분의 경우 적합"
        case .high:
            return "느림 (~120ms) - 바이큐빅 보간, 고품질 요구 시만 사용"
        @unknown default:
            return ""
        }
    }
    
    /// 시각적 특징
    static func visualCharacteristic(for interpolation: Image.Interpolation) -> String {
        switch interpolation {
        case .none:
            return "픽셀화, 계단 현상, 선명한 경계"
        case .low:
            return "약간 흐림, 빠른 렌더링"
        case .medium:
            return "부드러움, 적당한 디테일"
        case .high:
            return "매우 부드러움, 최상의 디테일"
        @unknown default:
            return ""
        }
    }
    
    // MARK: - 추천 사항
    
    /// 이미지 크기에 따른 추천 보간 품질
    static func recommended(for scale: CGFloat) -> Image.Interpolation {
        switch scale {
        case ..<0.5:
            // 축소 (원본의 절반 이하)
            return .medium
        case 0.5..<2.0:
            // 비슷한 크기
            return .medium
        case 2.0..<5.0:
            // 약간 확대
            return .high
        default:
            // 크게 확대 (5배 이상)
            return .none  // 픽셀 아트 느낌
        }
    }
    
    /// 용도에 따른 추천 보간 품질
    static func recommended(forUseCase useCase: ImageUseCase) -> Image.Interpolation {
        switch useCase {
        case .thumbnail:
            return .medium
        case .fullScreen:
            return .high
        case .scrolling:
            return .medium
        case .pixelArt:
            return .none
        case .icon:
            return .medium
        case .animation:
            return .low
        }
    }
    
    // MARK: - 유틸리티
    
    /// 보간 품질 이름
    static func name(for interpolation: Image.Interpolation) -> String {
        switch interpolation {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        @unknown default: return "Unknown"
        }
    }
    
    /// 모든 보간 품질
    static let allInterpolations: [Image.Interpolation] = [
        .none,
        .low,
        .medium,
        .high
    ]
    
    /// 예상 렌더링 시간 (ms)
    static func estimatedRenderTime(for interpolation: Image.Interpolation) -> Double {
        switch interpolation {
        case .none: return 15.0
        case .low: return 25.0
        case .medium: return 45.0
        case .high: return 120.0
        @unknown default: return 0.0
        }
    }
}

// MARK: - 이미지 사용 사례

enum ImageUseCase: String, CaseIterable {
    case thumbnail = "썸네일"
    case fullScreen = "전체 화면"
    case scrolling = "스크롤"
    case pixelArt = "픽셀 아트"
    case icon = "아이콘"
    case animation = "애니메이션"
    
    var recommendedInterpolation: Image.Interpolation {
        InterpolationHelper.recommended(forUseCase: self)
    }
}

// MARK: - SwiftUI Extensions

extension Image.Interpolation {
    
    /// 설명
    var description: String {
        InterpolationHelper.description(for: self)
    }
    
    /// 사용 사례
    var useCase: String {
        InterpolationHelper.useCase(for: self)
    }
    
    /// 성능 특성
    var performanceNote: String {
        InterpolationHelper.performanceNote(for: self)
    }
    
    /// 시각적 특징
    var visualCharacteristic: String {
        InterpolationHelper.visualCharacteristic(for: self)
    }
    
    /// 이름
    var name: String {
        InterpolationHelper.name(for: self)
    }
    
    /// 예상 렌더링 시간
    var estimatedRenderTime: Double {
        InterpolationHelper.estimatedRenderTime(for: self)
    }
}

// MARK: - 실무 예제 컴포넌트

/// 보간 품질을 적용한 이미지 뷰
struct InterpolatedImageView: View {
    let imageName: String
    let interpolation: Image.Interpolation
    let size: CGSize
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(interpolation)
            .frame(width: size.width, height: size.height)
    }
}

/// 상황에 맞는 보간 품질을 자동 선택하는 이미지
struct AdaptiveInterpolationImage: View {
    let imageName: String
    let targetSize: CGSize
    let originalSize: CGSize
    
    var interpolation: Image.Interpolation {
        let scale = targetSize.width / originalSize.width
        return InterpolationHelper.recommended(for: scale)
    }
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(interpolation)
            .frame(width: targetSize.width, height: targetSize.height)
    }
}

/// 스크롤 중엔 낮은 품질, 정지 시 고품질로 자동 전환
struct DynamicQualityImage: View {
    let imageName: String
    @State private var isScrolling = false
    
    var interpolation: Image.Interpolation {
        isScrolling ? .medium : .high
    }
    
    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(interpolation)
            .aspectRatio(contentMode: .fit)
    }
}

