//
//  AspectRatioTestView.swift
//  day06
//
//  Aspect Ratio 테스트 뷰 - .fit vs .fill 비교
//

import SwiftUI

struct AspectRatioTestView: View {
    @State private var contentMode: ContentMode = .fit
    @State private var selectedAspectRatio: ImageSizeCalculator.CommonAspectRatio = .landscape
    @State private var showClipped = true
    @State private var containerWidth: CGFloat = 300
    @State private var containerHeight: CGFloat = 200
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 제목 및 설명
                headerSection
                
                // Content Mode 선택
                contentModeSelector
                
                // Clipped 옵션
                clippedToggle
                
                // 실시간 비교
                comparisonSection
                
                // 컨테이너 크기 조절
                sizeControls
                
                // Aspect Ratio 프리셋
                aspectRatioPresets
                
                // 설명 카드
                infoCard
                
                // 실무 예제
                practicalExamples
            }
            .padding()
        }
        .navigationTitle("Aspect Ratio 테스트")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("📐 Aspect Ratio")
                .font(.largeTitle)
                .bold()
            
            Text("이미지 비율을 유지하는 방법")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Content Mode Selector
    
    private var contentModeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Content Mode")
                .font(.headline)
            
            Picker("Mode", selection: $contentMode) {
                Text("Fit").tag(ContentMode.fit)
                Text("Fill").tag(ContentMode.fill)
            }
            .pickerStyle(.segmented)
            
            Text(contentMode == .fit
                 ? "이미지 전체가 보이도록 맞춤 (여백 생김)"
                 : "영역을 완전히 채움 (이미지 잘림)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Clipped Toggle
    
    private var clippedToggle: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $showClipped) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("clipped() 적용")
                        .font(.headline)
                    Text(showClipped
                         ? "넘친 부분 자르기 (권장)"
                         : "넘친 부분도 표시")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Comparison Section
    
    private var comparisonSection: some View {
        VStack(spacing: 15) {
            Text("실시간 비교")
                .font(.headline)
            
            // 컨테이너 테두리
            ZStack {
                Rectangle()
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: containerWidth, height: containerHeight)
                
                // SF Symbol을 이미지처럼 사용
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(selectedAspectRatio.rawValue, contentMode: contentMode)
                    .foregroundStyle(.blue)
                    .frame(width: containerWidth, height: containerHeight)
                    .if(showClipped) { view in
                        view.clipped()
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 크기 정보
            VStack(spacing: 5) {
                Text("컨테이너: \(Int(containerWidth)) × \(Int(containerHeight))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("원본 비율: \(selectedAspectRatio.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                let calculatedSize = contentMode == .fit
                    ? ImageSizeCalculator.aspectFitSize(
                        from: CGSize(width: 400, height: 400 / selectedAspectRatio.rawValue),
                        to: CGSize(width: containerWidth, height: containerHeight)
                    )
                    : ImageSizeCalculator.aspectFillSize(
                        from: CGSize(width: 400, height: 400 / selectedAspectRatio.rawValue),
                        to: CGSize(width: containerWidth, height: containerHeight)
                    )
                
                Text("결과 크기: \(calculatedSize.formatted)")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Size Controls
    
    private var sizeControls: some View {
        VStack(spacing: 15) {
            Text("컨테이너 크기 조절")
                .font(.headline)
            
            VStack(spacing: 10) {
                HStack {
                    Text("너비")
                        .frame(width: 50, alignment: .leading)
                    Slider(value: $containerWidth, in: 200...350)
                    Text("\(Int(containerWidth))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.blue)
                }
                
                HStack {
                    Text("높이")
                        .frame(width: 50, alignment: .leading)
                    Slider(value: $containerHeight, in: 150...300)
                    Text("\(Int(containerHeight))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Aspect Ratio Presets
    
    private var aspectRatioPresets: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("비율 프리셋")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ImageSizeCalculator.CommonAspectRatio.allCases, id: \.self) { ratio in
                    ratioCard(ratio)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func ratioCard(_ ratio: ImageSizeCalculator.CommonAspectRatio) -> some View {
        VStack(spacing: 8) {
            Text(ratio.name)
                .font(.caption)
                .bold()
            
            Rectangle()
                .fill(ratio == selectedAspectRatio ? Color.blue : Color(.systemGray4))
                .aspectRatio(ratio.rawValue, contentMode: .fit)
                .frame(height: 40)
                .cornerRadius(4)
            
            Text(ratio.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ratio == selectedAspectRatio ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedAspectRatio = ratio
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📖 이해하기")
                .font(.title2)
                .bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label(".fit (Aspect Fit)", systemImage: "square.on.square")
                    .font(.headline)
                Text("""
                • 이미지 전체가 보임
                • 컨테이너보다 작게 표시될 수 있음
                • 여백이 생길 수 있음
                • 프로필 사진, 갤러리에 적합
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label(".fill (Aspect Fill)", systemImage: "square.fill.on.square.fill")
                    .font(.headline)
                Text("""
                • 컨테이너를 완전히 채움
                • 이미지 일부가 잘릴 수 있음
                • clipped() 필수!
                • 썸네일, 배경에 적합
                """)
                .font(.caption)
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
            
            // 프로필 이미지 (.fit)
            VStack(alignment: .leading, spacing: 10) {
                Text("프로필 이미지")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("John Doe")
                            .font(.headline)
                        Text("iOS Developer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // 썸네일 그리드 (.fill)
            VStack(alignment: .leading, spacing: 10) {
                Text("썸네일 그리드")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(0..<6) { _ in
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - View Extension

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        AspectRatioTestView()
    }
}

