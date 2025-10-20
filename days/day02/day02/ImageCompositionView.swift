//
//  ImageCompositionView.swift
//  day02
//
//  Core Graphics와 SwiftUI Canvas로 이미지 합성
//  이미지 오버레이, 블렌드 모드, 마스킹 등을 비교합니다.
//

import SwiftUI
import UIKit

struct ImageCompositionView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("렌더링 방식", selection: $selectedTab) {
                Text("Core Graphics").tag(0)
                Text("SwiftUI Canvas").tag(1)
                Text("실전 예제").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView {
                VStack(spacing: 30) {
                    switch selectedTab {
                    case 0:
                        CoreGraphicsCompositionExample()
                    case 1:
                        SwiftUICanvasCompositionExample()
                    case 2:
                        PracticalExamplesView()
                    default:
                        CoreGraphicsCompositionExample()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("이미지 합성")
    }
}

// MARK: - Core Graphics 합성

struct CoreGraphicsCompositionExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🖼️ Core Graphics 이미지 합성")
                .font(.title2)
                .bold()
            
            Text("UIImage와 CGContext로 이미지를 합성합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 1. 기본 오버레이
            ExampleCard(title: "1. 기본 오버레이") {
                Image(uiImage: drawBasicOverlay())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            // 2. 블렌드 모드
            ExampleCard(title: "2. 블렌드 모드") {
                Image(uiImage: drawBlendModes())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
            }
            
            // 3. 알파 합성
            ExampleCard(title: "3. 알파 합성 (투명도)") {
                Image(uiImage: drawAlphaComposite())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            // 4. 클리핑 마스크
            ExampleCard(title: "4. 클리핑 마스크") {
                Image(uiImage: drawClippingMask())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            CodeExplanationView(
                title: "Core Graphics 합성 특징",
                items: [
                    "UIImage.draw() 메서드 사용",
                    "CGBlendMode로 블렌드 모드 설정",
                    "context.setAlpha()로 투명도 제어",
                    "context.clip()으로 마스킹",
                    "정밀한 픽셀 단위 제어"
                ]
            )
        }
    }
    
    // 기본 오버레이
    private func drawBasicOverlay() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 배경
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 레이어 1: 파란 사각형
            let layer1 = createColoredRect(color: .systemBlue, size: CGSize(width: 150, height: 150))
            layer1.draw(at: CGPoint(x: 50, y: 25))
            
            // 레이어 2: 빨간 원 (오버레이)
            let layer2 = createColoredCircle(color: .systemRed, size: CGSize(width: 120, height: 120))
            layer2.draw(at: CGPoint(x: 130, y: 40))
            
            // 레이어 3: 초록 사각형
            let layer3 = createColoredRect(color: .systemGreen, size: CGSize(width: 100, height: 100))
            layer3.draw(at: CGPoint(x: 250, y: 50))
        }
    }
    
    // 블렌드 모드
    private func drawBlendModes() -> UIImage {
        let size = CGSize(width: 400, height: 250)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 배경 원
            let baseCircle = createColoredCircle(color: .systemBlue, size: CGSize(width: 80, height: 80))
            
            // 오버레이 원
            let overlayCircle = createColoredCircle(color: .systemRed, size: CGSize(width: 80, height: 80))
            
            let blendModes: [(CGBlendMode, String, CGPoint)] = [
                (.normal, "Normal", CGPoint(x: 60, y: 60)),
                (.multiply, "Multiply", CGPoint(x: 180, y: 60)),
                (.screen, "Screen", CGPoint(x: 300, y: 60)),
                (.overlay, "Overlay", CGPoint(x: 60, y: 160)),
                (.darken, "Darken", CGPoint(x: 180, y: 160)),
                (.lighten, "Lighten", CGPoint(x: 300, y: 160))
            ]
            
            for (mode, label, position) in blendModes {
                // 배경
                baseCircle.draw(at: position)
                
                // 오버레이 (오프셋)
                ctx.saveGState()
                ctx.setBlendMode(mode)
                overlayCircle.draw(at: CGPoint(x: position.x + 30, y: position.y))
                ctx.restoreGState()
                
                // 레이블
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                (label as NSString).draw(at: CGPoint(x: position.x + 10, y: position.y + 90), withAttributes: attrs)
            }
        }
    }
    
    // 알파 합성
    private func drawAlphaComposite() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 그라디언트 배경
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor.systemPurple.cgColor, UIColor.systemPink.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            
            // 다양한 알파값의 원
            let alphas: [(CGFloat, CGFloat)] = [
                (1.0, 50),
                (0.7, 130),
                (0.4, 210),
                (0.1, 290)
            ]
            
