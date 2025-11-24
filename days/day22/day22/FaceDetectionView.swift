import SwiftUI
import Vision
import PhotosUI

struct FaceDetectionView: View {
    @StateObject private var visionManager = VisionManager()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var faces: [VNFaceObservation] = []
    @State private var imageSize: CGSize = .zero
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
                                        DispatchQueue.main.async {
                                            if self.imageSize != size {
                                                self.imageSize = size
                                            }
                                        }
                                        
                                        for face in faces {
                                            let rect = VisionManager.convertBoundingBox(face.boundingBox, to: size)
                                            let path = Path(roundedRect: rect, cornerRadius: 4)
                                            context.stroke(path, with: .color(.red), lineWidth: 2)
                                        }
                                    }
                                }
                            }
                    }
                    .frame(maxHeight: 400)
                    .padding()
                } else {
                    ContentUnavailableView("No Image Selected", systemImage: "face.dashed")
                        .frame(height: 300)
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Select Photo", systemImage: "photo")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                if isProcessing {
                    ProgressView("Detecting faces...")
                } else if !faces.isEmpty {
                    Text("Detected \(faces.count) faces")
                        .font(.headline)
                }
            }
            .padding()
        }
        .navigationTitle("Face Detection")
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.selectedImage = uiImage
                        self.faces = []
                    }
                    detectFaces(in: uiImage)
                }
            }
        }
    }
    
    private func detectFaces(in image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let detectedFaces = try await visionManager.detectFaces(in: image)
                await MainActor.run {
                    self.faces = detectedFaces
                    self.isProcessing = false
                }
            } catch {
                print("Error detecting faces: \(error)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FaceDetectionView()
    }
}

