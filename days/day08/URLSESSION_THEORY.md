# URLSession 기본 이론

> URLSession의 핵심 개념과 이미지 로딩에서의 활용법

---

## 📚 URLSession이란?

**URLSession**은 iOS에서 HTTP/HTTPS 네트워크 통신을 담당하는 Apple의 표준 API입니다.

### 핵심 특징
- **비동기 처리**: 메인 스레드를 차단하지 않음
- **백그라운드 지원**: 앱이 백그라운드에 있어도 다운로드 가능
- **다양한 전송 타입**: 데이터, 다운로드, 업로드, 스트리밍
- **자동 재시도**: 네트워크 오류 시 자동 재시도 가능

---

## 🏗️ URLSession 아키텍처

### 3가지 핵심 구성 요소

```
┌─────────────────────────────────────────┐
│         URLSession                      │
│  (네트워크 요청 관리자)                    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         URLRequest                      │
│  (요청 정보: URL, 헤더, 메서드)            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│      URLSessionDataTask                 │
│  (실제 작업 수행 객체)                     │
└─────────────────────────────────────────┘
```

### 1. URLSession

세션은 네트워크 요청을 관리하는 **컨테이너**입니다.

```swift
// 3가지 세션 타입

// 1. Shared Session (간단한 요청)
let session = URLSession.shared

// 2. Default Session (커스터마이징)
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
let session = URLSession(configuration: config)

// 3. Ephemeral Session (캐시 없음, 프라이빗)
let config = URLSessionConfiguration.ephemeral
let session = URLSession(configuration: config)

// 4. Background Session (백그라운드 다운로드)
let config = URLSessionConfiguration.background(withIdentifier: "com.app.bg")
let session = URLSession(configuration: config)
```

### 2. URLRequest

요청의 **세부 정보**를 담는 객체입니다.

```swift
var request = URLRequest(url: url)
request.httpMethod = "GET"
request.setValue("image/jpeg", forHTTPHeaderField: "Accept")
request.timeoutInterval = 15
request.cachePolicy = .reloadIgnoringLocalCacheData
```

**주요 속성**:
- `url`: 요청 URL
- `httpMethod`: GET, POST, PUT 등
- `httpHeaders`: 커스텀 헤더
- `timeoutInterval`: 타임아웃 (초)
- `cachePolicy`: 캐시 정책

### 3. URLSessionTask

실제 네트워크 작업을 **수행**하는 객체입니다.

```swift
// Task 생성 (아직 실행 안 됨)
let task = session.dataTask(with: request) { data, response, error in
    // 완료 후 실행
}

// Task 실행
task.resume()

// Task 취소
task.cancel()
```

**Task 타입**:
- `dataTask`: 메모리로 데이터 다운로드
- `downloadTask`: 파일로 다운로드
- `uploadTask`: 데이터 업로드
- `streamTask`: 양방향 스트리밍

---

## 🔄 네트워크 요청 생명주기

### 기본 흐름

```
1. URLRequest 생성
        ↓
2. URLSession.dataTask() 호출
        ↓
3. task.resume() 시작
        ↓
4. 백그라운드 스레드에서 네트워크 요청
        ↓
5. 응답 수신
        ↓
6. completion handler 호출 (백그라운드 스레드)
        ↓
7. UI 업데이트 필요 시 → 메인 스레드로 전환
```

### 이미지 로딩 예제

```swift
func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    // 1. Task 생성 및 시작
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        // 2. completion handler (백그라운드 스레드)
        
        // 에러 체크
        guard error == nil else {
            print("네트워크 에러: \(error!)")
            completion(nil)
            return
        }
        
        // HTTP 응답 체크
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("HTTP 에러")
            completion(nil)
            return
        }
        
        // 데이터 체크
        guard let data = data else {
            print("데이터 없음")
            completion(nil)
            return
        }
        
        // 이미지 변환
        guard let image = UIImage(data: data) else {
            print("이미지 변환 실패")
            completion(nil)
            return
        }
        
        // 3. 메인 스레드로 전환 후 completion 호출
        DispatchQueue.main.async {
            completion(image)
        }
    }
    
    task.resume()
}
```

---

## 🧵 스레드와 UI 업데이트

### 메인 스레드 vs 백그라운드 스레드

iOS는 **메인 스레드에서만 UI 업데이트**가 가능합니다.

```
┌─────────────────────────────────────────┐
│         Main Thread                     │
│  - UI 업데이트                           │
│  - 사용자 인터랙션                        │
│  - 절대 차단하면 안 됨!                   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│      Background Thread(s)               │
│  - 네트워크 요청                          │
│  - 파일 I/O                              │
│  - 무거운 연산                            │
└─────────────────────────────────────────┘
```

### ⚠️ 주의: completion handler는 백그라운드에서 실행됨

```swift
// ❌ 잘못된 예: 백그라운드 스레드에서 UI 업데이트
URLSession.shared.dataTask(with: url) { data, response, error in
    // 이 블록은 백그라운드 스레드에서 실행됨!
    let image = UIImage(data: data!)
    self.imageView.image = image  // ⚠️ UI 업데이트 → 크래시 가능!
}.resume()
```

```swift
// ✅ 올바른 예: 메인 스레드로 전환
URLSession.shared.dataTask(with: url) { data, response, error in
    guard let data = data, let image = UIImage(data: data) else { return }
    
    // 메인 스레드로 전환
    DispatchQueue.main.async {
        self.imageView.image = image  // ✅ 안전한 UI 업데이트
    }
}.resume()
```

