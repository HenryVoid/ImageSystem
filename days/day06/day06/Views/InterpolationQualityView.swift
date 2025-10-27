//
//  InterpolationQualityView.swift
//  day06
//
//  보간 품질 비교 뷰 - .none, .low, .medium, .high
//

import SwiftUI

struct InterpolationQualityView: View {
    @State private var selectedInterpolation: Image.Interpolation = .medium
    @State private var zoomLevel: CGFloat = 4.0
    @State private var showPerformance = false
    
    // 작은 아이콘을 확대하여 보간 차이를 명확히 보기
    private let baseIconSize: CGFloat = 16
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 제목 및 설명
                headerSection
                
                // 보간 품질 선택
                interpolationSelector
                
                // 확대 수준 조절
                zoomSlider
                
                // 4가지 보간 품질 비교
                comparisonGrid
                
                // 현재 선택된 보간 품질 정보
                infoCard
                
                // 성능 측정
                if showPerformance {
                    performanceSection
                }
            }
            .padding()
        }
        .navigationTitle("Interpolation 품질 비교")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPerformance.toggle()
                } label: {
                    Image(systemName: showPerformance ? "speedometer.fill" : "speedometer")
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("🔍 보간 품질")
                .font(.largeTitle)
                .bold()
            
            Text("이미지 확대/축소 시 픽셀 사이를 채우는 방법")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Interpolation Selector
    
    private var interpolationSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("보간 품질 선택")
                .font(.headline)
            
            Picker("Interpolation", selection: $selectedInterpolation) {
                Text("None").tag(Image.Interpolation.none)
                Text("Low").tag(Image.Interpolation.low)
                Text("Medium").tag(Image.Interpolation.medium)
                Text("High").tag(Image.Interpolation.high)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Zoom Slider
    
    private var zoomSlider: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("확대 수준")
                    .font(.headline)
                Spacer()
                Text("\(Int(zoomLevel))×")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            HStack {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundStyle(.secondary)
                
                Slider(value: $zoomLevel, in: 2...10, step: 1)
                
                Image(systemName: "plus.magnifyingglass")
                    .foregroundStyle(.secondary)
            }
            
            Text("작은 아이콘을 \(Int(zoomLevel))배 확대하여 보간 품질 차이 확인")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Comparison Grid
    
    private var comparisonGrid: some View {
        VStack(spacing: 20) {
            Text("4가지 품질 비교")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(InterpolationHelper.allInterpolations, id: \.self) { interpolation in
                    interpolationCard(interpolation)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func interpolationCard(_ interpolation: Image.Interpolation) -> some View {
        VStack(spacing: 10) {
            // SF Symbol을 확대하여 보간 차이 표시
            Image(systemName: "star.fill")
                .resizable()
                .interpolation(interpolation)
                .frame(width: baseIconSize * zoomLevel, height: baseIconSize * zoomLevel)
                .foregroundStyle(.blue)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            
            Text(interpolation.name)
                .font(.caption)
                .bold()
            
            Text(interpolation.visualCharacteristic)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // 현재 선택된 것 표시
            if interpolation == selectedInterpolation {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(interpolation == selectedInterpolation ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(interpolation == selectedInterpolation ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedInterpolation = interpolation
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(selectedInterpolation.name)
                .font(.title2)
                .bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("설명", systemImage: "info.circle")
                    .font(.headline)
                Text(selectedInterpolation.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("사용 사례", systemImage: "lightbulb")
                    .font(.headline)
                Text(selectedInterpolation.useCase)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("시각적 특징", systemImage: "eye")
                    .font(.headline)
                Text(selectedInterpolation.visualCharacteristic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("성능", systemImage: "speedometer")
                    .font(.headline)
                Text(selectedInterpolation.performanceNote)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("성능 비교")
                .font(.title2)
                .bold()
            
            Text("예상 렌더링 시간 (100개 이미지)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 10) {
                ForEach(InterpolationHelper.allInterpolations, id: \.self) { interpolation in
                    performanceBar(interpolation)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("💡 성능 팁")
                    .font(.headline)
                
                Text("""
                • 스크롤 뷰: .medium 권장
                • 정적 화면: .high 사용 가능
                • 픽셀 아트: .none 필수
                • 실시간 애니메이션: .low
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func performanceBar(_ interpolation: Image.Interpolation) -> some View {
        let time = interpolation.estimatedRenderTime
        let maxTime: CGFloat = 120.0
        let ratio = CGFloat(time) / maxTime
        
        return HStack {
            Text(interpolation.name)
                .font(.caption)
                .frame(width: 60, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 20)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(colorForPerformance(ratio))
                        .frame(width: geometry.size.width * ratio, height: 20)
                        .cornerRadius(4)
                }
            }
            .frame(height: 20)
            
            Text(String(format: "%.0fms", time))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
    }
    
    private func colorForPerformance(_ ratio: CGFloat) -> Color {
        switch ratio {
        case 0..<0.3: return .green
        case 0.3..<0.6: return .yellow
        default: return .red
        }
    }
}

#Preview {
    NavigationStack {
        InterpolationQualityView()
    }
}


