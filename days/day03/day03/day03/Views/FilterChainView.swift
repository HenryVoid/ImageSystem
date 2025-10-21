//
//  FilterChainView.swift
//  day03
//
//  Created on 2025-10-21.
//

import SwiftUI
import CoreImage

/// 필터 체인 시각화 뷰
/// 각 단계별 미리보기로 필터 체인의 동작 원리 이해
struct FilterChainView: View {
    
    // MARK: - State
    
    @State private var currentStep: Step = .original
    @State private var blurRadius: Double = 10
    @State private var brightness: Double = 0.3
    @State private var saturation: Double = 1.5
    
    private let processor = ImageProcessor.shared
    private let sampleImage = UIImage(named: "sample") ?? UIImage(systemName: "photo")!
    
    // MARK: - Step Enum
    
    enum Step: Int, CaseIterable {
        case original = 0
        case afterBlur = 1
        case afterBrightness = 2
        case afterSaturation = 3
        
        var title: String {
            switch self {
            case .original: return "원본"
            case .afterBlur: return "1단계: 블러"
            case .afterBrightness: return "2단계: +밝기"
            case .afterSaturation: return "3단계: +채도"
            }
        }
        
        var description: String {
            switch self {
            case .original:
                return "원본 이미지입니다.\n필터 체인을 시작해봅시다!"
            case .afterBlur:
                return "블러 필터를 적용했습니다.\n아직 렌더링은 안됐어요! (레시피만 작성)"
            case .afterBrightness:
                return "블러 + 밝기 필터입니다.\n여전히 레시피만 추가하는 중!"
            case .afterSaturation:
                return "블러 + 밝기 + 채도 완성!\n이제 한번에 렌더링됩니다! 🚀"
            }
        }
        
        var icon: String {
            switch self {
            case .original: return "photo"
            case .afterBlur: return "aqi.medium"
            case .afterBrightness: return "sun.max"
            case .afterSaturation: return "paintpalette"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 핵심 설명
                explanationCard
                
                // 이미지 표시
                imageSection
                
                // 단계 선택
                stepSelector
                
                // 파라미터 조절
                parameterControls
                
                // 필터 체인 시각화
                chainVisualization
                
                // 성능 정보
                performanceInfo
            }
            .padding()
        }
        .navigationTitle("필터 체인 ⭐")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("필터 체인이란?")
                    .font(.headline)
            }
            
            Text("여러 필터를 연결하여 한번에 처리하는 기술입니다.")
                .font(.subheadline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("매번 렌더링: 300ms")
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("필터 체인: 30ms (10배 빠름!)")
                        .font(.caption)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var imageSection: some View {
        VStack(spacing: 12) {
            if let image = imageForCurrentStep {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                ProgressView()
                    .frame(height: 350)
            }
            
            // 설명
            HStack {
                Image(systemName: currentStep.icon)
                    .foregroundColor(.blue)
                Text(currentStep.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var stepSelector: some View {
        VStack(spacing: 10) {
            Text("단계 선택")
                .font(.headline)
            
            Picker("단계", selection: $currentStep) {
                ForEach(Step.allCases, id: \.self) { step in
                    Text(step.title).tag(step)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var parameterControls: some View {
        VStack(spacing: 16) {
            Text("파라미터 조절")
                .font(.headline)
            
            // 블러 반경
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "aqi.medium")
                    Text("블러 반경")
                    Spacer()
                    Text("\(Int(blurRadius))")
                        .foregroundColor(.secondary)
                }
                Slider(value: $blurRadius, in: 0...30)
            }
            
            // 밝기
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "sun.max")
                    Text("밝기")
                    Spacer()
                    Text(String(format: "%.2f", brightness))
                        .foregroundColor(.secondary)
                }
                Slider(value: $brightness, in: -0.5...0.5)
            }
            
            // 채도
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "paintpalette")
                    Text("채도")
                    Spacer()
                    Text(String(format: "%.2f", saturation))
                        .foregroundColor(.secondary)
                }
                Slider(value: $saturation, in: 0...2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var chainVisualization: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("필터 체인 구조")
                .font(.headline)
            
            VStack(spacing: 8) {
                ChainStepView(
                    title: "원본 이미지",
                    isActive: currentStep.rawValue >= 0
                )
                
                ArrowView()
                
                ChainStepView(
                    title: "블러 필터",
                    subtitle: "CIGaussianBlur (반경: \(Int(blurRadius)))",
                    isActive: currentStep.rawValue >= 1
                )
                
                ArrowView()
                
                ChainStepView(
                    title: "밝기 조정",
                    subtitle: "CIColorControls (밝기: \(String(format: "%.2f", brightness)))",
                    isActive: currentStep.rawValue >= 2
                )
                
                ArrowView()
                
                ChainStepView(
                    title: "채도 조정",
                    subtitle: "CIColorControls (채도: \(String(format: "%.2f", saturation)))",
                    isActive: currentStep.rawValue >= 3
                )
                
                if currentStep == .afterSaturation {
                    ArrowView(isRendering: true)
                    
                    VStack {
                        HStack {
                            Image(systemName: "cpu")
                            Text("GPU에서 한번에 렌더링!")
                                .font(.subheadline)
                                .bold()
                        }
                        .foregroundColor(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var performanceInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ 성능 정보")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("매번 렌더링")
                        .font(.subheadline)
                    Text("3번 GPU 작업")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("300ms")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("필터 체인")
                        .font(.subheadline)
                    Text("1번 GPU 작업")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("30ms")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            
            Text("필터 체인은 10배 빠르고, 메모리는 1/3만 사용합니다!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    // MARK: - Computed Properties
    
    private var imageForCurrentStep: UIImage? {
        guard let ciImage = processor.ciImage(from: sampleImage) else { return sampleImage }
        
        switch currentStep {
        case .original:
            return sampleImage
            
        case .afterBlur:
            // 블러만 적용
            guard let blurred = processor.applyBlur(to: ciImage, radius: blurRadius) else {
                return sampleImage
            }
            let cropped = processor.crop(blurred, to: ciImage.extent)
            return processor.render(cropped)
            
        case .afterBrightness:
            // 블러 + 밝기
            guard let blurred = processor.applyBlur(to: ciImage, radius: blurRadius) else {
                return sampleImage
            }
            
            let brightnessFilter = CIFilter(name: "CIColorControls")!
            brightnessFilter.setValue(blurred, forKey: kCIInputImageKey)
            brightnessFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
            brightnessFilter.setValue(1.0, forKey: kCIInputSaturationKey)
            brightnessFilter.setValue(1.0, forKey: kCIInputContrastKey)
            
            guard let output = brightnessFilter.outputImage else { return sampleImage }
            let cropped = processor.crop(output, to: ciImage.extent)
            return processor.render(cropped)
            
        case .afterSaturation:
            // 블러 + 밝기 + 채도 (전체 체인)
            guard let result = processor.applyBasicChain(
                to: ciImage,
                blurRadius: blurRadius,
                brightness: brightness,
                saturation: saturation
            ) else {
                return sampleImage
            }
            
            let cropped = processor.crop(result, to: ciImage.extent)
            return processor.render(cropped)
        }
    }
}

// MARK: - Chain Step View

struct ChainStepView: View {
    let title: String
    var subtitle: String? = nil
    let isActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? .blue : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Arrow View

struct ArrowView: View {
    var isRendering: Bool = false
    
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: isRendering ? "bolt.fill" : "arrow.down")
                .foregroundColor(isRendering ? .green : .gray)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        FilterChainView()
    }
}

