# Day 19: GIF / 애니메이션 이미지 다루기

> iOS에서 GIF와 애니메이션 이미지를 다루는 다양한 방법을 학습하는 프로젝트

---

## 📋 프로젝트 개요

이 프로젝트는 iOS에서 GIF 애니메이션을 로딩하고 렌더링하는 세 가지 주요 방법을 비교하고 학습합니다:

1. **UIImageView + UIImage.animatedImage**: UIKit 네이티브 방법
2. **SwiftUI 커스텀 구현**: CGImageSource를 활용한 커스텀 구현
3. **Nuke 라이브러리**: 고성능 이미지 로딩 라이브러리 활용

---

## 🎯 학습 목표

- GIF 포맷 구조 이해
- CGImageSource를 사용한 GIF 파싱
- UIKit과 SwiftUI에서 GIF 재생 구현
- 성능 최적화 전략 학습
- 메모리 및 CPU 효율적인 GIF 처리

---

## 🏗️ 프로젝트 구조

```
day19/
├── day19/
│   ├── Core/
│   │   ├── GIFParser.swift          # GIF 파싱 로직
│   │   └── GIFAnimator.swift        # 애니메이션 재생 로직
│   ├── Views/
│   │   ├── ContentView.swift        # 메인 뷰 (탭 네비게이션)
│   │   ├── UIImageViewGIFView.swift # UIKit 기반 GIF 뷰
│   │   ├── SwiftUIGIFView.swift     # SwiftUI 커스텀 GIF 뷰
│   │   ├── NukeGIFView.swift        # Nuke 기반 GIF 뷰
│   │   └── GIFComparisonView.swift # 세 방법 비교 뷰
│   └── tool/
│       └── GIFPerformanceMonitor.swift # 성능 모니터링 도구
├── GIF_THEORY.md                    # GIF 이론 설명
├── PERFORMANCE_GUIDE.md            # 성능 최적화 가이드
├── 시작하기.md                      # 빠른 시작 가이드
└── README.md                        # 프로젝트 개요
```

---

## 🚀 빠른 시작

### 1. 프로젝트 열기

```bash
cd day19
open day19.xcodeproj
```

### 2. 패키지 다운로드

Xcode가 자동으로 SPM 패키지를 다운로드합니다:
- **Nuke**: 이미지 로딩 라이브러리

### 3. 빌드 및 실행

```
⌘R (Run)
```

### 4. 앱 사용

4개 탭을 통해 각 방법을 체험할 수 있습니다:
- **UIImageView**: UIKit 기본 방법
- **SwiftUI**: 커스텀 구현
- **Nuke**: 라이브러리 활용
- **비교**: 성능 비교

---

## 📚 주요 기능

### 1. GIF 파싱 (GIFParser)

CGImageSource를 사용하여 GIF 파일을 파싱하고 프레임 정보를 추출합니다.

**주요 기능**:
- 프레임 추출
- 딜레이 정보 파싱
- 루프 정보 추출
- 메타데이터 읽기

**사용 예시**:
```swift
let parser = GIFParser(url: gifURL)
let frames = try await parser.parseFrames()
// frames: [GIFFrame] - 각 프레임의 이미지와 딜레이 정보
```

### 2. GIF 애니메이션 (GIFAnimator)

파싱된 프레임을 사용하여 애니메이션을 재생합니다.

**주요 기능**:
- 프레임 타이밍 제어
- 루프 처리
- 재생/일시정지 제어
- 메모리 효율적인 프레임 관리

**사용 예시**:
```swift
let animator = GIFAnimator(frames: frames)
animator.start()
animator.pause()
animator.resume()
```

### 3. UIKit 기반 GIF 뷰 (UIImageViewGIFView)

UIImageView와 UIImage.animatedImage를 사용한 기본 구현입니다.

**특징**:
- 간단한 구현
- 모든 프레임을 메모리에 로드
- 작은 GIF에 적합

### 4. SwiftUI 커스텀 GIF 뷰 (SwiftUIGIFView)

CGImageSource를 활용한 커스텀 구현입니다.

