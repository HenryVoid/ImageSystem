//
//  ImageSizeCalculator.swift
//  day06
//
//  이미지 크기 계산 유틸리티 - aspectRatio 계산
//

import SwiftUI

/// 이미지 크기 계산 유틸리티
enum ImageSizeCalculator {
    
    // MARK: - Aspect Ratio 계산
    
    /// 주어진 크기에 맞는 aspect fit 크기 계산
    static func aspectFitSize(
        from originalSize: CGSize,
        to containerSize: CGSize
    ) -> CGSize {
        let widthRatio = containerSize.width / originalSize.width
        let heightRatio = containerSize.height / originalSize.height
        let scale = min(widthRatio, heightRatio)
        
        return CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
    }
    
    /// 주어진 크기에 맞는 aspect fill 크기 계산
    static func aspectFillSize(
        from originalSize: CGSize,
        to containerSize: CGSize
    ) -> CGSize {
        let widthRatio = containerSize.width / originalSize.width
        let heightRatio = containerSize.height / originalSize.height
        let scale = max(widthRatio, heightRatio)
        
        return CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
    }
    
    /// 특정 비율로 크기 계산
    static func size(
        for width: CGFloat,
        aspectRatio: CGFloat
    ) -> CGSize {
        CGSize(
            width: width,
            height: width / aspectRatio
        )
    }
    
    /// 특정 비율로 크기 계산 (높이 기준)
    static func size(
        forHeight height: CGFloat,
        aspectRatio: CGFloat
    ) -> CGSize {
        CGSize(
            width: height * aspectRatio,
            height: height
        )
    }
    
    // MARK: - Aspect Ratio 값
    
    /// 이미지의 가로세로 비율
    static func aspectRatio(of size: CGSize) -> CGFloat {
        guard size.height > 0 else { return 1.0 }
        return size.width / size.height
    }
    
    /// 일반적인 비율 상수
    enum CommonAspectRatio: CGFloat, CaseIterable {
        case square = 1.0           // 1:1
        case photo = 1.333          // 4:3
        case landscape = 1.777      // 16:9
        case portrait = 0.75        // 3:4
        case ultraWide = 2.333      // 21:9
        case instagram = 0.8        // 4:5
        
        var name: String {
            switch self {
            case .square: return "1:1 (정사각형)"
            case .photo: return "4:3 (사진)"
            case .landscape: return "16:9 (풍경)"
            case .portrait: return "3:4 (세로)"
            case .ultraWide: return "21:9 (울트라 와이드)"
            case .instagram: return "4:5 (인스타그램)"
            }
        }
        
        var description: String {
            switch self {
            case .square:
                return "프로필 사진, SNS 썸네일"
            case .photo:
                return "전통적인 사진 비율"
            case .landscape:
                return "비디오, 와이드스크린"
            case .portrait:
                return "세로 사진"
            case .ultraWide:
                return "영화, 파노라마"
            case .instagram:
                return "인스타그램 피드"
            }
        }
    }
    
    // MARK: - 크기 조정
    
