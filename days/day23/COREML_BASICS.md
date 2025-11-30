# CoreML 및 Vision 프레임워크 기본 이해

## 1. CoreML이란?

**CoreML (Core Machine Learning)**은 Apple의 플랫폼(iOS, macOS, watchOS, tvOS)에서 머신러닝 모델을 쉽고 빠르고 효율적으로 실행할 수 있도록 돕는 프레임워크입니다.

### 주요 특징
1.  **On-device Inference (온디바이스 추론)**:
    *   데이터가 기기를 벗어나지 않아 **개인정보 보호(Privacy)**에 유리합니다.
    *   네트워크 연결 없이 동작하므로 **오프라인**에서도 사용 가능합니다.
    *   서버 비용이 들지 않고, 응답 속도(Latency)가 매우 빠릅니다.
2.  **하드웨어 가속**:
    *   CPU, GPU, 그리고 **Neural Engine (ANE)**을 자동으로 활용하여 성능을 최적화합니다.
3.  **다양한 모델 지원**:
    *   Vision (이미지 분석), Natural Language (자연어 처리), Speech (음성 인식), SoundAnalysis (소리 분석) 등 다양한 도메인의 모델을 통합 관리합니다.

## 2. Vision 프레임워크와의 관계

**Vision** 프레임워크는 컴퓨터 비전(이미지/영상 분석)을 위한 Apple의 고수준 프레임워크입니다. 얼굴 감지, 텍스트 인식(OCR), 바코드 인식 등의 기능을 제공합니다.

*   **CoreML과의 조합**: CoreML 모델을 Vision 프레임워크를 통해 실행하면, 이미지 전처리 과정을 Vision이 대신 처리해줍니다.
    *   이미지 리사이징 (Resizing)
    *   색상 공간 변환 (Color Space Conversion)
    *   회전 및 오리엔테이션 처리 (Orientation Handling)
*   **VNCoreMLModel**: CoreML 모델을 Vision에서 사용할 수 있는 형태로 래핑하는 클래스입니다.
*   **VNCoreMLRequest**: CoreML 모델을 사용하여 이미지 분석 요청을 처리하는 클래스입니다.

## 3. MobileNetV2 모델

이번 실습에서 사용할 **MobileNetV2**는 모바일 기기와 같이 리소스가 제한된 환경에서 효율적으로 동작하도록 설계된 경량화된 CNN(Convolutional Neural Network) 모델입니다.

*   **용도**: 이미지 분류 (Image Classification) - 1000개의 클래스(ImageNet 데이터셋)로 분류
*   **입력**: 224 x 224 크기의 RGB 이미지
*   **출력**: 각 클래스에 대한 확률 (Probability)

## 4. CoreML 모델 파일 (.mlmodel)

Xcode에 `.mlmodel` 파일을 추가하면, Xcode는 자동으로 Swift 클래스(인터페이스)를 생성해줍니다. 이를 통해 코드에서 모델의 입력(Input)과 출력(Output)에 타입 안전(Type-safe)하게 접근할 수 있습니다.