**특징**:
- 지연 로딩 지원
- 프레임 캐싱
- 메모리 효율적
- 큰 GIF 처리 가능

### 5. Nuke 기반 GIF 뷰 (NukeGIFView)

Nuke 라이브러리를 활용한 고성능 구현입니다.

**특징**:
- 네트워크 GIF 지원
- 자동 캐싱
- 최적화된 디코딩
- 프로덕션 레벨 성능

### 6. 성능 비교 (GIFComparisonView)

세 가지 방법을 동시에 비교하여 성능 차이를 확인합니다.

**비교 항목**:
- 메모리 사용량
- CPU 사용량
- 로딩 시간
- 프레임 레이트

---

## 🔧 핵심 구현

### GIF 파싱

```swift
import ImageIO

class GIFParser {
    func parseFrames() async throws -> [GIFFrame] {
        guard let imageSource = CGImageSourceCreateWithURL(url, nil) else {
            throw GIFError.invalidSource
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        var frames: [GIFFrame] = []
        
        for index in 0..<frameCount {
            // 프레임 이미지 추출
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
                continue
            }
            
            // 딜레이 정보 추출
            let delay = extractDelay(from: imageSource, at: index)
            
            let frame = GIFFrame(
                image: UIImage(cgImage: cgImage),
                delay: delay
            )
            frames.append(frame)
        }
        
        return frames
    }
}
```

### 애니메이션 재생

```swift
class GIFAnimator {
    private var displayLink: CADisplayLink?
    private var currentFrameIndex = 0
    private var accumulatedTime: TimeInterval = 0
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateFrame(_ displayLink: CADisplayLink) {
        let deltaTime = displayLink.duration
        accumulatedTime += deltaTime
        
        let currentDelay = frames[currentFrameIndex].delay
        
        if accumulatedTime >= currentDelay {
            showFrame(at: currentFrameIndex)
            currentFrameIndex = (currentFrameIndex + 1) % frames.count
            accumulatedTime = 0
        }
    }
}
```

---

## 📖 학습 자료

### 이론 문서

- **GIF_THEORY.md**: GIF 포맷 구조와 iOS 처리 방법 상세 설명
- **PERFORMANCE_GUIDE.md**: 성능 최적화 전략과 실전 팁
- **시작하기.md**: 빠른 시작 가이드 및 학습 순서

### 코드 파일

#### Core 모듈
- `GIFParser.swift`: GIF 파싱 로직
- `GIFAnimator.swift`: 애니메이션 재생 로직

#### Views 모듈
- `UIImageViewGIFView.swift`: UIKit 구현
- `SwiftUIGIFView.swift`: SwiftUI 구현
- `NukeGIFView.swift`: Nuke 구현
- `GIFComparisonView.swift`: 비교 뷰

#### 도구
- `GIFPerformanceMonitor.swift`: 성능 모니터링

---

## ⚡ 성능 최적화

### 메모리 최적화

1. **지연 로딩**: 필요한 프레임만 메모리에 로드
2. **프레임 캐싱**: 최근 사용한 프레임만 캐시 유지
3. **다운샘플링**: 큰 GIF를 작은 크기로 변환

### CPU 최적화

1. **백그라운드 디코딩**: 메인 스레드 블로킹 방지
2. **CADisplayLink**: 정확한 프레임 타이밍
3. **프레임 드롭 감지**: 성능 저하 시 품질 조정

### 배터리 최적화

1. **화면 가시성 감지**: 보이지 않을 때 일시정지
2. **백그라운드 일시정지**: 앱이 백그라운드로 이동 시 정지
3. **저전력 모드 대응**: 배터리 부족 시 프레임 레이트 감소

자세한 내용은 **PERFORMANCE_GUIDE.md**를 참고하세요.

---

## 🎓 학습 순서

### 1단계: 이론 학습 (30분)
1. GIF_THEORY.md 읽기
2. GIF 포맷 구조 이해
3. CGImageSource 개념 학습

