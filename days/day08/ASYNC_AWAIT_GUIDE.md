# async/await vs Completion Handler

> completion handler의 한계와 async/await를 활용한 현대적 비동기 처리

---

## 📚 비동기 처리의 진화

### 역사적 관점

```
iOS 2 (2008)    delegate 패턴
                   ↓
iOS 4 (2010)    블록(completion handler)
                   ↓
iOS 13 (2019)   Combine 프레임워크
                   ↓
iOS 15 (2021)   async/await ⭐
```

---

## 🔄 Completion Handler 방식

### 기본 구조

completion handler는 **콜백 함수**를 통해 비동기 결과를 전달합니다.

```swift
func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }.resume()
}

// 사용
loadImage(from: url) { image in
    // 이미지 로드 완료 후 실행
    print("이미지 로드됨: \(image)")
}
```

### 장점

✅ **간단한 사용**: 기본 개념이 직관적  
✅ **iOS 모든 버전**: iOS 2부터 지원  
✅ **디버깅**: 브레이크포인트 설정 용이

### 단점

❌ **콜백 지옥 (Callback Hell)**  
❌ **에러 처리 복잡**  
❌ **코드 가독성 저하**  
❌ **순서 보장 어려움**

---

## 😱 Callback Hell (콜백 지옥)

### 문제 예시

여러 비동기 작업을 순차적으로 수행할 때:

```swift
// 1. 사용자 정보 로드
loadUser(id: userId) { user in
    guard let user = user else { return }
    
    // 2. 프로필 이미지 로드
    loadImage(from: user.profileImageURL) { image in
        guard let image = image else { return }
        
        // 3. 이미지 리사이즈
        resizeImage(image, to: CGSize(width: 200, height: 200)) { resized in
            guard let resized = resized else { return }
            
            // 4. 필터 적용
            applyFilter(to: resized, filter: .sepia) { filtered in
                guard let filtered = filtered else { return }
                
                // 5. 캐시 저장
                cacheImage(filtered, key: "profile_\(userId)") { success in
                    if success {
                        // 드디어 완료!
                        print("모든 작업 완료")
                    }
                }
            }
        }
    }
}
```

**문제점**:
- 중첩 깊이 5단계 → 가독성 최악
- 에러 처리가 각 단계마다 반복
- 코드 수정이 매우 어려움

---

## ✨ async/await 방식

### 기본 구조

`async/await`는 **동기 코드처럼** 비동기 코드를 작성할 수 있게 합니다.

```swift
func loadImage(from url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    
    guard let image = UIImage(data: data) else {
        throw ImageError.invalidData
    }
    
    return image
}

// 사용
Task {
    do {
        let image = try await loadImage(from: url)
        print("이미지 로드됨: \(image)")
    } catch {
        print("에러: \(error)")
    }
}
```

### 장점

✅ **가독성**: 동기 코드처럼 직관적  
✅ **에러 처리**: try-catch로 통합  
✅ **순서 보장**: 코드 흐름 그대로  
✅ **취소 지원**: Task 취소 가능

### 단점

❌ **iOS 버전**: iOS 15+ 필요  
❌ **학습 곡선**: 새로운 개념 (Task, Actor 등)

---

## 🆚 두 방식 비교

### 예제 1: 단일 이미지 로드

**Completion Handler**:

```swift
func loadImage(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data, let image = UIImage(data: data) else {
            completion(.failure(ImageError.invalidData))
            return
        }
        
        completion(.success(image))
    }.resume()
}

// 사용
loadImage(url: url) { result in
    switch result {
    case .success(let image):
        print("성공: \(image)")
    case .failure(let error):
        print("실패: \(error)")
    }
}
```

**async/await**:

```swift
func loadImage(url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    
    guard let image = UIImage(data: data) else {
        throw ImageError.invalidData
    }
    
    return image
}

// 사용
Task {
    do {
        let image = try await loadImage(url: url)
        print("성공: \(image)")
    } catch {
        print("실패: \(error)")
    }
}
```

**비교**:
- async/await가 **30% 더 간결**
- 에러 처리가 **표준 try-catch**
- 가독성 **월등히 향상**

---

### 예제 2: 순차 작업 (콜백 지옥 해결)

**Completion Handler** (중첩 5단계):

