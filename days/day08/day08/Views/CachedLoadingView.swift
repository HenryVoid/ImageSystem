//
//  CachedLoadingView.swift
//  day08
//
//  NSCache 적용 이미지 로딩 데모

import SwiftUI

struct CachedLoadingView: View {
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadTime: TimeInterval = 0
    @State private var isCacheHit = false
    @State private var errorMessage: String?
    
    // 샘플 이미지 URL
    private let sampleURL = URL(string: "https://picsum.photos/800/600?random=2")!
    
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
            .navigationTitle("캐시 적용")
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
                    .overlay(
                        // 캐시 히트 배지
                        VStack {
                            HStack {
                                Spacer()
                                if isCacheHit {
                                    Text("✅ 캐시")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                } else {
                                    Text("📥 다운로드")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                    )
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
                    .foregroundColor(isCacheHit ? .green : .orange)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 캐시 상태
            HStack {
                Text("캐시 상태:")
                    .font(.headline)
                Spacer()
                if image != nil {
                    Text(isCacheHit ? "✅ 히트" : "❌ 미스")
                        .font(.body)
                        .foregroundColor(isCacheHit ? .green : .red)
                } else {
                    Text("-")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 캐시 통계
            HStack {
                Text("히트율:")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f%%", CachedImageLoader.shared.hitRate))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
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
            
            HStack(spacing: 12) {
                Button(action: clearImage) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("이미지 삭제")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(image == nil)
                
                Button(action: clearCache) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("캐시 초기화")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 동작 방식")
                .font(.headline)
            
            Text("• 첫 로드: 네트워크 다운로드 (~500ms)")
                .font(.caption)
            Text("• 재로드: 캐시에서 즉시 반환 (~5ms)")
                .font(.caption)
            Text("• NSCache로 메모리 관리")
                .font(.caption)
            Text("• 캐시 히트율 추적")
                .font(.caption)
            
            Text("\n🎯 실습: '이미지 로드'를 2번 눌러서 속도 차이를 체감하세요!")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 액션
    
    private func loadImage() {
        errorMessage = nil
        isLoading = true
        
        // 로딩 전 캐시 히트/미스 상태 저장
        let hitsBefore = CachedImageLoader.shared.cacheHits
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        CachedImageLoader.shared.loadImage(from: sampleURL) { result in
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            loadTime = duration
            isLoading = false
            
            // 캐시 히트 여부 확인
            let hitsAfter = CachedImageLoader.shared.cacheHits
            isCacheHit = hitsAfter > hitsBefore
            
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
        isCacheHit = false
        errorMessage = nil
    }
    
    private func clearCache() {
        CachedImageLoader.shared.clearCache()
        CachedImageLoader.shared.resetStats()
        clearImage()
    }
}

#Preview {
    CachedLoadingView()
}

































