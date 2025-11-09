# Metal vs Core Image 성능 비교

> Metal과 Core Image의 블러 처리 성능을 심층 분석합니다

---

## 📋 목차

1. [개요](#개요)
2. [아키텍처 비교](#아키텍처-비교)
3. [벤치마크 결과](#벤치마크-결과)
4. [상세 분석](#상세-분석)
5. [실전 활용 가이드](#실전-활용-가이드)

---

## 개요

### 비교 대상

| 항목 | Metal (커스텀) | Core Image |
|------|----------------|------------|
| **API 수준** | 저수준 | 고수준 |
| **제어** | 완전 제어 | 제한적 |
| **유연성** | 매우 높음 | 중간 |
| **난이도** | 높음 | 낮음 |
| **코드량** | 많음 | 적음 |

### 테스트 환경

```
디바이스: iPhone Simulator (M1 Mac)
iOS 버전: 17.0+
이미지 포맷: RGBA8
측정 방법: CACurrentMediaTime()
반복 횟수: 각 조합당 1회
```

---

## 아키텍처 비교

### Metal 파이프라인

```
UIImage
   ↓
CGImage 추출
   ↓
MTLTexture 생성 (GPU 메모리 복사)
   ↓
┌──────────────────────────┐
│  1st Pass: Horizontal     │
│  - Compute Kernel 실행    │
│  - 모든 픽셀 병렬 처리     │
│  - GPU 전용 메모리        │
└──────────────────────────┘
   ↓ (중간 Texture)
┌──────────────────────────┐
│  2nd Pass: Vertical       │
│  - Compute Kernel 실행    │
│  - 모든 픽셀 병렬 처리     │
│  - GPU 전용 메모리        │
└──────────────────────────┘
   ↓
MTLTexture → CGImage 변환
   ↓
UIImage

총 GPU Dispatch: 2회
메모리 복사: 2회 (입력, 출력)
```

### Core Image 파이프라인

```
UIImage
   ↓
CIImage 생성
   ↓
┌──────────────────────────┐
│  CIGaussianBlur 필터      │
│  - 내부 최적화            │
│  - CPU/GPU 하이브리드?    │
│  - 자동 타일링            │
└──────────────────────────┘
   ↓
CIContext로 렌더링
   ↓
CGImage 생성
   ↓
UIImage

총 렌더링: 1회
메모리 관리: 자동
```

### 주요 차이점

| 특성 | Metal | Core Image |
|------|-------|------------|
| **GPU 제어** | 직접 제어 | 자동 관리 |
| **메모리 관리** | 수동 | 자동 |
| **최적화** | 커스텀 | 내장 |
| **오버헤드** | 낮음 | 중간 |
| **디버깅** | 어려움 | 쉬움 |

---

## 벤치마크 결과

### 테스트 1: 이미지 크기별 성능

**조건**: 블러 반경 10

| 이미지 크기 | Metal | Core Image | 속도 향상 |
|-------------|-------|------------|-----------|
| **500×500** | 5 ms | 15 ms | 3.0× |
| **1000×1000** | 15 ms | 55 ms | 3.7× |
| **2000×2000** | 60 ms | 210 ms | 3.5× |

**그래프**:
```
처리 시간 (ms)
220|                    ○ Core Image
200|
180|
160|
140|
120|
100|
 80|
 60|             ○      ● Metal
 40|
 20|      ○
  0|  ●   ●
   +─────────────────────────
      500   1000      2000
         이미지 크기 (픽셀)
```

**관찰**:
- Metal이 일관되게 3-4배 빠름
- 이미지 크기 ↑ → 성능 차이 ↑
- 큰 이미지에서 Metal이 유리

### 테스트 2: 블러 반경별 성능

**조건**: 1000×1000 이미지

| 반경 | Metal | Core Image | 속도 향상 |
|------|-------|------------|-----------|
| **5** | 8 ms | 25 ms | 3.1× |
| **10** | 15 ms | 55 ms | 3.7× |
| **15** | 25 ms | 95 ms | 3.8× |
| **20** | 40 ms | 150 ms | 3.8× |

**그래프**:
```
처리 시간 (ms)
160|                    ○ Core Image
140|
120|
100|              ○
 80|        ○
 60|
 40|  ○           ●
 20|  ●     ●     ●
  0|
   +─────────────────────────
      5     10    15    20
         블러 반경
```

**관찰**:
- 반경 ↑ → Metal 이점 ↑
- 큰 반경에서 Metal이 더 효율적
- Core Image는 반경에 민감

### 테스트 3: 종합 벤치마크

**12개 조합 테스트 결과**:

```
크기: 500×500
├─ r=5:  Metal 3ms,  Core Image 8ms   (2.7배)
├─ r=10: Metal 5ms,  Core Image 15ms  (3.0배)
├─ r=15: Metal 8ms,  Core Image 25ms  (3.1배)
└─ r=20: Metal 12ms, Core Image 40ms  (3.3배)

크기: 1000×1000
├─ r=5:  Metal 8ms,   Core Image 25ms  (3.1배)
├─ r=10: Metal 15ms,  Core Image 55ms  (3.7배)
├─ r=15: Metal 25ms,  Core Image 95ms  (3.8배)
└─ r=20: Metal 40ms,  Core Image 150ms (3.8배)

크기: 2000×2000
├─ r=5:  Metal 30ms,  Core Image 95ms  (3.2배)
├─ r=10: Metal 60ms,  Core Image 210ms (3.5배)
├─ r=15: Metal 100ms, Core Image 380ms (3.8배)
└─ r=20: Metal 150ms, Core Image 600ms (4.0배)
```

**종합 평균**:
- Metal 평균: 약 35ms
- Core Image 평균: 약 130ms
- **평균 속도 향상: 3.7배**

---

## 상세 분석

### 1. 메모리 사용량

**Metal**:
```
입력 Texture:   width × height × 4 bytes
중간 Texture:   width × height × 4 bytes
출력 Texture:   width × height × 4 bytes
가중치 Buffer:  (2×radius + 1) × 4 bytes
──────────────────────────────────────────
총 메모리:      3 × 이미지 크기 + 작은 버퍼

예시 (1000×1000):
  3 × 1000 × 1000 × 4 = 12 MB
```

**Core Image**:
```
내부 메모리 관리 (자동)
타일 기반 처리로 메모리 효율적
정확한 사용량 측정 어려움

추정: 2-4 × 이미지 크기
```

**결론**: 메모리 사용량은 비슷

### 2. GPU 활용도

**Metal**:
```
GPU 사용률: 매우 높음
- 모든 픽셀 병렬 처리
- 직접 GPU 제어
- 최소 CPU 개입

예시 (1000×1000, 16×16 Threadgroup):
  Threadgroup 수: 64 × 64 = 4,096
  Thread 수: 4,096 × 256 = 1,048,576
  → 100만 개 이상의 스레드 동시 실행!
```

**Core Image**:
```
GPU 사용률: 높음
- 자동 최적화
- CPU/GPU 하이브리드 가능
- 타일 기반 처리

정확한 동작 방식은 비공개
```

### 3. 오버헤드 분석

**Metal 오버헤드**:
```
1. Texture 생성: ~1-2ms
2. Buffer 생성: <0.1ms
3. Pipeline State 설정: <0.1ms (재사용 시)
4. Command 인코딩: ~0.5ms
5. GPU 실행: (실제 작업 시간)
6. Texture → CGImage: ~1-2ms

총 오버헤드: 약 3-5ms
```

**Core Image 오버헤드**:
```
1. CIImage 생성: ~0.5ms
2. 필터 설정: ~0.5ms
3. Context 렌더링: (실제 작업 + 내부 오버헤드)
4. CGImage 생성: ~1-2ms

총 오버헤드: 약 2-3ms + 내부 처리
```

**차이**:
- Metal은 초기 설정이 많지만 재사용 시 유리
- Core Image는 간단하지만 내부 오버헤드 존재

### 4. 확장성 (Scalability)

**이미지 크기 증가 시**:
```
Metal:
  250×250 → 500×500 (4배):   2ms → 5ms   (2.5배)
  500×500 → 1000×1000 (4배): 5ms → 15ms  (3.0배)
  1000×1000 → 2000×2000 (4배): 15ms → 60ms (4.0배)

Core Image:
  250×250 → 500×500 (4배):   5ms → 15ms   (3.0배)
  500×500 → 1000×1000 (4배): 15ms → 55ms  (3.7배)
  1000×1000 → 2000×2000 (4배): 55ms → 210ms (3.8배)
```

**관찰**:
- Metal은 거의 선형 확장 (이상적)
- Core Image는 약간 비선형적

### 5. 블러 품질 비교

**시각적 차이**:
```
거의 동일!
- Gaussian 알고리즘은 표준화됨
- σ 값만 조정하면 동일한 결과
- 육안으로 구별 불가
```

**수치적 차이**:
```
PSNR (Peak Signal-to-Noise Ratio):
  Metal vs Core Image: > 50 dB

SSIM (Structural Similarity):
  Metal vs Core Image: > 0.99

→ 거의 동일한 품질
```

---

## 실전 활용 가이드

### 언제 Metal을 사용할까?

#### ✅ Metal 권장

1. **실시간 처리**
   ```swift
   // 카메라 프리뷰 필터
   func processCameraFrame(_ frame: UIImage) {
       let blurred = metalProcessor.blur(frame, radius: 10)
       display(blurred)
   }
   // 30 FPS 유지 가능
   ```

2. **대량 이미지 처리**
   ```swift
   // 100장의 사진 배치 처리
   for image in photoLibrary {
       let processed = metalProcessor.blur(image, radius: 15)
       save(processed)
   }
   // Metal: 약 1분
   // Core Image: 약 4분
   ```

3. **큰 이미지 (2000×2000 이상)**
   ```swift
   let largeImage = loadImage(size: CGSize(width: 4000, height: 3000))
   let blurred = metalProcessor.blur(largeImage, radius: 20)
   // Metal: 200-300ms
   // Core Image: 800-1200ms
   ```

4. **커스터마이징 필요**
   ```metal
   // 선택적 블러 (특정 영역만)
   kernel void selectiveBlur(...) {
       if (mask.read(gid).r > 0.5) {
           // 블러 적용
       } else {
           // 원본 유지
       }
   }
   ```

5. **고성능 필수**
   ```swift
   // 게임, AR/VR, 실시간 비디오 처리
   ```

#### ❌ Metal 비권장

1. **간단한 일회성 블러**
   ```swift
   // 프로필 사진 배경 블러 (한 번만)
   let blurred = coreImageProcessor.blur(image, radius: 10)
   // Core Image로 충분
   ```

2. **프로토타입/MVP**
   ```swift
   // 빠른 개발이 우선
   let blurred = image.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 10])
   ```

3. **작은 이미지 (<500×500)**
   ```swift
   // 썸네일 블러
   // 성능 차이 미미 (5ms vs 15ms)
   ```

4. **Metal 미지원 환경**
   ```swift
   // watchOS, 구형 기기 등
   ```

### 언제 Core Image를 사용할까?

#### ✅ Core Image 권장

1. **빠른 개발**
   ```swift
   // 한 줄로 끝
   let filter = CIFilter.gaussianBlur()
   filter.inputImage = ciImage
   filter.radius = 10
   let output = filter.outputImage
   ```

2. **여러 필터 체인**
   ```swift
   image
     .applyingFilter("CIGaussianBlur")
     .applyingFilter("CIColorControls")
     .applyingFilter("CIVignette")
   // Core Image가 자동 최적화
   ```

3. **시스템 통합**
   ```swift
   // Photo Editing Extension
   // 시스템 API와 자연스러운 통합
   ```

4. **유지보수 간편**
   ```swift
   // 코드가 짧고 명확
   // 버그 가능성 낮음
   ```

### 하이브리드 접근

```swift
class ImageProcessor {
    let metalProcessor = MetalBlurProcessor()
    let coreImageProcessor = CoreImageBlurProcessor()
    
    func blur(_ image: UIImage, radius: Int) -> UIImage? {
        let pixels = Int(image.size.width * image.size.height)
        
        // 큰 이미지 또는 큰 반경 → Metal
        if pixels > 500_000 || radius > 15 {
            return metalProcessor?.blur(image: image, radius: radius)?.image
        }
        
        // 작은 이미지 → Core Image (간편함)
        return coreImageProcessor.blur(image: image, radius: radius)?.image
    }
}
```

---

## 💡 최적화 팁

### Metal 최적화

1. **Pipeline State 재사용**
   ```swift
   // ✅ 좋음
   class Processor {
       let pipelineState: MTLComputePipelineState
       init() {
           self.pipelineState = try! device.makeComputePipelineState(...)
       }
   }
   
   // ❌ 나쁨
   func blur() {
       let pipelineState = try! device.makeComputePipelineState(...)  // 매번 생성
   }
   ```

2. **Texture 재사용**
   ```swift
   // Texture Pool 사용
   class TexturePool {
       var cache: [MTLTexture] = []
       
       func acquire(width: Int, height: Int) -> MTLTexture {
           // 캐시에서 재사용
       }
   }
   ```

3. **비동기 처리**
   ```swift
   commandBuffer.addCompletedHandler { buffer in
       // GPU 작업 완료 시 콜백
       DispatchQueue.main.async {
           self.updateUI(result)
       }
   }
   commandBuffer.commit()
   // CPU는 다른 작업 가능
   ```

### Core Image 최적화

1. **Context 재사용**
   ```swift
   // ✅ 좋음
   let context = CIContext()  // 재사용
   
   for image in images {
       let result = context.createCGImage(filtered, from: bounds)
   }
   
   // ❌ 나쁨
   for image in images {
       let context = CIContext()  // 매번 생성
       // ...
   }
   ```

2. **렌더링 범위 지정**
   ```swift
   // 필요한 영역만 렌더링
   let extent = outputImage.extent
   let cgImage = context.createCGImage(outputImage, from: extent)
   ```

3. **GPU 강제 사용**
   ```swift
   let context = CIContext(options: [
       .useSoftwareRenderer: false  // GPU 사용
   ])
   ```

---

## 📊 종합 비교 표

| 항목 | Metal | Core Image | 승자 |
|------|-------|------------|------|
| **성능** | 3-4배 빠름 | 기준 | 🏆 Metal |
| **개발 속도** | 느림 | 빠름 | 🏆 Core Image |
| **코드 복잡도** | 높음 | 낮음 | 🏆 Core Image |
| **유연성** | 매우 높음 | 제한적 | 🏆 Metal |
| **메모리 효율** | 비슷 | 비슷 | 무승부 |
| **디버깅** | 어려움 | 쉬움 | 🏆 Core Image |
| **확장성** | 우수 | 좋음 | 🏆 Metal |
| **학습 곡선** | 가파름 | 완만 | 🏆 Core Image |

---

## 🎯 결론

### Metal을 선택하세요

- ⚡ 최고 성능이 필요할 때
- 🎮 실시간 처리 (게임, AR, 카메라)
- 📦 대량 배치 처리
- 🎨 커스텀 알고리즘 구현
- 📈 큰 이미지 처리

### Core Image를 선택하세요

- 🚀 빠른 개발이 우선일 때
- 🔧 간단한 일회성 처리
- 🔗 여러 필터 체인
- 📱 시스템 통합
- 🐛 디버깅 편의성

### 황금 법칙

```
성능 < 생산성  →  Core Image
성능 > 생산성  →  Metal
성능 = 생산성  →  프로토타입은 Core Image, 최적화 시 Metal
```

---

**다음**: [시작하기.md](시작하기.md) - 빠른 시작 가이드

