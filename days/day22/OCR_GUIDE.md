# OCR (Optical Character Recognition) Guide

Vision의 `VNRecognizeTextRequest`를 사용하여 이미지에서 텍스트를 추출하는 방법입니다.

## 1. 텍스트 인식 요청 설정

OCR을 위해서는 `VNRecognizeTextRequest`를 사용하며, 인식 정확도와 속도 사이의 균형을 조절할 수 있는 옵션을 제공합니다.

```swift
func recognizeText(in image: UIImage) async throws -> [VNRecognizedTextObservation] {
    guard let cgImage = image.cgImage else { return [] }
    
    let request = VNRecognizeTextRequest()
    
    // 인식 수준 설정
    request.recognitionLevel = .accurate // .fast 또는 .accurate
    
    // 언어 보정 사용 여부
    request.usesLanguageCorrection = true
    
    // 인식할 언어 우선순위 (선택사항)
    // request.recognitionLanguages = ["en-US", "ko-KR"]
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])
    
    return request.results ?? []
}
```

## 2. Recognition Level

- **.accurate**: 딥러닝 기반의 신경망 모델을 사용하여 높은 정확도를 제공합니다. 복잡한 레이아웃이나 손글씨 인식에 유리하지만 처리 시간이 더 걸릴 수 있습니다.
- **.fast**: 빠른 속도를 위해 최적화된 레거시 알고리즘을 사용할 수 있습니다. 실시간 처리가 필요한 경우 적합합니다.

## 3. 결과 처리

결과는 `VNRecognizedTextObservation` 배열로 반환됩니다. 각 Observation은 인식된 텍스트 줄에 해당합니다.

### Top Candidates
Vision은 하나의 영역에 대해 여러 개의 인식 후보군을 제공할 수 있습니다. `topCandidates(_:)` 메서드로 가장 신뢰도가 높은 결과를 가져옵니다.

```swift
for observation in recognizedTexts {
    // 가장 신뢰도 높은 후보 1개 가져오기
    if let candidate = observation.topCandidates(1).first {
        let text = candidate.string
        let confidence = candidate.confidence
        print("Text: \(text) (Confidence: \(confidence))")
    }
}
```

## 4. 활용 팁

- **영역 표시**: `VNRecognizedTextObservation`도 `boundingBox`를 가지므로, 얼굴 인식과 마찬가지로 원본 이미지 위에 텍스트 영역을 표시할 수 있습니다.
- **자연어 처리(NLP) 연동**: 추출된 텍스트를 `NSLinguisticTagger`나 `NaturalLanguage` 프레임워크와 연동하여 의미 분석을 수행할 수 있습니다.
- **실시간 카메라 연동**: `AVCaptureVideoDataOutput`과 연동하여 카메라 프리뷰에서 실시간으로 텍스트를 인식할 수도 있습니다 (Vision + AVFoundation).

