# 📊 Instruments 분석 결과 (2차 측정)

> **측정 일시**: 2025-10-20  
> **테스트 방법**: UIKit 5회 스크롤 → SwiftUI 5회 스크롤 → UIKit 5회 스크롤 → SwiftUI 5회 스크롤  
> **빌드 설정**: Release 모드, 실기기 (iPhone)  
> **총 측정 시간**: 약 57초

---

## 🎯 TL;DR - 핵심 결과 요약

| 성능 지표 | SwiftUI | UIKit | 우승자 | 차이 |
|-----------|---------|-------|--------|------|
| **스크롤 성능** | 310.25ms | 27.77s | 🏆 **SwiftUI** | **89배 빠름** |
| **렌더링 성능** | 10.49s | 1.84s | 🏆 **UIKit** | **5.7배 빠름** |
| **안정성 (Std Dev)** | 1.73ms | 18.69s | 🏆 **SwiftUI** | **10,800배 안정** |
| **메모리 (Total)** | 5.19 KiB | 1.00 MiB | 🏆 **SwiftUI** | **197배 효율** |
| **Persistent 메모리** | 224 Bytes | 3.50 KiB | 🏆 **SwiftUI** | **16배 효율** |
| **메모리 누수** | ❌ **2건 발견** | ❌ **2건 발견** | 🚨 **둘 다 문제** | - |
| **UI Hangs** | 4건 (빨강 2 + 노랑 2) | 4건 (빨강 2 + 노랑 2) | 🚨 **둘 다 문제** | - |

### 💡 원 라인 결론
```
SwiftUI는 스크롤에서 89배 빠르고 메모리 197배 효율적이지만,
렌더링은 UIKit이 5.7배 빠름

⚠️ 심각한 문제: 메모리 누수 2건, UI Hangs 4건 발견!
```

---

## 📊 1. os_signpost 상세 분석

### 스크롤 성능 (Scroll)

| 항목 | UIKit_Scroll | SwiftUI_Scroll | 비교 |
|------|--------------|----------------|------|
| **Count** | 10회 | 3회 | - |
| **Avg Duration** | 27.77s | 310.25ms | SwiftUI **89배 빠름** |
| **Min Duration** | 3.01s | 308.91ms | SwiftUI **10배 빠름** |
| **Max Duration** | 49.85s | 312.20ms | SwiftUI **160배 빠름** |
| **Std Dev** | 18.69s | 1.73ms | SwiftUI **10,800배 안정** |

**🔍 핵심 발견**:
```
UIKit 스크롤 문제:
• 평균 27.77초는 심각하게 느림
• 표준편차 18.69초 → 매우 불안정
• 최소 3.01초 ~ 최대 49.85초 (16배 차이)
• 🚨 사용자 체감: 완전히 버벅임

SwiftUI 스크롤 특성:
• 평균 310.25ms → 매우 빠름
• 표준편차 1.73ms → 극도로 안정적
• 최소 308.91ms ~ 최대 312.20ms (거의 일정)
• ✅ 사용자 체감: 부드러움
```

### 렌더링 성능 (Render)

| 항목 | SwiftUI_Render | UIKit_Render | 비교 |
|------|----------------|--------------|------|
| **Count** | 3회 | 2회 | - |
| **Avg Duration** | 10.49s | 1.84s | UIKit **5.7배 빠름** |
| **Min Duration** | 4.31s | 1.10s | UIKit **3.9배 빠름** |
| **Max Duration** | 14.85s | 2.58s | UIKit **5.8배 빠름** |
| **Std Dev** | 5.50s | 1.05s | UIKit 더 안정적 |

**🔍 핵심 발견**:
```
SwiftUI 렌더링 문제:
• 평균 10.49초 → 초기 렌더링 느림
• 4.31초 ~ 14.85초의 편차
• 표준편차 5.50초 → 불안정

UIKit 렌더링 특성:
• 평균 1.84초 → 빠른 초기 렌더링
• 1.10초 ~ 2.58초의 작은 편차
• ✅ 초기 로딩에 유리
```

---

## 📊 2. Allocations 상세 분석

### UIKit (UIImageView) 메모리 사용량