            for (alpha, x) in alphas {
                ctx.saveGState()
                ctx.setAlpha(alpha)
                
                let circle = createColoredCircle(color: .white, size: CGSize(width: 80, height: 80))
                circle.draw(at: CGPoint(x: x, y: 60))
                
                ctx.restoreGState()
                
                // 레이블
                let label = "\(Int(alpha * 100))%"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                (label as NSString).draw(at: CGPoint(x: x + 25, y: 150), withAttributes: attrs)
            }
        }
    }
    
    // 클리핑 마스크
    private func drawClippingMask() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 원형 마스크
            ctx.saveGState()
            
            let circlePath = CGPath(
                ellipseIn: CGRect(x: 50, y: 50, width: 100, height: 100),
                transform: nil
            )
            ctx.addPath(circlePath)
            ctx.clip()
            
            // 그라디언트가 원 안에만 그려짐
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 50, y: 50),
                end: CGPoint(x: 150, y: 150),
                options: []
            )
            
            ctx.restoreGState()
            
            // 별 마스크
            ctx.saveGState()
            
            let starPath = createStarPath(center: CGPoint(x: 250, y: 100), radius: 50, points: 5)
            ctx.addPath(starPath)
            ctx.clip()
            
            // 패턴이 별 안에만 그려짐
            let colors2 = [UIColor.systemYellow.cgColor, UIColor.systemOrange.cgColor] as CFArray
            let gradient2 = CGGradient(colorsSpace: colorSpace, colors: colors2, locations: nil)!
            ctx.drawLinearGradient(
                gradient2,
                start: CGPoint(x: 200, y: 50),
                end: CGPoint(x: 300, y: 150),
                options: []
            )
            
            ctx.restoreGState()
        }
    }
    
    // 헬퍼 함수
    private func createColoredRect(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private func createColoredCircle(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func createStarPath(center: CGPoint, radius: CGFloat, points: Int) -> CGPath {
        let path = CGMutablePath()
        let angle = CGFloat.pi * 2 / CGFloat(points)
        let innerRadius = radius * 0.4
        
        for i in 0..<points * 2 {
            let r = i % 2 == 0 ? radius : innerRadius
            let currentAngle = angle * CGFloat(i) - .pi / 2
            let x = center.x + cos(currentAngle) * r
            let y = center.y + sin(currentAngle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - SwiftUI Canvas 합성

struct SwiftUICanvasCompositionExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🎨 SwiftUI Canvas 이미지 합성")
                .font(.title2)
                .bold()
            
            Text("GraphicsContext로 이미지를 합성합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 1. 기본 오버레이
            ExampleCard(title: "1. 기본 오버레이") {
                Canvas { context, size in
                    // 배경
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                    
                    // 레이어 1: 파란 사각형
                    let rect1 = Path(CGRect(x: 50, y: 25, width: 150, height: 150))
                    context.fill(rect1, with: .color(.blue))
                    
                    // 레이어 2: 빨간 원
                    let circle = Path(ellipseIn: CGRect(x: 130, y: 40, width: 120, height: 120))
                    context.fill(circle, with: .color(.red))
                    
                    // 레이어 3: 초록 사각형
                    let rect2 = Path(CGRect(x: 250, y: 50, width: 100, height: 100))
                    context.fill(rect2, with: .color(.green))
                }
                .frame(height: 200)
            }
            
            // 2. 블렌드 모드
            ExampleCard(title: "2. 블렌드 모드") {
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                    
                    let blendModes: [(GraphicsContext.BlendMode, String, CGPoint)] = [
                        (.normal, "Normal", CGPoint(x: 60, y: 60)),
                        (.multiply, "Multiply", CGPoint(x: 180, y: 60)),
                        (.screen, "Screen", CGPoint(x: 300, y: 60)),
                        (.overlay, "Overlay", CGPoint(x: 60, y: 160)),
                        (.darken, "Darken", CGPoint(x: 180, y: 160)),
                        (.lighten, "Lighten", CGPoint(x: 300, y: 160))
                    ]
                    
                    for (mode, label, position) in blendModes {
                        // 배경 원
                        let baseCircle = Path(ellipseIn: CGRect(x: position.x, y: position.y, width: 80, height: 80))
                        context.fill(baseCircle, with: .color(.blue))
                        
                        // 오버레이 원
                        var contextCopy = context
                        contextCopy.blendMode = mode
                        let overlayCircle = Path(ellipseIn: CGRect(x: position.x + 30, y: position.y, width: 80, height: 80))
                        contextCopy.fill(overlayCircle, with: .color(.red))
                        
                        // 레이블
                        let text = Text(label)
                            .font(.system(size: 10))
                        context.draw(text, at: CGPoint(x: position.x + 40, y: position.y + 95), anchor: .center)
                    }
                }
                .frame(height: 250)
            }
            
            // 3. 투명도
            ExampleCard(title: "3. 투명도") {
                Canvas { context, size in
                    // 그라디언트 배경
                    let gradient = Gradient(colors: [.purple, .pink])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
                    )
                    
                    // 다양한 투명도의 원
                    let alphas: [(Double, CGFloat)] = [
                        (1.0, 50),
                        (0.7, 130),
                        (0.4, 210),
                        (0.1, 290)
                    ]
                    
                    for (alpha, x) in alphas {
                        var contextCopy = context
                        contextCopy.opacity = alpha
                        
                        let circle = Path(ellipseIn: CGRect(x: x, y: 60, width: 80, height: 80))
                        contextCopy.fill(circle, with: .color(.white))
                        
                        let label = Text("\(Int(alpha * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        context.draw(label, at: CGPoint(x: x + 40, y: 150), anchor: .center)
                    }
                }
                .frame(height: 200)
            }
            
            // 4. 마스크
            ExampleCard(title: "4. 마스크") {
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                    
                    // 원형 마스크
                    let circleRect = CGRect(x: 50, y: 50, width: 100, height: 100)
                    let circlePath = Path(ellipseIn: circleRect)
                    
                    context.drawLayer { layerContext in
                        layerContext.clip(to: circlePath)
                        
                        let gradient = Gradient(colors: [.blue, .purple])
                        layerContext.fill(
                            Path(circleRect),
                            with: .linearGradient(gradient, startPoint: circleRect.origin, endPoint: CGPoint(x: circleRect.maxX, y: circleRect.maxY))
                        )
                    }
                    
                    // 별 마스크
                    let starCenter = CGPoint(x: 250, y: 100)
                    let starPath = createSwiftUIStarPath(center: starCenter, radius: 50, points: 5)
                    
                    context.drawLayer { layerContext in
                        layerContext.clip(to: starPath)
                        
                        let gradient = Gradient(colors: [.yellow, .orange])
                        let starBounds = starPath.boundingRect
                        layerContext.fill(
                            Path(starBounds),
                            with: .linearGradient(gradient, startPoint: starBounds.origin, endPoint: CGPoint(x: starBounds.maxX, y: starBounds.maxY))
                        )
                    }
                }
                .frame(height: 200)
            }
            
            CodeExplanationView(
                title: "SwiftUI Canvas 합성 특징",
                items: [
                    "Path와 GraphicsContext 사용",
                    "blendMode 프로퍼티로 블렌드",
                    "opacity로 투명도 제어",
                    "clip()으로 마스킹",
                    "선언적이고 직관적"
                ]
            )
        }
    }
    
    private func createSwiftUIStarPath(center: CGPoint, radius: CGFloat, points: Int) -> Path {
        var path = Path()
        let angle = CGFloat.pi * 2 / CGFloat(points)
        let innerRadius = radius * 0.4
        
        for i in 0..<points * 2 {
            let r = i % 2 == 0 ? radius : innerRadius
            let currentAngle = angle * CGFloat(i) - .pi / 2
            let x = center.x + cos(currentAngle) * r
            let y = center.y + sin(currentAngle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - 실전 예제

struct PracticalExamplesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🚀 실전 예제")
                .font(.title2)
                .bold()
            
            // 워터마크
            ExampleCard(title: "워터마크 추가") {
                Image(uiImage: createWatermarkedImage())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            // 프로필 아바타
            ExampleCard(title: "프로필 아바타 (원형 + 테두리)") {
                HStack(spacing: 20) {
                    Image(uiImage: createProfileAvatar())
                        .resizable()
                        .frame(width: 100, height: 100)
                    
                    Text("Core Graphics")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
            
            // 배지
            ExampleCard(title: "알림 배지") {
                Image(uiImage: createNotificationBadge())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
            }
        }
    }
    
    private func createWatermarkedImage() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 가상의 이미지 (그라디언트 배경)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor.systemTeal.cgColor, UIColor.systemBlue.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            
            // 워터마크
            let watermark = "© 2025"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.3)
            ]
            
            let textSize = watermark.size(withAttributes: attrs)
            let x = size.width - textSize.width - 20
            let y = size.height - textSize.height - 20
            
            (watermark as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        }
    }
    
    private func createProfileAvatar() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 원형 클리핑
            let circlePath = CGPath(ellipseIn: CGRect(origin: .zero, size: size), transform: nil)
            ctx.addPath(circlePath)
            ctx.clip()
            
            // 프로필 이미지 (그라디언트로 대체)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor.systemPurple.cgColor, UIColor.systemPink.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: size.width/2, y: size.height/2),
                startRadius: 0,
                endCenter: CGPoint(x: size.width/2, y: size.height/2),
                endRadius: size.width/2,
                options: []
            )
            
            // 테두리
            ctx.resetClip()
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(4)
            ctx.addPath(circlePath)
            ctx.strokePath()
        }
    }
    
    private func createNotificationBadge() -> UIImage {
        let size = CGSize(width: 120, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 아이콘 (사각형으로 표현)
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 30, y: 30, width: 40, height: 40))
            
            // 배지
            let badgeRect = CGRect(x: 60, y: 20, width: 30, height: 30)
            let badgePath = UIBezierPath(ovalIn: badgeRect)
            
            UIColor.systemRed.setFill()
            badgePath.fill()
            
            // 배지 숫자
            let count = "5"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = count.size(withAttributes: attrs)
            let textX = badgeRect.midX - textSize.width / 2
            let textY = badgeRect.midY - textSize.height / 2
            
            (count as NSString).draw(at: CGPoint(x: textX, y: textY), withAttributes: attrs)
        }
    }
}

// MARK: - 프리뷰

#Preview {
    NavigationStack {
        ImageCompositionView()
    }
}

