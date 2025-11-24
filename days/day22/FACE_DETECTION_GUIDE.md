# Face Detection Guide

Vision을 사용한 얼굴 감지 구현 가이드입니다.

## 1. 얼굴 감지 요청 설정

`VNDetectFaceRectanglesRequest`를 사용하여 이미지 내의 사람 얼굴을 감지할 수 있습니다. 이 Request는 얼굴의 경계 상자(Bounding Box)만을 반환합니다.

> **참고**: 눈, 코, 입 등의 세부 위치(Landmarks)를 감지하려면 `VNDetectFaceLandmarksRequest`를 사용해야 합니다.

```swift
func detectFaces(in image: UIImage) async throws -> [VNFaceObservation] {
    guard let cgImage = image.cgImage else { return [] }
    
    let request = VNDetectFaceRectanglesRequest()
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])
    
    return request.results ?? []
}
```

## 2. 결과 시각화 (Bounding Box)

감지된 얼굴은 `VNFaceObservation` 객체로 반환되며, `boundingBox` 프로퍼티(0.0~1.0 정규화 좌표)를 포함합니다.
이를 SwiftUI의 `Canvas`나 `Path`로 그리기 위해서는 뷰의 크기에 맞게 변환해야 합니다.

### 좌표 변환 메서드

```swift
static func convertBoundingBox(_ box: CGRect, to targetSize: CGSize) -> CGRect {
    let x = box.minX * targetSize.width
    let height = box.height * targetSize.height
    let y = (1 - box.maxY) * targetSize.height // Vision은 Y축이 아래에서 시작하므로 반전 필요
    let width = box.width * targetSize.width
    
    return CGRect(x: x, y: y, width: width, height: height)
}
```

### SwiftUI Canvas 활용 예시

```swift
Canvas { context, size in
    for face in faces {
        let rect = VisionManager.convertBoundingBox(face.boundingBox, to: size)
        let path = Path(roundedRect: rect, cornerRadius: 4)
        context.stroke(path, with: .color(.red), lineWidth: 2)
    }
}
```

## 3. 성능 고려사항

- **비동기 처리**: Vision 요청은 CPU/GPU 연산을 많이 사용하므로 반드시 메인 스레드가 아닌 백그라운드 스레드에서 수행해야 합니다. (`async/await` 또는 `DispatchQueue.global()` 활용)
- **이미지 크기**: 너무 큰 이미지는 처리 속도를 늦출 수 있습니다. 적절한 크기로 리사이징(Downsampling)하여 처리하는 것이 효율적일 수 있습니다.
- **방향(Orientation)**: `UIImage`는 `imageOrientation` 속성을 가지지만, `CGImage`는 순수 픽셀 데이터입니다. Vision에 전달할 때 오리엔테이션 처리가 필요한 경우 `VNImageRequestHandler(cgImage: orientation: options:)` 생성자를 사용해야 합니다.

