//
//  TextRenderingView.swift
//  day02
//
//  Core Graphics와 SwiftUI Canvas로 텍스트 렌더링
//  폰트, 색상, 스타일, 레이아웃 등을 비교합니다.
//

import SwiftUI
import UIKit

struct TextRenderingView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("렌더링 방식", selection: $selectedTab) {
                Text("Core Graphics").tag(0)
                Text("SwiftUI Canvas").tag(1)
                Text("비교").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView {
                VStack(spacing: 30) {
                    switch selectedTab {
                    case 0:
                        CoreGraphicsTextExample()
                    case 1:
                        SwiftUICanvasTextExample()
                    case 2:
                        TextComparisonExample()
                    default:
                        CoreGraphicsTextExample()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("텍스트 렌더링")
    }
}

// MARK: - Core Graphics 텍스트

struct CoreGraphicsTextExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("📝 Core Graphics 텍스트")
                .font(.title2)
                .bold()
            
            Text("NSAttributedString으로 텍스트를 그립니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 1. 기본 텍스트
            ExampleCard(title: "1. 기본 텍스트") {
                Image(uiImage: drawBasicText())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
            }
            
            // 2. 스타일 텍스트
            ExampleCard(title: "2. 다양한 스타일") {
                Image(uiImage: drawStyledText())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            // 3. 멀티라인 텍스트
            ExampleCard(title: "3. 멀티라인 & 정렬") {
                Image(uiImage: drawMultilineText())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            // 4. 텍스트 + 이미지
            ExampleCard(title: "4. 텍스트 + 배경") {
                Image(uiImage: drawTextWithBackground())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            CodeExplanationView(
                title: "Core Graphics 텍스트 특징",
                items: [
                    "NSAttributedString 사용 필수",
                    "UIFont로 폰트 지정",
                    "draw(at:) 또는 draw(in:) 메서드",
                    "정밀한 위치 제어 가능",
                    "이미지로 저장 쉬움"
                ]
            )
        }
    }
    
    // 기본 텍스트
    private func drawBasicText() -> UIImage {
        let size = CGSize(width: 400, height: 150)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 배경
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 텍스트
            let text = "Hello, Core Graphics!"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let x = (size.width - textSize.width) / 2
            let y = (size.height - textSize.height) / 2
            
            (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
    
    // 스타일 텍스트
    private func drawStyledText() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            var yOffset: CGFloat = 20
            
            // 1. Bold
            let bold = "Bold Text"
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            (bold as NSString).draw(at: CGPoint(x: 20, y: yOffset), withAttributes: boldAttrs)
            yOffset += 40
            
            // 2. Italic
            let italic = "Italic Text"
            let italicAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 24),
                .foregroundColor: UIColor.systemBlue
            ]
            (italic as NSString).draw(at: CGPoint(x: 20, y: yOffset), withAttributes: italicAttrs)
            yOffset += 40
            
            // 3. 색상 + 배경
            let colored = "Colored Background"
            let coloredAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.white,
                .backgroundColor: UIColor.systemPurple
            ]
            (colored as NSString).draw(at: CGPoint(x: 20, y: yOffset), withAttributes: coloredAttrs)
            yOffset += 40
            
            // 4. Underline + Strike
            let decorated = "Underline & Strike"
            let decoratedAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.systemRed,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ]
            (decorated as NSString).draw(at: CGPoint(x: 20, y: yOffset), withAttributes: decoratedAttrs)
        }
    }
    
    // 멀티라인 텍스트
    private func drawMultilineText() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let longText = """
            Core Graphics는 정밀한 텍스트
            렌더링을 제공합니다.
            줄바꿈과 정렬도 가능합니다.
            """
            
            // 왼쪽 정렬
            let leftStyle = NSMutableParagraphStyle()
            leftStyle.alignment = .left
            leftStyle.lineSpacing = 5
            
            let leftAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.black,
                .paragraphStyle: leftStyle
            ]
            
            let leftRect = CGRect(x: 20, y: 20, width: 160, height: 160)
            (longText as NSString).draw(in: leftRect, withAttributes: leftAttrs)
            
            // 중앙 정렬
            let centerStyle = NSMutableParagraphStyle()
            centerStyle.alignment = .center
            centerStyle.lineSpacing = 5
            
            let centerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.systemBlue,
                .paragraphStyle: centerStyle
            ]
            
            let centerRect = CGRect(x: 200, y: 20, width: 180, height: 160)
            (longText as NSString).draw(in: centerRect, withAttributes: centerAttrs)
        }
    }
    
    // 텍스트 + 배경
    private func drawTextWithBackground() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 그라디언트 배경
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor
            ] as CFArray
            
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors,
                locations: nil
            )!
            
            ctx.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
            
            // 중앙 텍스트
            let text = "Beautiful Text"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -3  // 음수: 채우기 + 테두리
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let x = (size.width - textSize.width) / 2
            let y = (size.height - textSize.height) / 2
            
            (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
}

