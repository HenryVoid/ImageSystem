//
//  ContentView.swift
//  day05
//
//  메인 네비게이션 뷰
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                // 헤더
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Day 5")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("이미지 리사이즈 & 포맷 변환")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("iOS에서 이미지를 효율적으로 리사이즈하고 포맷을 변환하는 방법을 학습합니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
                
                // 리사이즈 섹션
                Section(header: Text("리사이즈")) {
                    NavigationLink(destination: ResizeMethodsView()) {
                        MenuRow(
                            icon: "arrow.up.left.and.arrow.down.right",
                            iconColor: .blue,
                            title: "리사이즈 방법 비교",
                            description: "4가지 방법으로 성능 비교"
                        )
                    }
                }
                
                // 포맷 변환 섹션
                Section(header: Text("포맷 변환")) {
                    NavigationLink(destination: FormatComparisonView()) {
                        MenuRow(
                            icon: "doc.badge.gearshape",
                            iconColor: .green,
                            title: "포맷 비교",
                            description: "JPEG/PNG/HEIC 크기 비교"
                        )
                    }
                    
                    NavigationLink(destination: QualityBenchmarkView()) {
                        MenuRow(
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .orange,
                            title: "품질 벤치마크",
                            description: "품질별 파일 크기 측정"
                        )
                    }
                }
                
                // 배치 처리 섹션
                Section(header: Text("배치 처리")) {
                    NavigationLink(destination: BatchProcessingView()) {
                        MenuRow(
                            icon: "rectangle.stack.fill",
                            iconColor: .purple,
                            title: "배치 처리",
                            description: "대량 이미지 일괄 변환"
                        )
                    }
                }
                
                // 가이드 섹션
                Section(header: Text("학습 가이드")) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IMAGE_RESIZE_THEORY.md")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("리사이즈 이론 및 4가지 방법")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.teal)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FORMAT_CONVERSION_GUIDE.md")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("포맷 변환 가이드")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PERFORMANCE_GUIDE.md")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("성능 최적화 전략")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 학습 흐름
                Section(header: Text("추천 학습 순서")) {
                    LearningStepRow(number: 1, title: "이론 문서 읽기", duration: "30분")
                    LearningStepRow(number: 2, title: "리사이즈 실습", duration: "30분")
                    LearningStepRow(number: 3, title: "포맷 변환 실습", duration: "30분")
                    LearningStepRow(number: 4, title: "배치 처리 실습", duration: "20분")
                    LearningStepRow(number: 5, title: "성능 가이드 읽기", duration: "20분")
                }
            }
            .navigationTitle("Day 5")
        }
    }
}

// MARK: - Helper Views

struct MenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LearningStepRow: View {
    let number: Int
    let title: String
    let duration: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(duration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