```swift
loadUser(id: userId) { user in
    guard let user = user else { return }
    loadImage(from: user.profileURL) { image in
        guard let image = image else { return }
        resizeImage(image, to: size) { resized in
            guard let resized = resized else { return }
            applyFilter(to: resized) { filtered in
                guard let filtered = filtered else { return }
                cacheImage(filtered) { success in
                    print("완료: \(success)")
                }
            }
        }
    }
}
```

**async/await** (중첩 0단계):

```swift
do {
    let user = try await loadUser(id: userId)
    let image = try await loadImage(from: user.profileURL)
    let resized = try await resizeImage(image, to: size)
    let filtered = try await applyFilter(to: resized)
    let success = try await cacheImage(filtered)
    print("완료: \(success)")
} catch {
    print("에러: \(error)")
}
```

**비교**:
- 중첩 깊이: 5단계 → **0단계**
- 가독성: 어려움 → **명확**
- 에러 처리: 분산 → **단일 catch**

---

### 예제 3: 병렬 작업

여러 이미지를 **동시에** 로드하는 경우:

**Completion Handler**:

```swift
let group = DispatchGroup()
var images: [UIImage] = []

for url in urls {
    group.enter()
    loadImage(url: url) { result in
        if case .success(let image) = result {
            images.append(image)
        }
        group.leave()
    }
}

group.notify(queue: .main) {
    print("모든 이미지 로드 완료: \(images.count)개")
}
```

**async/await**:

```swift
let images = try await withThrowingTaskGroup(of: UIImage.self) { group in
    for url in urls {
        group.addTask {
            try await loadImage(url: url)
        }
    }
    
    var results: [UIImage] = []
    for try await image in group {
        results.append(image)
    }
    return results
}

print("모든 이미지 로드 완료: \(images.count)개")
```

**비교**:
- 병렬 처리가 **명시적**
- 에러 처리가 **통합**
- 코드가 **더 안전**

---

## 🎯 Task와 MainActor

### Task란?

`Task`는 비동기 작업의 **실행 단위**입니다.

```swift
// 새 Task 생성
Task {
    let image = try await loadImage(url: url)
    print(image)
}

// Task 취소 가능
let task = Task {
    let image = try await loadImage(url: url)
    return image
}

// 나중에 취소
task.cancel()

// 결과 대기
let image = await task.value
```

### Task의 우선순위

```swift
// 높음 (사용자 인터랙션)
Task(priority: .high) {
    // 즉시 실행
}

// 중간 (기본값)
Task(priority: .medium) {
    // 보통 실행
}

// 낮음 (백그라운드)
Task(priority: .low) {
    // 여유 있을 때 실행
}
```

### MainActor - 메인 스레드 보장

`@MainActor`는 **메인 스레드**에서 실행을 보장합니다.

```swift
@MainActor
func updateUI(image: UIImage) {
    // 자동으로 메인 스레드에서 실행
    imageView.image = image
}

// 또는
Task { @MainActor in
    imageView.image = image
}
```

**SwiftUI에서**:

```swift
@MainActor
class ImageViewModel: ObservableObject {
    @Published var image: UIImage?
    
    func loadImage() async {
        // @MainActor 덕분에 메인 스레드에서 실행
        self.image = try? await loadImage(url: url)
        // @Published 업데이트도 자동으로 메인 스레드
    }
}
```

---

## 🔄 Completion Handler → async/await 변환

### 변환 패턴

**Before** (Completion Handler):

```swift
func loadImage(url: URL, completion: @escaping (UIImage?, Error?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, ImageError.noData)
            return
        }
        
        completion(UIImage(data: data), nil)
    }.resume()
}
```

**After** (async/await):

```swift
func loadImage(url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    
    guard let image = UIImage(data: data) else {
        throw ImageError.invalidData
    }
    
    return image
}
```

### withCheckedContinuation - 브리지 패턴

기존 completion handler API를 async/await로 감싸기:

```swift
// 기존 completion handler 함수
func legacyLoadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
    // 기존 코드...
}

// async/await 래퍼
func loadImage(url: URL) async -> UIImage? {
    await withCheckedContinuation { continuation in
        legacyLoadImage(url: url) { image in
            continuation.resume(returning: image)
        }
    }
}
```