### 2단계: 기본 실습 (40분)
1. UIImageViewGIFView 실행 및 코드 분석
2. SwiftUIGIFView 실행 및 코드 분석
3. NukeGIFView 실행 및 코드 분석

### 3단계: 비교 분석 (30분)
1. GIFComparisonView에서 성능 비교
2. 각 방법의 장단점 파악
3. 사용 사례별 선택 기준 이해

### 4단계: 최적화 학습 (20분)
1. PERFORMANCE_GUIDE.md 읽기
2. 최적화 기법 이해
3. 실제 적용 방법 학습

---

## 🔍 주요 개념

### GIF 포맷

- **프레임**: 애니메이션을 구성하는 각 정지 이미지
- **딜레이**: 각 프레임의 표시 시간 (1/100초 단위)
- **루프**: 애니메이션 반복 횟수 (0 = 무한)

### CGImageSource

- Image I/O 프레임워크의 핵심 클래스
- 다양한 이미지 포맷 지원
- 메모리 효율적인 디코딩

### 프레임 타이밍

- **CADisplayLink**: 화면 새로고침과 동기화된 타이머
- **Timer**: 일반적인 타이머 (정확도 낮음)
- **프레임 드롭**: 예상 시간보다 늦게 표시되는 프레임

---

## 🐛 문제 해결

### 일반적인 문제

**Q: GIF가 재생되지 않아요**
- 파일 형식 확인 (GIF인지 확인)
- URL 유효성 확인
- 메모리 부족 여부 확인

**Q: 애니메이션이 느려요**
- 프레임 레이트 확인
- CPU 사용량 확인
- 백그라운드 디코딩 적용 여부 확인

**Q: 메모리 경고가 발생해요**
- 지연 로딩 구현 확인
- 프레임 캐시 크기 확인
- 다운샘플링 적용 고려

자세한 문제 해결 방법은 **시작하기.md**를 참고하세요.

---

## 📊 성능 비교

### 작은 GIF (< 1MB)

| 방법 | 메모리 | CPU | 구현 난이도 |
|------|--------|-----|------------|
| UIImageView | 높음 | 낮음 | 쉬움 |
| SwiftUI | 중간 | 중간 | 중간 |
| Nuke | 낮음 | 낮음 | 쉬움 |

### 큰 GIF (> 5MB)

| 방법 | 메모리 | CPU | 구현 난이도 |
|------|--------|-----|------------|
| UIImageView | 매우 높음 | 낮음 | 쉬움 |
| SwiftUI | 낮음 | 중간 | 중간 |
| Nuke | 낮음 | 낮음 | 쉬움 |

**결론**: 큰 GIF는 SwiftUI 커스텀 구현 또는 Nuke 사용 권장

---

## ✅ 체크리스트

### 기본 기능
- [ ] GIF 파일 파싱
- [ ] 프레임 추출
- [ ] 애니메이션 재생
- [ ] 재생/일시정지 제어

### 최적화
- [ ] 지연 로딩 구현
- [ ] 프레임 캐싱
- [ ] 메모리 모니터링
- [ ] 성능 측정

### 학습
- [ ] 이론 문서 읽기
- [ ] 코드 분석
- [ ] 성능 비교
- [ ] 최적화 적용

---

## 📚 참고 자료

### 공식 문서
- [Image I/O Framework](https://developer.apple.com/documentation/imageio)
- [CGImageSource](https://developer.apple.com/documentation/coregraphics/cgimagesource)
- [Nuke Documentation](https://kean.blog/nuke/guides/welcome)

### 관련 프로젝트
- **Day 8**: URLSession 기초
- **Day 9**: 이미지 로딩 라이브러리 비교
- **Day 14**: 썸네일 갤러리

---

## 🎉 완료 후

Day 19를 완료했다면:

1. **복습**: 핵심 개념 정리
2. **응용**: 나만의 GIF 뷰어 만들기
3. **공유**: 배운 내용 정리하기
4. **다음**: 동영상 처리 기능 학습

---

**Happy Coding! 🎬**

*GIF 애니메이션의 모든 것을 배우고 최적화된 구현을 만들어보세요!*

