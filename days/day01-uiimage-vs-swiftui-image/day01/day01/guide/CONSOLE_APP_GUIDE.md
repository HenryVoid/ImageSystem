# 8) Console.app에서 로그 확인하기

## 📱 Console.app이란?

macOS에 기본 내장된 로그 뷰어입니다. Xcode 콘솔보다 훨씬 강력하고, 실기기에서 실행 중일 때도 로그를 볼 수 있습니다.

**위치**: `/Applications/Utilities/Console.app`

---

## 🚀 빠른 시작

### 1단계: Console.app 실행

```bash
# 터미널에서
open /Applications/Utilities/Console.app

# 또는 Spotlight (⌘+Space)
Console
```

### 2단계: 디바이스 선택

좌측 사이드바에서:
- **내 Mac 로그**: "이 Mac"
- **실기기 로그**: iPhone/iPad 이름 (USB 연결 필요)

### 3단계: 필터 설정

우측 상단 검색창에:
```
subsystem:com.study.day01
```

이제 우리 앱의 로그만 보입니다! 🎯

---

## 🔍 필터링 테크닉

### 1. Subsystem으로 필터링 (가장 중요!)

```
subsystem:com.study.day01
```

우리 앱의 모든 로그만 표시됩니다.

### 2. Category별로 세분화

```
subsystem:com.study.day01 category:scroll
subsystem:com.study.day01 category:fps
subsystem:com.study.day01 category:memory
subsystem:com.study.day01 category:bench
```

### 3. 키워드 검색

```
subsystem:com.study.day01 AND "스크롤"
subsystem:com.study.day01 AND "FPS"
subsystem:com.study.day01 AND "메모리"
```

### 4. 로그 레벨 필터

좌측 하단의 레벨 버튼:
- **Default**: 일반 로그
- **Info**: 정보성 로그
- **Debug**: 디버그 로그 (Debug 빌드에만)
- **Error**: 에러 로그
- **Fault**: 심각한 에러

### 5. 시간 범위 지정

```
# 최근 1분
subsystem:com.study.day01 AND timestamp >= -60s

# 최근 5분
subsystem:com.study.day01 AND timestamp >= -5m

# 특정 시간 이후
subsystem:com.study.day01 AND timestamp >= 2025-10-19 14:30:00
```

---

## 📊 실전 사용 시나리오

### 시나리오 1: SwiftUI vs UIKit 비교

#### 1️⃣ SwiftUI 테스트
```
1. Console.app 필터: subsystem:com.study.day01
2. 앱에서 "swiftui" 탭 선택
3. 스크롤 테스트
4. Console에서 확인:
   - ✅ SwiftUI 이미지 리스트 시작
   - 스크롤 시작
   - FPS: 60 (또는 낮은 값)
   - 스크롤 종료
   - ❌ SwiftUI 이미지 리스트 종료
```

#### 2️⃣ UIKit 테스트
```
1. 앱에서 "uikit" 탭 선택
2. 스크롤 테스트
3. Console에서 비교:
   - FPS가 더 높은가?
   - 메모리는 어떻게 다른가?
```

---

### 시나리오 2: 스크롤 성능 집중 분석

**필터**:
```
subsystem:com.study.day01 category:scroll
```

**확인 사항**:
```
✅ 스크롤 시작 (드래그)
   ↓ (스크롤 중...)
✅ 스크롤 종료 (감속)

시간 측정:
- 타임스탬프 차이 계산
- SwiftUI vs UIKit 비교
```

---

### 시나리오 3: FPS 모니터링

**필터**:
```
subsystem:com.study.day01 category:fps
```

**패턴 분석**:
```
FPS: 60
FPS: 60
FPS: 58  ← 약간 떨어짐
FPS: 45  ← 많이 떨어짐 (병목 구간)
FPS: 60  ← 회복
```

---

### 시나리오 4: 메모리 추적

**필터**:
```
subsystem:com.study.day01 category:memory
```

**추적 순서**:
```
1. SwiftUI onAppear: 45.32 MB
2. 메모리: 52.18 MB (+7 MB)
3. 스크롤 후: 58.43 MB (+13 MB)
4. 탭 전환 후: 46.21 MB (메모리 해제 확인)
```

---

## 💾 로그 저장 및 내보내기

### 방법 1: 로그 저장
```
1. Console.app 메뉴 > File > Save Selection...
2. 또는 ⌘S
3. 파일명: performance_log_2025-10-19.txt
```

