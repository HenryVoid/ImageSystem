//
//  ContentView.swift
//  day02
//
//  Day 2: Core Graphics로 이미지 그리기
//  메인 네비게이션 화면
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                // 📚 학습 자료 섹션
                Section("📚 학습 자료") {
                    NavigationLink {
                        TheoryView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Core Graphics 이론", systemImage: "book.fill")
                            Text("좌표계, Context, Renderer 핵심 개념")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        SwiftUICanvasTheoryView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("SwiftUI Canvas 가이드", systemImage: "paintbrush.fill")
                            Text("iOS 15+ 선언적 그래픽 API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 🎨 Phase 2: 기본 구현
                Section("🎨 Phase 2: 기본 구현") {
                    NavigationLink {
                        CGContextView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("기본 도형 그리기", systemImage: "square.and.pencil")
                            Text("선, 사각형, 원, 삼각형, 별, 하트")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        TextRenderingView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("텍스트 렌더링", systemImage: "textformat")
                            Text("폰트, 색상, 스타일, 레이아웃")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        ImageCompositionView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("이미지 합성", systemImage: "photo.stack")
                            Text("오버레이, 블렌드 모드, 마스킹")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 📊 Phase 3: 성능 비교
                Section("📊 Phase 3: 성능 비교") {
                    NavigationLink {
                        PlaceholderView(title: "성능 벤치마크")
                    } label: {
                        Label("CG vs SwiftUI 비교", systemImage: "chart.bar")
                        Text("준비 중...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // 🚀 Phase 4: 실전 예제
                Section("🚀 Phase 4: 실전 예제") {
                    NavigationLink {
                        PlaceholderView(title: "워터마크")
                    } label: {
                        Label("워터마크 추가", systemImage: "c.circle")
                        Text("준비 중...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    NavigationLink {
                        PlaceholderView(title: "이미지 리사이징")
                    } label: {
                        Label("이미지 리사이징", systemImage: "arrow.up.left.and.arrow.down.right")
                        Text("준비 중...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    NavigationLink {
                        PlaceholderView(title: "썸네일 생성")
                    } label: {
                        Label("썸네일 생성", systemImage: "photo.on.rectangle")
                        Text("준비 중...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Day 2: Core Graphics")
        }
    }
}

// MARK: - 이론 뷰

struct TheoryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("📖 Core Graphics 이론")
                    .font(.largeTitle)
                    .bold()
                
                InfoCard(
                    icon: "book.fill",
                    title: "이론 문서",
                    description: "CORE_GRAPHICS_THEORY.md 파일을 참고하세요. 좌표계, Context, Renderer 등 핵심 개념을 학습할 수 있습니다."
                )
                
                InfoCard(
                    icon: "list.bullet",
                    title: "학습 순서",
                    description: """
                    1. 이론 문서 읽기
                    2. 기본 도형 그리기 실습
                    3. 텍스트 렌더링
                    4. 이미지 합성
                    5. 성능 비교
                    6. 실전 예제
                    """
                )
                
                InfoCard(
                    icon: "lightbulb.fill",
                    title: "핵심 개념",
                    description: """
                    • Core Graphics = 저수준 2D 그래픽 API
                    • 좌표계: 왼쪽 하단이 원점 (UIKit과 반대!)
                    • Context: 그림을 그릴 캔버스
                    • UIGraphicsImageRenderer: 안전한 렌더링
                    • State: save/restore로 관리
                    """
                )
            }
            .padding()
        }
        .navigationTitle("Core Graphics 이론")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SwiftUICanvasTheoryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🎨 SwiftUI Canvas")
                    .font(.largeTitle)
                    .bold()
                
                InfoCard(
                    icon: "paintbrush.fill",
                    title: "Canvas란?",
                    description: "iOS 15+에서 사용 가능한 SwiftUI의 즉시 모드 2D 그래픽 API입니다. 선언적이고 직관적이며, TimelineView와 함께 실시간 애니메이션에 적합합니다."
                )
                
                InfoCard(
                    icon: "star.fill",
                    title: "주요 특징",
                    description: """
                    • 선언적 SwiftUI 스타일 API
                    • GPU 가속 지원
                    • 실시간 애니메이션 (TimelineView)
                    • SwiftUI View와 완벽 통합
                    • 좌표계: SwiftUI 스타일 (왼쪽 상단)
                    """
                )
                
                InfoCard(
                    icon: "arrow.left.arrow.right",
                    title: "Core Graphics와 비교",
                    description: """
                    Canvas:
                    ✅ 화면 표시, 실시간 그리기
                    ✅ 간단한 API, 빠른 개발
                    ❌ 이미지 저장 번거로움
                    
                    Core Graphics:
                    ✅ 이미지 저장, PDF 생성
                    ✅ 정밀한 픽셀 제어
                    ❌ 복잡한 API, 느린 개발
                    """
                )
                
                InfoCard(
                    icon: "doc.text.fill",
                    title: "상세 가이드",
                    description: "SWIFTUI_CANVAS_GUIDE.md 파일에서 실전 예제와 함께 Canvas의 모든 기능을 학습할 수 있습니다."
                )
            }
            .padding()
        }
        .navigationTitle("SwiftUI Canvas")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 헬퍼 뷰

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("🚧 준비 중...")
                .font(.title)
                .bold()
            
            Text(title)
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("곧 구현될 예정입니다!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
