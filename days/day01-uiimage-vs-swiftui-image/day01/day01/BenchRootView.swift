//
//  BenchRootView.swift
//  day01
//
//  메인 벤치마크 화면 - SwiftUI vs UIKit 전환
//  ✅ 메모리 누수 & UI Hangs 해결 버전
//

import SwiftUI

enum Case: String, CaseIterable { 
    case swiftui = "SwiftUI"
    case uikit = "UIKit"
}

struct BenchRootView: View {
    @State private var current: Case = .swiftui
    @State private var showOptimizationInfo = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 8) {
                Text("🎯 이미지 성능 벤치마크")
                    .font(.headline)
                
                Text("FPS, 메모리를 실시간으로 확인하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // ✅ 최적화 배너
            if showOptimizationInfo {
                OptimizationBanner(isVisible: $showOptimizationInfo)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 탭 선택
            Picker("Target", selection: $current) {
                ForEach(Case.allCases, id: \.self) { 
                    Text($0.rawValue).tag($0) 
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // 컨텐츠
            switch current {
            case .swiftui: 
                SwiftUIImageList()
                    .transition(.opacity)
                    .id("swiftui") // ✅ 뷰 재생성 보장
            case .uikit:   
                UIKitListRepresentable()
                    .transition(.opacity)
                    .id("uikit") // ✅ 뷰 재생성 보장
            }
        }
        .onChange(of: current) { oldValue, newValue in
            // ✅ 탭 전환 시 메모리 정리 권장
            PerformanceLogger.log("📱 탭 전환: \(oldValue.rawValue) → \(newValue.rawValue)")
            
            // 약간의 지연 후 메모리 측정 (뷰가 완전히 해제된 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                MemorySampler.logCurrentMemory(label: "탭 전환 후")
            }
        }
    }
}

// MARK: - 최적화 배너
struct OptimizationBanner: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("✅ 최적화 적용됨")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                OptimizationItem(icon: "checkmark.circle.fill", text: "메모리 누수 해결 (weak self)")
                OptimizationItem(icon: "checkmark.circle.fill", text: "UI Hangs 해결 (비동기 디코딩)")
                OptimizationItem(icon: "checkmark.circle.fill", text: "이미지 preparingForDisplay() 사용")
                OptimizationItem(icon: "checkmark.circle.fill", text: "UICollectionView 셀 재사용")
                OptimizationItem(icon: "checkmark.circle.fill", text: "메모리 워닝 대응")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.8), Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct OptimizationItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
        }
    }
}
