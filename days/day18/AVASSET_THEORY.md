# AVAssetImageGenerator 이론

> AVAssetImageGenerator를 사용한 동영상 썸네일 생성의 기본 개념과 원리

---

## 📚 목차

1. [AVAssetImageGenerator란?](#avassetimagegenerator란)
2. [CMTime 이해하기](#cmtime-이해하기)
3. [썸네일 생성 과정](#썸네일-생성-과정)
4. [주요 속성과 설정](#주요-속성과-설정)
5. [비동기 처리](#비동기-처리)
6. [성능 고려사항](#성능-고려사항)

---

## AVAssetImageGenerator란?

`AVAssetImageGenerator`는 AVFoundation 프레임워크의 클래스로, 동영상 파일에서 특정 시간의 프레임을 이미지로 추출하는 기능을 제공합니다.

### 주요 특징

- **비디오 프레임 추출**: 동영상의 특정 시점을 정지 이미지로 변환
- **비동기 처리**: async/await를 통한 비동기 이미지 생성
- **최적화 옵션**: 크기 조정, 시간 허용 오차 등 다양한 최적화 옵션 제공

### 기본 사용법

```swift
import AVFoundation

let asset = AVAsset(url: videoURL)
let generator = AVAssetImageGenerator(asset: asset)

// 썸네일 생성
let time = CMTime(seconds: 5.0, preferredTimescale: 600)
let cgImage = try await generator.image(at: time).image
let thumbnail = UIImage(cgImage: cgImage)
```

---

## CMTime 이해하기

`CMTime`은 Core Media 프레임워크의 시간 표현 구조체로, 동영상의 정확한 시간을 표현합니다.

### 구조

```swift
struct CMTime {
    var value: Int64        // 시간 값
    var timescale: Int32    // 시간 스케일 (초당 단위 수)
    var flags: CMTimeFlags  // 플래그
    var epoch: Int64         // 에포크
}
```

### 시간 계산

```
실제 시간(초) = value / timescale
```

예시:
- `CMTime(value: 300, timescale: 600)` = 300/600 = 0.5초
- `CMTime(value: 5, timescale: 1)` = 5/1 = 5초

### preferredTimescale

일반적으로 사용하는 `preferredTimescale` 값:

- **600**: 비디오 프레임레이트(30fps)의 배수로 정확한 프레임 선택 가능
- **1000**: 밀리초 단위 표현
- **1**: 초 단위 표현 (가장 간단하지만 정확도 낮음)

### CMTime 생성 방법

```swift
// 방법 1: seconds와 preferredTimescale 사용 (권장)
let time1 = CMTime(seconds: 5.0, preferredTimescale: 600)

// 방법 2: value와 timescale 직접 지정
let time2 = CMTime(value: 3000, timescale: 600)

// 방법 3: 특수 값
let zero = CMTime.zero
let invalid = CMTime.invalid
let positiveInfinity = CMTime.positiveInfinity
```

---

## 썸네일 생성 과정

### 1. AVAsset 생성

```swift
let asset = AVAsset(url: videoURL)
```

- 동영상 파일의 메타데이터를 로드
- 실제 비디오 데이터는 아직 로드하지 않음 (lazy loading)

### 2. AVAssetImageGenerator 생성

```swift
let generator = AVAssetImageGenerator(asset: asset)
```

- Asset을 기반으로 이미지 생성기 생성
- 기본 설정으로 초기화됨

### 3. 옵션 설정

```swift
generator.appliesPreferredTrackTransform = true  // 회전 적용
generator.maximumSize = CGSize(width: 200, height: 200)  // 최대 크기
```

### 4. 이미지 생성

```swift
let time = CMTime(seconds: 5.0, preferredTimescale: 600)
let cgImage = try await generator.image(at: time).image
```

- 지정된 시간의 프레임을 디코딩
- CGImage로 반환

### 5. UIImage 변환

```swift
let thumbnail = UIImage(cgImage: cgImage)
```

---

## 주요 속성과 설정

### appliesPreferredTrackTransform

동영상의 회전 정보를 적용할지 여부를 결정합니다.

```swift
generator.appliesPreferredTrackTransform = true
```

- **true**: 동영상이 회전되어 촬영된 경우 올바른 방향으로 표시
- **false**: 원본 방향 그대로 표시

**권장**: 대부분의 경우 `true`로 설정

### maximumSize

생성되는 썸네일의 최대 크기를 지정합니다.

```swift
generator.maximumSize = CGSize(width: 200, height: 200)
```

- 비율은 유지되며 지정된 크기 이하로 생성
- 메모리 사용량과 생성 시간을 크게 줄일 수 있음

**권장**: 
- 썸네일용: 200x200
- 중간 크기: 400x400
- 고화질: 800x800

### requestedTimeToleranceBefore / requestedTimeToleranceAfter

요청한 시간의 정확도를 지정합니다.

```swift
generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
```

- **작은 값**: 더 정확하지만 느림
- **큰 값**: 덜 정확하지만 빠름

**권장**:
- 정확도 중요: 0.0 (정확한 프레임)
- 성능 중요: 0.1초 (충분히 정확하면서 빠름)

### requestedTimeToleranceBefore/After vs timeToleranceBefore/After

- **requestedTimeTolerance**: 요청한 시간의 허용 오차 (권장)
- **timeTolerance**: 실제 생성된 시간의 허용 오차 (읽기 전용)

---

## 비동기 처리

### async/await 패턴

AVAssetImageGenerator는 iOS 13+부터 async/await를 지원합니다.

```swift
// ✅ 권장: async/await
let cgImage = try await generator.image(at: time).image

// ❌ 구식: completion handler
generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { 
    requestedTime, cgImage, actualTime, result, error in
    // 처리
}
```

### Task 사용

```swift
Task {
    do {
        let thumbnail = try await ThumbnailGenerator.generateThumbnail(
            from: videoURL,
            at: 5.0
        )
        await MainActor.run {
            self.thumbnail = thumbnail
        }
    } catch {
        print("에러: \(error)")
    }
}
```

### MainActor

UI 업데이트는 반드시 메인 스레드에서 수행해야 합니다.

```swift
await MainActor.run {
    self.thumbnail = thumbnail
    self.isLoading = false
}
```

---

## 성능 고려사항

### 1. 크기 최적화

큰 썸네일은 메모리와 시간을 많이 소모합니다.

```swift
// ❌ 나쁜 예: 원본 크기
generator.maximumSize = CGSize(width: 1920, height: 1080)

// ✅ 좋은 예: 적절한 크기
generator.maximumSize = CGSize(width: 200, height: 200)
```

### 2. 시간 허용 오차

정확도와 성능의 균형을 맞춥니다.

```swift
// 정확도 우선 (느림)
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

// 성능 우선 (빠름, 충분히 정확)
generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
```

### 3. 배치 처리

여러 썸네일을 생성할 때는 병렬 처리합니다.

```swift
try await withThrowingTaskGroup(of: UIImage?.self) { group in
    for time in times {
        group.addTask {
            try? await generator.image(at: time).image
        }
    }
    // 결과 수집
}
```

### 4. 캐싱

같은 썸네일을 반복 생성하지 않도록 캐싱합니다.

```swift
let cacheKey = ThumbnailCacheKey(videoURL: url, time: time)
if let cached = cache.getThumbnail(for: cacheKey) {
    return cached
}
// 생성 후 캐시에 저장
```

### 5. 메모리 관리

- 큰 동영상 파일 처리 시 메모리 사용량 모니터링
- 필요없는 썸네일은 즉시 해제
- NSCache를 사용한 자동 메모리 관리

---

## 에러 처리

### 주요 에러 타입

```swift
enum ThumbnailError: LocalizedError {
    case invalidAsset          // 유효하지 않은 동영상
    case invalidTime           // 유효하지 않은 시간
    do {
        let thumbnail = try await generator.image(at: time).image
    } catch {
        // 에러 처리
    }
}
```

### 에러 처리 패턴

```swift
do {
    let thumbnail = try await ThumbnailGenerator.generateThumbnail(
        from: videoURL,
        at: time
    )
    // 성공 처리
} catch ThumbnailError.invalidAsset {
    // 동영상 파일 문제
} catch ThumbnailError.invalidTime {
    // 시간 범위 초과
} catch {
    // 기타 에러
    print("예상치 못한 에러: \(error)")
}
```

---

## 실무 활용 사례

### 1. 동영상 갤러리

여러 동영상의 썸네일을 빠르게 표시

```swift
// 각 동영상의 첫 프레임을 썸네일로 사용
let thumbnail = try await generator.image(at: .zero).image
```

### 2. 타임라인 썸네일

동영상 편집기의 타임라인에 썸네일 표시

```swift
// 동영상을 균등하게 나눠서 썸네일 생성
let times = (0..<10).map { 
    CMTime(seconds: duration * Double($0) / 10, preferredTimescale: 600) 
}
```

### 3. 썸네일 프리뷰

동영상 재생 전 썸네일 표시

```swift
// 동영상의 중간 지점 썸네일
let middleTime = CMTime(seconds: duration / 2, preferredTimescale: 600)
```

---

## 요약

1. **AVAssetImageGenerator**: 동영상에서 프레임을 이미지로 추출
2. **CMTime**: 정확한 시간 표현을 위한 구조체
3. **비동기 처리**: async/await를 사용한 비동기 이미지 생성
4. **성능 최적화**: 크기 제한, 시간 허용 오차, 캐싱 활용
5. **에러 처리**: 다양한 에러 상황에 대한 적절한 처리

---

## 참고 자료

- [Apple Documentation: AVAssetImageGenerator](https://developer.apple.com/documentation/avfoundation/avassetimagegenerator)
- [Apple Documentation: CMTime](https://developer.apple.com/documentation/coremedia/cmtime)
- [WWDC: Advances in AVFoundation](https://developer.apple.com/videos/play/wwdc2019/506/)

---

**다음 단계**: [THUMBNAIL_GUIDE.md](./THUMBNAIL_GUIDE.md)에서 실제 구현 방법을 학습하세요.

