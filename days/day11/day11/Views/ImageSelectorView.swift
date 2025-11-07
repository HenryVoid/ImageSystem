import SwiftUI

struct ImageSelectorView: View {
    @StateObject private var downloader = ImageDownloader()
    @State private var selectedResolution: ImageResolution = .medium
    @State private var seedInput: String = "42"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("이미지 다운로드")) {
                    Picker("해상도", selection: $selectedResolution) {
                        ForEach(ImageResolution.allCases, id: \.self) { resolution in
                            Text(resolution.description).tag(resolution)
                        }
                    }
                    
                    HStack {
                        Text("시드 번호")
                        TextField("1-1000", text: $seedInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: downloadImage) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("이미지 다운로드")
                        }
                    }
                    .disabled(downloader.isDownloading)
                    
                    if downloader.isDownloading {
                        ProgressView(value: downloader.downloadProgress) {
                            Text("다운로드 중...")
                        }
                    }
                    
                    if let error = downloader.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("샘플 이미지")) {
                    Button(action: loadSample) {
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("기본 샘플 이미지 사용")
                        }
                    }
                }
                
                if let image = downloader.downloadedImage {
                    Section(header: Text("미리보기")) {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(8)
                            
                            if let cgImage = image.cgImage {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("크기: \(cgImage.width) × \(cgImage.height)")
                                    Text("메모리: \(formatBytes(image.pngData()?.count ?? 0))")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("설명")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 해상도를 선택하여 다양한 크기의 이미지를 테스트하세요")
                        Text("• 시드 번호를 변경하면 다른 이미지를 다운로드합니다")
                        Text("• 네트워크가 필요합니다 (Picsum Photos API)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("이미지 선택")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if downloader.downloadedImage != nil {
                        Button("초기화") {
                            downloader.clear()
                        }
                    }
                }
            }
        }
    }
    
    private func downloadImage() {
        guard let seed = Int(seedInput), seed >= 1, seed <= 1000 else {
            return
        }
        
        Task {
            await downloader.downloadImage(resolution: selectedResolution, seed: seed)
        }
    }
    
    private func loadSample() {
        if let sample = downloader.loadSampleImage() {
            downloader.downloadedImage = sample
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

#Preview {
    ImageSelectorView()
}


