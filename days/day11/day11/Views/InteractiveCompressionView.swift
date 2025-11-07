import SwiftUI

struct InteractiveCompressionView: View {
    @StateObject private var downloader = ImageDownloader()
    @State private var selectedFormat: ImageFormat = .jpeg
    @State private var quality: Double = 80
    @State private var compressionResult: CompressionResult?
    @State private var isCompressing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 이미지 로드 섹션
                    if downloader.downloadedImage == nil {
                        loadImageSection
                    }
                    
                    // 압축 설정 섹션
                    if downloader.downloadedImage != nil {
                        compressionSettingsSection
                        
                        // 압축 버튼
                        Button(action: compressImage) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("압축 실행")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isCompressing)
                        .padding(.horizontal)
                        
                        // 결과 표시
                        if let result = compressionResult {
                            resultSection(result: result)
                        }
                        
                        // 진행 중
                        if isCompressing {
                            ProgressView("압축 중...")
                                .padding()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("인터랙티브 압축")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if downloader.downloadedImage != nil {
                        Button("초기화") {
                            reset()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Load Image Section
    
    private var loadImageSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("이미지를 로드하세요")
                .font(.headline)
            
            Button(action: loadSampleImage) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("샘플 이미지 로드")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Compression Settings Section
    
    private var compressionSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 원본 이미지
            if let image = downloader.downloadedImage {
                VStack(alignment: .leading) {
                    Text("원본 이미지")
                        .font(.headline)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    
                    if let size = image.pngData()?.count {
                        Text("크기: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // 포맷 선택
            VStack(alignment: .leading) {
                Text("포맷 선택")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ImageFormat.allCases, id: \.self) { format in
                            formatButton(format: format)
                        }
                    }
                }
            }
            
            Divider()
            
            // 품질 슬라이더
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("품질")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(quality))%")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                }
                
                Slider(value: $quality, in: 10...100, step: 5)
                    .accentColor(.blue)
                
                HStack {
                    Text("낮음 (작은 크기)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("높음 (큰 크기)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Format Button
    
    private func formatButton(format: ImageFormat) -> some View {
        Button(action: {
            selectedFormat = format
        }) {
            VStack(spacing: 8) {
                Image(systemName: format.icon)
                    .font(.system(size: 24))
                Text(format.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .background(
                selectedFormat == format
                    ? Color(format.color).opacity(0.2)
                    : Color.gray.opacity(0.1)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedFormat == format
                            ? Color(format.color)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Result Section
    
    private func resultSection(result: CompressionResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("압축 결과")
                .font(.headline)
            
            // 압축된 이미지
            if let compressedImage = result.compressedImage {
                Image(uiImage: compressedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
            
            // 통계
            VStack(spacing: 12) {
                statRow(
                    icon: "doc.text",
                    label: "원본 크기",
                    value: result.formattedOriginalSize,
                    color: .gray
                )
                
                statRow(
                    icon: "doc.text.fill",
                    label: "압축 후 크기",
                    value: result.formattedCompressedSize,
                    color: .blue
                )
                
                statRow(
                    icon: "arrow.down.circle.fill",
                    label: "압축률",
                    value: result.formattedCompressionRatio,
                    color: .green
                )
                
                statRow(
                    icon: "clock.fill",
                    label: "압축 시간",
                    value: result.formattedCompressionTime,
                    color: .orange
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .font(.system(.body, design: .monospaced))
        }
    }
    
    // MARK: - Actions
    
    private func loadSampleImage() {
        if let sample = downloader.loadSampleImage() {
            downloader.downloadedImage = sample
        }
    }
    
    private func compressImage() {
        guard let image = downloader.downloadedImage else { return }
        
        isCompressing = true
        
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                return ImageCompressor.shared.compress(
                    image,
                    format: selectedFormat,
                    quality: quality / 100.0
                )
            }.value
            
            await MainActor.run {
                compressionResult = result
                isCompressing = false
            }
        }
    }
    
    private func reset() {
        downloader.clear()
        compressionResult = nil
        quality = 80
        selectedFormat = .jpeg
    }
}

#Preview {
    InteractiveCompressionView()
}