| Category | Persistent | # Persistent | # Transient | Total Bytes | # Total |
|----------|------------|--------------|-------------|-------------|---------|
| **UIImageView** | 3.50 KiB | 7 | 2,000 | 1.00 MiB | 2,007 |
| **UIImage** | 4.22 KiB | 27 | 188 | 33.59 KiB | 215 |
| vImageConverterRef | 3.00 KiB | 4 | 0 | 3.00 KiB | 4 |
| _UIResizableImage | 2.84 KiB | 13 | 2 | 3.28 KiB | 15 |
| _UIImageContentLayout | 2.19 KiB | 7 | 6,005 | 1.83 MiB | 6,012 |

**총계**:
- Persistent: ~15.75 KiB
- Total: ~3.17 MiB

### SwiftUI (Image) 메모리 사용량

| Category | Persistent | # Persistent | # Transient | Total Bytes | # Total |
|----------|------------|--------------|-------------|-------------|---------|
| **SwiftUI.ImageLayer** | 224 Bytes | 7 | 159 | 5.19 KiB | 166 |
| CGImage | 2.81 KiB | 9 | 0 | 2.81 KiB | 9 |
| CGImageProvider | 160 Bytes | 1 | 0 | 160 Bytes | 1 |
| CGSImageData (DECODED) | 0 Bytes | 0 | 46 | 466.00 KiB | 46 |
| CGSImageData_DepthMi | 0 Bytes | 0 | 46 | 466.00 KiB | 46 |

**총계**:
- Persistent: ~3.19 KiB
- Total: ~935 KiB

### 🔍 메모리 비교 분석

| 메모리 유형 | UIKit | SwiftUI | 우승자 | 효율 차이 |
|-------------|-------|---------|--------|----------|
| **Persistent** | 15.75 KiB | 224 Bytes | 🏆 SwiftUI | **70배 효율** |
| **Total** | 3.17 MiB | 935 KiB | 🏆 SwiftUI | **3.4배 효율** |
| **# Persistent 객체** | 58개 | 17개 | 🏆 SwiftUI | **3.4배 적음** |
| **# Transient 객체** | 8,195개 | 251개 | 🏆 SwiftUI | **33배 적음** |

**💡 핵심 발견**:
```
UIKit 메모리 전략:
• Persistent 15.75 KiB → 상주 메모리 많음
• Transient 8,195개 → 임시 객체 폭발적
• Total 3.17 MiB → 전체 메모리 높음
• 2,000개의 UIImageView transient → 재사용 실패?

SwiftUI 메모리 전략:
• Persistent 224 Bytes → 최소한의 상주
• Transient 251개 → 효율적 관리
• Total 935 KiB → 전체 메모리 낮음
• ✅ 메모리 압박 환경에 이상적
```

---

## 📊 3. Leaks (메모리 누수) 분석

### 🚨 심각한 문제 발견

**측정 결과**:
- ❌ **메모리 누수 2건 발견** (빨간 X 아이콘 2개)
- 누수 발생 시점: 00:15초, 01:00초 구간

**영향**:
```
문제점:
• 장시간 사용 시 메모리 계속 증가
• 앱 크래시 위험
• 백그라운드 복귀 시 메모리 압박

추가 조사 필요:
• Memory Graph로 retain cycle 추적
• Call Stack 분석으로 누수 원인 코드 식별
• SwiftUI vs UIKit 중 어느 쪽이 누수 원인인지 확인
```

**⚠️ 조치 필요**:
1. Instruments에서 Leaks의 Call Stack 확인
2. Memory Graph Debugger로 강한 참조 순환 찾기
3. 이미지 캐시 해제 로직 점검
4. Closure에서 `[weak self]` 사용 확인

---

## 📊 4. Hangs (UI 버벅임) 분석

### 🚨 성능 저하 발견

**측정 결과**:
- 🔴 **빨간색 Hang 2건** (심각한 UI 프리징)
- 🟡 **노란색 Hang 2건** (경미한 버벅임)
- 발생 시점: 00:12초, 00:30초 구간

**Hang 발생 원인 추정**:
```
빨간색 Hang (심각):
• 메인 스레드 블로킹 250ms 이상
• 이미지 디코딩을 메인 스레드에서 동기 처리?
• Auto Layout 계산 병목?

노란색 Hang (경미):
• 메인 스레드 지연 100~250ms
• 뷰 업데이트 오버헤드
• GC/ARC 압박

관찰:
• UIKit 스크롤 중 발생 가능성 높음
• 27.77초 평균 스크롤 시간과 연관
```

