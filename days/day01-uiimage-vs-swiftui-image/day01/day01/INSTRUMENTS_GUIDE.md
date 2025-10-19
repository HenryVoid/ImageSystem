# 6) Instruments에서 "정답" 뽑기 (Step-by-step)

## 📱 사전 준비

### 1단계: 실기기 연결
- iPhone을 Mac에 USB로 연결
- Xcode에서 타겟 디바이스 선택
- 개발자 모드 활성화 확인

### 2단계: Release 모드로 빌드
```
Xcode > Product > Scheme > Edit Scheme...
Run > Info > Build Configuration > Release
```
⚠️ **중요**: Debug 모드는 최적화가 꺼져있어 성능이 실제보다 나쁘게 나옵니다!

---

## 🔬 Instruments 실행

### 방법 1: Xcode에서 직접
```
Xcode > Product > Profile (⌘I)
```

### 방법 2: Instruments 앱 직접 실행
```
Applications > Xcode > Contents > Applications > Instruments.app
```

---

## 📊 주요 측정 항목별 가이드

### 1️⃣ Time Profiler (CPU 사용률)

**목적**: SwiftUI vs UIKit 중 어느 쪽이 CPU를 많이 쓰는지

**실행 방법**:
1. Instruments 템플릿에서 "Time Profiler" 선택
2. 타겟 디바이스와 앱 선택
3. 녹화 버튼 (빨간 점) 클릭
4. 앱에서 SwiftUI 탭 → 스크롤 → 10초 대기
5. 앱에서 UIKit 탭 → 스크롤 → 10초 대기
6. 정지 버튼 클릭

**분석 방법**:
```
1. Call Tree 옵션 설정:
   ✅ Separate by Thread
   ✅ Hide System Libraries
   ✅ Flatten Recursion

2. Main Thread 찾기
3. 함수별 CPU 시간 확인
   - SwiftUI: Image(uiImage:) 관련 함수들
   - UIKit: UIImageView 관련 함수들

4. 비교 지표:
   - Total Time (ms)
   - % of Runtime
```

---

### 2️⃣ os_signpost (커스텀 구간 측정)

**목적**: 우리가 코드에 심어둔 사인포스트로 정확한 구간 측정

**실행 방법**:
1. "os_signpost" 템플릿 선택
2. 녹화 시작
3. 스크롤 테스트
4. 정지

**분석 방법**:
```
좌측 패널에서:
📍 SwiftUI_Scroll
📍 UIKit_Scroll
📍 SwiftUI_Render
📍 UIKit_Render

각 구간의 Duration(ms) 확인!

💡 팁: Summary 뷰에서 평균/최소/최대 확인 가능
```

---

### 3️⃣ Allocations (메모리 할당)

**목적**: 이미지 로딩 시 메모리 얼마나 먹는지

**실행 방법**:
1. "Allocations" 템플릿 선택
2. 녹화 시작 → 앱 시작 → 스크롤
3. Generation Analysis 활용

**분석 방법**:
```
1. Statistics 탭:
   - UIImage 검색
   - Persistent Bytes (지속 메모리)
   - Transient Bytes (임시 메모리)

2. Call Tree에서:
   - UIImage.init 호출 빈도
   - 메모리 증가량

3. 비교:
   SwiftUI Image vs UIKit UIImageView
   누가 메모리를 더 효율적으로 쓰는가?
```

---

### 4️⃣ Leaks (메모리 누수)

**목적**: 이미지 제거 후에도 메모리가 안 사라지는지 확인

**실행 방법**:
1. "Leaks" 템플릿 선택
2. 녹화 → 스크롤 → 탭 전환 반복
3. Leaks 자동 스캔 결과 확인

**분석**:
```
❌ 빨간 X 표시가 있으면 누수!
✅ 없으면 OK

누수가 있다면:
- Call Stack 확인
- 어느 이미지 로딩 코드가 원인인지 추적
```

---

### 5️⃣ System Trace (종합 분석)

**목적**: CPU, GPU, 메모리, 스레드 등 모든 것을 한눈에

**실행 방법**:
1. "System Trace" 템플릿
2. 녹화 → 테스트
3. 타임라인 분석

**분석**:
```
📊 타임라인에서:
1. Main Thread 활성도
   - 100% 찬 구간 = 병목
   
2. GPU 사용률
   - 이미지 렌더링 부하

3. Hangs (버벅임)
   - 빨간 막대 = UI 프리징

4. 커스텀 Signpost 구간
   - 우리가 심어둔 측정 마커
```

---

## 🎯 핵심 비교 지표

| 항목 | SwiftUI | UIKit | 우승자 |
|------|---------|-------|--------|
| CPU 사용률 (%) | ? | ? | |
| 평균 프레임 시간 (ms) | ? | ? | |
| 스크롤 시작→종료 (ms) | ? | ? | |
| 메모리 사용량 (MB) | ? | ? | |
| 60fps 유지율 (%) | ? | ? | |

---

## 💡 Instruments 꿀팁

### 1. 비교 실행
```
File > Recording Options > 
두 개의 기기/시뮬레이터 동시 측정 가능
```

### 2. 특정 구간만 확인
```
타임라인에서 드래그로 구간 선택
→ 우클릭 → "Focus on Selection"
```

### 3. 측정값 내보내기
```
File > Export > 
CSV 또는 XML로 저장 후 엑셀 분석
```

### 4. 커스텀 Instrument
```
File > Recording Options > os_signpost
"com.study.day01" subsystem 체크
→ 우리 로그만 필터링
```

---

## ⚠️ 주의사항

1. **첫 실행 제외**: 앱 시작 직후는 캐시가 없어서 느림 → 2회차 측정 사용
2. **배터리 충전 상태**: 배터리 세이버 모드면 성능 제한됨
3. **백그라운드 앱**: 다른 앱 종료하고 측정
4. **기기 온도**: 과열되면 쓰로틀링 발생 → 식힌 후 재측정
5. **시뮬레이터 금지**: 반드시 실기기에서!

---

## 🎓 결론 도출

측정 후 다음 질문에 답하기:

1. **SwiftUI Image가 빠른가, UIKit UIImageView가 빠른가?**
   - Time Profiler 결과:
   - Signpost 결과:

2. **메모리는 누가 효율적인가?**
   - Allocations 결과:

3. **스크롤 성능은?**
   - FPS 비교:
   - Hangs 발생 빈도:

4. **실용적인 결론**:
   - 100장 이하: 
   - 1000장 이상:
   - 추천 방식:

---

## 📚 참고 자료

- [Apple Instruments Help](https://help.apple.com/instruments/)
- [WWDC - Explore UI animation hitches and the render loop](https://developer.apple.com/videos/play/wwdc2020/10077/)
- [WWDC - Using Time Profiler](https://developer.apple.com/videos/play/wwdc2016/418/)

