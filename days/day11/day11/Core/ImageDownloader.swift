import UIKit

class ImageDownloader: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadedImage: UIImage?
    @Published var errorMessage: String?
    
    // MARK: - Download Methods
    
    func downloadImage(resolution: ImageResolution, seed: Int = Int.random(in: 1...1000)) async {
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            errorMessage = nil
        }
        
        let size = resolution.size
        let urlString = "https://picsum.photos/seed/\(seed)/\(Int(size.width))/\(Int(size.height))"
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                errorMessage = "잘못된 URL"
                isDownloading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    errorMessage = "다운로드 실패"
                    isDownloading = false
                }
                return
            }
            
            guard let image = UIImage(data: data) else {
                await MainActor.run {
                    errorMessage = "이미지 변환 실패"
                    isDownloading = false
                }
                return
            }
            
            await MainActor.run {
                downloadProgress = 1.0
                downloadedImage = image
                isDownloading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "네트워크 오류: \(error.localizedDescription)"
                isDownloading = false
            }
        }
    }
    
    // MARK: - Sample Image
    
    func loadSampleImage() -> UIImage? {
        // 기본 샘플 이미지 생성
        return generateSampleImage(size: CGSize(width: 800, height: 600))
    }
    
    private func generateSampleImage(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 그라데이션 배경
            let colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor,
                UIColor.systemPink.cgColor
            ]
            
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 0.5, 1.0]
            ) else { return }
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // 텍스트 추가
            let text = "Sample Image"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - Clear
    
    func clear() {
        downloadedImage = nil
        errorMessage = nil
        downloadProgress = 0.0
    }
}