// MARK: - SwiftUI Canvas 텍스트

struct SwiftUICanvasTextExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🎨 SwiftUI Canvas 텍스트")
                .font(.title2)
                .bold()
            
            Text("Text 뷰를 그대로 사용합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 1. 기본 텍스트
            ExampleCard(title: "1. 기본 텍스트") {
                Canvas { context, size in
                    let text = Text("Hello, Canvas!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    context.draw(text, at: CGPoint(x: size.width/2, y: size.height/2))
                }
                .frame(height: 150)
                .background(Color.white)
            }
            
            // 2. 스타일 텍스트
            ExampleCard(title: "2. 다양한 스타일") {
                Canvas { context, size in
                    var yOffset: CGFloat = 30
                    
                    // Bold
                    let bold = Text("Bold Text")
                        .font(.system(size: 24, weight: .bold))
                    context.draw(bold, at: CGPoint(x: 100, y: yOffset), anchor: .leading)
                    yOffset += 40
                    
                    // Italic
                    let italic = Text("Italic Text")
                        .font(.system(size: 24).italic())
                        .foregroundColor(.blue)
                    context.draw(italic, at: CGPoint(x: 100, y: yOffset), anchor: .leading)
                    yOffset += 40
                    
                    // 색상 + 배경
                    let colored = Text("Colored Background")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.purple)
                    context.draw(colored, at: CGPoint(x: 100, y: yOffset), anchor: .leading)
                    yOffset += 40
                    
                    // Underline + Strike
                    let decorated = Text("Underline & Strike")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .underline()
                        .strikethrough()
                    context.draw(decorated, at: CGPoint(x: 100, y: yOffset), anchor: .leading)
                }
                .frame(height: 200)
                .background(Color.white)
            }
            
            // 3. 그라디언트 텍스트
            ExampleCard(title: "3. 그라디언트 텍스트") {
                Canvas { context, size in
                    let text = Text("Gradient Text")
                        .font(.system(size: 40, weight: .black))
                    
                    // 그라디언트 마스크
                    context.drawLayer { layerContext in
                        layerContext.draw(text, at: CGPoint(x: size.width/2, y: size.height/2))
                    }
                    
                    // 배경 그라디언트
                    let gradient = Gradient(colors: [.blue, .purple, .pink])
                    let rect = CGRect(origin: .zero, size: size)
                    
                    context.fill(
                        Path(rect),
                        with: .linearGradient(
                            gradient,
                            startPoint: .zero,
                            endPoint: CGPoint(x: size.width, y: 0)
                        )
                    )
                    
                    // 텍스트를 마스크로 사용
                    context.blendMode = .destinationOut
                    context.draw(text, at: CGPoint(x: size.width/2, y: size.height/2))
                }
                .frame(height: 150)
                .background(Color.gray.opacity(0.1))
            }
            
            // 4. 애니메이션 텍스트
            ExampleCard(title: "4. 애니메이션 텍스트") {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let angle = Angle.radians(time.remainder(dividingBy: 2 * .pi))
                        
                        context.translateBy(x: size.width/2, y: size.height/2)
                        context.rotate(by: angle)
                        
                        let text = Text("Rotating!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)
                        
                        context.draw(text, at: .zero)
                    }
                }
                .frame(height: 150)
                .background(Color.white)
            }
            
            CodeExplanationView(
                title: "SwiftUI Canvas 텍스트 특징",
                items: [
                    "Text 뷰를 그대로 사용",
                    "SwiftUI 모디파이어 적용 가능",
                    "context.draw()로 그리기",
                    "애니메이션 쉬움 (TimelineView)",
                    "이미지 저장은 iOS 16+ 필요"
                ]
            )
        }
    }
}

