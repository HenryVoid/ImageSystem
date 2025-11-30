import SwiftUI
import Vision
import CoreML

/// 이미지 분류 결과를 담는 구조체
struct ClassificationResult: Identifiable {
    let id = UUID()
    let identifier: String
    let confidence: Double
    
    var formattedConfidence: String {
        return String(format: "%.2f%%", confidence * 100)
    }
}

class ImageClassifier: ObservableObject {
    @Published var results: [ClassificationResult] = []
    @Published var errorMessage: String?
    
    // CoreML 모델 인스턴스 (Lazy loading)
    // 주의: 실제 프로젝트에 MobileNetV2.mlmodel을 추가해야 이 코드가 컴파일됩니다.
    // 모델 파일이 없다면 컴파일 에러가 발생하므로, 모델 추가 후 주석을 해제하거나 수정하세요.
    private lazy var classificationRequest: VNCoreMLRequest? = {
        do {
            // 1. MobileNetV2 모델 로드
            // Xcode에서 MobileNetV2.mlmodel을 추가하면 자동으로 'MobileNetV2' 클래스가 생성됩니다.
            // 만약 다른 모델을 사용한다면 해당 클래스 이름을 사용해야 합니다.
            let configuration = MLModelConfiguration()
            
            // TODO: [사용자 설정 필요] MobileNetV2 모델을 프로젝트에 추가한 후 아래 주석을 해제하고 사용하세요.
            // let model = try MobileNetV2(configuration: configuration).model
            
            // 임시 코드: 컴파일 에러 방지를 위해 더미 모델 사용 (실제 실행 시엔 교체 필요)
            // 실제로는 아래 코드를 지우고 위 코드를 사용해야 합니다.
            guard let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc") else {
                 print("Model file not found")
                 return nil
            }
            let model = try MLModel(contentsOf: modelURL)
            
            // 2. Vision 모델 생성
            let visionModel = try VNCoreMLModel(for: model)
            
            // 3. Request 생성
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                self?.handleClassification(request: request, error: error)
            }
            
            // 이미지 처리 옵션: 중앙 크롭 (MobileNetV2는 정사각형 입력을 선호함)
            request.imageCropAndScaleOption = .centerCrop
            return request
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "모델 로드 실패: \(error.localizedDescription)"
            }
            return nil
        }
    }()
    
    /// 이미지를 분류합니다.
    func classify(image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            self.errorMessage = "이미지 변환 실패"
            return
        }
        
        // 이미지의 방향 정보 확인
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            
            do {
                // 모델이 준비되지 않았거나(placeholder), 로드되지 않았다면 에러 처리
                guard let request = self.classificationRequest else {
                    DispatchQueue.main.async {
                        self.errorMessage = "모델이 준비되지 않았습니다. MobileNetV2.mlmodel을 추가했는지 확인하세요."
                    }
                    return
                }
                
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "분류 요청 실패: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleClassification(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = "분류 에러: \(error.localizedDescription)"
                return
            }
            
            guard let observations = request.results as? [VNClassificationObservation] else {
                self.errorMessage = "예측 결과를 가져올 수 없습니다."
                return
            }
            
            // 상위 3개 결과만 표시
            self.results = observations.prefix(3).map { observation in
                ClassificationResult(identifier: observation.identifier, confidence: Double(observation.confidence))
            }
        }
    }
}

// UIImage Orientation -> CGImagePropertyOrientation 변환 헬퍼
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

