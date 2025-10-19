//
//  BenchRootView.swift
//  day01
//
//  메인 벤치마크 화면 - SwiftUI vs UIKit 전환
//

import SwiftUI

enum Case: String, CaseIterable { 
    case swiftui = "SwiftUI"
    case uikit = "UIKit"
}

struct BenchRootView: View {
    @State private var current: Case = .swiftui
    
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
            case .uikit:   
                UIKitListRepresentable()
                    .transition(.opacity)
            }
        }
        .onChange(of: current) { oldValue, newValue in
            // 탭 전환 시 로그
            PerformanceLogger.log("📱 탭 전환: \(oldValue.rawValue) → \(newValue.rawValue)")
            MemorySampler.logCurrentMemory(label: "탭 전환 후")
        }
    }
}
