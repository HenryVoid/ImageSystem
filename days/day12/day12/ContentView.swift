//
//  ContentView.swift
//  day12
//
//  LazyVStack + AsyncImage 성능 측정 메인 뷰
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 기본 리스트
            NavigationStack {
                BasicListView()
                    .navigationTitle("기본 리스트")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("기본", systemImage: "list.bullet")
            }
            .tag(0)
            
            // Tab 2: 캐싱 비교
            NavigationStack {
                CachedListView()
                    .navigationTitle("캐싱 리스트")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("캐싱", systemImage: "arrow.triangle.2.circlepath")
            }
            .tag(1)
            
            // Tab 3: 프리패칭 실험
            NavigationStack {
                PrefetchListView()
                    .navigationTitle("프리패칭")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("프리패칭", systemImage: "arrow.down.circle")
            }
            .tag(2)
            
            // Tab 4: 성능 비교
            NavigationStack {
                ComparisonView()
                    .navigationTitle("성능 비교")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("비교", systemImage: "chart.bar")
            }
            .tag(3)
            
            // Tab 5: 설정
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("설정", systemImage: "gear")
            }
            .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
