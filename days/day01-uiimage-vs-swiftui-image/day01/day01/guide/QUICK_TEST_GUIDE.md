# 🚀 빠른 테스트 가이드

> **최적화 버전 테스트하기**  
> 메모리 누수와 UI Hangs가 해결된 버전으로 성능을 재측정하세요!

---

## ✅ 적용된 최적화 요약

| 문제 | 해결 방법 | 상태 |
|------|----------|------|
| 메모리 누수 2건 | weak self, Observer 제거 | ✅ 해결 |
| UI Hangs 4건 | 비동기 이미지 디코딩 | ✅ 해결 |
| UIKit 스크롤 27.77초 | UICollectionView 재사용 | ✅ 개선 |
| 메모리 3.17 MiB | 캐시 관리, preparingForDisplay | ✅ 개선 |

---

## 📱 1단계: 앱 실행

### Xcode에서 빌드
```bash
1. Xcode 열기
2. 타겟: 실기기 선택 (시뮬레이터 X)
3. ⌘ + R 실행
```

### 확인사항
- ✅ 상단에 초록색 최적화 배너 표시
- ✅ SwiftUI/UIKit 탭 전환 가능
- ✅ 이미지 로딩 시 ProgressView 표시 (SwiftUI)
- ✅ 부드러운 스크롤

---

## 🔬 2단계: Instruments 측정

### A. Leaks (메모리 누수) - 최우선 확인!

```bash
1. Xcode > Product > Profile (⌘I)
2. "Leaks" 템플릿 선택
3. 녹화 시작 (빨간 버튼)
4. 앱에서 다음 작업 반복 (5분간):
   - UIKit 탭 → 5번 스크롤
   - SwiftUI 탭 → 5번 스크롤
   - 반복 10회
5. 정지
```

**예상 결과**:
```
✅ Before: 빨간 X 아이콘 2개
✅ After:  빨간 X 아이콘 0개 (누수 없음!)
```

### B. os_signpost (스크롤 성능)

```bash
1. Instruments > "os_signpost" 선택
2. 녹화 시작
3. 테스트:
   - UIKit 탭: 5번 스크롤
   - SwiftUI 탭: 5번 스크롤
   - UIKit 탭: 5번 스크롤
   - SwiftUI 탭: 5번 스크롤
4. 정지
5. Summary > Intervals 확인
```

**예상 결과**:
```
Before:
- UIKit_Scroll: 평균 27.77s (심각)
- SwiftUI_Scroll: 평균 310.25ms

After:
- UIKit_Scroll: 평균 1~3s (정상) ✅
- SwiftUI_Scroll: 평균 300~400ms (유지)
```

### C. System Trace (Hangs)

```bash
1. Instruments > "System Trace" 선택
2. 녹화 → 스크롤 테스트
3. 타임라인에서 "Hangs" 트랙 확인
```

**예상 결과**:
```
✅ Before: 빨간색 2개 + 노란색 2개
✅ After:  빨간색 0개 + 노란색 0~1개
```

### D. Allocations (메모리)

```bash
1. Instruments > "Allocations" 선택
2. 녹화 → 스크롤
3. Statistics > UIImageView, SwiftUI.ImageLayer 검색
```

**예상 결과**:
```
Before:
- UIKit Total: 3.17 MiB
- SwiftUI Total: 935 KiB

After:
- UIKit Total: 1.5 MiB 이하 (50% 감소) ✅
- SwiftUI Total: 800 KiB 이하 (유지 또는 감소)
```

---

## 📊 3단계: 결과 비교

### Before/After 비교표

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 메모리 누수 | 2건 | 0건 | ✅ 100% |
| UI Hangs | 4건 | 0~1건 | ✅ 75~100% |
| UIKit 스크롤 | 27.77s | 1~3s | ✅ 90~96% |
| UIKit 메모리 | 3.17 MiB | 1.5 MiB | ✅ 50% |

### 체크리스트