### 방법 2: 터미널로 추출
```bash
# 실시간 로그 보기
log stream --predicate 'subsystem == "com.study.day01"'

# 파일로 저장
log stream --predicate 'subsystem == "com.study.day01"' > my_log.txt

# 특정 카테고리만
log stream --predicate 'subsystem == "com.study.day01" && category == "fps"'

# 최근 1시간 로그 수집
log show --predicate 'subsystem == "com.study.day01"' --last 1h > performance_log.txt
```

---

## 🎨 Console.app UI 가이드

### 좌측 패널 (디바이스/소스)
```
📱 이 Mac
📱 iPhone (연결된 실기기)
🔍 최근 검색
⭐ 즐겨찾기
```

### 중앙 패널 (로그 목록)
```
┌─────────────┬──────────┬─────────────────────────────┐
│ 시간        │ 프로세스  │ 메시지                       │
├─────────────┼──────────┼─────────────────────────────┤
│ 14:30:01.234│ day01    │ ✅ SwiftUI 이미지 리스트 시작 │
│ 14:30:02.105│ day01    │ FPS: 60                     │
│ 14:30:03.450│ day01    │ 스크롤 시작                   │
└─────────────┴──────────┴─────────────────────────────┘
```

### 우측 패널 (상세 정보)
```
로그 하나를 클릭하면:
- Subsystem: com.study.day01
- Category: bench
- Process: day01
- PID: 12345
- Thread: 0x16e8a3000
- Full Message: ...
```

---

## 🔧 고급 필터 문법

### AND/OR 조합
```
subsystem:com.study.day01 AND (category:fps OR category:scroll)
```

### NOT 조건
```
subsystem:com.study.day01 AND NOT category:debug
```

### 정규식 사용
```
subsystem:com.study.day01 AND message MATCHES "FPS: [0-9]+"
```

### 프로세스 지정
```
process:day01 AND subsystem:com.study.day01
```

---

## 📈 데이터 분석 팁

### 1. 엑셀로 분석

로그를 텍스트로 저장 후:
```
1. Excel 열기
2. 데이터 > 텍스트에서
3. 구분 기호: 탭
4. FPS 값만 추출 → 평균/최소/최대 계산
```

### 2. 스크립트로 파싱

```bash
# FPS 평균 계산
grep "FPS:" performance_log.txt | awk '{sum+=$2; count++} END {print sum/count}'

# 메모리 사용량 추이
grep "메모리:" performance_log.txt | awk '{print $2}'
```

### 3. 타임스탬프 차이 계산

```bash
# 스크롤 시작~종료 시간 측정
grep "스크롤" performance_log.txt
# 타임스탬프 차이를 수동 계산 또는 스크립트 사용
```

---

## 🎯 핵심 요약

### ✅ 해야 할 것
1. **subsystem 필터 필수**: `subsystem:com.study.day01`
2. **category로 세분화**: fps, scroll, memory 등
3. **로그 저장**: 비교 분석을 위해 파일로 저장
4. **실기기에서 테스트**: 시뮬레이터는 부정확

### ❌ 하지 말아야 할 것
1. 필터 없이 전체 로그 보기 (너무 많음)
2. Debug 빌드로 성능 측정
3. 다른 앱 실행 중 측정
4. Console.app 없이 Xcode 콘솔만 사용

---

## 🎓 실전 체크리스트

측정 전:
- [ ] iPhone USB 연결
- [ ] Console.app 실행
- [ ] 필터 설정: `subsystem:com.study.day01`
- [ ] 화면 녹화 준비 (선택)

측정 중:
- [ ] SwiftUI 탭 → 스크롤 → 10초 대기
- [ ] UIKit 탭 → 스크롤 → 10초 대기
- [ ] Console.app에서 로그 실시간 확인

측정 후:
- [ ] 로그 파일 저장
- [ ] FPS 평균값 계산
- [ ] 메모리 증가량 확인
- [ ] 스크롤 반응 시간 비교
- [ ] 결론 정리

---

## 🆘 문제 해결

### Q: 로그가 안 보여요!
```
1. 필터 확인: subsystem 이름 정확한가?
2. 앱이 실행 중인가?
3. 실기기 연결 확인
4. 좌측에서 올바른 디바이스 선택했는가?
```

### Q: 로그가 너무 많아요!
```
subsystem 필터를 꼭 사용하세요!
subsystem:com.study.day01
```

### Q: 오래된 로그도 보고 싶어요
```
상단 메뉴 > Action > Include Info Messages
상단 메뉴 > Action > Include Debug Messages
```

### Q: 실기기 로그가 안 보여요
```
1. iPhone 잠금 해제
2. USB 재연결
3. "신뢰" 버튼 누름
4. Console.app 재시작
```

---

이제 준비 완료! 🚀 실기기에서 앱을 실행하고 Console.app으로 성능을 분석해보세요!