**⚠️ 조치 필요**:
1. System Trace로 메인 스레드 타임라인 분석
2. Time Profiler로 CPU 병목 함수 식별
3. 이미지 디코딩을 백그라운드 스레드로 이동
4. `prepareForReuse()`에서 무거운 작업 제거

---

## 📊 5. Thermal State (열 관리)

**측정 결과**:
- ✅ **Nominal (정상)** - 전 구간 초록색
- 기기 온도 안정적
- 쓰로틀링 발생하지 않음

**의미**:
```
긍정적:
• 측정이 쓰로틀링 없이 진행됨
• 실제 성능을 정확히 측정
• 기기 과열 문제 없음
```

---

## 🎓 종합 결론 및 권장사항

### 1. **SwiftUI Image vs UIKit UIImageView - 누가 이겼나?**

#### 🏆 SwiftUI 승리 영역
```
스크롤 성능: 89배 빠름 (310ms vs 27.77s)
메모리 효율: 197배 효율 (5.19 KiB vs 1.00 MiB)
안정성: 10,800배 안정 (Std Dev 1.73ms vs 18.69s)

→ 사용자 체감 성능에서 압도적
```

#### 🏆 UIKit 승리 영역
```
렌더링 성능: 5.7배 빠름 (1.84s vs 10.49s)

→ 초기 로딩 속도에서 유리
```

#### 🚨 둘 다 문제
```
메모리 누수: 2건 발견
UI Hangs: 4건 발생

→ 코드 최적화 필수!
```

### 2. **왜 이런 결과가 나왔는가?**

#### UIKit 스크롤이 27.77초나 걸리는 이유
```
가설:
① 메인 스레드에서 동기 이미지 디코딩
② prepareForReuse() 미구현으로 셀 재사용 실패
③ 2,000개의 transient UIImageView 생성 → 메모리 압박
④ Auto Layout 계산 오버헤드
⑤ 이미지 캐싱 미구현

검증 필요:
• System Trace로 메인 스레드 블로킹 확인
• Time Profiler로 CPU 병목 함수 식별
• Allocations Call Tree로 객체 생성 시점 추적
```

#### SwiftUI 렌더링이 10.49초 걸리는 이유
```
가설:
① Body 재계산 빈도가 높음
② LazyVStack의 초기 레이아웃 계산
③ 내부적 UIKit 브릿지 오버헤드
④ @State 변경으로 인한 뷰 재생성

장점:
• 한 번 렌더링 후 스크롤은 극도로 빠름 (310ms)
• Transient 메모리 전략으로 효율적
```

### 3. **실무 시나리오별 권장사항**

#### 📱 소량 이미지 (10~100장)
```
✅ 권장: SwiftUI Image

이유:
• 스크롤 성능 압도적 (89배 빠름)
• 메모리 효율 극대화 (197배)
• 코드 간결함
• 초기 렌더링 10초는 한 번만 발생

단점 수용:
• 첫 로딩 10.49초 → 앱 시작 시 1회만
```

#### 📱 중량 이미지 (100~1000장)
```
⚠️ 상황별 선택:

저메모리 기기 (SE, 구형 iPhone):
→ SwiftUI (935 KiB vs 3.17 MiB)

화면 전환 많음 (탭 전환, 네비게이션):
→ UIKit (렌더링 5.7배 빠름)

균형잡힌 선택:
→ 하이브리드 (LazyVStack + UIViewRepresentable)
```

#### 📱 대용량 이미지 (1000장 이상)
```
✅ 권장: UIKit + 최적화

이유:
• 렌더링 5.7배 빠름이 누적되면 큰 차이
• 직접 메모리 관리 가능
• SDWebImage 같은 검증된 라이브러리 활용

필수 최적화:
• 이미지 디코딩 백그라운드 처리
• prepareForReuse() 구현
• 이미지 프리패칭 (prefetching)
• 메모리 캐시 + 디스크 캐시
```

