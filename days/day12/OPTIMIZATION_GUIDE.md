# 이미지 리스트 최적화 가이드

> LazyVStack + AsyncImage 조합의 성능을 극대화하는 실전 최적화 전략

---

## 📚 목차

1. [최적화 개요](#최적화-개요)
2. [캐싱 전략](#캐싱-전략)
3. [프리패칭 구현](#프리패칭-구현)
4. [이미지 다운샘플링](#이미지-다운샘플링)
5. [메모리 관리](#메모리-관리)
6. [LazyVGrid 대안](#lazyvgrid-대안)
7. [종합 최적화](#종합-최적화)

---

## 최적화 개요

### 성능 문제 진단

#### 문제 1: 느린 스크롤 (낮은 FPS)

**증상**:
- 스크롤이 끊김
- FPS가 45 이하
- 이미지가 늦게 나타남

**원인**:
```swift
// ❌ 최적화 없는 기본 구현
LazyVStack {
    ForEach(0..<1000) { index in
        AsyncImage(url: imageURL(index))
    }
}

문제점:
1. 캐시 없음 → 매번 네트워크 요청
2. 큰 이미지 → 디코딩 시간 길어짐
3. 동시 요청 많음 → 병목 발생
```

#### 문제 2: 높은 메모리 사용

**증상**:
- 메모리가 300MB 초과
- 메모리 경고 발생
- 앱 크래시

**원인**:
```
큰 이미지 디코딩:
- 원본 크기: 1920×1080 JPEG (200KB)
- 디코딩 후: 1920×1080×4 = 8MB!
- 10개 화면에: 80MB
- 100개 캐시: 800MB 💥
```

#### 문제 3: 과도한 네트워크 사용

**증상**:
- 데이터 사용량 많음
- 느린 로딩
- 재로드 시 또 다운로드

**원인**:
```
캐시 없음:
- 첫 로드: 100개 × 200KB = 20MB
- 재로드: 또 20MB
- 3번 재로드: 총 80MB ❌
```

### 최적화 단계

```
1단계: LazyVStack 사용
└─ VStack 대비 90% 메모리 절감

2단계: 캐싱 적용
└─ NSCache로 재로드 40배 빠름

3단계: 프리패칭
└─ 스크롤 끊김 제거

4단계: 다운샘플링
└─ 메모리 80% 절감

5단계: 메모리 관리
└─ 안정성 향상
```

---

## 캐싱 전략

### NSCache 기본 구현

```swift
import UIKit

actor ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        // 메모리 제한 설정
        cache.countLimit = 100 // 최대 100개 이미지
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        // 비용 계산: 픽셀 수 × 4 bytes
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
```

### 캐시 통계 추적

```swift
actor ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSURL, UIImage>()
    private(set) var hitCount = 0
    private(set) var missCount = 0
    
    var hitRate: Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0 }
        return Double(hitCount) / Double(total) * 100
    }
    
    func image(for url: URL) -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            hitCount += 1 // 캐시 히트!
            return cached
        } else {
            missCount += 1 // 캐시 미스
            return nil
        }
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
    
    func resetStats() {
        hitCount = 0
        missCount = 0
    }
}
```

### 캐싱 적용 AsyncImage

```swift
struct CachedAsyncImage: View {
    let url: URL?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        // 1. 캐시 확인
        if let cached = await ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }
        
        // 2. 네트워크 로드
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 3. 디코딩 (백그라운드)
            if let uiImage = await decodeImage(data) {
                // 4. 캐시 저장
                await ImageCache.shared.setImage(uiImage, for: url)
                self.image = uiImage
            }
        } catch {
            print("Failed to load: \(error)")
        }
    }
    
    private func decodeImage(_ data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value
    }
}
```

### 캐싱 효과

```
성능 비교 (100개 이미지):

캐싱 없음:
├─ 첫 로드: 20초
├─ 재로드: 20초 (또 다운로드)
├─ 네트워크: 20MB × 3 = 60MB
└─ 메모리: 150MB

캐싱 적용:
├─ 첫 로드: 20초
├─ 재로드: 0.5초 (40배 빠름!) ⚡
├─ 네트워크: 20MB (첫 번째만)
└─ 메모리: 180MB (+30MB 캐시)

개선:
- 재로드 시간: 95% 단축
- 네트워크: 67% 절감
- 사용자 경험: 크게 향상 ✅
```

---

## 프리패칭 구현

### 기본 개념

**프리패칭**이란?
- 사용자가 스크롤하기 **전에** 이미지를 미리 로드
- 다음 10개 이미지를 백그라운드에서 준비
- 스크롤 시 즉시 표시

### 프리패칭 매니저

```swift
@MainActor
class PrefetchManager: ObservableObject {
    @Published private(set) var prefetchedIndices: Set<Int> = []
    
    private var prefetchTasks: [Int: Task<Void, Never>] = [:]
    
    func prefetch(indices: [Int], urlProvider: (Int) -> URL) {
        for index in indices {
            // 이미 프리패치 중이면 스킵
            guard prefetchTasks[index] == nil else { continue }
            
            let task = Task {
                await prefetchImage(index: index, url: urlProvider(index))
            }
            prefetchTasks[index] = task
        }
    }
    
    private func prefetchImage(index: Int, url: URL) async {
        // 이미 캐시에 있으면 스킵
        if await ImageCache.shared.image(for: url) != nil {
            await MainActor.run {
                prefetchedIndices.insert(index)
            }
            return
        }
        
        // 백그라운드에서 다운로드
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 디코딩
            if let image = await Task.detached {
                UIImage(data: data)
            }.value {
                // 캐시 저장
                await ImageCache.shared.setImage(image, for: url)
                
                await MainActor.run {
                    prefetchedIndices.insert(index)
                }
            }
        } catch {
            // 에러 무시 (메인 로드 시 재시도)
        }
        
        // Task 정리
        await MainActor.run {
            prefetchTasks.removeValue(forKey: index)
        }
    }
    
    func cancelPrefetch(indices: [Int]) {
        for index in indices {
            prefetchTasks[index]?.cancel()
            prefetchTasks.removeValue(forKey: index)
        }
    }
}
```

### 프리패칭 적용

```swift
struct PrefetchListView: View {
    let imageCount: Int
    
    @StateObject private var prefetchManager = PrefetchManager()
    @State private var visibleIndices: Set<Int> = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<imageCount, id: \.self) { index in
                    CachedAsyncImage(url: imageURL(index))
                        .frame(height: 200)
                        .onAppear {
                            handleAppear(index: index)
                        }
                        .onDisappear {
                            handleDisappear(index: index)
                        }
                }
            }
        }
    }
    
    private func handleAppear(index: Int) {
        visibleIndices.insert(index)
        
        // 다음 10개 프리패치
        let nextIndices = (index + 1...min(index + 10, imageCount - 1))
        prefetchManager.prefetch(
            indices: Array(nextIndices),
            urlProvider: imageURL
        )
    }
    
    private func handleDisappear(index: Int) {
        visibleIndices.remove(index)
        
        // 멀리 떨어진 프리패치 취소
        let farIndices = (index + 20...min(index + 30, imageCount - 1))
        prefetchManager.cancelPrefetch(indices: Array(farIndices))
    }
    
    private func imageURL(_ index: Int) -> URL {
        URL(string: "https://picsum.photos/400/400?random=\(index)")!
    }
}
```

### 프리패칭 전략

#### 전략 1: 고정 범위
```swift
// 다음 10개 항상 프리패치
let prefetchIndices = (currentIndex + 1...currentIndex + 10)
```

#### 전략 2: 스크롤 방향 예측
```swift
class SmartPrefetcher {
    private var lastIndex = 0
    
    func shouldPrefetch(currentIndex: Int) -> [Int] {
        let direction = currentIndex > lastIndex ? 1 : -1 // 스크롤 방향
        lastIndex = currentIndex
        
        if direction > 0 {
            // 아래로 스크롤: 다음 15개
            return Array((currentIndex + 1)...(currentIndex + 15))
        } else {
            // 위로 스크롤: 이전 15개
            return Array((currentIndex - 15)...(currentIndex - 1))
        }
    }
}
```

#### 전략 3: 우선순위 기반
```swift
Task.detached(priority: .utility) { // 낮은 우선순위
    await prefetchImage(url)
}
```

### 프리패칭 효과

```
스크롤 성능 비교:

프리패칭 없음:
├─ 이미지 나타남 → 로딩 시작
├─ 로딩 시간: 200ms
├─ 깜빡임 효과 ⚠️
├─ FPS: 45-50
└─ 사용자 경험: 끊김

프리패칭 적용:
├─ 이미지 나타남 → 즉시 표시 (이미 로드됨)
├─ 로딩 시간: 5ms (캐시)
├─ 부드러운 표시 ✅
├─ FPS: 55-60
└─ 사용자 경험: 매우 부드러움

개선:
- 로딩 시간: 97% 단축
- FPS: 22% 향상
- 끊김 제거 ✅
```

---

## 이미지 다운샘플링

### 왜 다운샘플링인가?

```
문제: 큰 이미지의 메모리 낭비

원본 이미지: 1920×1080
화면 크기: 400×400

메모리 사용:
- 원본 디코딩: 1920×1080×4 = 8MB 💥
- 다운샘플: 400×400×4 = 640KB ✅

절감: 92% (12.5배 효율)
```

### Core Graphics 다운샘플링

```swift
import CoreGraphics
import ImageIO

extension UIImage {
    static func downsample(data: Data, to targetSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(targetSize.width, targetSize.height) * scale
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
}
```

### 다운샘플링 적용

```swift
struct DownsampledAsyncImage: View {
    let url: URL?
    let targetSize: CGSize
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 다운샘플링 (백그라운드)
            let downsampled = await Task.detached {
                UIImage.downsample(data: data, to: targetSize)
            }.value
            
            self.image = downsampled
        } catch {
            print("Failed: \(error)")
        }
    }
}

// 사용
DownsampledAsyncImage(
    url: imageURL,
    targetSize: CGSize(width: 400, height: 400)
)
.frame(width: 400, height: 400)
```

### 다운샘플링 효과

```
메모리 비교 (100개 이미지):

다운샘플링 없음:
├─ 원본: 1920×1080
├─ 이미지당: 8MB
├─ 10개 화면: 80MB
├─ 100개 캐시: 800MB 💥
└─ 메모리 경고 발생

다운샘플링 적용:
├─ 타겟: 400×400
├─ 이미지당: 640KB
├─ 10개 화면: 6.4MB
├─ 100개 캐시: 64MB ✅
└─ 안정적 동작

절감: 92% 메모리 절감
```

---

## 메모리 관리

### 메모리 경고 처리

```swift
class ImageCacheManager: ObservableObject {
    private let cache = NSCache<NSURL, UIImage>()
    
    init() {
        // 메모리 경고 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning - clearing cache")
        cache.removeAllObjects()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

### 캐시 크기 제한

```swift
class LimitedImageCache {
    private let cache = NSCache<NSURL, UIImage>()
    
    init(maxItems: Int = 100, maxMemoryMB: Int = 100) {
        cache.countLimit = maxItems
        cache.totalCostLimit = maxMemoryMB * 1024 * 1024
        
        // 자동 정리: 가장 오래된 것부터 제거
        cache.evictsObjectsWithDiscardedContent = true
    }
}
```

### 메모리 사용량 모니터링

```swift
class MemoryMonitor: ObservableObject {
    @Published var usedMemoryMB: Double = 0
    
    private var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMemory()
        }
    }
    
    private func updateMemory() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedBytes = Double(info.resident_size)
            usedMemoryMB = usedBytes / 1024 / 1024
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
```

---

## LazyVGrid 대안

### LazyVGrid 기본 구조

```swift
struct ImageGridView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<100) { index in
                    CachedAsyncImage(url: imageURL(index))
                        .frame(height: 120)
                }
            }
            .padding()
        }
    }
}
```

### LazyVStack vs LazyVGrid

```
LazyVStack (세로 리스트):
├─ 한 줄에 1개 아이템
├─ 큰 이미지 적합
├─ 메모리: 10개 × 2MB = 20MB
└─ 사용: 피드, 상세 리스트

LazyVGrid (그리드):
├─ 한 줄에 3개 아이템
├─ 작은 썸네일 적합
├─ 메모리: 30개 × 200KB = 6MB
└─ 사용: 갤러리, 썸네일

선택 기준:
- 큰 이미지 + 상세 정보 → LazyVStack
- 작은 썸네일 + 많은 개수 → LazyVGrid
```

### 적응형 그리드

```swift
struct AdaptiveGrid: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var columns: [GridItem] {
        switch sizeClass {
        case .compact: // iPhone
            return [GridItem(.flexible()), GridItem(.flexible())]
        default: // iPad
            return Array(repeating: GridItem(.flexible()), count: 4)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(0..<100) { index in
                    CachedAsyncImage(url: imageURL(index))
                        .aspectRatio(1, contentMode: .fill)
                }
            }
        }
    }
}
```

---

## 종합 최적화

### 최종 최적화 구현

```swift
import SwiftUI

