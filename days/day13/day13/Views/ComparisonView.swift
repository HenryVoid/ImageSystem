//
//  ComparisonView.swift
//  day13
//
//  Created on 11/10/25.
//

import SwiftUI

struct ComparisonView: View {
    @EnvironmentObject var imageLoader: ImageLoader
    @State private var blurRadius: Double = 10
    @State private var isProcessing = false
    @State private var metalResult: BlurResult?
    @State private var coreImageResult: BlurResult?
    @State private var selectedView: ViewMode = .sideBySide
    
    private let metalProcessor = MetalBlurProcessor()
    private let coreImageProcessor = CoreImageBlurProcessor()
    
    enum ViewMode: String, CaseIterable {
        case sideBySide = "나란히"
        case stacked = "위아래"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설정 섹션
                VStack(alignment: .leading, spacing: 15) {
                    Text("비교 설정")
                        .font(.headline)
                    
                    // 블러 반경
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("블러 반경")
                            Spacer()
                            Text("\(Int(blurRadius))")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $blurRadius, in: 1...25, step: 1)
                    }
                    
                    // 뷰 모드
                    Picker("표시 방식", selection: $selectedView) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // 비교 실행 버튼
                    Button(action: compareBlur) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.left.arrow.right")
                            }
                            Text(isProcessing ? "처리 중..." : "비교 실행")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(imageLoader.currentImage == nil || isProcessing)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 결과 비교
                if let metalResult = metalResult, let coreImageResult = coreImageResult {
                    if selectedView == .sideBySide {
                        sideBySideView(metal: metalResult, coreImage: coreImageResult)
                    } else {
                        stackedView(metal: metalResult, coreImage: coreImageResult)
                    }
                    
                    // 통계 비교
                    statisticsView(metal: metalResult, coreImage: coreImageResult)
                } else if let original = imageLoader.currentImage {
                    // 원본 이미지
                    VStack(alignment: .leading, spacing: 15) {
                        Text("원본 이미지")
                            .font(.headline)
                        
                        Image(uiImage: original)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                
                // 안내 메시지
                if imageLoader.currentImage == nil {
                    VStack(spacing: 10) {
                        Image(systemName: "square.split.2x1")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("이미지를 먼저 로드해주세요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                }
            }
            .padding()
        }
        .navigationTitle("결과 비교")
    }
    
    private func sideBySideView(metal: BlurResult, coreImage: BlurResult) -> some View {
        VStack(spacing: 15) {
            Text("결과 비교")
                .font(.headline)
            
            HStack(spacing: 15) {
                // Metal
                VStack(spacing: 8) {
                    Text("Metal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Image(uiImage: metal.image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                
                // Core Image
                VStack(spacing: 8) {
                    Text("Core Image")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Image(uiImage: coreImage.image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 2)
                        )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func stackedView(metal: BlurResult, coreImage: BlurResult) -> some View {
        VStack(spacing: 15) {
            Text("결과 비교")
                .font(.headline)
            
            // Metal
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                    Text("Metal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(metal.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(uiImage: metal.image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            
            Divider()
            
            // Core Image
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                    Text("Core Image")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(coreImage.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(uiImage: coreImage.image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 2)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func statisticsView(metal: BlurResult, coreImage: BlurResult) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("상세 통계")
                .font(.headline)
            
            VStack(spacing: 12) {
                ComparisonRow(
                    title: "처리 시간",
                    metalValue: metal.formattedTime,
                    coreImageValue: coreImage.formattedTime,
                    winner: metal.processingTime < coreImage.processingTime ? "Metal" : "Core Image"
                )
                
                let speedup = metal.processingTime < coreImage.processingTime
                    ? coreImage.processingTime / metal.processingTime
                    : metal.processingTime / coreImage.processingTime
                
                ComparisonRow(
                    title: "속도 차이",
                    metalValue: metal.processingTime < coreImage.processingTime ? "🏆 \(String(format: "%.1f", speedup))배 빠름" : "",
                    coreImageValue: coreImage.processingTime < metal.processingTime ? "🏆 \(String(format: "%.1f", speedup))배 빠름" : "",
                    winner: nil
                )
                
                ComparisonRow(
                    title: "블러 반경",
                    metalValue: "\(metal.radius)",
                    coreImageValue: "\(coreImage.radius)",
                    winner: nil
                )
            }
            
            // 추천
            Text("💡 추천")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
            let recommendation: String
            if metal.processingTime < coreImage.processingTime {
                recommendation = "Metal이 \(String(format: "%.1f", speedup))배 빠릅니다. 실시간 처리나 대량 이미지 처리에 Metal을 사용하세요."
            } else {
                recommendation = "Core Image가 \(String(format: "%.1f", speedup))배 빠릅니다. 간단한 블러 처리에는 Core Image가 효율적입니다."
            }
            
            Text(recommendation)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func compareBlur() {
        guard let image = imageLoader.currentImage else { return }
        
        isProcessing = true
        metalResult = nil
        coreImageResult = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Metal 블러
            let metal = metalProcessor?.blur(image: image, radius: Int(blurRadius))
            
            // Core Image 블러
            let coreImage = coreImageProcessor.blur(image: image, radius: Int(blurRadius))
            
            DispatchQueue.main.async {
                metalResult = metal
                coreImageResult = coreImage
                isProcessing = false
            }
        }
    }
}

struct ComparisonRow: View {
    let title: String
    let metalValue: String
    let coreImageValue: String
    let winner: String?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                // Metal
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text(metalValue)
                        .font(.caption)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(winner == "Metal" ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(6)
                
                // Core Image
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text(coreImageValue)
                        .font(.caption)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(winner == "Core Image" ? Color.orange.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

