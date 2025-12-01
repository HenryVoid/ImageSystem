//
//  ContentView.swift
//  day24
//
//  Created on 12/01/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    var body: some View {
        TabView {
            BasicFilterView()
                .tabItem {
                    Label("Basic", systemImage: "wand.and.stars")
                }
            
            EmotionFilterView()
                .tabItem {
                    Label("Emotion", systemImage: "face.smiling")
                }
            
            HighlightFilterView()
                .tabItem {
                    Label("Highlight", systemImage: "sun.max")
                }
            
            PipelineView()
                .tabItem {
                    Label("Pipeline", systemImage: "arrow.triangle.branch")
                }
        }
    }
}

// MARK: - Shared Image Loader
struct DemoImageProvider {
    static func loadSampleImage() -> CIImage? {
        // 1. Assets에 이미지가 있다면 그것을 사용
        if let uiImage = UIImage(named: "sample"),
           let ciImage = CIImage(image: uiImage) {
            return ciImage
        }
        
        // 2. 없다면 시스템 이미지 사용 (유색으로 렌더링)
        if let uiImage = UIImage(systemName: "photo.artframe"),
           let cgImage = uiImage.cgImage { // 시스템 이미지는 바로 CIImage로 안 될 수 있음
            return CIImage(cgImage: cgImage)
        }
        
        // 3. 그것도 안되면 Core Image로 생성한 체커보드
        let filter = CIFilter.checkerboardGenerator()
        filter.center = CGPoint(x: 150, y: 150)
        filter.color0 = CIColor(red: 1, green: 0.9, blue: 0.8)
        filter.color1 = CIColor(red: 0.3, green: 0.5, blue: 0.9)
        filter.width = 50
        filter.sharpness = 1
        return filter.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))
    }
}

// MARK: - 1. Basic Filter (Pink Tint)
struct BasicFilterView: View {
    @State private var outputImage: UIImage?
    
    var body: some View {
        VStack {
            Text("Basic: Pink Tint")
                .font(.headline)
                .padding()
            
            if let image = outputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                ContentUnavailableView("이미지 로딩 중...", systemImage: "photo")
            }
            
            Button("Apply Pink Tint") {
                applyFilter()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear { applyFilter() }
    }
    
    private func applyFilter() {
        guard let input = DemoImageProvider.loadSampleImage() else { return }
        
        let filter = PinkTintFilter()
        filter.inputImage = input
        
        if let output = filter.outputImage,
           let cgImage = CIContextManager.shared.render(output) {
            self.outputImage = UIImage(cgImage: cgImage)
        }
    }
}

// MARK: - 2. Emotion Filter (Slider)
struct EmotionFilterView: View {
    @State private var emotionScore: Float = 50.0
    @State private var outputImage: UIImage?
    
    var body: some View {
        VStack {
            Text("Emotion Filter")
                .font(.headline)
            
            Text("Score: \(Int(emotionScore))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let image = outputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(Text("Loading..."))
            }
            
            HStack {
                Text("Cold")
                    .foregroundColor(.blue)
                Slider(value: $emotionScore, in: 0...100)
                    .onChange(of: emotionScore) { _ in
                        applyFilter()
                    }
                Text("Warm")
                    .foregroundColor(.orange)
            }
            .padding()
        }
        .padding()
        .onAppear { applyFilter() }
    }
    
    private func applyFilter() {
        guard let input = DemoImageProvider.loadSampleImage() else { return }
        
        let filter = EmotionFilter()
        filter.inputImage = input
        filter.inputEmotion = emotionScore
        
        // CIContextManager를 통해 빠르게 렌더링
        if let output = filter.outputImage,
           let cgImage = CIContextManager.shared.render(output) {
            self.outputImage = UIImage(cgImage: cgImage)
        }
    }
}

// MARK: - 3. Highlight Filter
struct HighlightFilterView: View {
    @State private var outputImage: UIImage?
    
    var body: some View {
        VStack {
            Text("Highlight Filter")
                .font(.headline)
                .padding()
            
            Text("밝은 영역만 핑크색으로 강조합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let image = outputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
            }
            
            Button("Apply Highlight Filter") {
                applyFilter()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear { applyFilter() }
    }
    
    private func applyFilter() {
        // 흑백 그라데이션 등을 사용하면 효과가 더 잘 보임
        // 여기서는 기본 샘플 이미지 사용
        guard let input = DemoImageProvider.loadSampleImage() else { return }
        
        let filter = HighlightFilter()
        filter.inputImage = input
        
        if let output = filter.outputImage,
           let cgImage = CIContextManager.shared.render(output) {
            self.outputImage = UIImage(cgImage: cgImage)
        }
    }
}

// MARK: - 4. Pipeline Demo
struct PipelineView: View {
    @State private var outputImage: UIImage?
    
    var body: some View {
        VStack {
            Text("Filter Pipeline")
                .font(.headline)
            
            Text("Tint -> Blur -> Vignette")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            if let image = outputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
            }
            
            Button("Run Pipeline") {
                runPipeline()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { runPipeline() }
    }
    
    private func runPipeline() {
        guard let input = DemoImageProvider.loadSampleImage() else { return }
        
        // 1. Custom Pink Tint
        let tintFilter = PinkTintFilter()
        tintFilter.inputImage = input
        guard let tintOutput = tintFilter.outputImage else { return }
        
        // 2. Gaussian Blur (Built-in)
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = tintOutput
        blurFilter.radius = 10.0
        guard let blurOutput = blurFilter.outputImage else { return }
        
        // 3. Vignette (Built-in)
        let vignetteFilter = CIFilter.vignette()
        vignetteFilter.inputImage = blurOutput
        vignetteFilter.intensity = 2.0
        vignetteFilter.radius = 1.0
        
        // 4. Final Render
        // Core Image의 장점: 중간 이미지를 렌더링하지 않고, 마지막에 한 번만 커널을 합쳐서 실행함 (Concatenation)
        if let finalOutput = vignetteFilter.outputImage,
           // Blur 등으로 인해 이미지가 커질 수 있으므로 원본 크기로 크롭
           let croppedOutput = finalOutput.cropped(to: input.extent) as CIImage?,
           let cgImage = CIContextManager.shared.render(croppedOutput) {
            self.outputImage = UIImage(cgImage: cgImage)
        }
    }
}

#Preview {
    ContentView()
}
