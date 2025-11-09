//
//  ContentView.swift
//  day13
//
//  Created by 송형욱 on 11/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var imageLoader = ImageLoader()
    
    var body: some View {
        TabView {
            // 1. 인터랙티브 블러
            NavigationView {
                InteractiveBlurView()
                    .environmentObject(imageLoader)
            }
            .tabItem {
                Label("인터랙티브", systemImage: "slider.horizontal.3")
            }
            
            // 2. 벤치마크
            NavigationView {
                BenchmarkView()
                    .environmentObject(imageLoader)
            }
            .tabItem {
                Label("벤치마크", systemImage: "speedometer")
            }
            
            // 3. 결과 비교
            NavigationView {
                ComparisonView()
                    .environmentObject(imageLoader)
            }
            .tabItem {
                Label("비교", systemImage: "square.split.2x1")
            }
            
            // 4. 이미지 선택
            NavigationView {
                ImageSelectorView()
                    .environmentObject(imageLoader)
            }
            .tabItem {
                Label("이미지", systemImage: "photo")
            }
        }
    }
}

#Preview {
    ContentView()
}
