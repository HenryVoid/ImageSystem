# Day 8: URLSession 비동기 이미지 로딩

> URLSession을 직접 활용하여 원격 이미지를 비동기로 로드하고 캐싱하는 방법을 학습합니다

---

## 📚 학습 목표

### 핵심 목표
- **URLSession 마스터**: completion handler와 async/await 두 방식 모두 이해
- **스레드 안전**: 메인/백그라운드 스레드 동작 원리와 UI 업데이트 타이밍 제어
- **캐싱 전략**: NSCache를 활용한 효율적인 이미지 캐싱 구현
- **성능 비교**: 캐시 적용 전후 성능 차이를 직접 측정

### 학습 포인트

#### URLSession 기초
- URLSession, URLRequest, URLSessionDataTask의 역할
- completion handler의 콜백 패턴
- async/await의 구조적 동시성
- 에러 처리와 HTTP 응답 검증

#### 스레드 관리
- 메인 스레드에서만 UI 업데이트 가능
- `DispatchQueue.main.async`의 필요성
- `@MainActor`를 활용한 자동 스레드 전환
- weak self 캡처 리스트로 메모리 누수 방지

#### 이미지 캐싱
- NSCache vs Dictionary
- 캐시 키 설계 (URL 기반)
- 중복 요청 방지 전략
- 메모리 경고 대응

#### 성능 측정
- os_signpost를 활용한 시간 측정
- 캐시 히트율 추적
- 네트워크 트래픽 비교
- Instruments 활용

---

## 🗂️ 파일 구조

```
day08/
├── README.md                       # 이 파일
├── 시작하기.md                     # 빠른 시작 가이드
├── URLSESSION_THEORY.md           # URLSession 기본 개념
├── ASYNC_AWAIT_GUIDE.md           # async/await vs completion handler
├── CACHING_GUIDE.md               # 이미지 캐싱 전략
├── PERFORMANCE_GUIDE.md           # 성능 비교 및 최적화
│
└── day08/
    ├── ContentView.swift          # 4개 탭 메인 뷰
    │
    ├── Core/                      # 핵심 이미지 로더
    │   ├── SimpleImageLoader.swift      # 캐시 없는 기본 로더
    │   ├── CachedImageLoader.swift      # NSCache 적용 로더
    │   └── AsyncImageLoader.swift       # async/await 버전
    │
    ├── Views/                     # UI 뷰
    │   ├── SimpleLoadingView.swift      # 기본 로딩 데모
    │   ├── CachedLoadingView.swift      # 캐시 적용 데모
    │   ├── ComparisonView.swift         # 캐시 vs 비캐시 비교
    │   └── BenchmarkView.swift          # 성능 벤치마크
    │
    └── tool/                      # 성능 측정 도구
        ├── PerformanceLogger.swift      # os_signpost 로깅
        ├── MemorySampler.swift          # 메모리 사용량 측정
        └── NetworkMonitor.swift         # 네트워크 상태 확인
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day08
open day08.xcodeproj
```

### 2. 앱 실행
```
⌘R (Run)
```

### 3. 네트워크 연결 필요
이 프로젝트는 인터넷 연결이 필요합니다 (무료 이미지 API 사용).

