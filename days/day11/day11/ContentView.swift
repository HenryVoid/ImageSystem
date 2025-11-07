import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            InteractiveCompressionView()
                .tabItem {
                    Label("인터랙티브", systemImage: "slider.horizontal.3")
                }
            
            BenchmarkView()
                .tabItem {
                    Label("벤치마크", systemImage: "chart.bar")
                }
            
            ComparisonResultView()
                .tabItem {
                    Label("비교", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            ImageSelectorView()
                .tabItem {
                    Label("이미지", systemImage: "photo")
                }
        }
    }
}

#Preview {
    ContentView()
}