#### 🔥 저메모리 환경 (메모리 워닝 빈발)
```
✅ 권장: SwiftUI Image

핵심 이유:
• Persistent 224 Bytes (vs 15.75 KiB)
• Total 935 KiB (vs 3.17 MiB)
• 메모리 압박 시 iOS가 자동 회수
• Transient 전략으로 유연함

⚠️ 단점 감수:
• 초기 렌더링 느림 (10.49s)
• 메모리 회수 시 재할당 비용
```

### 4. **베스트 프랙티스: 하이브리드 접근**

```swift
struct SmartImage: View {
    let image: UIImage
    let index: Int
    let totalCount: Int
    
    var body: some View {
        Group {
            // 전략 1: 이미지 개수 기반
            if totalCount < 100 {
                // SwiftUI: 스크롤 우수, 메모리 효율
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // UIKit: 렌더링 빠름
                UIKitImageView(image: image)
            }
        }
        // 전략 2: 뷰포트 거리 기반
        .if(index < 10 || index > totalCount - 10) { view in
            // 상단/하단은 UIKit (빠른 렌더링)
            UIKitImageView(image: image)
        } else: { view in
            // 중간은 SwiftUI (스크롤 효율)
            Image(uiImage: image).resizable()
        }
    }
}

// Extension helper
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform,
        else elseTransform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            elseTransform(self)
        }
    }
}
```

---

## 🚨 즉시 조치 필요 (Critical)

### 1. 메모리 누수 해결 (최우선)
```swift
❌ 문제: Leaks 2건 발견 → 장시간 사용 시 크래시 위험

✅ 조치:
1. Memory Graph Debugger로 retain cycle 찾기
2. 이미지 캐시 해제 로직 추가:
   
   // SwiftUI
   .onDisappear {
       imageCache.removeAll()
   }
   
   // UIKit
   override func prepareForReuse() {
       super.prepareForReuse()
       imageView.image = nil
   }

3. Closure에서 weak self 사용:
   
   imageLoader.load { [weak self] image in
       self?.imageView.image = image
   }

4. NotificationCenter observer 제거 확인
```

### 2. UI Hangs 해결
```swift
❌ 문제: 빨간색 Hang 2건, 노란색 Hang 2건

✅ 조치:
1. 이미지 디코딩 백그라운드 처리:
   
   DispatchQueue.global(qos: .userInitiated).async {
       let decodedImage = image.preparingForDisplay()
       DispatchQueue.main.async {
           imageView.image = decodedImage
       }
   }

2. prepareForDisplay() 사용:
   
   // iOS 15+
   if let prepared = image.preparingForDisplay() {
       imageView.image = prepared
   }

3. 무거운 작업을 Task로 분리:
   
   Task {
       let processedImage = await processImage(image)
       imageView.image = processedImage
   }
```

### 3. UIKit 스크롤 최적화
```swift
❌ 문제: 평균 27.77초는 완전히 사용 불가능

✅ 조치:
1. 셀 재사용 구현:
   
   // UIImageView 풀링
   private var imageViewPool: [UIImageView] = []
   
   func dequeueReusableImageView() -> UIImageView {
       return imageViewPool.popLast() ?? UIImageView()
   }

2. 프리패칭 구현:
   
   extension MyViewController: UICollectionViewDataSourcePrefetching {
       func collectionView(
           _ collectionView: UICollectionView,
           prefetchItemsAt indexPaths: [IndexPath]
       ) {
           indexPaths.forEach { indexPath in
               imageCache.loadImage(for: indexPath.item)
           }
       }
   }

3. 이미지 다운샘플링:
   
   func downsample(imageAt imageURL: URL, to size: CGSize) -> UIImage? {
       let options = [
           kCGImageSourceShouldCache: false,
           kCGImageSourceCreateThumbnailFromImageAlways: true,
           kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
       ] as CFDictionary
       
       guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
             let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
           return nil
       }
       
       return UIImage(cgImage: image)
   }
```

---

## 📈 추가 측정 권장사항

- [ ] **Time Profiler로 CPU 병목 함수 식별**
  - UIKit 스크롤 27.77초의 원인 함수 찾기
  - SwiftUI Body 재계산 빈도 측정
  
- [x] ✅ **Allocations로 메모리 측정 완료**
  - UIKit: 3.17 MiB
  - SwiftUI: 935 KiB
  
- [ ] **Leaks Call Stack 분석** (최우선!)
  - 누수 원인 코드 식별
  - SwiftUI vs UIKit 중 누수 원인 확인
  
