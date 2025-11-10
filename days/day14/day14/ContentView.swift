//
//  ContentView.swift
//  day14
//
//  Day14 썸네일 갤러리 메인 뷰
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 그리드 갤러리
            GridGalleryView()
                .tabItem {
                    Label("그리드", systemImage: "square.grid.3x3")
                }
                .tag(0)
            
            // Tab 2: 리스트 갤러리
            ListGalleryView()
                .tabItem {
                    Label("리스트", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Tab 3: 라이브러리 비교
            LibraryComparisonView()
                .tabItem {
                    Label("비교", systemImage: "chart.bar.xaxis")
                }
                .tag(2)
            
            // Tab 4: 검색 & 필터
            SearchFilterView()
                .tabItem {
                    Label("검색", systemImage: "magnifyingglass")
                }
                .tag(3)
            
            // Tab 5: 성능 모니터
            PerformanceMonitorView()
                .tabItem {
                    Label("성능", systemImage: "gauge")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
