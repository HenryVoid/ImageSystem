# Day 18 — AVAsset 썸네일 생성

> 동영상에서 특정 타임의 이미지를 추출해 썸네일을 자동 생성하는 기능 학습

---

## 📋 프로젝트 개요

AVAssetImageGenerator를 사용하여 동영상 파일에서 특정 시간의 프레임을 이미지로 추출하고, 비동기 처리, 배치 처리, 캐싱 등을 활용한 썸네일 생성 시스템을 구현합니다.

---

## 🎯 학습 목표

1. **AVAssetImageGenerator 이해**: 동영상에서 프레임을 이미지로 추출하는 방법
2. **CMTime 이해**: 정확한 시간 표현과 처리
3. **비동기 처리**: async/await를 사용한 비동기 썸네일 생성
4. **배치 처리**: 여러 타임라인에서 썸네일을 효율적으로 생성
5. **캐싱 시스템**: 메모리와 디스크 캐시를 활용한 성능 최적화
6. **성능 최적화**: 크기 제한, 시간 허용 오차 등 최적화 기법

---

## 📁 프로젝트 구조

```
day18/
├── day18/
│   ├── Core/
│   │   └── ThumbnailGenerator.swift      # 썸네일 생성 핵심 로직
│   ├── Views/
│   │   ├── SimpleThumbnailView.swift     # 기본 썸네일 생성 데모
│   │   ├── BatchThumbnailView.swift      # 배치 썸네일 생성 데모
│   │   └── ThumbnailGalleryView.swift    # 썸네일 갤러리 뷰
│   ├── tool/
│   │   ├── PerformanceLogger.swift      # 성능 측정 도구
│   │   └── ThumbnailCache.swift         # 썸네일 캐싱 시스템
│   ├── ContentView.swift                # 메인 네비게이션
│   └── day18App.swift                   # 앱 진입점
├── 시작하기.md                           # 빠른 시작 가이드
├── AVASSET_THEORY.md                    # 이론 설명
├── THUMBNAIL_GUIDE.md                   # 구현 가이드
├── PERFORMANCE_GUIDE.md                 # 성능 최적화 가이드
└── README.md                            # 프로젝트 개요
```

---

## 🚀 빠른 시작

### 1. 프로젝트 열기

```bash
cd day18
open day18.xcodeproj
```

### 2. 앱 실행

```
⌘R (Run)
```

### 3. 학습 순서

1. **시작하기.md** 읽기 (5분)
2. **AVASSET_THEORY.md** 읽기 (30분)
3. **SimpleThumbnailView** 실습 (20분)
4. **BatchThumbnailView** 실습 (30분)
5. **ThumbnailGalleryView** 실습 (30분)
6. **THUMBNAIL_GUIDE.md** 읽기 (20분)
7. **PERFORMANCE_GUIDE.md** 읽기 (20분)

**총 학습 시간: 약 2시간 30분**

---

## 📚 주요 컴포넌트

### Core 모듈

#### ThumbnailGenerator

AVAssetImageGenerator를 래핑한 썸네일 생성기입니다.

**주요 기능**:
- 단일 타임라인 썸네일 생성
- 배치 썸네일 생성 (여러 타임라인)
- 비동기 처리 (async/await)
- 크기 최적화 옵션

**사용 예제**:
```swift
// 단일 썸네일
let thumbnail = try await ThumbnailGenerator.generateThumbnail(
    from: videoURL,
    at: 5.0
)

// 배치 썸네일
let thumbnails = try await ThumbnailGenerator.generateThumbnails(
    from: videoURL,
    at: [1.0, 5.0, 10.0, 15.0],
    progressHandler: { progress in
        print("진행률: \(progress * 100)%")
    }
)
```

### Views 모듈

#### SimpleThumbnailView

기본 썸네일 생성 데모입니다.

**기능**:
- 동영상 선택
- 특정 시간 입력
- 썸네일 생성 및 표시
- 성능 측정

#### BatchThumbnailView

배치 썸네일 생성 데모입니다.

**기능**:
- 여러 타임라인에서 썸네일 생성
- 진행률 표시
- 그리드 레이아웃으로 표시
- 성능 측정

#### ThumbnailGalleryView

썸네일 갤러리 뷰입니다.

**기능**:
- 여러 동영상의 썸네일 관리
- 캐싱 시스템 활용
- 캐시 정보 표시
- 성능 모니터링

### Tool 모듈

#### PerformanceLogger

성능 측정 로깅 유틸리티입니다.

**기능**:
- 생성 시간 측정
- 메모리 사용량 추적
- 카테고리별 로깅

#### ThumbnailCache

썸네일 캐싱 시스템입니다.

**기능**:
- 메모리 캐시 (NSCache)
- 디스크 캐시
- 캐시 크기 관리
- 자동 메모리 정리

---

## 🔑 핵심 개념

### AVAssetImageGenerator

동영상에서 프레임을 이미지로 추출하는 클래스입니다.

```swift
let asset = AVAsset(url: videoURL)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.maximumSize = CGSize(width: 200, height: 200)

let time = CMTime(seconds: 5.0, preferredTimescale: 600)
let cgImage = try await generator.image(at: time).image
```

