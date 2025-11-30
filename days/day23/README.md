# Day 23: CoreML 이미지 분류 (Image Classification)

## 📝 학습 목표
- CoreML 프레임워크와 Vision 프레임워크의 역할 이해
- 사전 학습된(Pre-trained) MobileNetV2 모델을 iOS 앱에 통합
- Vision을 사용하여 이미지 분류 기능 구현
- SwiftUI에서 PhotosPicker를 사용하여 이미지 선택 및 결과 표시

## 📱 구현 내용

### 1. CoreML + Vision 통합
- **ImageClassifier.swift**: `VNCoreMLModel`과 `VNCoreMLRequest`를 사용하여 이미지 분류 로직을 구현했습니다.
- Vision 프레임워크가 이미지 리사이징과 오리엔테이션 처리를 담당하여, CoreML 모델 입력에 맞는 형태로 자동 변환해줍니다.

### 2. 이미지 전처리 (유틸리티)
- **ImagePredictor.swift**: `UIImage`를 `CVPixelBuffer`로 직접 변환하거나 리사이즈하는 저수준 코드를 포함했습니다. (학습 목적)

### 3. UI (SwiftUI)
- `PhotosPicker`를 통해 갤러리에서 사진을 선택합니다.
- 선택된 사진을 화면에 표시하고, 즉시 분류 작업을 수행합니다.
- 분류 결과(Label)와 신뢰도(Confidence)를 리스트로 보여줍니다.

## 🛠️ 모델 설정 (필수)
이 프로젝트는 **MobileNetV2.mlmodel** 파일이 필요합니다.
자세한 설정 방법은 [MODEL_SETUP_INSTRUCTIONS.md](MODEL_SETUP_INSTRUCTIONS.md)를 참고하세요.

## 📚 개념 정리
CoreML과 Vision에 대한 자세한 이론적 배경은 [COREML_BASICS.md](COREML_BASICS.md)에 정리되어 있습니다.

## 📸 실행 예시
1. 앱 실행 후 '사진 선택하기' 버튼 터치
2. 갤러리에서 사물(예: 컵, 키보드, 강아지 등) 사진 선택
3. 화면 하단에 예측된 사물 이름과 확률 표시

```
분류 결과
----------------
Coffee Mug   98.5%
Cup          1.2%
Espresso     0.3%
```

## 💡 배운 점
- **On-device ML**: 네트워크 연결 없이 기기 내부에서 빠르게 추론이 가능함을 확인했습니다.
- **Vision Framework**: CoreML 모델의 까다로운 입력 조건(크기, 포맷)을 Vision이 쉽게 처리해준다는 점이 편리했습니다.
- **Model Integration**: `.mlmodel` 파일을 추가하는 것만으로 Swift 클래스가 자동 생성되어 사용하기 매우 쉽습니다.