**에러 처리 포함**:

```swift
func loadImage(url: URL) async throws -> UIImage {
    try await withCheckedThrowingContinuation { continuation in
        legacyLoadImage(url: url) { result in
            switch result {
            case .success(let image):
                continuation.resume(returning: image)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

---

## 📱 SwiftUI에서의 활용

### Completion Handler 방식

```swift
struct ImageView: View {
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
            } else if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            isLoading = true
            loadImage(url: url) { loadedImage in
                DispatchQueue.main.async {
                    self.image = loadedImage
                    self.isLoading = false
                }
            }
        }
    }
}
```

### async/await 방식

```swift
struct ImageView: View {
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
            } else if isLoading {
                ProgressView()
            }
        }
        .task {
            isLoading = true
            image = try? await loadImage(url: url)
            isLoading = false
        }
    }
}
```

**장점**:
- `.task` modifier가 자동으로 취소 처리
- `DispatchQueue.main.async` 불필요
- 코드 간결

---

## 🎓 에러 처리 비교

### Completion Handler

```swift
enum Result<T> {
    case success(T)
    case failure(Error)
}

loadImage(url: url) { result in
    switch result {
    case .success(let image):
        // 성공
    case .failure(let error):
        if let networkError = error as? URLError {
            // 네트워크 에러
        } else {
            // 기타 에러
        }
    }
}
```

### async/await

```swift
do {
    let image = try await loadImage(url: url)
    // 성공
} catch let error as URLError {
    // 네트워크 에러
    print("네트워크 에러: \(error.code)")
} catch {
    // 기타 에러
    print("에러: \(error)")
}
```

**비교**:
- async/await가 **표준 Swift 에러 처리**
- 여러 타입의 에러를 **쉽게 구분**

---

## 📊 성능 비교

### 메모리 사용

| 방식 | 메모리 오버헤드 |
|------|----------------|
| Completion Handler | 클로저 캡처로 인한 추가 메모리 |
| async/await | 컴파일러 최적화로 **더 효율적** |

### 실행 속도

거의 동일하지만, async/await가 약간 유리:
- 컴파일러 최적화
- 불필요한 스레드 전환 감소

### 코드 크기

async/await가 **20-40% 더 간결**

---

## 🎯 언제 무엇을 사용할까?

### Completion Handler 사용

✅ iOS 13 이하 지원 필요  
✅ 기존 레거시 코드베이스  
✅ 단순한 비동기 작업 (1-2개)

### async/await 사용

✅ iOS 15+ 타겟  
✅ 복잡한 비동기 흐름 (3개 이상)  
✅ 새 프로젝트 시작  
✅ 가독성이 중요한 경우  
✅ 병렬 처리 필요

---

## 💡 실전 팁

### 1. 혼용 가능

```swift
// 기존 completion handler 함수를 async/await로 호출
Task {
    await withCheckedContinuation { continuation in
        legacyFunction { result in
            continuation.resume(returning: result)
        }
    }
}
```

### 2. 점진적 마이그레이션

한 번에 모두 바꾸지 말고, 새 기능부터 async/await 도입

### 3. Task 취소 처리

```swift
Task {
    for url in urls {
        // 취소되었는지 확인
        if Task.isCancelled {
            break
        }
        
        let image = try await loadImage(url: url)
        images.append(image)
    }
}
```

### 4. Detached Task

부모 Task와 독립적으로 실행:

```swift
Task.detached(priority: .background) {
    // 백그라운드에서 독립 실행
    let image = try await loadImage(url: url)
}
```

---

## 🎓 핵심 요약

### Completion Handler
- ✅ 간단한 비동기 작업
- ❌ 콜백 지옥
- ❌ 복잡한 에러 처리

### async/await
- ✅ 가독성 우수
- ✅ 에러 처리 통합
- ✅ 순서 보장 명확
- ❌ iOS 15+ 필요

### 권장 사항

**새 프로젝트**: async/await 사용  
**기존 프로젝트**: 점진적으로 마이그레이션  
**iOS 14 이하 지원**: completion handler 유지

---

**다음 단계**: CACHING_GUIDE.md에서 NSCache를 활용한 이미지 캐싱 전략을 학습합니다! 🚀



