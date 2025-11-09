//
//  ComparisonView.swift
//  day08
//
//  캐시 vs 비캐시 성능 비교

import SwiftUI

struct ComparisonView: View {
    @State private var noCacheTime: TimeInterval = 0
    @State private var cachedTime: TimeInterval = 0
    @State private var isTestingNoCache = false
    @State private var isTestingCached = false
    @State private var testCount = 0
    
    // 테스트용 10개 이미지 URL
    private let testURLs = (1...10).map { 
        URL(string: "https://picsum.photos/400/300?random=\($0)")!
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더
                    headerSection
                    
                    // 비교 카드
                    HStack(spacing: 16) {
                        noCacheCard
                        cachedCard
                    }
                    .padding(.horizontal)
                    
                    // 결과 비교
                    if noCacheTime > 0 && cachedTime > 0 {
                        resultSection
                    }
                    
                    // 버튼
                    buttonSection
                    
                    // 설명
                    descriptionSection
                }
                .padding()
            }
            .navigationTitle("성능 비교")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 섹션들
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("10개 이미지 로딩 테스트")
                .font(.title2)
                .fontWeight(.bold)
            
            if testCount > 0 {
                Text("테스트 \(testCount)회차")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var noCacheCard: some View {
        VStack(spacing: 12) {
            // 아이콘
            Image(systemName: "network")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            // 제목
            Text("캐시 없음")
                .font(.headline)
            
            // 시간
            if isTestingNoCache {
                ProgressView()
            } else {
                Text(noCacheTime > 0 ? String(format: "%.0f ms", noCacheTime * 1000) : "-")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(noCacheTime > 0 ? .red : .secondary)
            }
            
            // 상태
            Text(statusText(isLoading: isTestingNoCache, time: noCacheTime))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var cachedCard: some View {
        VStack(spacing: 12) {
            // 아이콘
            Image(systemName: "bolt.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            // 제목
            Text("캐시 적용")
                .font(.headline)
            
            // 시간
            if isTestingCached {
                ProgressView()
            } else {
                Text(cachedTime > 0 ? String(format: "%.0f ms", cachedTime * 1000) : "-")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(cachedTime > 0 ? .green : .secondary)
            }
            
            // 상태
            Text(statusText(isLoading: isTestingCached, time: cachedTime))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var resultSection: some View {
        VStack(spacing: 16) {
            Text("📊 결과 분석")
                .font(.headline)
            
            // 속도 개선
            if cachedTime > 0 {
                let improvement = noCacheTime / cachedTime
                HStack {
                    Text("속도 개선:")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f배 빠름", improvement))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 시간 절약
            let timeSaved = noCacheTime - cachedTime
            HStack {
                Text("시간 절약:")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.0f ms", timeSaved * 1000))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // 효율
            let efficiency = (1 - cachedTime / noCacheTime) * 100
            HStack {
                Text("효율 개선:")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f%%", efficiency))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.purple)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button(action: runTest) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("테스트 시작")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isTestingNoCache || isTestingCached ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isTestingNoCache || isTestingCached)
            
            Button(action: resetTest) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("초기화")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📝 테스트 방법")
                .font(.headline)
            
            Text("1️⃣ '테스트 시작' 버튼 클릭")
                .font(.caption)
            Text("2️⃣ 좌측(캐시 없음) 먼저 테스트")
                .font(.caption)
            Text("3️⃣ 우측(캐시 적용) 테스트")
                .font(.caption)
            Text("4️⃣ 결과 비교")
                .font(.caption)
            
            Divider()
            
            Text("💡 2회차부터 캐시 효과 극대화!")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 헬퍼
    
    private func statusText(isLoading: Bool, time: TimeInterval) -> String {
        if isLoading {
            return "테스트 중..."
        } else if time > 0 {
            return "완료"
        } else {
            return "대기 중"
        }
    }
    
    // MARK: - 액션
    
    private func runTest() {
        testCount += 1
        
        // 1단계: 캐시 없는 버전 테스트
        testNoCache {
            // 2단계: 캐시 적용 버전 테스트
            testCached {}
        }
    }
    
    private func testNoCache(completion: @escaping () -> Void) {
        isTestingNoCache = true
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let group = DispatchGroup()
        
        for url in testURLs {
            group.enter()
            SimpleImageLoader.shared.loadImage(from: url) { _ in
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            noCacheTime = CFAbsoluteTimeGetCurrent() - startTime
            isTestingNoCache = false
            completion()
        }
    }
    
    private func testCached(completion: @escaping () -> Void) {
        isTestingCached = true
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let group = DispatchGroup()
        
        for url in testURLs {
            group.enter()
            CachedImageLoader.shared.loadImage(from: url) { _ in
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            cachedTime = CFAbsoluteTimeGetCurrent() - startTime
            isTestingCached = false
            completion()
        }
    }
    
    private func resetTest() {
        noCacheTime = 0
        cachedTime = 0
        testCount = 0
        CachedImageLoader.shared.clearCache()
        CachedImageLoader.shared.resetStats()
    }
}

#Preview {
    ComparisonView()
}