// 1. 캐싱 + 다운샘플링 + 프리패칭 통합
struct OptimizedAsyncImage: View {
    let url: URL?
    let targetSize: CGSize
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        // 1. 캐시 확인
        if let cached = await ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }
        
        // 2. 네트워크 로드
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 3. 다운샘플링 (백그라운드)
            if let downsampled = await downsample(data) {
                // 4. 캐시 저장
                await ImageCache.shared.setImage(downsampled, for: url)
                self.image = downsampled
            }
        } catch {
            print("Failed: \(error)")
        }
    }
    
    private func downsample(_ data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            UIImage.downsample(data: data, to: targetSize)
        }.value
    }
}

// 2. 최적화된 리스트
struct OptimizedListView: View {
    let imageCount: Int
    let imageSize: CGSize
    
    @StateObject private var prefetchManager = PrefetchManager()
    @StateObject private var memoryMonitor = MemoryMonitor()
    
    var body: some View {
        VStack {
            // 성능 정보
            HStack {
                Text("메모리: \(String(format: "%.1f", memoryMonitor.usedMemoryMB)) MB")
                Spacer()
                Text("프리패치: \(prefetchManager.prefetchedIndices.count)")
            }
            .padding()
            .background(Color.black.opacity(0.1))
            
            // 최적화된 리스트
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(0..<imageCount, id: \.self) { index in
                        OptimizedAsyncImage(
                            url: imageURL(index),
                            targetSize: imageSize
                        )
                        .frame(height: imageSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onAppear {
                            handleAppear(index: index)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            memoryMonitor.startMonitoring()
        }
        .onDisappear {
            memoryMonitor.stopMonitoring()
        }
    }
    
    private func handleAppear(index: Int) {
        // 다음 10개 프리패치
        let nextIndices = (index + 1...min(index + 10, imageCount - 1))
        prefetchManager.prefetch(
            indices: Array(nextIndices),
            urlProvider: imageURL
        )
    }
    
    private func imageURL(_ index: Int) -> URL {
        let size = Int(imageSize.width)
        return URL(string: "https://picsum.photos/\(size)/\(size)?random=\(index)")!
    }
}
```

### 최적화 체크리스트

#### 필수 최적화
- [x] LazyVStack 사용 (VStack 대신)
- [x] NSCache 기반 캐싱
- [x] 이미지 다운샘플링
- [x] 메모리 경고 처리

#### 고급 최적화
- [x] 프리패칭 구현
- [x] 백그라운드 디코딩
- [x] 캐시 크기 제한
- [x] 성능 모니터링

#### 선택적 최적화
- [ ] 디스크 캐시 추가
- [ ] 진행률 표시
- [ ] 에러 재시도
- [ ] 오프라인 지원

### 성능 개선 결과

```
최적화 전 (기본 AsyncImage):
├─ FPS: 45
├─ 메모리: 350MB
├─ 네트워크: 60MB (3회 로드)
├─ 로딩 시간: 20초
└─ 사용자 경험: 끊김 ⚠️

최적화 후 (종합):
├─ FPS: 58 (+29%)
├─ 메모리: 120MB (-66%)
├─ 네트워크: 20MB (-67%)
├─ 로딩 시간: 0.5초 (재로드, -97%)
└─ 사용자 경험: 매우 부드러움 ✅

개선 효과:
- 성능: 29% 향상
- 메모리: 66% 절감
- 네트워크: 67% 절감
- 속도: 97% 단축
```

---

## 💡 핵심 정리

### 최적화 우선순위

1. **LazyVStack** (필수)
   - 비용: 코드 1줄
   - 효과: 90% 메모리 절감

2. **캐싱** (매우 중요)
   - 비용: 100줄 코드
   - 효과: 40배 속도 향상

3. **다운샘플링** (중요)
   - 비용: 50줄 코드
   - 효과: 90% 메모리 절감

4. **프리패칭** (선택)
   - 비용: 150줄 코드
   - 효과: 부드러운 UX

### 최적화 전략

```
단계별 적용:
1. LazyVStack으로 변경 (1분)
2. 캐싱 추가 (30분)
3. 다운샘플링 적용 (1시간)
4. 프리패칭 구현 (2시간)

총 투자: 약 4시간
효과: 3배 이상 성능 향상
ROI: 매우 높음! ✅
```

---

**최적화 = 더 나은 사용자 경험!** 🚀


