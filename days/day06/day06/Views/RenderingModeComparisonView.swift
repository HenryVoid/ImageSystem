//
//  RenderingModeComparisonView.swift
//  day06
//
//  렌더링 모드 비교 뷰 - .original vs .template
//

import SwiftUI

struct RenderingModeComparisonView: View {
    @State private var selectedMode: Image.TemplateRenderingMode = .original
    @State private var tintColor: Color = .blue
    @State private var selectedSymbol = "star.fill"
    
    private let availableColors: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .yellow
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 제목 및 설명
                headerSection
                
                // 렌더링 모드 선택
                modeSelector
                
                // 틴트 색상 선택 (템플릿 모드일 때만)
                if selectedMode == .template {
                    colorSelector
                }
                
                // SF Symbols 비교
                symbolComparison
                
                // 설명 카드
                infoCard
                
                // 실무 예제
                practicalExamples
            }
            .padding()
        }
        .navigationTitle("Rendering Mode 비교")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("🎨 렌더링 모드")
                .font(.largeTitle)
                .bold()
            
            Text("이미지를 원본 색상 또는 템플릿(단색)으로 렌더링")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("렌더링 모드")
                .font(.headline)
            
            Picker("Mode", selection: $selectedMode) {
                Text("Original").tag(Image.TemplateRenderingMode.original)
                Text("Template").tag(Image.TemplateRenderingMode.template)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Color Selector
    
    private var colorSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("틴트 색상")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(availableColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: tintColor == color ? 3 : 0)
                            )
                            .onTapGesture {
                                tintColor = color
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Symbol Comparison
    
    private var symbolComparison: some View {
        VStack(spacing: 20) {
            Text("SF Symbols 비교")
                .font(.headline)
            
            // SF Symbol 선택
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(RenderingModeHelper.sampleSymbols, id: \.self) { symbol in
                        VStack {
                            Image(systemName: symbol)
                                .font(.title)
                                .foregroundStyle(.primary)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: selectedSymbol == symbol ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedSymbol = symbol
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 비교 결과
            HStack(spacing: 40) {
                // Original
                VStack(spacing: 10) {
                    Image(systemName: selectedSymbol)
                        .renderingMode(.original)
                        .font(.system(size: 80))
                        .frame(width: 120, height: 120)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Text("Original")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Template
                VStack(spacing: 10) {
                    Image(systemName: selectedSymbol)
                        .renderingMode(.template)
                        .font(.system(size: 80))
                        .foregroundStyle(tintColor)
                        .frame(width: 120, height: 120)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Text("Template")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(selectedMode.name)
                .font(.title2)
                .bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("설명", systemImage: "info.circle")
                    .font(.headline)
                Text(selectedMode.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("사용 사례", systemImage: "lightbulb")
                    .font(.headline)
                Text(selectedMode.useCase)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("성능 특성", systemImage: "speedometer")
                    .font(.headline)
                Text(selectedMode.performanceNote)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Practical Examples
    
    private var practicalExamples: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("실무 예제")
                .font(.title2)
                .bold()
            
            // 아이콘 버튼
            VStack(alignment: .leading, spacing: 10) {
                Text("아이콘 버튼")
                    .font(.headline)
                
                HStack(spacing: 15) {
                    RenderingModeIconButton(
                        systemName: "heart.fill",
                        mode: .template,
                        color: .red,
                        action: {}
                    )
                    
                    RenderingModeIconButton(
                        systemName: "star.fill",
                        mode: .template,
                        color: .yellow,
                        action: {}
                    )
                    
                    RenderingModeIconButton(
                        systemName: "bookmark.fill",
                        mode: .template,
                        color: .blue,
                        action: {}
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // 상태 표시
            VStack(alignment: .leading, spacing: 10) {
                Text("상태 표시")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    HStack(spacing: 5) {
                        StatusIcon(isActive: true)
                        Text("활성")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 5) {
                        StatusIcon(isActive: false)
                        Text("비활성")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // 탭바 아이콘
            VStack(alignment: .leading, spacing: 10) {
                Text("탭바 아이콘 시뮬레이션")
                    .font(.headline)
                
                HStack(spacing: 0) {
                    ForEach(["house", "magnifyingglass", "heart", "person"], id: \.self) { symbol in
                        VStack(spacing: 5) {
                            Image(systemName: symbol)
                                .renderingMode(.template)
                                .font(.title3)
                                .foregroundStyle(.blue)
                            Text(symbol.capitalized)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        RenderingModeComparisonView()
    }
}

