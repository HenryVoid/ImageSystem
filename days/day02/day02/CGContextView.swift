//
//  CGContextView.swift
//  day02
//
//  Core Graphics 기본 도형 그리기 예제
//  선, 사각형, 원, 삼각형, 복잡한 경로 등을 직접 그려봅니다.
//

import SwiftUI
import UIKit

// MARK: - 메인 뷰

struct CGContextView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            // 탭 선택
            Picker("예제 선택", selection: $selectedTab) {
                Text("기본 도형").tag(0)
                Text("복잡한 경로").tag(1)
                Text("그라디언트").tag(2)
                Text("변환").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 선택된 예제 표시
            ScrollView {
                VStack(spacing: 30) {
                    switch selectedTab {
                    case 0:
                        BasicShapesExample()
                    case 1:
                        ComplexPathExample()
                    case 2:
                        GradientExample()
                    case 3:
                        TransformExample()
                    default:
                        BasicShapesExample()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Core Graphics 기본")
    }
}

// MARK: - 1. 기본 도형 예제

struct BasicShapesExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("1️⃣ 기본 도형 그리기")
                .font(.title2)
                .bold()
            
            Text("선, 사각형, 원 등 기본 도형을 Core Graphics로 직접 그립니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 생성된 이미지 표시
            Image(uiImage: drawBasicShapes())
                .resizable()
                .scaledToFit()
                .frame(height: 400)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            // 코드 설명
            CodeExplanationView(
                title: "코드 설명",
                items: [
                    "UIGraphicsImageRenderer로 안전하게 이미지 생성",
                    "cgContext로 그리기 명령 수행",
                    "setFillColor/setStrokeColor로 색상 설정",
                    "fill/stroke/strokePath로 실제 그리기 실행"
                ]
            )
        }
    }
    
    /// 기본 도형 그리기 함수
    private func drawBasicShapes() -> UIImage {
        // 1️⃣ 렌더러 생성 (400x400 크기)
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        // 2️⃣ 이미지 생성
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 배경 (흰색)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 📐 사각형 (파란색)
            ctx.setFillColor(UIColor.systemBlue.cgColor)
            ctx.fill(CGRect(x: 50, y: 50, width: 100, height: 100))
            
            // 텍스트 레이블
            drawLabel("사각형\nfill()", at: CGPoint(x: 50, y: 160))
            
            // ⭕ 원 (빨간색)
            ctx.setFillColor(UIColor.systemRed.cgColor)
            ctx.fillEllipse(in: CGRect(x: 250, y: 50, width: 100, height: 100))
            
            drawLabel("원\nfillEllipse()", at: CGPoint(x: 250, y: 160))
            
            // 📏 선 (초록색, 굵기 5)
            ctx.setStrokeColor(UIColor.systemGreen.cgColor)
            ctx.setLineWidth(5)
            ctx.setLineCap(.round)  // 선 끝을 둥글게
            ctx.move(to: CGPoint(x: 50, y: 250))
            ctx.addLine(to: CGPoint(x: 350, y: 250))
            ctx.strokePath()
            
            drawLabel("선\nstrokePath()", at: CGPoint(x: 50, y: 260))
            
            // 🔲 테두리만 있는 사각형 (보라색)
            ctx.setStrokeColor(UIColor.systemPurple.cgColor)
            ctx.setLineWidth(3)
            ctx.stroke(CGRect(x: 50, y: 300, width: 100, height: 80))
            
            drawLabel("테두리\nstroke()", at: CGPoint(x: 160, y: 330))
            
            // 🟡 테두리 + 채우기 (노란색 + 주황색 테두리)
            let rect = CGRect(x: 250, y: 300, width: 100, height: 80)
            ctx.setFillColor(UIColor.systemYellow.cgColor)
            ctx.fill(rect)
            ctx.setStrokeColor(UIColor.systemOrange.cgColor)
            ctx.setLineWidth(3)
            ctx.stroke(rect)
            
            drawLabel("채우기+테두리", at: CGPoint(x: 250, y: 320))
        }
    }
    
    /// 텍스트 레이블 그리기 헬퍼 함수
    private func drawLabel(_ text: String, at point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        (text as NSString).draw(at: point, withAttributes: attributes)
    }
}

// MARK: - 2. 복잡한 경로 예제

