//
//  ContentView.swift
//  day19
//
//  메인 뷰 - 탭 기반 네비게이션
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                UIImageViewGIFView()
            }
            .tabItem {
                Label("UIImageView", systemImage: "photo")
            }
            
            NavigationView {
                SwiftUIGIFView()
            }
            .tabItem {
                Label("SwiftUI", systemImage: "swift")
            }
            
            NavigationView {
                NukeGIFView()
            }
            .tabItem {
                Label("Nuke", systemImage: "bolt")
            }
            
            NavigationView {
                GIFComparisonView()
            }
            .tabItem {
                Label("비교", systemImage: "chart.bar")
            }
        }
    }
}

#Preview {
    ContentView()
}

