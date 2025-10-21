//
//  BasicFilterView.swift
//  day03
//
//  Created on 2025-10-21.
//

import SwiftUI
import CoreImage

/// 기본 필터 적용 뷰
/// 단일 필터의 효과를 확인
struct BasicFilterView: View {
    
    // MARK: - State
    
    @State private var selectedFilter: FilterType = .blur
    @State private var filterIntensity: Double = 0.5
    @State private var showOriginal = false
    
    private let processor = ImageProcessor.shared
    private let sampleImage = UIImage(named: "sample") ?? UIImage(systemName: "photo")!
    
    // MARK: - Filter Types
    
    enum FilterType: String, CaseIterable {
        case blur = "블러"
        case sepia = "세피아"
        case sharpen = "샤픈"
        case vignette = "비네팅"
        case brightness = "밝기"
        case saturation = "채도"
        case contrast = "대비"
        
        var icon: String {
            switch self {
            case .blur: return "aqi.medium"
            case .sepia: return "camera.filters"
            case .sharpen: return "wand.and.stars"
            case .vignette: return "circle.lefthalf.filled"
            case .brightness: return "sun.max"
            case .saturation: return "paintpalette"
            case .contrast: return "circle.lefthalf.filled.righthalf.striped.horizontal"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 이미지 표시
                imageSection
                
                // 필터 선택
                filterSelectionSection
                
                // 강도 조절
                intensityControlSection
                
                // Before/After 토글
                toggleSection
                
                // 정보
                infoSection
            }
            .padding()
        }
        .navigationTitle("기본 필터")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var imageSection: some View {
        VStack {
            if showOriginal {
                Image(uiImage: sampleImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                if let filtered = filteredImage {
                    Image(uiImage: filtered)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    ProgressView("필터 적용 중...")
                        .frame(height: 400)
                }
            }
        }
        .animation(.easeInOut, value: showOriginal)
        .animation(.easeInOut, value: filterIntensity)
    }
    
    private var filterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("필터 선택")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        filterIntensity = 0.5 // 기본값으로 리셋
                    }
                }
            }
        }
    }
    
    private var intensityControlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("강도 조절")
                    .font(.headline)
                Spacer()
                Text("\(Int(filterIntensity * 100))%")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $filterIntensity, in: 0...1)
                .accentColor(.blue)
        }
    }
    
    private var toggleSection: some View {
        Button(action: {
            showOriginal.toggle()
        }) {
            HStack {
                Image(systemName: showOriginal ? "photo" : "wand.and.stars")
                Text(showOriginal ? "원본 보기" : "필터 보기")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📌 사용법")
                .font(.headline)
            
            Text("• 필터를 선택하세요")
            Text("• 슬라이더로 강도를 조절하세요")
            Text("• 버튼을 눌러 원본과 비교하세요")
            
            Divider()
                .padding(.vertical, 8)
            
            Text("🎯 학습 포인트")
                .font(.headline)
            
            Text("• 각 필터의 효과 이해")
            Text("• 파라미터 조절의 영향")
            Text("• 실시간 프리뷰")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Computed Properties
    
    private var filteredImage: UIImage? {
        guard let ciImage = processor.ciImage(from: sampleImage) else { return nil }
        
        let scaledIntensity = filterIntensity
        let ciOutput: CIImage?
        
        switch selectedFilter {
        case .blur:
            ciOutput = processor.applyBlur(to: ciImage, radius: scaledIntensity * 20)
        case .sepia:
            ciOutput = processor.applySepia(to: ciImage, intensity: scaledIntensity)
        case .sharpen:
            ciOutput = processor.applySharpen(to: ciImage, sharpness: scaledIntensity * 2)
        case .vignette:
            ciOutput = processor.applyVignette(to: ciImage, intensity: scaledIntensity * 3)
        case .brightness:
            ciOutput = processor.adjustBrightness(to: ciImage, brightness: (scaledIntensity - 0.5))
        case .saturation:
            ciOutput = processor.adjustSaturation(to: ciImage, saturation: scaledIntensity * 2)
        case .contrast:
            ciOutput = processor.adjustContrast(to: ciImage, contrast: scaledIntensity * 2)
        }
        
        guard let output = ciOutput else { return nil }
        
        // extent 관리 (블러는 이미지 확장)
        let croppedOutput = processor.crop(output, to: ciImage.extent)
        return processor.render(croppedOutput)
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let filter: BasicFilterView.FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.title2)
                Text(filter.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        BasicFilterView()
    }
}

