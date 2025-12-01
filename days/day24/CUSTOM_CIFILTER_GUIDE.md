# Core Image 커스텀 필터 (Custom CIFilter) 가이드

Core Image는 강력한 이미지 처리 프레임워크이지만, 내장 필터만으로는 원하는 모든 효과를 구현하기 어려울 때가 있습니다. 이때 `CIKernel`을 사용하여 커스텀 필터를 제작할 수 있습니다.

## 1. CIFilter의 기본 구조

모든 `CIFilter`는 기본적으로 **입력 이미지(`CIImage`)**와 **매개변수**를 받아 처리된 **출력 이미지(`CIImage`)**를 반환하는 구조를 가집니다.

- **Input**: `inputImage` (CIImage), `inputIntensity` (NSNumber) 등
- **Processing**: 커널(Kernel)을 통해 픽셀 연산 수행
- **Output**: `outputImage` (CIImage)

## 2. CIKernel의 종류

Core Image는 Metal Shading Language (MSL) 기반의 커널을 사용합니다.

### A. CIColorKernel (가장 흔함, 빠름)
- **용도**: 픽셀의 색상(RGBA)만 변경할 때 사용합니다.
- **특징**: 입력 픽셀 1개 -> 출력 픽셀 1개 (1:1 매핑). 좌표 변환 불가.
- **예시**: 흑백 변환, 틴트, 밝기 조절, 감정 필터.
- **성능**: 매우 빠름.

### B. CIWarpKernel (기하학적 변형)
- **용도**: 픽셀의 **위치**를 변경할 때 사용합니다.
- **특징**: 출력 픽셀 좌표 -> 입력 픽셀 좌표 매핑 (Reverse Mapping).
- **예시**: 왜곡, 회전, 어안 렌즈 효과.

### C. CIKernel (일반 커널)
- **용도**: 색상과 위치를 모두 제어하거나, 주변 픽셀(Convolution)을 참조해야 할 때.
- **특징**: 가장 유연하지만 `CIColorKernel`보다 느릴 수 있음.
- **예시**: 블러(Blur), 엣지 검출(Edge Detection).

## 3. Metal Kernel 구현 방식

Swift에서 커스텀 커널을 사용하는 방식은 크게 두 가지가 있습니다.

1.  **Build-time Compilation (`.ci.metal` 파일 사용)**
    - Build Settings에서 Linker Flags 설정 필요 (`-fcikernel`).
    - 앱 바이너리에 컴파일된 형태로 포함됨 (로딩 속도 빠름).
    - 설정이 다소 복잡할 수 있음.

2.  **Runtime Compilation (String 기반)**
    - Metal 코드를 String으로 작성하여 런타임에 `CIKernel(source:)`로 컴파일.
    - 설정이 간편하고 즉시 수정 가능하여 학습용/프로토타입용으로 적합.
    - 앱 시작 시 컴파일 오버헤드가 있을 수 있음 (캐싱으로 해결 가능).

> **이번 24일차 학습에서는 설정의 복잡도를 낮추기 위해 2번(String 기반) 방식을 사용합니다.**

## 4. 최적화 포인트

1.  **CIContext 재사용**:
    - `CIContext` 생성 비용은 매우 비쌉니다. 앱 전체에서 하나만 만들어(`Singleton` 등) 재사용해야 합니다.
    - Metal 디바이스를 공유하는 `CIContext(mtlDevice: ...)`를 사용하는 것이 성능상 이점(Zero-copy 등)이 큽니다.

2.  **ROI (Region of Interest) 처리**:
    - `CIKernel`을 일반 커널로 사용할 때, 필요한 영역만 연산하도록 ROI 델리게이트 메서드를 구현하면 성능이 향상됩니다. (ColorKernel은 자동 처리됨)

3.  **체인 연결 최적화**:
    - `CIImage` 파이프라인(필터 연결)은 실제 렌더링 시점에 하나의 커널로 합쳐져서 실행될 수 있습니다(Concatenation). 불필요한 중간 렌더링을 피하세요.

## 5. 구현 예시 (Pink Tint)

```metal
// Metal (String)
#include <CoreImage/CoreImage.h>
extern "C" {
    namespace coreimage {
        float4 pinkTint(sample_t s) {
            float4 pink = float4(1.0, 0.5, 0.7, 1.0);
            return s * pink; // 단순 곱셈으로 틴트 효과
        }
    }
}
```

```swift
// Swift
class PinkTintFilter: CIFilter {
    var inputImage: CIImage?
    
    static var kernel: CIColorKernel = {
        return CIColorKernel(source: "...")!
    }()
    
    override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }
        return PinkTintFilter.kernel.apply(extent: input.extent, arguments: [input])
    }
}
```

