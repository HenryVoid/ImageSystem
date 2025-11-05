//
//  ContentView.swift
//  day10
//
//  Created by 송형욱 on 11/5/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            KingfisherGalleryView()
                .tabItem {
                    Label("Kingfisher", systemImage: "photo.stack")
                }
            
            NukeGalleryView()
                .tabItem {
                    Label("Nuke", systemImage: "bolt.fill")
                }
            
            CacheMonitorView()
                .tabItem {
                    Label("모니터", systemImage: "chart.xyaxis.line")
                }
            
            CacheSettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
