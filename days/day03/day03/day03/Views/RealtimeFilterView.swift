//
//  RealtimeFilterView.swift
//  day03
//
//  Created on 2025-10-21.
//

import SwiftUI
import CoreImage

/// 실시간 필터 처리 뷰
/// 슬라이더 조절 시 즉시 필터 적용
struct RealtimeFilterView: View {
    
    // MARK: - State
    
    @State private var blurRadius: Double = 5
    @State private var brightness: Double = 0
    @State private var saturation: Double = 1
    @State private var contrast: Double = 1
    
    @State private var isProcessing = false
    @State private var frameTime: TimeInterval = 0
    
    private let processor = ImageProcessor.shared
    private let sampleImage = UIImage(named: "sample") ?? UIImage(systemName: "photo")!
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                explanationCard
                
                // 이미지 표시
                imageSection
                
                // 성능 표시
                performanceSection
                
                // 컨트롤
                controlsSection
                
                // 프리셋 버튼
                presetsSection
                
                // 정보
                infoSection
            }
            .padding()
        }
        .navigationTitle("실시간 필터")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("실시간 처리")
                    .font(.headline)
            }
            
            Text("필터 체인을 사용하면 실시간으로 60fps 처리가 가능합니다!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var imageSection: some View {
        VStack {
            if let filtered = filteredImage {
                Image(uiImage: filtered)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                ProgressView()
                    .frame(height: 400)
            }
        }
    }
    
    private var performanceSection: some View {
        HStack {
            Image(systemName: isProcessing ? "hourglass" : "checkmark.circle.fill")
                .foregroundColor(isProcessing ? .orange : .green)
            
            VStack(alignment: .leading) {
                Text("렌더링 시간")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", frameTime * 1000))ms")
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("FPS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(1.0 / max(frameTime, 0.001)))")
                    .font(.headline)
                    .foregroundColor(frameTime < 0.017 ? .green : .orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            Text("필터 조절")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 블러
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "aqi.medium")
                    Text("블러 반경")
                    Spacer()
                    Text("\(Int(blurRadius))")
                        .foregroundColor(.secondary)
                }
                Slider(value: $blurRadius, in: 0...30)
                    .onChange(of: blurRadius) { _ in
                        measurePerformance()
                    }
            }
            
            // 밝기
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sun.max")
                    Text("밝기")
                    Spacer()
                    Text(String(format: "%.2f", brightness))
                        .foregroundColor(.secondary)
                }
                Slider(value: $brightness, in: -1...1)
                    .onChange(of: brightness) { _ in
                        measurePerformance()
                    }
            }
            
            // 채도
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "paintpalette")
                    Text("채도")
                    Spacer()
                    Text(String(format: "%.2f", saturation))
                        .foregroundColor(.secondary)
                }
                Slider(value: $saturation, in: 0...2)
                    .onChange(of: saturation) { _ in
                        measurePerformance()
                    }
            }
            
            // 대비
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                    Text("대비")
                    Spacer()
                    Text(String(format: "%.2f", contrast))
                        .foregroundColor(.secondary)
                }
                Slider(value: $contrast, in: 0.5...2)
                    .onChange(of: contrast) { _ in
                        measurePerformance()
                    }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var presetsSection: some View {
        VStack(spacing: 12) {
            Text("프리셋")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PresetButton(title: "리셋", icon: "arrow.counterclockwise") {
                    resetFilters()
                }
                
                PresetButton(title: "부드럽게", icon: "aqi.medium") {
                    applyPreset(blur: 15, brightness: 0.2, saturation: 1.2, contrast: 0.9)
                }
                
                PresetButton(title: "선명하게", icon: "wand.and.stars") {
                    applyPreset(blur: 0, brightness: 0.1, saturation: 1.3, contrast: 1.5)
                }
                
                PresetButton(title: "흑백", icon: "circle.grid.cross") {
                    applyPreset(blur: 0, brightness: 0, saturation: 0, contrast: 1.2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 실시간 처리 비결")
                .font(.headline)
            
            Text("• 필터 체인으로 한번에 렌더링")
            Text("• CIContext 재사용")
            Text("• Metal GPU 가속")
            Text("• 최적화된 extent 관리")
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                Image(systemName: frameTime < 0.017 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(frameTime < 0.017 ? .green : .orange)
                
                Text(frameTime < 0.017 ? "60fps 유지 중! ✨" : "성능 저하 감지")
                    .font(.subheadline)
            }
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Computed Properties
    
    private var filteredImage: UIImage? {
        guard let ciImage = processor.ciImage(from: sampleImage) else { return sampleImage }
        
        // 필터 체인 구성
        var currentImage = ciImage
        
        // 1. 블러
        if blurRadius > 0 {
            if let blurred = processor.applyBlur(to: currentImage, radius: blurRadius) {
                currentImage = processor.crop(blurred, to: ciImage.extent)
            }
        }
        
        // 2. 색상 조정 (밝기 + 채도 + 대비)
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(currentImage, forKey: kCIInputImageKey)
        colorFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        colorFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        colorFilter.setValue(contrast, forKey: kCIInputContrastKey)
        
        if let output = colorFilter.outputImage {
            currentImage = output
        }
        
        // 렌더링
        return processor.render(currentImage)
    }
    
    // MARK: - Methods
    
    private func measurePerformance() {
        let startTime = Date()
        _ = filteredImage
        frameTime = Date().timeIntervalSince(startTime)
    }
    
    private func resetFilters() {
        withAnimation {
            blurRadius = 5
            brightness = 0
            saturation = 1
            contrast = 1
        }
    }
    
    private func applyPreset(blur: Double, brightness: Double, saturation: Double, contrast: Double) {
        withAnimation {
            self.blurRadius = blur
            self.brightness = brightness
            self.saturation = saturation
            self.contrast = contrast
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        RealtimeFilterView()
    }
}