### CMTime

정확한 시간 표현을 위한 구조체입니다.

```swift
// 시간 생성
let time = CMTime(seconds: 5.0, preferredTimescale: 600)
// 실제 시간 = 5.0초

// 시간 계산
let duration = CMTimeGetSeconds(time)  // Double 반환
```

### 비동기 처리

async/await를 사용한 비동기 썸네일 생성입니다.

```swift
Task {
    let thumbnail = try await ThumbnailGenerator.generateThumbnail(
        from: videoURL,
        at: 5.0
    )
    await MainActor.run {
        self.thumbnail = thumbnail
    }
}
```

### 캐싱

메모리와 디스크 캐시를 활용한 성능 최적화입니다.

```swift
let cacheKey = ThumbnailCacheKey(videoURL: url, time: 5.0)

// 캐시 확인
if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
    return cached
}

// 생성 후 캐시 저장
let thumbnail = try await ThumbnailGenerator.generateThumbnail(...)
ThumbnailCache.shared.storeThumbnail(thumbnail, for: cacheKey)
```

---

## 📖 문서 가이드

### 시작하기.md

빠른 시작 가이드입니다.
- 프로젝트 열기
- 앱 실행
- 학습 순서
- 핵심 코드 예제

### AVASSET_THEORY.md

이론 설명 문서입니다.
- AVAssetImageGenerator 개념
- CMTime 이해
- 썸네일 생성 과정
- 주요 속성과 설정
- 비동기 처리
- 성능 고려사항

### THUMBNAIL_GUIDE.md

구현 가이드 문서입니다.
- 기본 썸네일 생성
- 비동기 처리
- 배치 처리
- 캐싱 활용
- 에러 처리
- 실전 예제

### PERFORMANCE_GUIDE.md

성능 최적화 가이드입니다.
- 성능 측정
- 최적화 전략
- 메모리 관리
- 캐싱 전략
- 병렬 처리
- 실전 최적화

---

## ⚡ 성능 최적화

### 크기 제한

```swift
generator.maximumSize = CGSize(width: 200, height: 200)
```

### 시간 허용 오차

```swift
generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
```

### 캐싱

```swift
// 항상 캐시 확인 후 생성
if let cached = cache.getThumbnail(for: key) {
    return cached
}
```

### 병렬 처리

```swift
try await withThrowingTaskGroup(of: UIImage?.self) { group in
    for time in times {
        group.addTask {
            try? await generator.image(at: time).image
        }
    }
}
```

---

## 🐛 문제 해결

### "유효하지 않은 동영상 파일입니다"

- 파일 형식 확인 (MP4, MOV, M4V 권장)
- 파일 손상 여부 확인

### "유효하지 않은 시간입니다"

- 동영상 길이 확인
- 유효한 시간 범위 내에서 지정

### "이미지 생성에 실패했습니다"

- `maximumSize`로 크기 제한
- 메모리 사용량 확인
- 다른 시간으로 재시도

### 썸네일 생성이 느림

- `maximumSize` 설정으로 크기 제한
- `requestedTimeTolerance` 설정으로 성능 향상
- 캐싱 활용

---

## 📊 성능 측정

### 생성 시간 측정

```swift
let (thumbnail, duration) = await PerformanceMeasurer.measureTime {
    try await ThumbnailGenerator.generateThumbnail(from: url, at: 5.0)
}
print("생성 시간: \(duration)초")
```

### 메모리 사용량 측정

```swift
let memory = PerformanceMeasurer.getMemoryUsage()
print("메모리: \(PerformanceMeasurer.formatMemoryUsage(memory))")
```

---

## ✅ 학습 체크리스트

### 기본

- [ ] 프로젝트를 성공적으로 실행했다
- [ ] SimpleThumbnailView에서 썸네일을 생성했다
- [ ] BatchThumbnailView에서 배치 썸네일을 생성했다
- [ ] ThumbnailGalleryView에서 캐싱을 확인했다

### 이론

- [ ] AVAssetImageGenerator 구조를 이해한다
- [ ] CMTime의 개념을 안다
- [ ] 비동기 처리 패턴을 이해한다
- [ ] 캐싱 전략을 안다

### 가이드

- [ ] AVASSET_THEORY.md를 읽었다
- [ ] THUMBNAIL_GUIDE.md를 읽었다
- [ ] PERFORMANCE_GUIDE.md를 읽었다
- [ ] 실무 활용 사례를 이해했다

---

## 🔗 참고 자료

- [Apple Documentation: AVAssetImageGenerator](https://developer.apple.com/documentation/avfoundation/avassetimagegenerator)
- [Apple Documentation: CMTime](https://developer.apple.com/documentation/coremedia/cmtime)
- [WWDC: Advances in AVFoundation](https://developer.apple.com/videos/play/wwdc2019/506/)

---

## 📝 라이선스

이 프로젝트는 학습 목적으로 제작되었습니다.

---

**즐거운 학습 되세요! 🎬**

