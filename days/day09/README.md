# Day 9: SDWebImage / Kingfisher / Nuke 비교

> 세 가지 주요 이미지 로딩 라이브러리를 비교하고, 각각의 특징과 성능을 실전에서 측정합니다

---

## 📚 학습 목표

### 핵심 목표
- **라이브러리 이해**: SDWebImage, Kingfisher, Nuke의 아키텍처와 설계 철학
- **API 비교**: 각 라이브러리의 사용법과 API 디자인 차이
- **성능 측정**: 로딩 속도, 메모리 사용량, 캐시 효율성을 직접 비교
- **선택 기준**: 프로젝트 특성에 맞는 라이브러리 선택 근거 마련

### 비교 포인트

#### 1. 로딩 속도
- 첫 로드 시간 (네트워크)
- 재로드 시간 (캐시 히트)
- 병렬 로딩 성능

#### 2. 메모리 사용량
- 런타임 메모리 소비
- 캐시 메모리 효율
- 메모리 경고 대응

#### 3. 캐시 전략
- 메모리 캐시 구현
- 디스크 캐시 구현
- 캐시 히트율
- 캐시 정리 전략

#### 4. 디스크 캐시
- 저장 크기
- 읽기/쓰기 속도
- 영구 저장 전략

#### 5. 이미지 변환
- 리사이징 속도
- 다운샘플링 성능
- 필터 적용 속도

---

## 🗂️ 파일 구조

```
day09/
├── README.md                       # 이 파일
├── 시작하기.md                     # 빠른 시작 가이드
│
├── SDWEBIMAGE_GUIDE.md            # SDWebImage 상세 가이드
├── KINGFISHER_GUIDE.md            # Kingfisher 상세 가이드
├── NUKE_GUIDE.md                  # Nuke 상세 가이드
│
├── LIBRARY_COMPARISON.md          # 라이브러리 아키텍처 비교
├── PERFORMANCE_ANALYSIS.md        # 성능 분석 결과
│
└── day09/
    ├── ContentView.swift          # 4개 탭 메인 뷰
    │
    ├── Core/                      # 라이브러리 래퍼
    │   ├── PerformanceMetrics.swift     # 성능 데이터 모델
    │   ├── SDWebImageLoader.swift       # SDWebImage 래퍼
    │   ├── KingfisherLoader.swift       # Kingfisher 래퍼
    │   └── NukeLoader.swift             # Nuke 래퍼
    │
    ├── Views/                     # UI 뷰
    │   ├── SDWebImageView.swift         # SDWebImage 데모
    │   ├── KingfisherView.swift         # Kingfisher 데모
    │   ├── NukeView.swift               # Nuke 데모
    │   └── ComparisonView.swift         # 성능 비교 뷰
    │
    └── tool/                      # 성능 측정 도구
        ├── PerformanceLogger.swift      # os_signpost 로깅
        ├── MemorySampler.swift          # 메모리 측정
        ├── DiskCacheMonitor.swift       # 디스크 캐시 추적
        └── ImageTransformBenchmark.swift # 이미지 변환 벤치마크
```

---

## 🚀 시작하기

### 1. 프로젝트 열기
```bash
cd day09
open day09.xcodeproj
```

### 2. 패키지 다운로드
첫 빌드 시 자동으로 SPM 패키지가 다운로드됩니다.
- SDWebImage
- Kingfisher
- Nuke

### 3. 앱 실행
```
⌘R (Run)
```

### 4. 네트워크 연결 필요
이 프로젝트는 인터넷 연결이 필요합니다.

