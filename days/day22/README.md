# Day 22: Vision 얼굴 및 텍스트 인식

Vision 프레임워크를 활용하여 이미지 분석 기능을 구현하는 예제 프로젝트입니다.

## 주요 기능

1. **얼굴 인식 (Face Detection)**
   - `VNDetectFaceRectanglesRequest` 활용
   - 이미지 내 얼굴 위치 감지 및 Bounding Box 시각화
   - Vision 좌표계 -> SwiftUI 좌표계 변환 구현

2. **텍스트 인식 (OCR)**
   - `VNRecognizeTextRequest` 활용
   - 이미지 내 텍스트 감지 및 추출
   - 인식된 텍스트 영역 표시 및 신뢰도(Confidence) 출력

3. **통합 파이프라인 (Combined Pipeline)**
   - 하나의 이미지에 대해 얼굴 인식과 텍스트 인식을 동시에 수행
   - `VNImageRequestHandler`를 통한 다중 Request 처리

## 학습 가이드

- [Vision 기초 (VISION_BASICS.md)](VISION_BASICS.md)
- [얼굴 인식 구현 (FACE_DETECTION_GUIDE.md)](FACE_DETECTION_GUIDE.md)
- [OCR 구현 (OCR_GUIDE.md)](OCR_GUIDE.md)

## 요구 사항

- iOS 16.0+
- Xcode 15.0+

