# SwiftUI Image 기본 개념

> SwiftUI의 `Image`는 단순한 이미지 표시를 넘어 강력한 View 프로토콜 기반의 선언적 렌더링 시스템입니다.

---

## 📚 목차

1. [SwiftUI Image란?](#swiftui-image란)
2. [UIImage vs SwiftUI Image](#uiimage-vs-swiftui-image)
3. [View 프로토콜로서의 Image](#view-프로토콜로서의-image)
4. [렌더링 파이프라인](#렌더링-파이프라인)
5. [Lazy Loading](#lazy-loading)

---

## SwiftUI Image란?

### 정의

```swift
@frozen public struct Image : View {
    // SwiftUI의 선언적 이미지 뷰
}
```

**핵심 특징**:
- `View` 프로토콜을 채택한 구조체
- 불변(Immutable) 구조
- 선언적 API
- 자동 최적화

### 생성 방법

```swift
// 1. Asset Catalog
Image("sample")

// 2. SF Symbols
Image(systemName: "star.fill")

// 3. UIImage에서 변환
Image(uiImage: myUIImage)

// 4. CGImage에서
if let cgImage = myCGImage {
    Image(cgImage, scale: 2.0, label: Text("Label"))
}
```

---

## UIImage vs SwiftUI Image

### 근본적 차이

| 측면 | UIImage | SwiftUI Image |
|------|---------|---------------|
| **타입** | 클래스 (참조형) | 구조체 (값형) |
| **역할** | 데이터 모델 | View |
| **스레드 안전** | ❌ 메인 스레드 필요 | ✅ 값 타입이라 안전 |
| **메모리** | 힙 할당 | 스택 할당 |
| **수정** | 가능 | 불가 (새 인스턴스 생성) |

### 메모리 모델

#### UIImage (Reference Type)
```swift
let image1 = UIImage(named: "sample")  // 힙에 할당
let image2 = image1                     // 참조 복사
// image1, image2는 같은 메모리 가리킴
```

#### SwiftUI Image (Value Type)
```swift
let image1 = Image("sample")  // 스택에 할당
let image2 = image1           // 값 복사
// image1, image2는 독립적 (실제로는 COW 최적화)
```

**Copy-on-Write (COW)**:
- SwiftUI는 실제로 복사가 일어날 때까지 메모리 공유
- 수정이 발생하면 그때 새 복사본 생성
- 성능 최적화 자동 적용

---

## View 프로토콜로서의 Image

### View로서의 특성

```swift
// Image는 View 프로토콜 준수
struct ContentView: View {
    var body: some View {
        Image("sample")              // ✅ View로 직접 사용
            .resizable()             // ✅ View modifier 적용
            .frame(width: 200, height: 200)
    }
}
```

### 조합 가능성 (Composability)

```swift
// 다른 View와 자유롭게 조합
VStack {
    Image("header")
    Text("Title")
    HStack {
        Image(systemName: "star")
        Image(systemName: "heart")
    }
}
```

### 수정자 체이닝 (Modifier Chaining)

```swift
Image("sample")
    .resizable()              // 크기 조정 가능
    .interpolation(.high)     // 보간 품질
    .aspectRatio(contentMode: .fit)  // 비율 유지
    .frame(width: 300, height: 200)  // 프레임 설정
    .clipShape(RoundedRectangle(cornerRadius: 20))  // 모양 자르기
    .shadow(radius: 10)       // 그림자
```

**특징**:
- 각 modifier는 새 View를 반환
- 불변성 유지
- 순서가 중요 (파이프라인 처리)

---

## 렌더링 파이프라인

### SwiftUI 렌더링 단계

```
1. View 선언
   ↓
2. View Graph 구성
   ↓
3. 레이아웃 계산
   ↓
4. 렌더링 (Core Animation)
   ↓
5. 화면 출력
```

### Image 렌더링 흐름

```swift
Image("sample")
    .resizable()          // 1️⃣ 리사이즈 가능 표시
    .interpolation(.high) // 2️⃣ 보간 품질 설정
    .frame(width: 200)    // 3️⃣ 레이아웃 크기 제안
```

**실제 처리**:
1. **선언 단계**: 렌더링 지시만 저장 (실제 실행 X)
2. **레이아웃 단계**: 부모 뷰가 크기 제안
3. **렌더링 단계**: 실제 이미지 디코딩 및 스케일링
4. **캐싱**: 렌더링 결과 자동 캐싱

### 실제 예제

```swift
struct ImagePipelineView: View {
    var body: some View {
        Image("large-photo")  // ① Asset 참조만 저장
            .resizable()      // ② 렌더링 옵션 기록
            .frame(width: 300, height: 300)  // ③ 크기 제안
        // 여기까지는 실제 이미지 로드 안됨!
    }
}

// ④ 화면에 실제 표시될 때 렌더링 발생
```

**최적화**:
- 화면 밖 이미지는 렌더링 안함 (Lazy)
- 동일 이미지는 캐시에서 재사용
- 디바이스 스케일 자동 고려 (@2x, @3x)

---

## Lazy Loading

### 개념

SwiftUI Image는 **지연 로딩(Lazy Loading)**을 자동으로 수행합니다.

```swift
ScrollView {
    ForEach(0..<1000) { i in
        Image("photo-\(i)")  // 1000개 선언
            .resizable()
            .frame(width: 300, height: 200)
    }
}
// ✅ 화면에 보이는 것만 렌더링
// ✅ 스크롤하면 동적으로 로드/해제
```

### LazyVStack과의 조합

```swift
ScrollView {
    LazyVStack {  // View 자체도 lazy 생성
        ForEach(photos) { photo in
            Image(photo.name)  // 이미지도 lazy 렌더링
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
        }
    }
}
```

**이중 최적화**:
1. `LazyVStack`: View 인스턴스 지연 생성
2. `Image`: 이미지 렌더링 지연 실행

### 메모리 효율

```swift
// ❌ UIKit 방식 (모든 이미지 로드)
for i in 0..<100 {
    let imageView = UIImageView(image: UIImage(named: "photo-\(i)"))
    // 메모리: 100개 × 10MB = 1GB 💥
}

// ✅ SwiftUI 방식 (보이는 것만)
ScrollView {
    LazyVStack {
        ForEach(0..<100) { i in
            Image("photo-\(i)")
                .resizable()
                .frame(height: 200)
        }
    }
}
// 메모리: 화면에 보이는 ~5개 × 10MB = 50MB ✅
```

---

## 렌더링 최적화

### Asset Catalog 최적화

**자동 최적화**:
```
sample.imageset/
  ├── sample.png      (1x)
  ├── sample@2x.png   (2x)
  └── sample@3x.png   (3x)
```

SwiftUI가 자동으로 디바이스에 맞는 이미지 선택:
- iPhone 15 Pro: @3x 사용
- iPad: @2x 사용
- Mac: @1x 또는 @2x

### Interpolation 최적화

```swift
// 큰 이미지를 작게 표시
Image("4K-photo")
    .resizable()
    .interpolation(.medium)  // 기본값, 균형 잡힌 품질
    .frame(width: 100, height: 100)

// 작은 아이콘을 크게 확대
Image(systemName: "star")
    .resizable()
    .interpolation(.none)    // 픽셀 아트 스타일
    .frame(width: 200, height: 200)
```

### 동적 해상도 적용

```swift
// Retina 디스플레이 고려
Image(uiImage: myUIImage)
    .resizable()
    .frame(width: 100, height: 100)
// 실제 렌더링: 200×200 (2x) 또는 300×300 (3x)
```

---

## 실무 활용 패턴

### 1. 조건부 이미지 로딩

```swift
struct AdaptiveImage: View {
    let name: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image(colorScheme == .dark ? "\(name)-dark" : name)
            .resizable()
    }
}
```

### 2. 비동기 이미지 로딩

```swift
struct AsyncImageView: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "photo")
            @unknown default:
                EmptyView()
            }
        }
    }
}
```

### 3. 플레이스홀더 패턴

```swift
struct ImageWithPlaceholder: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background(
                Color.gray.opacity(0.2)  // 로드 전 배경
            )
    }
}
```

---

## 성능 고려사항

### Do's ✅

```swift
// ✅ Asset Catalog 사용
Image("sample")

// ✅ SF Symbols 활용
Image(systemName: "star.fill")

// ✅ resizable() 먼저 호출
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 200)

// ✅ LazyVStack/LazyHStack 사용
ScrollView {
    LazyVStack {
        ForEach(images) { img in
            Image(img.name).resizable()
        }
    }
}
```

### Don'ts ❌

```swift
// ❌ UIImage를 매번 생성
Image(uiImage: UIImage(named: "sample")!)  // 비효율

// ❌ resizable() 없이 frame 사용
Image("large-photo")
    .frame(width: 100)  // 원본 크기로 렌더링 후 클리핑

// ❌ VStack에 많은 이미지
VStack {  // Lazy 아님!
    ForEach(0..<1000) { i in
        Image("photo-\(i)")  // 모두 즉시 생성
    }
}

// ❌ 고해상도 이미지를 작게 표시
Image("8K-photo")  // 48MB
    .resizable()
    .frame(width: 50, height: 50)  // 메모리 낭비
// 해결: 썸네일 이미지 사용
```

---

## 핵심 정리

### SwiftUI Image의 특징

1. **값 타입**: 구조체, 불변성, 스레드 안전
2. **View 프로토콜**: 다른 View와 자유로운 조합
3. **선언적**: 무엇을 표시할지만 명시
4. **Lazy Loading**: 필요할 때만 렌더링
5. **자동 최적화**: 디바이스 스케일, 캐싱

### 렌더링 최적화

1. Asset Catalog 활용 (@1x, @2x, @3x)
2. `resizable()` 먼저 호출
3. `LazyVStack`/`LazyHStack` 사용
4. 적절한 `interpolation` 선택
5. 썸네일 이미지 활용

### UIKit과의 차이

| UIKit | SwiftUI |
|-------|---------|
| Imperative (명령형) | Declarative (선언형) |
| UIImageView + UIImage | Image (통합) |
| 수동 메모리 관리 | 자동 최적화 |
| 명시적 레이아웃 | 선언적 레이아웃 |

---

## 다음 단계

이제 SwiftUI Image의 기본 개념을 이해했다면:

1. **RENDERING_MODE_GUIDE.md**: 렌더링 옵션 상세 학습
2. **PERFORMANCE_GUIDE.md**: 성능 최적화 기법
3. **실습**: 각종 뷰에서 직접 테스트

---

**Happy Learning! 🎨**

*SwiftUI Image의 강력함을 경험하세요!*