### SwiftUI에서의 처리

```swift
@State private var image: UIImage?

func loadImage() {
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, let loadedImage = UIImage(data: data) else { return }
        
        // @State 업데이트는 메인 스레드에서
        DispatchQueue.main.async {
            self.image = loadedImage
        }
    }.resume()
}
```

---

## 🔒 메모리 관리: weak self

### Retain Cycle 문제

completion handler가 `self`를 캡처하면 **메모리 누수** 위험이 있습니다.

```swift
class ImageViewController: UIViewController {
    func loadImage() {
        // ❌ 강한 참조 순환
        URLSession.shared.dataTask(with: url) { data, response, error in
            // self를 강하게 캡처 → ViewController가 해제되지 않을 수 있음
            self.imageView.image = UIImage(data: data!)
        }.resume()
    }
}
```

### 해결: weak self 사용

```swift
class ImageViewController: UIViewController {
    func loadImage() {
        // ✅ weak self로 순환 참조 방지
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }  // self가 이미 해제되었으면 종료
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
    }
}
```

### 언제 weak self가 필요한가?

| 상황 | weak self 필요? |
|------|----------------|
| 짧은 네트워크 요청 (< 1초) | 선택 (권장) |
| 긴 네트워크 요청 (> 5초) | **필수** |
| ViewController에서 사용 | **필수** |
| Singleton/Manager에서 사용 | 불필요 |
| SwiftUI View에서 사용 | 대부분 불필요 (구조체) |

---

## 🚨 이미지 로딩의 비효율 포인트

### 1. 중복 요청

동일한 이미지를 여러 번 다운로드하는 낭비:

```swift
// ❌ 문제: 같은 이미지를 10번 다운로드
for _ in 0..<10 {
    loadImage(from: url)  // 매번 네트워크 요청!
}
```

**해결**: 캐싱 (Day 8에서 구현)

### 2. 메인 스레드 차단

```swift
// ❌ 절대 하지 말 것: 동기 네트워크 요청
let data = try! Data(contentsOf: url)  // 앱이 멈춤!
let image = UIImage(data: data)
```

**해결**: 항상 비동기 처리 (URLSession 사용)

### 3. UI 업데이트 타이밍

```swift
// ❌ 백그라운드 스레드에서 UI 업데이트
URLSession.shared.dataTask(with: url) { data, response, error in
    self.imageView.image = UIImage(data: data!)  // 크래시 위험
}.resume()
```

**해결**: `DispatchQueue.main.async` 사용

### 4. 메모리 누수

```swift
// ❌ 강한 참조 순환
URLSession.shared.dataTask(with: url) { data, response, error in
    self.property = value  // self를 강하게 캡처
}.resume()
```

**해결**: `[weak self]` 캡처 리스트

---

## 🎯 에러 처리

### 3단계 검증

```swift
URLSession.shared.dataTask(with: url) { data, response, error in
    // 1단계: 네트워크 에러 체크
    if let error = error {
        print("네트워크 에러: \(error.localizedDescription)")
        return
    }
    
    // 2단계: HTTP 상태 코드 체크
    guard let httpResponse = response as? HTTPURLResponse else {
        print("올바르지 않은 응답")
        return
    }
    
    switch httpResponse.statusCode {
    case 200...299:
        print("성공")
    case 400...499:
        print("클라이언트 에러 (404 등)")
        return
    case 500...599:
        print("서버 에러")
        return
    default:
        print("알 수 없는 상태 코드")
        return
    }
    
    // 3단계: 데이터 유효성 체크
    guard let data = data, !data.isEmpty else {
        print("데이터 없음")
        return
    }
    
    // 이미지 변환
    guard let image = UIImage(data: data) else {
        print("이미지 변환 실패")
        return
    }
    
    // 성공!
    DispatchQueue.main.async {
        completion(image)
    }
}.resume()
```

---

## 📊 주요 응답 코드

| 코드 | 의미 | 처리 |
|------|------|------|
| 200 | OK | 성공 |
| 304 | Not Modified | 캐시 사용 가능 |
| 400 | Bad Request | 요청 오류 |
| 401 | Unauthorized | 인증 필요 |
| 403 | Forbidden | 권한 없음 |
| 404 | Not Found | 리소스 없음 |
| 500 | Server Error | 서버 오류 (재시도) |
| 503 | Service Unavailable | 서버 과부하 (재시도) |

---

## 🎓 핵심 요약

### URLSession 사용 체크리스트

- [ ] `URLSession.shared` 또는 커스텀 세션 사용
- [ ] `dataTask(with:completionHandler:)` 호출
- [ ] `task.resume()` 반드시 호출 (안 하면 실행 안 됨!)
- [ ] completion handler에서 `error` 먼저 체크
- [ ] HTTP 상태 코드 검증
- [ ] 데이터 유효성 확인
- [ ] UI 업데이트 시 `DispatchQueue.main.async` 사용
- [ ] ViewController에서는 `[weak self]` 사용
- [ ] 캐싱 고려 (중복 요청 방지)

### 다음 단계

- **ASYNC_AWAIT_GUIDE.md**: completion handler의 한계와 async/await의 장점
- **CACHING_GUIDE.md**: NSCache를 활용한 효율적인 캐싱 전략
- **PERFORMANCE_GUIDE.md**: 캐시 적용 전후 성능 비교

---

**URLSession의 기본을 마스터했습니다! 🎉**














