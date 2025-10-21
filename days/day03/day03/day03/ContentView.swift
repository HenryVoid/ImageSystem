//
//  ContentView.swift
//  day03
//
//  Created on 2025-10-21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("🎓 학습 자료")) {
                    Link("📖 Core Image 이론", destination: URL(string: "file://")!)
                        .foregroundColor(.blue)
                    Link("🔗 필터 체인 가이드", destination: URL(string: "file://")!)
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("🎨 실습")) {
                    NavigationLink("1️⃣ 기본 필터", destination: BasicFilterView())
                    NavigationLink("2️⃣ 필터 체인 ⭐", destination: FilterChainView())
                    NavigationLink("3️⃣ 실시간 필터", destination: RealtimeFilterView())
                }
                
                Section(header: Text("📊 성능 측정")) {
                    NavigationLink("벤치마크", destination: BenchmarkView())
                }
                
                Section(header: Text("ℹ️ 정보")) {
                    HStack {
                        Text("프로젝트")
                        Spacer()
                        Text("Day 03: Core Image")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("학습 주제")
                        Spacer()
                        Text("필터 체인")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Core Image 학습")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
}
