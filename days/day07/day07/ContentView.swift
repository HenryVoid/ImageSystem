//
//  ContentView.swift
//  day07
//
//  메인 탭 뷰 - SwiftUI/UIKit 비교 및 필터 테스트
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1: SwiftUI 뷰어
            GalleryGridView()
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }
            
            // Tab 2: UIKit 뷰어
            UIKitGalleryView()
                .tabItem {
                    Label("UIKit", systemImage: "apple.logo")
                }
            
            // Tab 3: 필터 테스트
            FilterTestView()
                .tabItem {
                    Label("필터", systemImage: "wand.and.stars")
                }
            
            // Tab 4: 성능 벤치마크
            BenchmarkView()
                .tabItem {
                    Label("벤치마크", systemImage: "speedometer")
                }
        }
    }
}

#Preview {
    ContentView()
}