struct ComplexPathExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("2️⃣ 복잡한 경로 그리기")
                .font(.title2)
                .bold()
            
            Text("move/addLine/closePath로 삼각형, 별, 다각형 등을 그립니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Image(uiImage: drawComplexPaths())
                .resizable()
                .scaledToFit()
                .frame(height: 400)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            CodeExplanationView(
                title: "경로(Path) 개념",
                items: [
                    "beginPath(): 새 경로 시작",
                    "move(to:): 시작점 이동 (그리지 않음)",
                    "addLine(to:): 선 추가",
                    "closePath(): 시작점으로 닫기",
                    "fillPath(): 경로 채우기"
                ]
            )
        }
    }
    
    private func drawComplexPaths() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 배경
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 1️⃣ 삼각형 (파란색)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 100, y: 50))     // 꼭대기
            ctx.addLine(to: CGPoint(x: 50, y: 150))  // 왼쪽 아래
            ctx.addLine(to: CGPoint(x: 150, y: 150)) // 오른쪽 아래
            ctx.closePath()  // 다시 꼭대기로
            
            ctx.setFillColor(UIColor.systemBlue.cgColor)
            ctx.fillPath()
            
            drawLabel("삼각형", at: CGPoint(x: 75, y: 160))
            
            // 2️⃣ 별 (노란색)
            drawStar(ctx: ctx, center: CGPoint(x: 300, y: 100), 
                    radius: 50, points: 5)
            ctx.setFillColor(UIColor.systemYellow.cgColor)
            ctx.fillPath()
            
            drawLabel("별 (5각)", at: CGPoint(x: 270, y: 160))
            
            // 3️⃣ 육각형 (초록색)
            drawPolygon(ctx: ctx, center: CGPoint(x: 100, y: 280), 
                       radius: 50, sides: 6)
            ctx.setFillColor(UIColor.systemGreen.cgColor)
            ctx.fillPath()
            
            drawLabel("육각형", at: CGPoint(x: 70, y: 350))
            
            // 4️⃣ 하트 (빨간색)
            drawHeart(ctx: ctx, center: CGPoint(x: 300, y: 280), size: 60)
            ctx.setFillColor(UIColor.systemRed.cgColor)
            ctx.fillPath()
            
            drawLabel("하트", at: CGPoint(x: 280, y: 350))
        }
    }
    
    /// 별 그리기
    private func drawStar(ctx: CGContext, center: CGPoint, 
                         radius: CGFloat, points: Int) {
        let angle = CGFloat.pi * 2 / CGFloat(points)
        let innerRadius = radius * 0.4
        
        ctx.beginPath()
        
        for i in 0..<points * 2 {
            let r = i % 2 == 0 ? radius : innerRadius
            let currentAngle = angle * CGFloat(i) - .pi / 2
            let x = center.x + cos(currentAngle) * r
            let y = center.y + sin(currentAngle) * r
            
            if i == 0 {
                ctx.move(to: CGPoint(x: x, y: y))
            } else {
                ctx.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        ctx.closePath()
    }
    
    /// 정다각형 그리기
    private func drawPolygon(ctx: CGContext, center: CGPoint, 
                            radius: CGFloat, sides: Int) {
        let angle = CGFloat.pi * 2 / CGFloat(sides)
        
        ctx.beginPath()
        
        for i in 0..<sides {
            let currentAngle = angle * CGFloat(i) - .pi / 2
            let x = center.x + cos(currentAngle) * radius
            let y = center.y + sin(currentAngle) * radius
            
            if i == 0 {
                ctx.move(to: CGPoint(x: x, y: y))
            } else {
                ctx.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        ctx.closePath()
    }
    
    /// 하트 그리기 (베지어 곡선 사용)
    private func drawHeart(ctx: CGContext, center: CGPoint, size: CGFloat) {
        ctx.beginPath()
        
        // 하트는 두 개의 반원 + 삼각형으로 구성
        let topY = center.y - size * 0.3
        
        ctx.move(to: CGPoint(x: center.x, y: center.y + size * 0.5))
        
        // 왼쪽 곡선
        ctx.addCurve(
            to: CGPoint(x: center.x - size * 0.5, y: topY),
            control1: CGPoint(x: center.x, y: center.y),
            control2: CGPoint(x: center.x - size * 0.5, y: center.y - size * 0.1)
        )
        
        // 왼쪽 상단 반원
        ctx.addArc(
            center: CGPoint(x: center.x - size * 0.25, y: topY),
            radius: size * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: false
        )
        
        // 오른쪽 상단 반원
        ctx.addArc(
            center: CGPoint(x: center.x + size * 0.25, y: topY),
            radius: size * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: false
        )
        
        // 오른쪽 곡선
        ctx.addCurve(
            to: CGPoint(x: center.x, y: center.y + size * 0.5),
            control1: CGPoint(x: center.x + size * 0.5, y: center.y - size * 0.1),
            control2: CGPoint(x: center.x, y: center.y)
        )
        
        ctx.closePath()
    }
    
    private func drawLabel(_ text: String, at point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        (text as NSString).draw(at: point, withAttributes: attributes)
    }
}

// MARK: - 3. 그라디언트 예제

struct GradientExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("3️⃣ 그라디언트")
                .font(.title2)
                .bold()
            
            Text("선형, 방사형 그라디언트를 Core Graphics로 그립니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Image(uiImage: drawGradients())
                .resizable()
                .scaledToFit()
                .frame(height: 400)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            CodeExplanationView(
                title: "그라디언트 개념",
                items: [
                    "CGGradient: 색상 배열로 그라디언트 생성",
                    "drawLinearGradient: 선형 (직선) 그라디언트",
                    "drawRadialGradient: 방사형 (원형) 그라디언트",
                    "locations: 색상 위치 지정 (0.0 ~ 1.0)"
                ]
            )
        }
    }
    
    private func drawGradients() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            // 1️⃣ 선형 그라디언트 (위→아래)
            let colors1 = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor
            ] as CFArray
            
            let gradient1 = CGGradient(
                colorsSpace: colorSpace,
                colors: colors1,
                locations: nil  // 균등 분포
            )!
            
            ctx.drawLinearGradient(
                gradient1,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: 200),
                options: []
            )
            
            drawLabel("선형 그라디언트\n(위→아래)", at: CGPoint(x: 10, y: 10))
            
            // 2️⃣ 선형 그라디언트 (좌→우)
            let colors2 = [
                UIColor.systemRed.cgColor,
                UIColor.systemOrange.cgColor,
                UIColor.systemYellow.cgColor
            ] as CFArray
            
            let gradient2 = CGGradient(
                colorsSpace: colorSpace,
                colors: colors2,
                locations: nil
            )!
            
            ctx.drawLinearGradient(
                gradient2,
                start: CGPoint(x: 0, y: 200),
                end: CGPoint(x: 400, y: 200),
                options: []
            )
            
            drawLabel("선형 그라디언트\n(좌→우, 3색)", at: CGPoint(x: 10, y: 210))
            
            // 3️⃣ 방사형 그라디언트 (왼쪽 원)
            let colors3 = [
                UIColor.systemGreen.cgColor,
                UIColor.systemTeal.cgColor,
                UIColor.systemBlue.cgColor
            ] as CFArray
            
            let gradient3 = CGGradient(
                colorsSpace: colorSpace,
                colors: colors3,
                locations: nil
            )!
            
            ctx.drawRadialGradient(
                gradient3,
                startCenter: CGPoint(x: 100, y: 300),
                startRadius: 0,
                endCenter: CGPoint(x: 100, y: 300),
                endRadius: 70,
                options: []
            )
            
            drawLabel("방사형\n그라디언트", at: CGPoint(x: 60, y: 360))
            
            // 4️⃣ 방사형 그라디언트 (오른쪽, 오프셋)
            let colors4 = [
                UIColor.systemYellow.cgColor,
                UIColor.systemOrange.cgColor,
                UIColor.systemRed.cgColor
            ] as CFArray
            
            let gradient4 = CGGradient(
                colorsSpace: colorSpace,
                colors: colors4,
                locations: nil
            )!
            
            // 시작점과 끝점이 다름 (태양 효과)
            ctx.drawRadialGradient(
                gradient4,
                startCenter: CGPoint(x: 280, y: 280),
                startRadius: 10,
                endCenter: CGPoint(x: 300, y: 300),
                endRadius: 70,
                options: []
            )
            
            drawLabel("오프셋\n그라디언트", at: CGPoint(x: 260, y: 360))
        }
    }
    
    private func drawLabel(_ text: String, at point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -2  // 음수: 채우기 + 테두리
        ]
        (text as NSString).draw(at: point, withAttributes: attributes)
    }
}