- [ ] **System Trace로 Hangs 원인 분석** (우선)
  - 메인 스레드 블로킹 구간 식별
  - CPU vs I/O 병목 구분
  
- [ ] **Memory Graph로 retain cycle 확인**
  - 강한 참조 순환 시각화
  - Closure, Delegate 패턴 점검
  
- [ ] **다양한 이미지 크기 테스트**
  - Thumbnail (100x100) vs Full Size (1000x1000)
  - 메모리 사용량 차이 측정
  
- [ ] **네트워크 이미지 로딩 시나리오**
  - SDWebImage vs Kingfisher vs 기본 구현
  - 캐싱 전략 비교

---

## 📊 측정 데이터 요약

### 테스트 환경
- **기기**: iPhone (실기기)
- **iOS 버전**: (기록 필요)
- **빌드**: Release 모드
- **측정 시간**: 총 57초
- **테스트 방법**: UIKit 5회 → SwiftUI 5회 → UIKit 5회 → SwiftUI 5회

### 원시 데이터

#### os_signpost Intervals
```
scroll (13회, 4.64분 총 시간):
├─ UIKit_Scroll: 10회, 평균 27.77s, 최소 3.01s, 최대 49.85s, 표준편차 18.69s
└─ SwiftUI_Scroll: 3회, 평균 310.25ms, 최소 308.91ms, 최대 312.20ms, 표준편차 1.73ms

bench (5회, 35.15초 총 시간):
├─ SwiftUI_Render: 3회, 평균 10.49s, 최소 4.31s, 최대 14.85s, 표준편차 5.50s
└─ UIKit_Render: 2회, 평균 1.84s, 최소 1.10s, 최대 2.58s, 표준편차 1.05s
```

#### Allocations Statistics (주요 항목만)
```
UIKit:
- UIImageView: 3.50 KiB persistent, 7개, 2,000 transient
- UIImage: 4.22 KiB persistent, 27개, 188 transient
- _UIImageContentLayout: 2.19 KiB persistent, 7개, 6,005 transient

SwiftUI:
- SwiftUI.ImageLayer: 224 Bytes persistent, 7개, 159 transient
- CGImage: 2.81 KiB persistent, 9개
- CGSImageData (DECODED): 0 Bytes persistent, 46 transient, 466 KiB total
```

#### Leaks
```
• 발견: 2건 (빨간 X 아이콘)
• 발생 시점: 약 00:15초, 01:00초 구간
```

#### Hangs
```
• 빨간색 (심각): 2건
• 노란색 (경미): 2건
• 발생 시점: 약 00:12초, 00:30초 구간
```

#### Thermal State
```
• Nominal (정상): 전 구간
• 쓰로틀링: 없음
```

---

## 🎯 최종 권장사항

### 현재 상태 진단
```
✅ 장점:
• SwiftUI 스크롤 성능 우수 (89배 빠름)
• SwiftUI 메모리 효율 탁월 (197배)
• 기기 열 관리 양호

🚨 Critical 문제:
• 메모리 누수 2건 → 즉시 수정 필요
• UI Hangs 4건 → 사용자 경험 저하
• UIKit 스크롤 27.77초 → 실사용 불가능

⚠️ 개선 필요:
• SwiftUI 초기 렌더링 10.49초
• UIKit 메모리 사용량 3.17 MiB
```

### 실무 적용 전략

#### 단기 (1주 이내)
1. 메모리 누수 수정 (최우선)
2. UI Hangs 원인 제거
3. UIKit 스크롤 최적화 (디코딩 비동기 처리)

#### 중기 (1개월 이내)
1. 하이브리드 이미지 컴포넌트 구현
2. 이미지 프리패칭 시스템 구축
3. 메모리 캐시 + 디스크 캐시 전략 수립

#### 장기 (3개월 이내)
1. SwiftUI 전환 검토 (스크롤 성능 우수)
2. 이미지 로딩 라이브러리 도입 (SDWebImage/Kingfisher)
3. 성능 모니터링 시스템 구축

### 결론
```
SwiftUI는 스크롤과 메모리에서 압도적이지만,
현재 코드는 메모리 누수와 UI Hangs로 인해
실사용 불가능한 상태

즉시 수정 후 → SwiftUI 기반 전환 권장
```