// MARK: - 비교 예제

struct TextComparisonExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("⚖️ Core Graphics vs Canvas")
                .font(.title2)
                .bold()
            
            ComparisonTable()
            
            // 실전 예제: 카드 디자인
            ExampleCard(title: "실전: 카드 디자인 (Core Graphics)") {
                Image(uiImage: drawCardDesign())
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            ExampleCard(title: "실전: 카드 디자인 (Canvas)") {
                CanvasCardDesign()
                    .frame(height: 200)
            }
            
            RecommendationCard()
        }
    }
    
    private func drawCardDesign() -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 배경 (라운드 렉트)
            let cardRect = CGRect(x: 20, y: 20, width: 360, height: 160)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 16)
            
            ctx.addPath(path.cgPath)
            ctx.clip()
            
            // 그라디언트
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.systemIndigo.cgColor,
                UIColor.systemPurple.cgColor
            ] as CFArray
            
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 20, y: 20),
                end: CGPoint(x: 380, y: 180),
                options: []
            )
            
            // 텍스트
            let title = "Core Graphics Card"
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            (title as NSString).draw(at: CGPoint(x: 40, y: 50), withAttributes: titleAttrs)
            
            let subtitle = "정밀한 이미지 생성"
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            (subtitle as NSString).draw(at: CGPoint(x: 40, y: 90), withAttributes: subtitleAttrs)
        }
    }
}

struct CanvasCardDesign: View {
    var body: some View {
        Canvas { context, size in
            // 배경 그라디언트
            let cardRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
            let roundedPath = Path(roundedRect: cardRect, cornerRadius: 16)
            
            let gradient = Gradient(colors: [.indigo, .purple])
            context.fill(
                roundedPath,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 20, y: 20),
                    endPoint: CGPoint(x: size.width - 20, y: size.height - 20)
                )
            )
            
            // 텍스트
            let title = Text("SwiftUI Canvas Card")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            context.draw(title, at: CGPoint(x: 40, y: 60), anchor: .leading)
            
            let subtitle = Text("빠른 화면 렌더링")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.9))
            context.draw(subtitle, at: CGPoint(x: 40, y: 100), anchor: .leading)
        }
        .background(Color.white)
    }
}

struct ComparisonTable: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 비교표")
                .font(.headline)
            
            ComparisonRow(
                feature: "API",
                coreGraphics: "NSAttributedString",
                canvas: "SwiftUI Text"
            )
            
            ComparisonRow(
                feature: "간결성",
                coreGraphics: "복잡 ⚠️",
                canvas: "간단 ✅"
            )
            
            ComparisonRow(
                feature: "이미지 저장",
                coreGraphics: "쉬움 ✅",
                canvas: "iOS 16+ ⚠️"
            )
            
            ComparisonRow(
                feature: "애니메이션",
                coreGraphics: "어려움 ❌",
                canvas: "쉬움 ✅"
            )
            
            ComparisonRow(
                feature: "성능",
                coreGraphics: "CPU",
                canvas: "GPU 가능"
            )
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ComparisonRow: View {
    let feature: String
    let coreGraphics: String
    let canvas: String
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(coreGraphics)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(canvas)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RecommendationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 권장 사항")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                RecommendationItem(
                    icon: "💾",
                    title: "이미지 저장",
                    description: "Core Graphics 사용"
                )
                
                RecommendationItem(
                    icon: "🎨",
                    title: "화면 표시",
                    description: "SwiftUI Canvas 사용"
                )
                
                RecommendationItem(
                    icon: "⚡",
                    title: "애니메이션",
                    description: "SwiftUI Canvas + TimelineView"
                )
                
                RecommendationItem(
                    icon: "🎯",
                    title: "정밀 제어",
                    description: "Core Graphics 사용"
                )
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
}

struct RecommendationItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 헬퍼 뷰

struct ExampleCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - 프리뷰

#Preview {
    NavigationStack {
        TextRenderingView()
    }
}