// MARK: - 4. 변환 예제

struct TransformExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("4️⃣ 변환 (Transform)")
                .font(.title2)
                .bold()
            
            Text("이동, 회전, 확대/축소 변환을 적용합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Image(uiImage: drawTransforms())
                .resizable()
                .scaledToFit()
                .frame(height: 400)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            CodeExplanationView(
                title: "변환 개념",
                items: [
                    "translateBy: 위치 이동",
                    "rotate: 회전 (라디안 단위)",
                    "scaleBy: 확대/축소",
                    "saveGState/restoreGState: 상태 저장/복원"
                ]
            )
        }
    }
    
    private func drawTransforms() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 배경
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 기본 사각형 함수
            func drawRect(color: UIColor, label: String = "") {
                ctx.setFillColor(color.cgColor)
                ctx.fill(CGRect(x: -25, y: -25, width: 50, height: 50))
                
                if !label.isEmpty {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                        .foregroundColor: UIColor.white
                    ]
                    (label as NSString).draw(
                        at: CGPoint(x: -20, y: -10),
                        withAttributes: attributes
                    )
                }
            }
            
            // 1️⃣ 원본 (변환 없음)
            ctx.saveGState()
            ctx.translateBy(x: 100, y: 100)
            drawRect(color: .systemGray, label: "원본")
            ctx.restoreGState()
            
            drawLabel("원본", at: CGPoint(x: 85, y: 130))
            
            // 2️⃣ 이동 (Translate)
            ctx.saveGState()
            ctx.translateBy(x: 100, y: 100)  // 기준점
            ctx.translateBy(x: 150, y: 0)    // 오른쪽으로 이동
            drawRect(color: .systemBlue, label: "이동")
            ctx.restoreGState()
            
            drawLabel("이동\ntranslateBy", at: CGPoint(x: 225, y: 130))
            
            // 3️⃣ 회전 (Rotate)
            ctx.saveGState()
            ctx.translateBy(x: 100, y: 250)
            ctx.rotate(by: .pi / 4)  // 45도 회전
            drawRect(color: .systemRed, label: "45°")
            ctx.restoreGState()
            
            drawLabel("회전\nrotate", at: CGPoint(x: 85, y: 280))
            
            // 4️⃣ 확대 (Scale)
            ctx.saveGState()
            ctx.translateBy(x: 250, y: 250)
            ctx.scaleBy(x: 1.5, y: 1.5)  // 1.5배 확대
            drawRect(color: .systemGreen, label: "1.5x")
            ctx.restoreGState()
            
            drawLabel("확대\nscaleBy", at: CGPoint(x: 225, y: 290))
            
            // 5️⃣ 복합 변환 (이동 + 회전 + 확대)
            ctx.saveGState()
            ctx.translateBy(x: 300, y: 100)
            ctx.rotate(by: -.pi / 6)  // -30도
            ctx.scaleBy(x: 0.8, y: 1.2)  // X축 축소, Y축 확대
            drawRect(color: .systemPurple, label: "복합")
            ctx.restoreGState()
            
            drawLabel("복합 변환\n이동+회전+확대", at: CGPoint(x: 260, y: 130))
            
            // 6️⃣ State Stack 예시
            ctx.saveGState()  // [상태1 저장]
            ctx.translateBy(x: 100, y: 350)
            
            drawRect(color: .systemOrange.withAlphaComponent(0.3), label: "1")
            
            ctx.saveGState()  // [상태1, 상태2 저장]
            ctx.translateBy(x: 40, y: 0)
            drawRect(color: .systemOrange.withAlphaComponent(0.6), label: "2")
            
            ctx.saveGState()  // [상태1, 상태2, 상태3 저장]
            ctx.translateBy(x: 40, y: 0)
            drawRect(color: .systemOrange, label: "3")
            
            ctx.restoreGState()  // [상태1, 상태2]
            ctx.restoreGState()  // [상태1]
            ctx.restoreGState()  // []
            
            drawLabel("State Stack\n(저장→복원)", at: CGPoint(x: 85, y: 370))
        }
    }
    
    private func drawLabel(_ text: String, at point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        (text as NSString).draw(at: point, withAttributes: attributes)
    }
}

// MARK: - 헬퍼 뷰: 코드 설명

struct CodeExplanationView: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.blue)
                    Text(items[index])
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - 프리뷰

#Preview {
    NavigationStack {
        CGContextView()
    }
}

