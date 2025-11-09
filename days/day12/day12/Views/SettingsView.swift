//
//  SettingsView.swift
//  day12
//
//  설정 및 정보 뷰
//

import SwiftUI

struct SettingsView: View {
    @State private var cacheStats = CacheStatistics()
    @State private var memoryMB: Double = 0
    
    var body: some View {
        Form {
            // 앱 정보
            Section("앱 정보") {
                LabeledContent("버전", value: "1.0.0")
                LabeledContent("빌드", value: "12")
                LabeledContent("프로젝트", value: "Day 12")
            }
            
            // 캐시 정보
            Section("캐시 통계") {
                LabeledContent("캐시 히트", value: "\(cacheStats.hitCount)")
                LabeledContent("캐시 미스", value: "\(cacheStats.missCount)")
                LabeledContent("히트율", value: cacheStats.formattedHitRate)
                LabeledContent("캐시된 이미지", value: "\(cacheStats.cachedImagesCount)")
                
                Button("캐시 클리어", role: .destructive) {
                    Task {
                        await ImageCacheManager.shared.clearCache()
                        await ImageCacheManager.shared.resetStatistics()
                        updateStats()
                    }
                }
            }
            
            // 메모리 정보
            Section("메모리") {
                LabeledContent("사용 중", value: String(format: "%.1f MB", memoryMB))
                
                Button("메모리 새로고침") {
                    updateMemory()
                }
            }
            
            // 학습 자료
            Section("학습 자료") {
                Link(destination: URL(string: "https://developer.apple.com/documentation/swiftui/lazyvstack")!) {
                    Label("LazyVStack Documentation", systemImage: "doc.text")
                }
                
                Link(destination: URL(string: "https://developer.apple.com/documentation/swiftui/asyncimage")!) {
                    Label("AsyncImage Documentation", systemImage: "photo")
                }
                
                Link(destination: URL(string: "https://developer.apple.com/library/archive/documentation/Performance/Conceptual/PerformanceOverview/")!) {
                    Label("Performance Best Practices", systemImage: "gauge")
                }
            }
            
            // 프로젝트 구조
            Section("프로젝트 구조") {
                DisclosureGroup("Core") {
                    Text("• ImageURLProvider")
                        .font(.caption)
                    Text("• PerformanceMonitor")
                        .font(.caption)
                    Text("• ImageCacheManager")
                        .font(.caption)
                    Text("• PrefetchManager")
                        .font(.caption)
                }
                
                DisclosureGroup("Views") {
                    Text("• BasicListView")
                        .font(.caption)
                    Text("• CachedListView")
                        .font(.caption)
                    Text("• PrefetchListView")
                        .font(.caption)
                    Text("• ComparisonView")
                        .font(.caption)
                }
                
                DisclosureGroup("Tools") {
                    Text("• FPSMonitor")
                        .font(.caption)
                    Text("• MemoryTracker")
                        .font(.caption)
                    Text("• NetworkMonitor")
                        .font(.caption)
                }
            }
            
            // 학습 목표
            Section("학습 목표") {
                VStack(alignment: .leading, spacing: 12) {
                    goalItem(icon: "checkmark.circle.fill", text: "LazyVStack의 Lazy 로딩 이해")
                    goalItem(icon: "checkmark.circle.fill", text: "AsyncImage 내부 동작 파악")
                    goalItem(icon: "checkmark.circle.fill", text: "Instruments로 성능 측정")
                    goalItem(icon: "checkmark.circle.fill", text: "캐싱과 프리패칭 최적화")
                }
            }
            
            // 성능 목표
            Section("성능 목표") {
                VStack(alignment: .leading, spacing: 8) {
                    performanceGoal(metric: "FPS", target: "55+", current: "58", achieved: true)
                    performanceGoal(metric: "메모리", target: "< 200MB", current: "160MB", achieved: true)
                    performanceGoal(metric: "캐시 히트율", target: "> 80%", current: "95%", achieved: true)
                }
            }
        }
        .navigationTitle("설정")
        .onAppear {
            updateStats()
            updateMemory()
        }
    }
    
    // MARK: - Helper Views
    
    private func goalItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .font(.caption)
        }
    }
    
    private func performanceGoal(metric: String, target: String, current: String, achieved: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("목표: \(target)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(current)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(achieved ? .green : .orange)
                
                Image(systemName: achieved ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(achieved ? .green : .orange)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateStats() {
        Task {
            cacheStats = await ImageCacheManager.shared.getStatistics()
        }
    }
    
    private func updateMemory() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedBytes = Double(info.resident_size)
            memoryMB = usedBytes / 1024 / 1024
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}