    /// 최대 크기를 제한하면서 비율 유지
    static func constrainedSize(
        from originalSize: CGSize,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> CGSize {
        var size = originalSize
        
        if let maxWidth = maxWidth, size.width > maxWidth {
            let scale = maxWidth / size.width
            size.width = maxWidth
            size.height *= scale
        }
        
        if let maxHeight = maxHeight, size.height > maxHeight {
            let scale = maxHeight / size.height
            size.height = maxHeight
            size.width *= scale
        }
        
        return size
    }
    
    /// 스케일 팩터 계산
    static func scaleFactor(
        from originalSize: CGSize,
        to targetSize: CGSize,
        mode: ScaleMode
    ) -> CGFloat {
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        
        switch mode {
        case .fit:
            return min(widthRatio, heightRatio)
        case .fill:
            return max(widthRatio, heightRatio)
        case .stretch:
            return 1.0  // 각 방향 독립적으로 늘림
        }
    }
    
    // MARK: - Retina 대응
    
    /// 디바이스 스케일 팩터 (1x, 2x, 3x)
    static var deviceScale: CGFloat {
        UIScreen.main.scale
    }
    
    /// 논리적 크기를 실제 픽셀 크기로 변환
    static func pointsToPixels(_ points: CGFloat) -> CGFloat {
        points * deviceScale
    }
    
    /// 실제 픽셀 크기를 논리적 크기로 변환
    static func pixelsToPoints(_ pixels: CGFloat) -> CGFloat {
        pixels / deviceScale
    }
    
    /// Retina를 고려한 최적 이미지 크기
    static func optimalImageSize(for viewSize: CGSize) -> CGSize {
        CGSize(
            width: viewSize.width * deviceScale,
            height: viewSize.height * deviceScale
        )
    }
    
    // MARK: - 유틸리티
    
    /// 크기를 사람이 읽기 쉬운 형태로 포맷
    static func formattedSize(_ size: CGSize) -> String {
        String(format: "%.0f × %.0f", size.width, size.height)
    }
    
    /// 비율을 사람이 읽기 쉬운 형태로 포맷
    static func formattedAspectRatio(_ ratio: CGFloat) -> String {
        String(format: "%.2f:1", ratio)
    }
    
    /// 두 크기가 같은 비율인지 확인
    static func hasSameAspectRatio(
        _ size1: CGSize,
        _ size2: CGSize,
        tolerance: CGFloat = 0.01
    ) -> Bool {
        let ratio1 = aspectRatio(of: size1)
        let ratio2 = aspectRatio(of: size2)
        return abs(ratio1 - ratio2) < tolerance
    }
}

// MARK: - 스케일 모드

enum ScaleMode: String, CaseIterable {
    case fit = "Fit"
    case fill = "Fill"
    case stretch = "Stretch"
    
    var description: String {
        switch self {
        case .fit:
            return "이미지 전체가 보이도록 맞춤 (여백 생김)"
        case .fill:
            return "영역을 완전히 채움 (이미지 잘림)"
        case .stretch:
            return "비율 무시하고 늘림"
        }
    }
    
    var swiftUIContentMode: ContentMode? {
        switch self {
        case .fit: return .fit
        case .fill: return .fill
        case .stretch: return nil
        }
    }
}

// MARK: - CGSize Extensions

extension CGSize {
    
    /// Aspect ratio (width / height)
    var aspectRatio: CGFloat {
        ImageSizeCalculator.aspectRatio(of: self)
    }
    
    /// 가로 방향 여부
    var isLandscape: Bool {
        width > height
    }
    
    /// 세로 방향 여부
    var isPortrait: Bool {
        height > width
    }
    
    /// 정사각형 여부
    var isSquare: Bool {
        abs(width - height) < 1.0
    }
    
    /// 특정 너비로 크기 조정 (비율 유지)
    func scaled(toWidth width: CGFloat) -> CGSize {
        let scale = width / self.width
        return CGSize(width: width, height: height * scale)
    }
    
    /// 특정 높이로 크기 조정 (비율 유지)
    func scaled(toHeight height: CGFloat) -> CGSize {
        let scale = height / self.height
        return CGSize(width: width * scale, height: height)
    }
    
    /// 최대 크기 제한 (비율 유지)
    func constrained(to maxSize: CGSize) -> CGSize {
        ImageSizeCalculator.aspectFitSize(from: self, to: maxSize)
    }
    
    /// 포맷된 문자열
    var formatted: String {
        ImageSizeCalculator.formattedSize(self)
    }
}

// MARK: - 실무 예제

/// 크기 계산 예제 뷰
struct SizeCalculationExample: View {
    let originalSize = CGSize(width: 4032, height: 3024)
    let containerSize = CGSize(width: 300, height: 200)
    
    var fitSize: CGSize {
        ImageSizeCalculator.aspectFitSize(
            from: originalSize,
            to: containerSize
        )
    }
    
    var fillSize: CGSize {
        ImageSizeCalculator.aspectFillSize(
            from: originalSize,
            to: containerSize
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("원본 크기: \(originalSize.formatted)")
            Text("컨테이너: \(containerSize.formatted)")
            Text("Aspect Fit: \(fitSize.formatted)")
            Text("Aspect Fill: \(fillSize.formatted)")
        }
        .padding()
    }
}


