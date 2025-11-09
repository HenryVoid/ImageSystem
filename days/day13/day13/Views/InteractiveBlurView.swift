//
//  InteractiveBlurView.swift
//  day13
//
//  Created on 11/10/25.
//

import SwiftUI

struct InteractiveBlurView: View {
    @EnvironmentObject var imageLoader: ImageLoader
    @State private var blurMethod: BlurResult.BlurMethod = .metal
    @State private var blurRadius: Double = 10
    @State private var isProcessing = false
    @State private var result: BlurResult?
    
    private let metalProcessor = MetalBlurProcessor()
    private let coreImageProcessor = CoreImageBlurProcessor()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설정 섹션
                VStack(alignment: .leading, spacing: 15) {
                    Text("블러 설정")
                        .font(.headline)
                    
                    // 블러 방식 선택
                    Picker("블러 방식", selection: $blurMethod) {
                        ForEach(BlurResult.BlurMethod.allCases, id: \.self) { method in
                            Label(method.rawValue, systemImage: method.icon)
                                .tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // 블러 반경 슬라이더
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
                    
                    // 블러 실행 버튼
                    Button(action: applyBlur) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isProcessing ? "처리 중..." : "블러 적용")
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
                
                // 결과 표시
                if let result = result {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("결과")
                            .font(.headline)
                        
                        // 처리된 이미지
                        Image(uiImage: result.image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                        
                        // 메트릭
                        VStack(spacing: 10) {
                            MetricRow(title: "처리 방식", value: result.method.rawValue)
                            MetricRow(title: "블러 반경", value: "\(result.radius)")
                            MetricRow(title: "처리 시간", value: result.formattedTime)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                } else if imageLoader.currentImage != nil {
                    // 원본 이미지
                    VStack(alignment: .leading, spacing: 15) {
                        Text("원본 이미지")
                            .font(.headline)
                        
                        Image(uiImage: imageLoader.currentImage!)
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
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("이미지를 먼저 로드해주세요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("'이미지 선택' 탭에서 이미지를 생성하거나 다운로드하세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }
            }
            .padding()
        }
        .navigationTitle("인터랙티브 블러")
    }
    
    private func applyBlur() {
        guard let image = imageLoader.currentImage else { return }
        
        isProcessing = true
        result = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let blurResult: BlurResult?
            
            switch blurMethod {
            case .metal:
                blurResult = metalProcessor?.blur(image: image, radius: Int(blurRadius))
            case .coreImage:
                blurResult = coreImageProcessor.blur(image: image, radius: Int(blurRadius))
            }
            
            DispatchQueue.main.async {
                self.result = blurResult
                self.isProcessing = false
            }
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}

