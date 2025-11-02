//
//  ContentView.swift
//  day09
//
//  SDWebImage, Kingfisher, Nuke 비교 메인 뷰
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SDWebImageView()
                .tabItem {
                    Label("SDWebImage", systemImage: "photo.circle")
                }
            
            KingfisherView()
                .tabItem {
                    Label("Kingfisher", systemImage: "photo.circle.fill")
                }
            
            NukeView()
                .tabItem {
                    Label("Nuke", systemImage: "photo.artframe")
                }
            
            ComparisonView()
                .tabItem {
                    Label("비교", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    ContentView()
}
