# Vision Framework Basics

Vision 프레임워크는 Apple 플랫폼에서 컴퓨터 비전 알고리즘을 수행하기 위한 고성능 이미지 분석 라이브러리입니다.

## 1. 핵심 컴포넌트

Vision의 작업 흐름은 크게 세 가지 요소로 구성됩니다.

### 1.1. Request (요청)
이미지에서 무엇을 찾을지 정의하는 추상 클래스입니다.
- `VNImageBasedRequest`: 이미지 분석을 위한 기본 클래스
- `VNDetectFaceRectanglesRequest`: 얼굴 위치 감지
- `VNRecognizeTextRequest`: 텍스트 감지 및 인식 (OCR)
- `VNDetectBarcodesRequest`: 바코드/QR코드 감지
- `VNDetectHumanBodyPoseRequest`: 신체 포즈 감지

### 1.2. Request Handler (처리자)
이미지 데이터를 받아서 하나 이상의 Request를 실행하는 객체입니다.
- `VNImageRequestHandler`: 단일 이미지에 대한 분석 요청 처리
- `VNSequenceRequestHandler`: 비디오 프레임과 같은 이미지 시퀀스 처리

### 1.3. Observation (관찰 결과)
분석 결과는 `VNObservation`의 서브클래스로 반환됩니다.
- `VNFaceObservation`: 얼굴의 위치(Bounding Box) 및 랜드마크
- `VNRecognizedTextObservation`: 인식된 텍스트 문자열 및 신뢰도
- `VNRectangleObservation`: 감지된 사각형 영역

## 2. 기본 워크플로우

1. **Request 생성**: 분석하고자 하는 작업을 정의합니다.
2. **Handler 생성**: 입력 이미지(CGImage, CIImage, CVPixelBuffer 등)를 래핑합니다.
3. **Perform**: 핸들러가 요청을 실행합니다 (동기 또는 비동기).
4. **Result 처리**: Request의 `results` 프로퍼티를 확인하여 결과를 사용합니다.

```swift
// 1. Request
let request = VNDetectFaceRectanglesRequest()

// 2. Handler
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

// 3. Perform
try handler.perform([request])

// 4. Result
guard let results = request.results else { return }
```

## 3. 좌표계 시스템 (Coordinate System)

**중요**: Vision 프레임워크는 **Normalized Coordinates** (0.0 ~ 1.0)를 사용하며, 원점(0,0)이 **좌측 하단 (Bottom-Left)**에 위치합니다.
반면, UIKit/SwiftUI는 원점이 **좌측 상단 (Top-Left)**에 위치하므로 좌표 변환이 필요합니다.

### 변환 공식
- x: `visionX * width`
- y: `(1 - visionY) * height` (Y축 반전)
- w: `visionWidth * width`
- h: `visionHeight * height`