**사용 이미지 API**: [Picsum Photos](https://picsum.photos)
- `https://picsum.photos/800/600?random=1`
- `https://picsum.photos/800/600?random=2`
- 등등...

---

## 📖 사용 가이드

### Tab 1: 기본 로딩

**SimpleLoadingView** - 캐시 없는 단순 이미지 로더

```swift
// 핵심 구현
URLSession.shared.dataTask(with: url) { data, response, error in
    guard let data = data, let image = UIImage(data: data) else { return }
    
    DispatchQueue.main.async {
        self.image = image
    }
}.resume()
```

**특징**:
- 매번 네트워크에서 다운로드
- 동일 이미지 재요청 시에도 새로 다운로드
- 로딩 시간: 평균 500ms

**실습**:
1. "이미지 로드" 버튼 클릭
2. 로딩 시간 확인
3. "다시 로드" 클릭 → 또 500ms 소요 확인

---

### Tab 2: 캐시 적용

**CachedLoadingView** - NSCache를 활용한 캐시 로더

```swift
// 핵심 구현
if let cached = cache.object(forKey: key) {
    return cached  // 즉시 반환!
}

// 없으면 다운로드 후 캐시에 저장
URLSession.shared.dataTask(with: url) { data, response, error in
    guard let data = data, let image = UIImage(data: data) else { return }
    
    cache.setObject(image, forKey: key)
    
    DispatchQueue.main.async {
        completion(image)
    }
}.resume()
```

**특징**:
- 첫 로드: 500ms (네트워크)
- 재로드: 5ms (캐시) ← **100배 빠름!**
- 캐시 히트율 표시

**실습**:
1. "이미지 로드" 버튼 클릭 → "캐시 미스" 표시
2. 로딩 시간 확인 (약 500ms)
3. "다시 로드" 클릭 → "캐시 히트" 표시
4. 로딩 시간 확인 (약 5ms) ⚡
5. "캐시 초기화" 후 다시 테스트

---

### Tab 3: 비교 테스트

**ComparisonView** - 캐시 vs 비캐시 성능 비교

10개 이미지를 2번 로드하여 비교:

| 구분 | 1차 로드 | 2차 로드 | 총 시간 | 데이터 |
|------|---------|---------|---------|--------|
| **캐시 없음** | 5000ms | 5000ms | 10000ms | 2.0MB |
| **캐시 적용** | 5000ms | 50ms | 5050ms | 1.0MB |
| **개선** | - | **100배** | **50%↓** | **50%↓** |

**실습**:
1. "테스트 시작" 버튼 클릭
2. 좌우 비교 확인
3. 로딩 시간 비교
4. 캐시 히트율 확인

---

### Tab 4: 벤치마크

**BenchmarkView** - 정밀 성능 측정

반복 테스트를 통한 통계 측정:

```
📊 캐시 없음 (20회)
평균: 487.3ms
최소: 456.2ms
최대: 523.8ms
캐시 히트율: 0%

📊 캐시 적용 (20회)
평균: 245.6ms
최소: 4.8ms
최대: 512.3ms
캐시 히트율: 50%
```

**실습**:
1. "전체 벤치마크" 버튼 클릭
2. 각 테스트 결과 확인
3. Instruments에서 signpost 확인 (선택)

---

## 🔑 핵심 개념

### 1. URLSession 요청 흐름

```
URLRequest 생성
    ↓
URLSession.dataTask() 호출
    ↓
task.resume() 시작
    ↓
[백그라운드 스레드] 네트워크 요청
    ↓
[백그라운드 스레드] completion handler 호출
    ↓
DispatchQueue.main.async
    ↓
[메인 스레드] UI 업데이트
```

### 2. Completion Handler vs async/await

**Completion Handler**:
```swift
func loadImage(completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        let image = UIImage(data: data!)
        DispatchQueue.main.async {
            completion(image)
        }
    }.resume()
}
```

**async/await**:
```swift
func loadImage() async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    return UIImage(data: data)!
}

// 사용
Task {
    let image = try await loadImage()
}
```

**비교**:
- async/await가 더 간결하고 가독성 좋음
- completion handler는 모든 iOS 버전 지원
- Day 8에서는 **둘 다** 학습

### 3. NSCache 동작 원리

```
이미지 요청
    ↓
캐시 키 생성 (URL)
    ↓
NSCache.object(forKey:) 호출
    ↓
┌─ 있으면: 즉시 반환 (캐시 히트)
│
└─ 없으면: 네트워크 다운로드
      ↓
    캐시에 저장
      ↓
    반환
```

**자동 관리**:
- 메모리 부족 시 자동 삭제 (LRU)
- 스레드 안전
- 용량 제한 설정 가능

---

## 💡 핵심 기법

### 1. 메인 스레드 전환

```swift
// ❌ 잘못된 예
URLSession.shared.dataTask(with: url) { data, response, error in
    self.imageView.image = UIImage(data: data!)  // 크래시 위험!
}.resume()

// ✅ 올바른 예
URLSession.shared.dataTask(with: url) { data, response, error in
    guard let data = data, let image = UIImage(data: data) else { return }
    
    DispatchQueue.main.async {
        self.imageView.image = image  // 안전!
    }
}.resume()
```

### 2. weak self 캡처

```swift
// ❌ 메모리 누수 위험
func loadImage() {
    URLSession.shared.dataTask(with: url) { data, response, error in
        self.image = UIImage(data: data!)  // strong reference cycle
    }.resume()
}

// ✅ 안전한 구현
func loadImage() {
    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
        guard let self = self else { return }
        // ...
    }.resume()
}
```

### 3. 중복 요청 방지

```swift
// 동일 URL 동시 다운로드 방지
private var runningRequests = [String: [((UIImage?) -> Void)]]()

func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    let key = url.absoluteString
    
    // 이미 진행 중이면
    if runningRequests[key] != nil {
        runningRequests[key]?.append(completion)  // 대기 목록에 추가
        return
    }
    
    // 새 요청 시작
    runningRequests[key] = [completion]
    // ... 다운로드 로직
}
```

---

## 📊 성능 비교 (실측)

### 시나리오: 10개 이미지 × 3회 로드

**캐시 없음**:
```
1차: ████████████████████ 5000ms (10개 다운로드)
2차: ████████████████████ 5000ms (10개 다운로드)
3차: ████████████████████ 5000ms (10개 다운로드)
───────────────────────────────────────────
총: 15000ms, 데이터: 3.0MB
```

**캐시 적용**:
```
1차: ████████████████████ 5000ms (10개 다운로드)
2차: █ 50ms (캐시)
3차: █ 50ms (캐시)
───────────────────────────────────────────
총: 5100ms, 데이터: 1.0MB
```

**개선**:
- ⚡ **66% 시간 단축** (15000ms → 5100ms)
- 💰 **66% 데이터 절감** (3.0MB → 1.0MB)
- 🚀 **100배 빠른 재로드** (5000ms → 50ms)

---

## 🎓 학습 체크리스트

### 기본 (Tab 1-2)
- [ ] URLSession.shared.dataTask 사용법 이해
- [ ] completion handler 패턴 이해
- [ ] DispatchQueue.main.async 필요성 이해
- [ ] NSCache 기본 사용법 숙지
- [ ] 캐시 히트/미스 개념 이해

### 응용 (Tab 3)
- [ ] 캐시 적용 전후 성능 차이 체감
- [ ] 중복 요청 방지 구현 이해
- [ ] 캐시 키 설계 이해
- [ ] 메모리 경고 대응 방법 파악

### 심화 (Tab 4)
- [ ] async/await 버전 구현 비교
- [ ] os_signpost를 활용한 성능 측정
- [ ] Instruments에서 signpost 확인
- [ ] 캐시 히트율 최적화 전략 이해

---

## 🔍 Instruments 활용

### Logging (os_signpost)

1. ⌘I로 Profiling 시작
2. **Logging** 템플릿 선택
3. 앱에서 벤치마크 실행
4. **Points of Interest** 확인

**확인 가능한 signpost**:
- `Image_Load_NoCache`: 캐시 없는 로딩
- `Image_Load_Cached`: 캐시 적용 로딩
- `Cache_Hit`: 캐시 히트
- `Cache_Miss`: 캐시 미스

### Network

1. ⌘I로 Profiling 시작
2. **Network** 템플릿 선택
3. 앱에서 이미지 로딩
4. 다운로드 트래픽 확인

**확인 사항**:
- 총 다운로드 크기
- 요청 횟수
- 중복 요청 여부

---

## 🐛 문제 해결

### 이미지가 로드되지 않음

**원인**: 인터넷 연결 문제 또는 시뮬레이터 제한

**해결**:
1. Wi-Fi 연결 확인
2. 시뮬레이터 재시작
3. Safari에서 URL 직접 접속 테스트

---

### 앱이 느리거나 멈춤

**원인**: 메인 스레드에서 네트워크 요청

**해결**:
1. completion handler 내부에서 UI 업데이트 확인
2. `DispatchQueue.main.async` 사용 확인
3. Instruments Time Profiler로 메인 스레드 확인

---

### 메모리 부족 경고

**원인**: 캐시가 너무 큼

**해결**:
```swift
cache.totalCostLimit = 50 * 1024 * 1024  // 50MB로 제한
cache.countLimit = 30  // 최대 30개 이미지
```

---

## 📚 참고 자료

### 이론 문서 (필수)
1. **URLSESSION_THEORY.md**: URLSession 기본 개념
2. **ASYNC_AWAIT_GUIDE.md**: async/await 사용법
3. **CACHING_GUIDE.md**: NSCache 활용법
4. **PERFORMANCE_GUIDE.md**: 성능 최적화

### Apple 공식 문서
- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [NSCache](https://developer.apple.com/documentation/foundation/nscache)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Performance](https://developer.apple.com/documentation/os/logging/recording_performance_data)

### 이전 학습 복습
- **Day 1-7**: 이미지 기본 처리 및 렌더링
- **Day 8**: 네트워크 이미지 로딩 ← 현재

---

## 🎯 다음 단계

Day 8을 완료했다면:

1. **실전 프로젝트 적용**
   - 자신의 앱에 이미지 캐싱 적용
   - AsyncImage 대신 커스텀 로더 사용

2. **추가 기능 구현**
   - 디스크 캐시 추가 (URLCache)
   - 이미지 프리로딩
   - 다운샘플링 적용

3. **고급 최적화**
   - 병렬 다운로드 (TaskGroup)
   - 점진적 이미지 로딩
   - 오프라인 모드 지원

---

## 💬 핵심 요약

### URLSession 3요소
1. **URLSession**: 네트워크 관리자
2. **URLRequest**: 요청 정보
3. **URLSessionDataTask**: 실제 작업

### 필수 주의사항
- ✅ completion handler는 백그라운드 스레드
- ✅ UI 업데이트는 `DispatchQueue.main.async`
- ✅ ViewController에서는 `[weak self]`
- ✅ NSCache로 중복 다운로드 방지

### 캐싱 효과
- ⚡ 100배 빠른 재로드
- 💰 50% 데이터 절감
- 🚀 즉각적인 UX

---

**Happy Coding! 🎨**

*URLSession과 캐싱을 마스터하여 효율적인 이미지 로딩을 구현하세요!*

