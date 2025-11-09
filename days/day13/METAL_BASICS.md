# Metal 기본 개념

> Metal의 핵심 구조와 파이프라인을 이해하기 위한 종합 가이드

---

## 📋 목차

1. [Metal이란?](#metal이란)
2. [Metal 아키텍처](#metal-아키텍처)
3. [핵심 컴포넌트](#핵심-컴포넌트)
4. [Compute Pipeline](#compute-pipeline)
5. [Metal Shading Language](#metal-shading-language)
6. [실전 예제](#실전-예제)

---

## Metal이란?

### 정의

Metal은 Apple이 개발한 **저수준 GPU 프로그래밍 API**입니다.

### 특징

- ⚡ **저수준 접근**: CPU와 GPU 간 오버헤드 최소화
- 🚀 **고성능**: Direct3D 12, Vulkan과 유사한 수준
- 🎯 **Apple 전용**: iOS, macOS, tvOS, visionOS
- 🔧 **범용 GPU**: 그래픽스 + 컴퓨팅 모두 지원

### Metal vs 다른 API

| 특성 | Metal | OpenGL ES | Core Image |
|------|-------|-----------|------------|
| **추상화 수준** | 낮음 | 중간 | 높음 |
| **성능** | 최고 | 중간 | 좋음 |
| **제어** | 완전 제어 | 제한적 | 자동화 |
| **난이도** | 높음 | 중간 | 쉬움 |
| **유연성** | 최고 | 중간 | 제한적 |

---

## Metal 아키텍처

### 전체 구조

```
┌─────────────────────────────────────────┐
│          애플리케이션 코드 (Swift)         │
│         (CPU에서 실행)                     │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│           Metal Framework                │
│  ┌─────────────────────────────────┐    │
│  │     MTLDevice (GPU 추상화)       │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │   MTLCommandQueue (작업 큐)      │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  MTLCommandBuffer (명령 모음)    │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ MTLCommandEncoder (명령 인코딩)  │    │
│  └─────────────────────────────────┘    │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         GPU Hardware (Metal 드라이버)     │
│  ┌─────────────────────────────────┐    │
│  │    Shader Code (.metal 파일)     │    │
│  │         (GPU에서 실행)            │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### 실행 흐름

```
1. Device 생성
   └─ MTLCreateSystemDefaultDevice()

2. Library 로드
   └─ device.makeDefaultLibrary()

3. Function 가져오기
   └─ library.makeFunction(name: "myKernel")

4. Pipeline State 생성
   └─ device.makeComputePipelineState(function:)

5. Command Queue 생성
   └─ device.makeCommandQueue()

6. Command Buffer 생성
   └─ queue.makeCommandBuffer()

7. Encoder 생성
   └─ buffer.makeComputeCommandEncoder()

8. 리소스 바인딩
   ├─ setTexture(_, index:)
   ├─ setBuffer(_, index:)
   └─ setSamplerState(_, index:)

9. Dispatch
   └─ dispatchThreadgroups(_, threadsPerThreadgroup:)

10. Encoding 종료
    └─ endEncoding()

11. Commit
    └─ commit()

12. 완료 대기 (선택)
    └─ waitUntilCompleted()
```

---

## 핵심 컴포넌트

### 1. MTLDevice

GPU를 나타내는 객체입니다.

```swift
// Device 생성
guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("Metal을 지원하지 않는 디바이스")
}

print(device.name)  // "Apple M1" 등
```

**역할**:
- GPU 하드웨어 접근
- 리소스 생성 (Buffer, Texture, Pipeline State)
- Command Queue 생성

**특징**:
- 앱당 하나의 Device 사용 (싱글톤 패턴 권장)
- 스레드 안전

---

### 2. MTLCommandQueue

GPU 명령을 순서대로 실행하는 큐입니다.

```swift
let commandQueue = device.makeCommandQueue()
```

**역할**:
- Command Buffer 생성
- 실행 순서 관리
- 자동 스케줄링

**특징**:
- 여러 Command Buffer를 병렬 제출 가능
- FIFO 순서 보장
- 스레드 안전

---

### 3. MTLCommandBuffer

GPU에 제출할 명령의 묶음입니다.

```swift
let commandBuffer = commandQueue.makeCommandBuffer()
```

**역할**:
- Encoder를 통해 명령 기록
- GPU에 작업 제출
- 완료 콜백 등록

**특징**:
- 일회성 객체 (재사용 불가)
- 여러 Encoder 사용 가능
- 비동기 실행

```swift
commandBuffer?.addCompletedHandler { buffer in
    print("GPU 작업 완료!")
}
commandBuffer?.commit()
```

---

### 4. MTLCommandEncoder

Command Buffer에 명령을 인코딩합니다.

**종류**:

#### Compute Command Encoder
```swift
let encoder = commandBuffer.makeComputeCommandEncoder()
encoder?.setComputePipelineState(pipelineState)
encoder?.setTexture(texture, index: 0)
encoder?.dispatchThreadgroups(...)
encoder?.endEncoding()
```

#### Render Command Encoder (그래픽스용)
```swift
let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc)
// 그래픽스 명령 인코딩
encoder?.endEncoding()
```

#### Blit Command Encoder (복사/변환용)
```swift
let encoder = commandBuffer.makeBlitCommandEncoder()
encoder?.copy(from: srcTexture, to: dstTexture)
encoder?.endEncoding()
```

---

### 5. MTLTexture

GPU에서 사용하는 이미지 데이터입니다.

```swift
// Texture Descriptor 생성
let descriptor = MTLTextureDescriptor.texture2DDescriptor(
    pixelFormat: .rgba8Unorm,
    width: 1024,
    height: 768,
    mipmapped: false
)
descriptor.usage = [.shaderRead, .shaderWrite]

// Texture 생성
let texture = device.makeTexture(descriptor: descriptor)
```

**Pixel Format**:
- `.rgba8Unorm`: 8비트 RGBA (가장 일반적)
- `.r32Float`: 32비트 Float (단일 채널)
- `.bgra8Unorm`: 8비트 BGRA (화면 출력용)

**Usage**:
- `.shaderRead`: Shader에서 읽기
- `.shaderWrite`: Shader에서 쓰기
- `.renderTarget`: 렌더링 타겟

---

### 6. MTLBuffer

GPU에서 사용하는 메모리 버퍼입니다.

```swift
// 배열로부터 Buffer 생성
var data: [Float] = [1.0, 2.0, 3.0, 4.0]
let buffer = device.makeBuffer(
    bytes: &data,
    length: data.count * MemoryLayout<Float>.stride,
    options: .storageModeShared
)
```

**Storage Mode**:
- `.shared`: CPU와 GPU 공유 (느림, 편리)
- `.private`: GPU 전용 (빠름, CPU 접근 불가)
- `.managed`: 명시적 동기화 (macOS 전용)

---

### 7. MTLLibrary

컴파일된 Shader 함수의 모음입니다.

```swift
// 앱 번들의 기본 라이브러리
let library = device.makeDefaultLibrary()

// 특정 함수 가져오기
let function = library?.makeFunction(name: "myKernel")
```

---

### 8. MTLComputePipelineState

컴파일된 Compute Shader 파이프라인입니다.

```swift
let pipelineState = try device.makeComputePipelineState(function: function)
```

**특징**:
- 생성 비용이 높음 (초기화 시 한 번만)
- 재사용 가능
- 스레드 안전

---

## Compute Pipeline

### 개념

Compute Pipeline은 **범용 GPU 연산**을 위한 파이프라인입니다.

```
Input (Texture/Buffer)
        ↓
   Compute Kernel
        ↓
Output (Texture/Buffer)
```

### Thread 구조

```
Grid (전체 작업 공간)
├─ Threadgroup 0
│  ├─ Thread 0
│  ├─ Thread 1
│  └─ ...
├─ Threadgroup 1
│  ├─ Thread 0
│  └─ ...
└─ ...
```

**예시**: 1024×768 이미지 처리

```swift
// Threadgroup 크기 (한 그룹당 스레드 수)
let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)

// Threadgroup 개수
let threadgroups = MTLSize(
    width: (1024 + 15) / 16,  // = 64
    height: (768 + 15) / 16,  // = 48
    depth: 1
)

encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
```

**결과**:
- 총 Threadgroup: 64 × 48 = 3,072개
- 총 Thread: 3,072 × 256 = 786,432개
- 각 Thread가 하나의 픽셀 담당

---

## Metal Shading Language

### 개요

MSL(Metal Shading Language)은 C++14 기반의 GPU 프로그래밍 언어입니다.

### 기본 문법

```metal
#include <metal_stdlib>
using namespace metal;

// Kernel 함수
kernel void myKernel(
    // 입력 Texture
    texture2d<float, access::read> input [[texture(0)]],
    
    // 출력 Texture
    texture2d<float, access::write> output [[texture(1)]],
    
    // Buffer
    constant float &factor [[buffer(0)]],
    
    // Thread 위치
    uint2 gid [[thread_position_in_grid]]
)
{
    // Texture 읽기
    float4 color = input.read(gid);
    
    // 처리
    color *= factor;
    
    // Texture 쓰기
    output.write(color, gid);
}
```

### 주요 타입

```metal
// 벡터
float2 vec2 = float2(1.0, 2.0);
float3 vec3 = float3(1.0, 2.0, 3.0);
float4 vec4 = float4(1.0, 2.0, 3.0, 4.0);

// 행렬
float4x4 matrix;

// Texture
texture2d<float, access::read> tex;
texture2d<float, access::write> outTex;

// Buffer
constant float *data;
device float *output;
```

### Attribute Qualifier

```metal
// [[texture(n)]]: Texture 인덱스
// [[buffer(n)]]: Buffer 인덱스
// [[thread_position_in_grid]]: Grid 내 Thread 위치
// [[thread_position_in_threadgroup]]: Threadgroup 내 Thread 위치
// [[threads_per_threadgroup]]: Threadgroup당 Thread 수
```

### Access Qualifier

```metal
// read: 읽기 전용
texture2d<float, access::read> input;

// write: 쓰기 전용
texture2d<float, access::write> output;

// read_write: 읽기/쓰기 (제한적)
texture2d<float, access::read_write> inout;
```

### Address Space

```metal
// device: GPU 전역 메모리 (느림)
device float *globalData;

// constant: 읽기 전용 상수 (빠름)
constant float *weights;

// threadgroup: Threadgroup 공유 메모리 (매우 빠름)
threadgroup float sharedData[256];

// thread: Thread 로컬 변수 (레지스터)
thread float temp = 0.0;
```

---

## 실전 예제

### 예제 1: 간단한 이미지 반전

**Swift 코드**:
```swift
class ImageInverter {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        
        let library = device.makeDefaultLibrary()!
        let function = library.makeFunction(name: "invertColors")!
        self.pipelineState = try! device.makeComputePipelineState(function: function)
    }
    
    func invert(_ texture: MTLTexture) -> MTLTexture {
        // 출력 Texture 생성
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: texture.pixelFormat,
            width: texture.width,
            height: texture.height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        let output = device.makeTexture(descriptor: descriptor)!
        
        // Command Buffer 생성
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        
        // Pipeline 설정
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setTexture(output, index: 1)
        
        // Dispatch
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (texture.width + 15) / 16,
            height: (texture.height + 15) / 16,
            depth: 1
        )
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()
        
        // 실행
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return output
    }
}
```

**Metal Shader**:
```metal
#include <metal_stdlib>
using namespace metal;

kernel void invertColors(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
)
{
    // 범위 체크
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) {
        return;
    }
    
    // 픽셀 읽기
    float4 color = input.read(gid);
    
    // 색상 반전 (알파는 유지)
    color.rgb = 1.0 - color.rgb;
    
    // 쓰기
    output.write(color, gid);
}
```

### 예제 2: Grayscale 변환

**Metal Shader**:
```metal
kernel void grayscale(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
)
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) {
        return;
    }
    
    float4 color = input.read(gid);
    
    // Luminance 계산 (BT.709 표준)
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    
    output.write(float4(gray, gray, gray, color.a), gid);
}
```

### 예제 3: 밝기 조절

**Metal Shader**:
```metal
kernel void adjustBrightness(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float &brightness [[buffer(0)]],  // -1.0 ~ 1.0
    uint2 gid [[thread_position_in_grid]]
)
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) {
        return;
    }
    
    float4 color = input.read(gid);
    
    // 밝기 조절
    color.rgb = clamp(color.rgb + brightness, 0.0, 1.0);
    
    output.write(color, gid);
}
```

---

## 💡 Best Practices

### 1. Pipeline State 재사용

```swift
// ❌ 나쁜 예
func process() {
    let pipeline = try! device.makeComputePipelineState(function: function)
    // 매번 생성 = 느림
}

