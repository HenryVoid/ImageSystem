//
//  RenderingModeHelper.swift
//  day06
//
//  렌더링 모드 헬퍼 - .original vs .template
//

import SwiftUI

/// 렌더링 모드 헬퍼
enum RenderingModeHelper {
    
    // MARK: - 렌더링 모드 설명
    
    /// 각 렌더링 모드의 설명
    static func description(for mode: Image.TemplateRenderingMode) -> String {
        switch mode {
        case .original:
            return "원본 색상 유지 - 이미지의 실제 색상을 그대로 표시합니다."
        case .template:
            return "템플릿 모드 - 이미지를 단색 실루엣으로 변환하여 틴트 색상을 적용합니다."
        @unknown default:
            return "알 수 없는 모드"
        }
    }
    
    /// 렌더링 모드의 사용 사례
    static func useCase(for mode: Image.TemplateRenderingMode) -> String {
        switch mode {
        case .original:
            return """
            • SF Symbols의 다색(multicolor) 표시
            • 로고의 원래 색상 유지
            • 사진 이미지 표시
            """
        case .template:
            return """
            • 아이콘 버튼 (틴트 적용)
            • 탭바 아이콘
            • 다크 모드 대응 아이콘
            • 상태 표시 (색상 변경)
            """
        @unknown default:
            return "해당 없음"
        }
    }
    
    /// 렌더링 모드별 성능 특성
    static func performanceNote(for mode: Image.TemplateRenderingMode) -> String {
        switch mode {
        case .original:
            return "원본 색상 정보를 유지하므로 메모리 사용량이 약간 더 높습니다."
        case .template:
            return "단색으로 변환되므로 메모리 효율적이며, 색상 변경이 빠릅니다."
        @unknown default:
            return ""
        }
    }
    
    // MARK: - 샘플 이미지 생성
    
    /// 비교용 샘플 SF Symbol 목록
    static let sampleSymbols: [String] = [
        "star.fill",
        "heart.fill",
        "circle.fill",
        "square.fill",
        "triangle.fill",
        "diamond.fill",
        "suit.heart.fill",
        "suit.club.fill",
        "suit.spade.fill",
        "suit.diamond.fill"
    ]
    
    /// 다색 SF Symbols (원본 색상이 있는 것들)
    static let multicolorSymbols: [String] = [
        "star.fill",
        "heart.fill",
        "flag.fill",
        "bolt.fill",
        "flame.fill"
    ]
    
    // MARK: - 유틸리티
    
    /// 렌더링 모드 이름
    static func name(for mode: Image.TemplateRenderingMode) -> String {
        switch mode {
        case .original: return "Original"
        case .template: return "Template"
        @unknown default: return "Unknown"
        }
    }
    
    /// 모든 렌더링 모드
    static let allModes: [Image.TemplateRenderingMode] = [
        .original,
        .template
    ]
}

// MARK: - SwiftUI Extensions

extension Image.TemplateRenderingMode {
    
    /// 설명
    var description: String {
        RenderingModeHelper.description(for: self)
    }
    
    /// 사용 사례
    var useCase: String {
        RenderingModeHelper.useCase(for: self)
    }
    
    /// 성능 특성
    var performanceNote: String {
        RenderingModeHelper.performanceNote(for: self)
    }
    
    /// 이름
    var name: String {
        RenderingModeHelper.name(for: self)
    }
}

// MARK: - 실무 예제 컴포넌트

/// 렌더링 모드를 적용한 아이콘 버튼
struct RenderingModeIconButton: View {
    let systemName: String
    let mode: Image.TemplateRenderingMode
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .renderingMode(mode)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.2))
                .clipShape(Circle())
        }
    }
}

/// 다크 모드 대응 로고
struct AdaptiveLogo: View {
    let imageName: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image(imageName)
            .renderingMode(.template)
            .foregroundStyle(colorScheme == .dark ? .white : .black)
    }
}

/// 상태 표시 아이콘
struct StatusIcon: View {
    let isActive: Bool
    
    var body: some View {
        Image(systemName: "circle.fill")
            .renderingMode(.template)
            .foregroundStyle(isActive ? .green : .gray)
            .font(.caption)
    }
}

