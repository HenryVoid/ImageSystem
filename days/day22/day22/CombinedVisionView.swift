import SwiftUI
import Vision
import PhotosUI

struct CombinedVisionView: View {
    @StateObject private var visionManager = VisionManager()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var faces: [VNFaceObservation] = []
    @State private var recognizedTexts: [VNRecognizedTextObservation] = []
    @State private var isProcessing = false
    
    var body: some View {
        ScrollView {
            VStack {
                if let selectedImage {
                    ZStack {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .overlay {
                                GeometryReader { geometry in
                                    Canvas { context, size in
                                        // Draw Faces
                                        for face in faces {
                                            let rect = VisionManager.convertBoundingBox(face.boundingBox, to: size)
                                            let path = Path(roundedRect: rect, cornerRadius: 4)
                                            context.stroke(path, with: .color(.red), lineWidth: 2)
                                        }
                                        
                                        // Draw Text
                                        for text in recognizedTexts {
                                            let rect = VisionManager.convertBoundingBox(text.boundingBox, to: size)
                                            let path = Path(roundedRect: rect, cornerRadius: 2)
                                            context.stroke(path, with: .color(.blue), lineWidth: 1)
                                        }
                                    }
                                }
                            }
                    }
                    .frame(maxHeight: 400)
                    .padding()
                    
                    if !faces.isEmpty || !recognizedTexts.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            if !faces.isEmpty {
                                Label("Faces Detected: \(faces.count)", systemImage: "face.dashed")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                            }
                            
                            if !recognizedTexts.isEmpty {
                                Label("Text Regions: \(recognizedTexts.count)", systemImage: "text.viewfinder")
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                
                                ForEach(recognizedTexts.prefix(5), id: \.self) { text in
                                    if let candidate = text.topCandidates(1).first {
                                        Text(candidate.string)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                if recognizedTexts.count > 5 {
                                    Text("+ \(recognizedTexts.count - 5) more...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                } else {
                    ContentUnavailableView("Select Image for Analysis", systemImage: "person.crop.rectangle.badge.plus")
                        .frame(height: 300)
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Analyze Image", systemImage: "sparkles.magnifyingglass")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                if isProcessing {
                    ProgressView("Analyzing...")
                }
            }
            .padding()
        }
        .navigationTitle("Vision Pipeline")
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.selectedImage = uiImage
                        self.faces = []
                        self.recognizedTexts = []
                    }
                    processImage(uiImage)
                }
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let results = try await visionManager.processImage(in: image)
                await MainActor.run {
                    self.faces = results.faces
                    self.recognizedTexts = results.text
                    self.isProcessing = false
                }
            } catch {
                print("Processing Error: \(error)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CombinedVisionView()
    }
}

