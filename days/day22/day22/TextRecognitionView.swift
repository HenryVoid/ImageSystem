import SwiftUI
import Vision
import PhotosUI

struct TextRecognitionView: View {
    @StateObject private var visionManager = VisionManager()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
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
                                        for observation in recognizedTexts {
                                            let rect = VisionManager.convertBoundingBox(observation.boundingBox, to: size)
                                            context.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(.blue), lineWidth: 1)
                                        }
                                    }
                                }
                            }
                    }
                    .frame(maxHeight: 300)
                    .padding()
                    
                    // Text List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recognized Text:")
                            .font(.headline)
                        
                        ForEach(recognizedTexts, id: \.self) { observation in
                            if let candidate = observation.topCandidates(1).first {
                                HStack {
                                    Text(candidate.string)
                                        .font(.body)
                                    Spacer()
                                    Text(String(format: "%.2f", candidate.confidence))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    
                } else {
                    ContentUnavailableView("No Image Selected", systemImage: "text.viewfinder")
                        .frame(height: 300)
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Select Photo for OCR", systemImage: "doc.text.viewfinder")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                if isProcessing {
                    ProgressView("Recognizing text...")
                }
            }
            .padding()
        }
        .navigationTitle("Text Recognition")
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.selectedImage = uiImage
                        self.recognizedTexts = []
                    }
                    performOCR(in: uiImage)
                }
            }
        }
    }
    
    private func performOCR(in image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let results = try await visionManager.recognizeText(in: image)
                await MainActor.run {
                    self.recognizedTexts = results
                    self.isProcessing = false
                }
            } catch {
                print("OCR Error: \(error)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TextRecognitionView()
    }
}

