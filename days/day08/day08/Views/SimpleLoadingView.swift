//
//  SimpleLoadingView.swift
//  day08
//
//  캐시 없는 단순 이미지 로딩 데모

import SwiftUI

struct SimpleLoadingView: View {
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadTime: TimeInterval = 0
    @State private var errorMessage: String?
    
    // 샘플 이미지 URL
    private let sampleURL = URL(string: "https://picsum.photos/800/600?random=1")!
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 이미지 표시 영역
                imageSection
                
                // 정보 표시
                infoSection
                
                // 버튼
                buttonSection
                
                // 설명
                descriptionSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("기본 로딩 (캐시 없음)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 섹션들
    
    private var imageSection: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(12)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("이미지 없음")
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
    }
    
    private var infoSection: some View {
        VStack(spacing: 12) {
            // 로딩 시간
            HStack {
                Text("로딩 시간:")
                    .font(.headline)
                Spacer()
                Text(loadTime > 0 ? String(format: "%.0f ms", loadTime * 1000) : "-")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(loadTime > 0 ? .green : .secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 캐시 상태
            HStack {
                Text("캐시 사용:")
                    .font(.headline)
                Spacer()
                Text("❌ 없음")
                    .font(.body)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 에러 메시지
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button(action: loadImage) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(isLoading ? "로딩 중..." : "이미지 로드")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading)
            
            Button(action: clearImage) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("이미지 삭제")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(image == nil)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 동작 방식")
                .font(.headline)
            
            Text("• 매번 네트워크에서 새로 다운로드")
                .font(.caption)
            Text("• 캐시 사용 안 함")
                .font(.caption)
            Text("• 같은 이미지를 여러 번 요청해도 매번 다운로드")
                .font(.caption)
            Text("• 평균 로딩 시간: 500ms")
                .font(.caption)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 액션
    
    private func loadImage() {
        errorMessage = nil
        isLoading = true
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        SimpleImageLoader.shared.loadImage(from: sampleURL) { result in
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            loadTime = duration
            isLoading = false
            
            switch result {
            case .success(let loadedImage):
                image = loadedImage
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func clearImage() {
        image = nil
        loadTime = 0
        errorMessage = nil
    }
}

#Preview {
    SimpleLoadingView()
}

































