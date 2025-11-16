# GIF 포맷 이론

> GIF와 애니메이션 이미지의 구조와 iOS에서의 처리 방법

---

## 📚 목차

1. [GIF란?](#gif란)
2. [GIF 포맷 구조](#gif-포맷-구조)
3. [애니메이션 GIF](#애니메이션-gif)
4. [iOS에서 GIF 처리](#ios에서-gif-처리)
5. [CGImageSource를 활용한 파싱](#cgimagesource를-활용한-파싱)
6. [프레임과 딜레이](#프레임과-딜레이)
7. [루프 처리](#루프-처리)

---

## GIF란?

GIF (Graphics Interchange Format)는 1987년에 개발된 비트맵 이미지 포맷입니다.

### 주요 특징

- **손실 없는 압축**: LZW 압축 알고리즘 사용
- **색상 제한**: 최대 256색 (8비트)
- **애니메이션 지원**: 여러 프레임을 순차적으로 재생
- **투명도 지원**: 단일 색상 투명도 (알파 채널 없음)

### GIF의 장단점

**장점**:
- 애니메이션 지원
- 손실 없는 압축
- 널리 지원되는 포맷
- 작은 파일 크기 (단순한 이미지의 경우)

**단점**:
- 색상 제한 (256색)
- 큰 이미지나 복잡한 애니메이션은 파일 크기가 큼
- iOS에서 네이티브 지원이 제한적

---

## GIF 포맷 구조

### 기본 구조

```
GIF 파일 구조:
├── Header (6 bytes)
├── Logical Screen Descriptor
├── Global Color Table (선택적)
├── Image Data
│   ├── Image Descriptor
│   ├── Local Color Table (선택적)
│   └── Image Data
├── Graphic Control Extension (애니메이션용)
└── Trailer (1 byte: 0x3B)
```

### 주요 구성 요소

#### 1. Header
- GIF 시그니처: "GIF87a" 또는 "GIF89a"
- 버전 정보 포함

#### 2. Logical Screen Descriptor
- 캔버스 크기 (width, height)
- Global Color Table 존재 여부
- 색상 해상도

#### 3. Color Table
- **Global Color Table**: 전체 GIF에 적용되는 색상 팔레트
- **Local Color Table**: 특정 프레임에만 적용되는 색상 팔레트
- 최대 256색 (8비트)

#### 4. Image Descriptor
- 프레임의 위치와 크기
- Local Color Table 사용 여부
- 인터레이스 여부

#### 5. Graphic Control Extension
- **Delay Time**: 다음 프레임까지의 딜레이 (1/100초 단위)
- **Disposal Method**: 프레임 처리 방법
  - 0: 지정 없음
  - 1: 그대로 유지
  - 2: 배경색으로 복원
  - 3: 이전 프레임으로 복원
- **Transparent Color**: 투명 색상 인덱스
- **User Input Flag**: 사용자 입력 대기 여부

---

## 애니메이션 GIF

### 애니메이션 원리

애니메이션 GIF는 여러 정지 이미지(프레임)를 순차적으로 재생하여 움직임을 표현합니다.

```
프레임 1 (0.1초) → 프레임 2 (0.1초) → 프레임 3 (0.1초) → ...
```

### 프레임 구조

각 프레임은 독립적인 이미지 데이터를 가지며, Graphic Control Extension으로 딜레이 정보를 포함합니다.

```swift
struct GIFFrame {
    let image: CGImage
    let delay: TimeInterval  // 초 단위
    let disposalMethod: DisposalMethod
    let hasTransparency: Bool
}
```

### 루프 처리

GIF는 애니메이션을 반복 재생할 수 있습니다:

- **무한 루프**: 애니메이션이 끝나면 처음부터 다시 시작
- **제한 루프**: 지정된 횟수만큼 재생 후 정지
- **1회 재생**: 한 번만 재생

---

## iOS에서 GIF 처리

### 네이티브 지원

iOS는 GIF를 직접적으로 완전히 지원하지 않습니다:

- `UIImage`는 정적 GIF만 지원 (첫 프레임만 표시)
- `UIImageView`는 애니메이션 GIF를 자동으로 재생하지 않음
- `UIImage.animatedImage()`를 사용해야 함

### UIImage.animatedImage

```swift
let images = [UIImage(named: "frame1")!, UIImage(named: "frame2")!]
let animatedImage = UIImage.animatedImage(with: images, duration: 1.0)
imageView.image = animatedImage
```

**제한사항**:
- 모든 프레임을 메모리에 로드해야 함
- 프레임별 딜레이를 개별적으로 설정할 수 없음
- 큰 GIF 파일의 경우 메모리 문제 발생 가능

---

## CGImageSource를 활용한 파싱

### CGImageSource란?

`CGImageSource`는 Image I/O 프레임워크의 클래스로, 다양한 이미지 포맷을 읽고 파싱할 수 있습니다.

### GIF 파싱 과정

```swift
import ImageIO

// 1. CGImageSource 생성
guard let imageSource = CGImageSourceCreateWithURL(url, nil) else {
    return
}

// 2. 프레임 개수 확인
let frameCount = CGImageSourceGetCount(imageSource)

// 3. 각 프레임 추출
for index in 0..<frameCount {
    // 프레임 이미지
    guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
        continue
    }
    
    // 딜레이 정보 추출
    guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String: Any],
          let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
          let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double else {
        continue
    }
    
    // 프레임 정보 저장
    let frame = GIFFrame(image: UIImage(cgImage: cgImage), delay: delay)
    frames.append(frame)
}
```

### 주요 함수

#### CGImageSourceCreateWithURL
```swift
func CGImageSourceCreateWithURL(_ url: CFURL, _ options: CFDictionary?) -> CGImageSource?
```
- URL에서 이미지 소스 생성
- Data나 파일 경로에서도 생성 가능

#### CGImageSourceGetCount
```swift
func CGImageSourceGetCount(_ isrc: CGImageSource) -> Int
```
- 이미지 소스의 프레임 개수 반환
- 정적 이미지는 1 반환

#### CGImageSourceCreateImageAtIndex
```swift
func CGImageSourceCreateImageAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage?
```
- 특정 인덱스의 프레임을 CGImage로 반환
- 메모리 효율적: 필요한 프레임만 디코딩

#### CGImageSourceCopyPropertiesAtIndex
```swift
func CGImageSourceCopyPropertiesAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CFDictionary?
```
- 프레임의 메타데이터 반환
- 딜레이, 루프 정보 등 포함

---

## 프레임과 딜레이

### 딜레이 시간

GIF의 딜레이 시간은 **1/100초 단위**로 저장됩니다:

```swift
// GIF 딜레이 (1/100초) → 초 단위 변환
let delayInSeconds = delay / 100.0
```

**주의사항**:
- 딜레이가 0이면 기본값(0.1초) 사용
- 너무 짧은 딜레이(0.01초 미만)는 부드럽지 않을 수 있음
- 너무 긴 딜레이(10초 이상)는 사용자 경험 저하

### 프레임 레이트 계산

```swift
// 평균 딜레이로 프레임 레이트 계산
let averageDelay = frames.map { $0.delay }.reduce(0, +) / Double(frames.count)
let fps = 1.0 / averageDelay
```

### 최적 딜레이

일반적인 애니메이션:
- **10-20 fps**: 부드러운 애니메이션
- **30 fps**: 매우 부드러운 애니메이션 (파일 크기 증가)
- **5 fps 이하**: 느린 애니메이션

---

## 루프 처리

### 루프 정보 추출

```swift
// GIF 파일의 루프 정보 추출
guard let properties = CGImageSourceCopyProperties(imageSource, nil) as? [String: Any],
      let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
      let loopCount = gifProperties[kCGImagePropertyGIFLoopCount as String] as? Int else {
    return
}

// loopCount 값:
// - 0: 무한 루프
// - n: n번 반복
```

### 루프 구현

```swift
class GIFAnimator {
    private var currentLoop = 0
    private let maxLoops: Int  // 0이면 무한
    
    func playFrame() {
        // 프레임 재생
        displayFrame(currentFrameIndex)
        
        // 마지막 프레임인지 확인
        if currentFrameIndex == frames.count - 1 {
            currentLoop += 1
            
            // 루프 제한 확인
            if maxLoops > 0 && currentLoop >= maxLoops {
                stop()
                return
            }
            
            // 처음으로 돌아가기
            currentFrameIndex = 0
        } else {
            currentFrameIndex += 1
        }
    }
}
```

---

## 메모리 관리

### 문제점

큰 GIF 파일의 경우 모든 프레임을 메모리에 로드하면 메모리 부족이 발생할 수 있습니다.

### 해결 방법

#### 1. 지연 로딩 (Lazy Loading)
```swift
// 필요한 프레임만 디코딩
func getFrame(at index: Int) -> UIImage? {
    if let cached = frameCache[index] {
        return cached
    }
    
    guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
        return nil
    }
    
    let image = UIImage(cgImage: cgImage)
    frameCache[index] = image
    return image
}
```

#### 2. 프레임 캐싱
```swift
// 최근 사용한 프레임만 캐시에 유지
class FrameCache {
    private var cache: [Int: UIImage] = [:]
    private let maxCacheSize = 10
    
    func getFrame(at index: Int) -> UIImage? {
        // 캐시에 있으면 반환
        if let cached = cache[index] {
            return cached
        }
        
        // 새 프레임 로드
        let frame = loadFrame(at: index)
        
        // 캐시 크기 제한
        if cache.count >= maxCacheSize {
            // 가장 오래된 프레임 제거
            let oldestKey = cache.keys.min()!
            cache.removeValue(forKey: oldestKey)
        }
        
        cache[index] = frame
        return frame
    }
}
```

#### 3. 다운샘플링
```swift
// 큰 GIF를 작은 크기로 다운샘플링
let options: [CFString: Any] = [
    kCGImageSourceThumbnailMaxPixelSize: 300,
    kCGImageSourceCreateThumbnailFromImageAlways: true
]

guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, index, options as CFDictionary) else {
    return nil
}
```

---

## 성능 최적화

### 1. 프레임 디코딩 최적화

```swift
// 백그라운드 스레드에서 디코딩
Task.detached(priority: .userInitiated) {
    let frame = self.decodeFrame(at: index)
    await MainActor.run {
        self.currentFrame = frame
    }
}
```

### 2. 프레임 드롭 방지

```swift
// CADisplayLink 사용으로 정확한 타이밍
let displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
displayLink.preferredFramesPerSecond = 60
displayLink.add(to: .main, forMode: .common)
```

### 3. 배터리 최적화

- 화면에 보이지 않을 때 애니메이션 일시정지
- 백그라운드로 이동 시 애니메이션 정지
- 저전력 모드 감지

---

## 실전 팁

### 1. GIF 파일 크기 확인

```swift
if let fileSize = try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64 {
    let sizeInMB = Double(fileSize) / (1024 * 1024)
    print("GIF 크기: \(sizeInMB) MB")
}
```

### 2. 프레임 개수 확인

```swift
let frameCount = CGImageSourceGetCount(imageSource)
print("프레임 개수: \(frameCount)")
```

### 3. 애니메이션 길이 계산

```swift
let totalDuration = frames.map { $0.delay }.reduce(0, +)
print("애니메이션 길이: \(totalDuration)초")
```

---

## 참고 자료

- [Image I/O Framework](https://developer.apple.com/documentation/imageio)
- [CGImageSource Documentation](https://developer.apple.com/documentation/coregraphics/cgimagesource)
- [GIF Specification](https://www.w3.org/Graphics/GIF/spec-gif89a.txt)

---

**다음 단계**: PERFORMANCE_GUIDE.md에서 성능 최적화 방법을 학습하세요.

