//
//  BatchProcessingView.swift
//  day05
//
//  배치 이미지 처리 뷰
//

import SwiftUI

struct BatchProcessingView: View {
    @State private var isProcessing = false
    @State private var progress: Double = 0
    @State private var currentCount = 0
    @State private var totalCount = 0
    @State private var result: CompressionManager.BatchResult?
    @State private var selectedPreset: CompressionPreset = .standard
    @State private var selectedFormat: ImageFormat? = nil
    
    private let testImageCount = 50  // 테스트용 이미지 개수
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                headerSection
                
                // 설정
                settingsSection
                
                // 처리 버튼
                processButton
                
                // 진행률
                if isProcessing {
                    progressSection
                }
                
                // 결과
                if let result = result {
                    resultsSection(result)
                }
                
                // 설명
                descriptionSection
            }
            .padding()
        }
        .navigationTitle("배치 처리")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("대량 이미지 처리")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("여러 이미지를 동시에 리사이즈하고 압축하여 성능을 측정합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("설정")
                .font(.headline)
            
            // 프리셋 선택
            VStack(alignment: .leading, spacing: 8) {
                Text("압축 프리셋")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(CompressionPreset.allCases, id: \.rawValue) { preset in
                            PresetButton(
                                preset: preset,
                                isSelected: selectedPreset == preset
                            ) {
                                selectedPreset = preset
                            }
                        }
                    }
                }
            }
            
            // 포맷 선택
            VStack(alignment: .leading, spacing: 8) {
                Text("포맷")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    FormatToggle(title: "자동 (HEIC)", isSelected: selectedFormat == nil) {
                        selectedFormat = nil
                    }
                    
                    FormatToggle(title: "JPEG", isSelected: selectedFormat != nil) {
                        selectedFormat = .jpeg(quality: 0.8)
                    }
                }
            }
            
            // 테스트 정보
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("테스트: \(testImageCount)개의 샘플 이미지 복제")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var processButton: some View {
        Button(action: startProcessing) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "gearshape.2.fill")
                }
                Text(isProcessing ? "처리 중..." : "배치 처리 시작")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isProcessing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isProcessing)
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("처리 중...")
                    .font(.headline)
                Spacer()
                Text("\(currentCount)/\(totalCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func resultsSection(_ result: CompressionManager.BatchResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("결과")
                .font(.title3)
                .fontWeight(.bold)
            
            // 요약 카드
            summaryCard(result)
            
            // 상세 정보
            detailsCard(result)
            
            // 최적화 효과
            optimizationCard(result)
        }
    }
    
    private func summaryCard(_ result: CompressionManager.BatchResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                StatBox(
                    value: "\(result.successCount)",
                    label: "처리 완료",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatBox(
                    value: result.formattedDuration,
                    label: "총 시간",
                    icon: "clock.fill",
                    color: .blue
                )
            }
            
            HStack {
                StatBox(
                    value: result.formattedSaved,
                    label: "절약",
                    icon: "arrow.down.circle.fill",
                    color: .orange
                )
                
                StatBox(
                    value: String(format: "%.0f%%", result.savedPercentage),
                    label: "압축률",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }
    
    private func detailsCard(_ result: CompressionManager.BatchResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 정보")
                .font(.headline)
            
            DetailRow(label: "원본 크기", value: formatBytes(result.totalOriginalSize))
            DetailRow(label: "압축 후 크기", value: formatBytes(result.totalCompressedSize))
            DetailRow(label: "절약 용량", value: formatBytes(result.savedBytes))
            DetailRow(label: "압축 비율", value: String(format: "%.1f%%", result.compressionRatio * 100))
            
            Divider()
            
            DetailRow(label: "처리 이미지", value: "\(result.successCount)/\(result.originalCount)")
            DetailRow(label: "처리 시간", value: result.formattedDuration)
            DetailRow(
                label: "이미지당 평균",
                value: String(format: "%.0f ms", result.duration / Double(result.successCount) * 1000)
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func optimizationCard(_ result: CompressionManager.BatchResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최적화 효과")
                .font(.headline)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text("메모리 최적화")
                        .fontWeight(.semibold)
                    Text("autoreleasepool 사용으로 메모리 압박 방지")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text("병렬 처리")
                        .fontWeight(.semibold)
                    Text("멀티코어를 활용한 고속 처리")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("공간 절약")
                        .fontWeight(.semibold)
                    Text("\(result.formattedSaved) 절약 (약 \(Int(result.savedPercentage))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("배치 처리 최적화")
                .font(.headline)
            
            OptimizationTip(
                icon: "arrow.circlepath",
                title: "autoreleasepool",
                description: "각 이미지 처리 후 즉시 메모리 해제"
            )
            
            OptimizationTip(
                icon: "arrow.branch",
                title: "병렬 처리",
                description: "멀티코어를 활용하여 동시 처리"
            )
            
            OptimizationTip(
                icon: "photo.stack",
                title: "다운샘플링",
                description: "원본을 메모리에 로드하지 않음"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Actions
    
    private func startProcessing() {
        isProcessing = true
        progress = 0
        currentCount = 0
        totalCount = testImageCount
        result = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 샘플 이미지 로드
            guard let sampleImage = UIImage(named: "sample") else {
                DispatchQueue.main.async {
                    isProcessing = false
                }
                return
            }
            
            // 테스트를 위해 이미지 복제
            let images = Array(repeating: sampleImage, count: testImageCount)
            
            // 배치 처리
            let (_, batchResult) = CompressionManager.batchCompress(
                images: images,
                preset: selectedPreset,
                format: selectedFormat
            ) { current, total in
                DispatchQueue.main.async {
                    currentCount = current
                    totalCount = total
                    progress = Double(current) / Double(total)
                }
            }
            
            DispatchQueue.main.async {
                result = batchResult
                isProcessing = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Helper Views

struct PresetButton: View {
    let preset: CompressionPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                Text(preset.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

struct FormatToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct OptimizationTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        BatchProcessingView()
    }
}

