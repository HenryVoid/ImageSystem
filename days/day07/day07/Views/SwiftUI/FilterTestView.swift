//
//  FilterTestView.swift
//  day07
//
//  Core Image 필터 테스트 뷰
//

import SwiftUI

/// 필터 테스트 뷰
struct FilterTestView: View {
    @State private var originalImage: UIImage?
    @State private var filteredImage: UIImage?
    @State private var selectedFilters: [FilterType] = []
    @State private var isProcessing = false
    @State private var processingTime: TimeInterval = 0
    
    let maxFilters = 3
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 이미지 프리뷰
                    imagePreviewSection
                    
                    // 필터 선택
                    filterSelectionSection
                    
                    // 프리셋
                    presetSection
                    
                    // 성능 정보
                    performanceSection
                    
                    // 액션 버튼
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("필터 테스트")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadOriginalImage()
            }
        }
    }
    
    // MARK: - 뷰 컴포넌트
    
    private var imagePreviewSection: some View {
        HStack(spacing: 10) {
            // 원본
            VStack {
                if let image = originalImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Text("원본")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 필터 적용
            VStack {
                if isProcessing {
                    ProgressView()
                        .frame(height: 200)
                } else if let image = filteredImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Color.gray.opacity(0.2)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            Text("필터를 선택하세요")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                }
                Text("필터 적용")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var filterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("필터 선택 (최대 \(maxFilters)개)")
                .font(.headline)
            
            // 선택된 필터 표시
            if !selectedFilters.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(selectedFilters.enumerated()), id: \.offset) { index, filter in
                        HStack(spacing: 4) {
                            Text("\(index + 1).")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(filter.rawValue)
                                .font(.caption)
                            Button {
                                selectedFilters.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
            }
            
            // 필터 목록
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FilterType.allCases.filter { $0 != .none }) { filter in
                    Button {
                        addFilter(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedFilters.contains(filter) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundStyle(selectedFilters.contains(filter) ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(selectedFilters.count >= maxFilters && !selectedFilters.contains(filter))
                }
            }
        }
    }
    
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("프리셋")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FilterPreset.presets) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            VStack(spacing: 4) {
                                Text(preset.name)
                                    .font(.subheadline)
                                    .bold()
                                Text(preset.filters.map { $0.rawValue }.joined(separator: " + "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(width: 140)
                            .background(.purple.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("성능")
                .font(.headline)
            
            HStack {
                Label("처리 시간", systemImage: "clock")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.2f ms", processingTime * 1000))
                    .font(.subheadline)
                    .bold()
            }
            .padding()
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                applyFilters()
            } label: {
                Label("적용", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedFilters.isEmpty || isProcessing)
            
            Button {
                resetFilters()
            } label: {
                Label("초기화", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedFilters.isEmpty && filteredImage == nil)
        }
    }
    
    // MARK: - 액션
    
    private func loadOriginalImage() {
        originalImage = ImageLoader.shared.loadUIImage(named: "sample")
    }
    
    private func addFilter(_ filter: FilterType) {
        if selectedFilters.count < maxFilters && !selectedFilters.contains(filter) {
            selectedFilters.append(filter)
        }
    }
    
    private func applyFilters() {
        guard !selectedFilters.isEmpty, let original = originalImage else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let signpost = Signpost.filtering(label: "FilterChain")
            signpost.begin()
            
            let start = CFAbsoluteTimeGetCurrent()
            let filtered = FilterEngine.shared.applyFilterChain(selectedFilters, to: original)
            let end = CFAbsoluteTimeGetCurrent()
            
            signpost.end()
            
            DispatchQueue.main.async {
                self.filteredImage = filtered
                self.processingTime = end - start
                self.isProcessing = false
                
                let filterNames = selectedFilters.map { $0.rawValue }.joined(separator: " → ")
                PerformanceLogger.log("필터 체인 적용 완료: \(filterNames) (\(String(format: "%.2fms", processingTime * 1000)))", category: "filtering")
            }
        }
    }
    
    private func applyPreset(_ preset: FilterPreset) {
        selectedFilters = preset.filters
        applyFilters()
    }
    
    private func resetFilters() {
        selectedFilters.removeAll()
        filteredImage = nil
        processingTime = 0
    }
}

#Preview {
    FilterTestView()
}

