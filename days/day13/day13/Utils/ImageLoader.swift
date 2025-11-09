//
//  ImageLoader.swift
//  day13
//
//  Created on 11/10/25.
//

import UIKit
import SwiftUI

/// 이미지 로딩 및 생성 유틸리티
final class ImageLoader: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var isLoading = false
    
    /// 샘플 이미지 생성 (단색 + 그라데이션 + 노이즈)
    func generateSampleImage(size: CGSize) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let image = self?.createColorfulImage(size: size)
            
            DispatchQueue.main.async {
                self?.currentImage = image
                self?.isLoading = false
            }
        }
    }
    
    /// 다양한 패턴이 있는 테스트 이미지 생성
    private func createColorfulImage(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // 그라데이션 배경
            let colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor,
                UIColor.systemPink.cgColor,
                UIColor.systemOrange.cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 0.33, 0.66, 1.0]
            )
            
            if let gradient = gradient {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
            
            // 원 패턴 추가 (블러 효과 확인용)
            let circleCount = 5
            for i in 0..<circleCount {
                let x = size.width * CGFloat(i) / CGFloat(circleCount - 1)
                let radius = size.width / 8
                
                UIColor.white.withAlphaComponent(0.3).setFill()
                context.cgContext.fillEllipse(in: CGRect(
                    x: x - radius,
                    y: size.height / 2 - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            }
            
            // 텍스트 추가 (선명도 비교용)
            let text = "Blur Test"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: size.width / 10),
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
    
    /// Picsum Photos에서 랜덤 이미지 다운로드
    func downloadImage(width: Int, height: Int, seed: Int = Int.random(in: 1...1000)) {
        isLoading = true
        
        let urlString = "https://picsum.photos/seed/\(seed)/\(width)/\(height)"
        guard let url = URL(string: urlString) else {
            print("❌ URL 생성 실패")
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ 다운로드 실패: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    print("❌ 이미지 데이터 변환 실패")
                    return
                }
                
                self?.currentImage = image
                print("✅ 이미지 다운로드 완료: \(width)×\(height)")
            }
        }.resume()
    }
    
    /// 포토 라이브러리에서 이미지 선택
    func loadImage(_ image: UIImage) {
        currentImage = image
    }
}