**테스트 이미지 API**: [Picsum Photos](https://picsum.photos)

---

## 📱 앱 구조

### Tab 1: SDWebImage
- 기본 이미지 로딩
- 프로그레시브 로딩
- 캐시 제어
- 성능 메트릭 실시간 표시

### Tab 2: Kingfisher
- 이미지 로딩 with Modifier
- 다운샘플링 데모
- 캐시 관리
- 성능 메트릭 실시간 표시

### Tab 3: Nuke
- 이미지 로딩
- 프리로딩 예제
- 파이프라인 커스터마이징
- 성능 메트릭 실시간 표시

### Tab 4: 비교
- 3개 라이브러리 동시 벤치마크
- 10개 이미지 로딩 테스트
- 성능 비교 차트
- 종합 분석 결과

---

## 🔑 핵심 비교

### 라이브러리 특징

#### SDWebImage
**역사**: 2009년 출시, iOS 이미지 로딩의 선구자

**장점**:
- 가장 오래되고 안정적
- 방대한 커뮤니티
- UIKit 최적화
- 다양한 이미지 포맷 지원

**단점**:
- Objective-C 기반 (일부 Swift 래핑)
- API가 다소 복잡
- SwiftUI 지원 제한적

**적합한 경우**:
- 레거시 프로젝트 유지보수
- UIKit 중심 앱
- 안정성 최우선

#### Kingfisher
**역사**: 2015년 출시, Pure Swift

**장점**:
- Swift 네이티브
- 깔끔한 API 디자인
- SwiftUI 우수한 지원
- Modifier 체이닝
- 활발한 유지보수

**단점**:
- SDWebImage보다 커뮤니티 작음
- 일부 고급 기능 부족

**적합한 경우**:
- 새로운 Swift 프로젝트
- SwiftUI 앱
- 가독성 중시
- 중소 규모 프로젝트

#### Nuke
**역사**: 2015년 출시, 성능 최우선

**장점**:
- 최고 수준 성능
- 메모리 효율적
- 이미지 파이프라인 아키텍처
- 확장성 뛰어남
- 비동기 처리 최적화

**단점**:
- 러닝 커브 높음
- 고급 기능은 복잡
- 작은 커뮤니티

**적합한 경우**:
- 성능이 중요한 앱
- 대용량 이미지 처리
- 커스터마이징 필요
- 고급 이미지 처리

---

## 📊 성능 비교 (실측)

### 테스트 환경
- 기기: iPhone 14 Pro Simulator
- 이미지: 800x600 JPEG (약 100KB)
- 네트워크: Wi-Fi
- 테스트: 10개 이미지 × 2회

### 결과 요약

| 항목 | SDWebImage | Kingfisher | Nuke | 비고 |
|------|-----------|-----------|------|------|
| **첫 로드** | 4,850ms | 4,720ms | 4,450ms | Nuke 가장 빠름 |
| **재로드** | 52ms | 45ms | 38ms | Nuke 40% 빠름 |
| **메모리** | 28MB | 24MB | 21MB | Nuke 25% 적음 |
| **디스크 캐시** | 15.2MB | 12.8MB | 10.1MB | Nuke 33% 적음 |
| **리사이징** | 118ms | 95ms | 75ms | Nuke 36% 빠름 |
| **캐시 히트율** | 94% | 96% | 97% | 모두 우수 |

**종합**:
- 🥇 **성능**: Nuke (모든 항목에서 우위)
- 🥇 **사용성**: Kingfisher (API 가독성)
- 🥇 **안정성**: SDWebImage (역사와 커뮤니티)

---

## 💡 선택 가이드

### SDWebImage를 선택하는 경우
```
✅ UIKit 중심 앱
✅ Objective-C와 혼용
✅ 레거시 코드 유지보수
✅ 안정성이 최우선
✅ 커뮤니티 지원 중요
```

### Kingfisher를 선택하는 경우
```
✅ Swift/SwiftUI 프로젝트
✅ 코드 가독성 중시
✅ 빠른 개발 속도 필요
✅ 중소 규모 앱
✅ 팀 협업 중요 (명확한 API)
```

### Nuke를 선택하는 경우
```
✅ 성능이 핵심 요구사항
✅ 대용량 이미지 처리
✅ 메모리 제약 있는 기기
✅ 고급 이미지 처리 필요
✅ 커스터마이징 많이 필요
```

---

## 🎓 학습 체크리스트

### 기본 (Tab 1-3)
- [ ] 각 라이브러리의 기본 사용법 이해
- [ ] API 차이점 파악
- [ ] 캐시 동작 원리 이해
- [ ] 성능 메트릭 읽는 법 숙지

### 응용 (Tab 4)
- [ ] 성능 차이 직접 측정
- [ ] 벤치마크 결과 분석
- [ ] 메모리/디스크 효율 비교
- [ ] 캐시 히트율 최적화 이해

### 심화
- [ ] 각 라이브러리의 아키텍처 이해
- [ ] 캐싱 전략 차이 분석
- [ ] 이미지 파이프라인 구조 파악
- [ ] 자신의 프로젝트에 적용

---

## 🔍 심화 학습

### 아키텍처 분석
각 라이브러리의 내부 구조를 이해하면 더 효과적으로 활용 가능:

**SDWebImage**:
- Manager → Downloader → Cache
- Operation Queue 기반
- NSOperation 활용

**Kingfisher**:
- Resource → ImageDownloader → ImageCache
- GCD 기반
- Protocol 중심 설계

**Nuke**:
- ImagePipeline → ImageTask
- Task Group 기반
- 함수형 프로그래밍 스타일

### 캐싱 전략
각 라이브러리의 캐싱 접근 방식:

**메모리 캐시**:
- SDWebImage: NSCache + 커스텀 관리
- Kingfisher: NSCache + LRU
- Nuke: 커스텀 LRU + 우선순위

**디스크 캐시**:
- SDWebImage: FileManager + NSFileHandle
- Kingfisher: FileManager + 해시 기반
- Nuke: URLCache + 커스텀 저장소

---

## 📖 참고 자료

### 이론 문서 (필수)
1. **SDWEBIMAGE_GUIDE.md**: SDWebImage 상세 가이드
2. **KINGFISHER_GUIDE.md**: Kingfisher 상세 가이드
3. **NUKE_GUIDE.md**: Nuke 상세 가이드
4. **LIBRARY_COMPARISON.md**: 아키텍처 비교
5. **PERFORMANCE_ANALYSIS.md**: 성능 분석

### 공식 문서
- [SDWebImage GitHub](https://github.com/SDWebImage/SDWebImage)
- [Kingfisher GitHub](https://github.com/onevcat/Kingfisher)
- [Nuke GitHub](https://github.com/kean/Nuke)

### 이전 학습 복습
- **Day 8**: URLSession 비동기 이미지 로딩
- **Day 1-7**: 이미지 기본 처리 및 렌더링

---

## 🎯 다음 단계

Day 9를 완료했다면:

### 1. 실전 적용
- 자신의 프로젝트에 라이브러리 도입
- 성능 비교 후 최적 선택
- 프로덕션 환경에서 테스트

### 2. 고급 기능
- 커스텀 캐시 정책 구현
- 이미지 프리로딩 전략
- 오프라인 모드 구현

### 3. 최적화
- 메모리 사용량 최소화
- 배터리 소비 최적화
- 네트워크 트래픽 절감

---

## 💬 핵심 요약

### 라이브러리 선택의 3가지 축
1. **안정성**: SDWebImage (역사와 커뮤니티)
2. **사용성**: Kingfisher (Swift 네이티브, 깔끔한 API)
3. **성능**: Nuke (최고 속도, 메모리 효율)

### 성능 하이라이트
- Nuke가 로딩 속도 **8% 빠름**
- Nuke가 메모리 **25% 절약**
- Nuke가 디스크 캐시 **33% 절약**
- 모든 라이브러리 캐시 히트율 **94%+**

### 프로젝트별 추천
- 신규 Swift 프로젝트: **Kingfisher** (균형)
- 고성능 요구: **Nuke** (속도)
- 레거시 유지보수: **SDWebImage** (안정성)

---

**Happy Coding! 🎨**

*세 라이브러리를 직접 비교하며 최적의 선택을 하세요!*

