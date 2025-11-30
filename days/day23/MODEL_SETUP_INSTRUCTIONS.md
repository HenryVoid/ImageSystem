# MobileNetV2 모델 준비 안내

이 프로젝트를 실행하기 위해서는 사전 학습된 CoreML 모델 파일이 필요합니다. Apple은 개발자들이 쉽게 테스트할 수 있도록 여러 오픈 소스 모델을 변환하여 제공하고 있습니다.

## 1. 모델 다운로드

1.  **Apple Developer - Machine Learning Models** 페이지로 이동합니다.
    *   URL: [https://developer.apple.com/machine-learning/models/](https://developer.apple.com/machine-learning/models/)
2.  **MobileNetV2** 섹션을 찾습니다 (보통 Image Classification 카테고리에 있습니다).
3.  `MobileNetV2` (Float 16 또는 Int8 Quantized 버전)을 다운로드합니다.
    *   파일 이름 예시: `MobileNetV2.mlmodel`
    *   용량이 작은 `MobileNetV2Int8LUT.mlmodel` 등을 사용해도 무방합니다.

## 2. Xcode 프로젝트에 추가

1.  다운로드한 `.mlmodel` 파일을 Finder에서 찾습니다.
2.  Xcode 프로젝트 내비게이터의 `day23` 그룹(폴더)으로 파일을 **드래그 앤 드롭**합니다.
3.  추가 시 옵션 창이 뜨면 다음을 확인합니다:
    *   **Copy items if needed**: 체크 ✅
    *   **Add to targets**: `day23` (앱 타겟) 체크 ✅
4.  `Finish`를 클릭합니다.

## 3. 모델 확인

1.  Xcode에서 추가된 `.mlmodel` 파일을 클릭합니다.
2.  중앙 에디터 영역에 모델 정보가 표시됩니다.
    *   **Name**: MobileNetV2 (또는 파일명)
    *   **Type**: Image Classifier
    *   **Input**: `image` (Color 224 x 224) - *모델마다 이름이 다를 수 있습니다 (예: `image_1`)*
    *   **Output**: `classLabel` (String), `classLabelProbs` (Dictionary)
3.  **Model Class** 섹션에서 `Swift generated source`를 확인할 수 있습니다. (자동 생성됨)

> **참고**: 만약 다운로드 받은 모델의 클래스 이름이 `MobileNetV2`가 아니라면, 코드에서 해당 클래스 이름을 사용해야 합니다. 이 예제 코드는 `MobileNetV2`를 기준으로 작성되었습니다.

