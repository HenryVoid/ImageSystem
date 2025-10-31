//
//  ContentView.swift
//  day08
//
//  URLSession 비동기 이미지 로딩 메인 뷰

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1: 기본 로딩 (캐시 없음)
            SimpleLoadingView()
                .tabItem {
                    Label("기본 로딩", systemImage: "network")
                }
            
            // Tab 2: 캐시 적용
            CachedLoadingView()
                .tabItem {
                    Label("캐시 적용", systemImage: "bolt.fill")
                }
            
            // Tab 3: 성능 비교
            ComparisonView()
                .tabItem {
                    Label("비교 테스트", systemImage: "chart.bar.fill")
                }
            
            // Tab 4: 벤치마크
            BenchmarkView()
                .tabItem {
                    Label("벤치마크", systemImage: "speedometer")
                }
        }
        .onAppear {
            // 네트워크 모니터링 시작
            if #available(iOS 12.0, *) {
                NetworkMonitor.shared.start()
            }
        }
    }
}

#Preview {
    ContentView()
}
