//
//  BasicListView.swift
//  day12
//
//  기본 LazyVStack + AsyncImage 리스트
//

import SwiftUI

struct BasicListView: View {
    @State private var imageCount = 100
    @State private var imageSize: ImageSize = .medium
    @State private var loadedCount = 0
    
    @StateObject private var performanceMonitor = PerformanceMonitor()
    
    let countOptions = [10, 100, 500, 1000]
    
    var body: some View {
        VStack(spacing: 0) {
            // 성능 정보 헤더
            performanceHeader
            
            // 컨트롤
            controls
            
            // 이미지 리스트
            imageList
        }
        .onAppear {
            performanceMonitor.startMonitoring()
        }
        .onDisappear {
            performanceMonitor.stopMonitoring()
        }
    }
    
    // MARK: - Components
    
    private var performanceHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("FPS: \(String(format: "%.0f", performanceMonitor.metrics.fps))")
                    .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                Text("메모리: \(performanceMonitor.metrics.formattedMemory)")
                    .font(.system(.body, design: .monospaced))
            }
            
            HStack {
                Text("로드됨: \(loadedCount)/\(imageCount)")
                    .font(.system(.caption, design: .monospaced))
                
                Spacer()
                
                Text("요청: \(performanceMonitor.metrics.networkRequests)")
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
    
    private var controls: some View {
        VStack(spacing: 12) {
            // 이미지 개수 선택
            VStack(alignment: .leading, spacing: 4) {
                Text("이미지 개수")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(countOptions, id: \.self) { count in
                        Button(action: {
                            imageCount = count
                            loadedCount = 0
                            performanceMonitor.resetStats()
                        }) {
                            Text("\(count)개")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(imageCount == count ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(imageCount == count ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 이미지 크기 선택
            VStack(alignment: .leading, spacing: 4) {
                Text("이미지 크기")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(ImageSize.allCases, id: \.self) { size in
                        Button(action: {
                            imageSize = size
                            loadedCount = 0
                        }) {
                            Text(size.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(imageSize == size ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(imageSize == size ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Divider()
        }
        .padding(.horizontal)
    }
    
    private var imageList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<imageCount, id: \.self) { index in
                    imageRow(index: index)
                }
            }
            .padding()
        }
    }
    
    private func imageRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: ImageURLProvider.url(for: index, size: imageSize)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                    
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .onAppear {
                            loadedCount += 1
                        }
                    
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                    
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(10)
            
            Text("Image #\(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    BasicListView()
}