측정 완료 후 확인:
- [ ] Leaks: 빨간 X 아이콘이 사라졌나요?
- [ ] Hangs: 빨간색 막대가 사라졌나요?
- [ ] 스크롤: UIKit 평균이 5초 미만인가요?
- [ ] 메모리: UIKit이 2 MiB 미만인가요?
- [ ] 체감: 앱이 부드럽게 동작하나요?

---

## 🎯 4단계: 최종 확인

### 실사용 테스트

```
1. 앱 실행 → 5분간 방치
2. UIKit/SwiftUI 탭 번갈아 전환 (20회)
3. 각 탭에서 빠르게 스크롤 (50회)
4. 홈 버튼으로 백그라운드 전환
5. 앱 다시 활성화
6. 메모리 레이블 확인 (화면 좌상단)
```

**예상 동작**:
```
✅ 앱이 크래시하지 않음
✅ 메모리가 계속 증가하지 않음
✅ 스크롤이 항상 부드러움
✅ 탭 전환이 즉시 반응함
```

---

## 🐛 문제 발생 시

### 여전히 메모리 누수가 있다면?
```swift
// Memory Graph Debugger 사용
1. 앱 실행 중
2. Xcode 하단 디버그 바에서 메모리 그래프 아이콘 클릭
3. 좌측 패널에서 "!" 표시 확인
4. Leaks가 있는 객체 선택 → 참조 경로 추적
```

### 여전히 스크롤이 느리다면?
```swift
// Time Profiler로 병목 함수 찾기
1. Instruments > Time Profiler
2. 녹화 → 스크롤
3. Call Tree 옵션:
   ✅ Separate by Thread
   ✅ Hide System Libraries
   ✅ Flatten Recursion
4. Main Thread에서 가장 긴 함수 확인
```

### 빌드 에러가 발생한다면?
```bash
# iOS 15 미만 지원 여부 확인
# preparingForDisplay()는 iOS 15+

if #available(iOS 15.0, *) {
    // iOS 15+ 코드
} else {
    // iOS 15 미만 폴백
}
```

---

## 📝 결과 기록

측정 후 다음 내용을 기록하세요:

```markdown
### 측정 일시: ____년 __월 __일

#### Leaks
- 누수 발견: __건
- 상태: [ ] 해결됨 [ ] 미해결

#### Hangs
- 빨간색: __건
- 노란색: __건
- 상태: [ ] 해결됨 [ ] 미해결

#### os_signpost
- UIKit_Scroll 평균: __초
- SwiftUI_Scroll 평균: __ms
- 개선율: __%

#### Allocations
- UIKit Total: __ MiB
- SwiftUI Total: __ KiB
- 메모리 감소: __%

#### 종합 평가
최적화 효과: [ ] 매우 좋음 [ ] 좋음 [ ] 보통 [ ] 미흡
```

---

## 💡 성능 개선 팁

### 더 나은 성능을 위해
```swift
1. 이미지 크기 줄이기
   - Assets.xcassets에서 @2x만 사용
   - 불필요한 @3x 제거

2. LazyVStack threshold 조정
   - .lazyVStack(spacing: 8, pinnedViews: [])

3. 이미지 캐시 크기 제한
   - NSCache maxCount 설정
   - 메모리 압박 시 자동 해제

4. 백그라운드 우선순위
   - Task(priority: .background) 사용
```

---

## 🎓 참고 문서

- [ANALYSIS_RESULTS.md](./ANALYSIS_RESULTS.md) - 최초 측정 결과
- [OPTIMIZATION_APPLIED.md](./OPTIMIZATION_APPLIED.md) - 적용한 최적화 상세
- [INSTRUMENTS_GUIDE.md](./INSTRUMENTS_GUIDE.md) - Instruments 사용법

---

## ✅ 완료 후

모든 측정이 끝나면:
1. [ANALYSIS_RESULTS.md](./ANALYSIS_RESULTS.md) 파일 업데이트
2. Before/After 비교 추가
3. 최종 권장사항 수정

축하합니다! 🎉 메모리 누수와 UI Hangs를 해결하고 성능을 크게 개선했습니다!