// ✅ 좋은 예
class Processor {
    let pipeline: MTLComputePipelineState
    
    init() {
        self.pipeline = try! device.makeComputePipelineState(function: function)
    }
    
    func process() {
        // 재사용
    }
}
```

### 2. Command Buffer 재사용하지 않기

```swift
// ❌ 잘못된 예
let commandBuffer = queue.makeCommandBuffer()!
commandBuffer.commit()
commandBuffer.commit()  // 에러! 재사용 불가

// ✅ 올바른 예
let commandBuffer1 = queue.makeCommandBuffer()!
commandBuffer1.commit()

let commandBuffer2 = queue.makeCommandBuffer()!
commandBuffer2.commit()
```

### 3. 적절한 Threadgroup 크기

```swift
// 일반적인 권장값
let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)  // 256 threads

// 또는 Pipeline에서 자동 계산
let w = pipelineState.threadExecutionWidth  // 보통 32
let h = pipelineState.maxTotalThreadsPerThreadgroup / w
let threadgroupSize = MTLSize(width: w, height: h, depth: 1)
```

### 4. Texture 경계 체크

```metal
// ✅ 항상 경계 체크
if (gid.x >= texture.get_width() || gid.y >= texture.get_height()) {
    return;
}
```

### 5. 비동기 실행

```swift
// 완료 대기
commandBuffer.commit()
commandBuffer.waitUntilCompleted()  // 동기

// 콜백 사용 (비동기)
commandBuffer.addCompletedHandler { buffer in
    print("완료!")
}
commandBuffer.commit()
// 즉시 반환
```

---

## 📚 추가 학습 자료

- [Metal Programming Guide](https://developer.apple.com/metal/)
- [Metal Shading Language Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [Metal Best Practices Guide](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/)

---

**다음**: [GAUSSIAN_BLUR_THEORY.md](GAUSSIAN_BLUR_THEORY.md) - Gaussian Blur 알고리즘 이론

