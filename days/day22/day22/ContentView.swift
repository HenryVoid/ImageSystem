import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Basic Vision") {
                    NavigationLink(destination: FaceDetectionView()) {
                        Label("Face Detection", systemImage: "face.dashed")
                    }
                    
                    NavigationLink(destination: TextRecognitionView()) {
                        Label("Text Recognition (OCR)", systemImage: "text.viewfinder")
                    }
                }
                
                Section("Advanced") {
                    NavigationLink(destination: CombinedVisionView()) {
                        Label("Combined Pipeline", systemImage: "arrow.triangle.branch")
                    }
                }
                
                Section("Info") {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/vision")!) {
                        Label("Vision Framework Docs", systemImage: "book.closed")
                    }
                }
            }
            .navigationTitle("Day 22: Vision")
        }
    }
}

#Preview {
    ContentView()
}
