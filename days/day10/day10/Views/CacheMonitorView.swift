//
//  CacheMonitorView.swift
//  day10
//
//  캐시 상태 실시간 모니터링 UI
//

import SwiftUI

struct CacheMonitorView: View {
    // MARK: - Properties
    
    @StateObject private var kingfisher = KingfisherCacheManager.shared
    @StateObject private var nuke = NukeCacheManager.shared
    @StateObject private var memoryMonitor = MemorySampler.shared
    @StateObject private var diskMonitor = DiskMonitor.shared
    @StateObject private var analyzer = CacheAnalyzer.shared
    
    @State private var selectedTab = 0
    @State private var isMonitoring = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 탭 선택
                Picker("", selection: $selectedTab) {
                    Text("Kingfisher").tag(0)
                    Text("Nuke").tag(1)
                    Text("시스템").tag(2)
                    Text("비교").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                // 탭 컨텐츠
                TabView(selection: $selectedTab) {
                    kingfisherMonitor
                        .tag(0)
                    
                    nukeMonitor
                        .tag(1)
                    
                    systemMonitor
                        .tag(2)
                    
                    comparisonView
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("캐시 모니터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleMonitoring) {
                        Image(systemName: isMonitoring ? "pause.circle.fill" : "play.circle.fill")
                            .foregroundColor(isMonitoring ? .red : .green)
                    }
                }
            }
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    // MARK: - Kingfisher Monitor
    
    private var kingfisherMonitor: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 캐시 통계
                cacheStatsCard(
                    title: "Kingfisher 캐시",
                    memoryUsage: kingfisher.currentMemoryUsageMB,
                    memoryLimit: Double(kingfisher.configuration.memoryCacheSizeMB),
                    diskUsage: kingfisher.currentDiskUsageMB,
                    diskLimit: Double(kingfisher.configuration.diskCacheSizeMB),
                    hitRate: kingfisher.hitRate
                )
                
                // 히트율 세부 정보
                hitRateCard(
                    totalRequests: kingfisher.totalRequests,
                    memoryHits: kingfisher.memoryHits,
                    diskHits: kingfisher.diskHits,
                    misses: kingfisher.misses
                )
                
                // 액션 버튼
                actionButtons(
                    onClearMemory: { kingfisher.clearMemoryCache() },
                    onClearDisk: { kingfisher.clearDiskCache() },
                    onClearAll: { kingfisher.clearAllCache() },
                    onResetStats: { kingfisher.resetStatistics() }
                )
                
                // 요약 텍스트
                summaryCard(kingfisher.summary())
            }
            .padding()
        }
    }
    
    // MARK: - Nuke Monitor
    
    private var nukeMonitor: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 캐시 통계
                cacheStatsCard(
                    title: "Nuke 캐시",
                    memoryUsage: nuke.currentMemoryUsageMB,
                    memoryLimit: Double(nuke.configuration.memoryCacheSizeMB),
                    diskUsage: nuke.currentDiskUsageMB,
                    diskLimit: Double(nuke.configuration.diskCacheSizeMB),
                    hitRate: nuke.hitRate
                )
                
                // 히트율 세부 정보
                hitRateCard(
                    totalRequests: nuke.totalRequests,
                    memoryHits: nuke.memoryHits,
                    diskHits: nuke.diskHits,
                    misses: nuke.misses
                )
                
                // 액션 버튼
                actionButtons(
                    onClearMemory: { nuke.clearMemoryCache() },
                    onClearDisk: { nuke.clearDiskCache() },
                    onClearAll: { nuke.clearAllCache() },
                    onResetStats: { nuke.resetStatistics() }
                )
                
                // 요약 텍스트
                summaryCard(nuke.summary())
            }
            .padding()
        }
    }
    
    // MARK: - System Monitor
    
    private var systemMonitor: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 메모리 사용량
                systemResourceCard(
                    title: "메모리",
                    icon: "memorychip",
                    color: .blue,
                    current: memoryMonitor.currentMemoryUsageMB(),
                    total: memoryMonitor.totalPhysicalMemoryMB(),
                    unit: "MB"
                )
                
                // 디스크 사용량
                systemResourceCard(
                    title: "디스크",
                    icon: "internaldrive",
                    color: .purple,
                    current: diskMonitor.usedDiskSpaceMB(),
                    total: diskMonitor.totalDiskSpaceMB(),
                    unit: "GB",
                    divisor: 1024
                )
                
                // 캐시 디렉토리
                VStack(alignment: .leading, spacing: 12) {
                    Label("캐시 디렉토리", systemImage: "folder")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("크기")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(String(format: "%.1f", diskMonitor.cacheDiskUsageMB)) MB")
                                .fontWeight(.medium)
                        }
                        
                        if diskMonitor.isLowDiskSpace() {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("디스크 공간 부족")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding()
        }
    }
    
    // MARK: - Comparison View
    
    private var comparisonView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 히트율 비교
                comparisonCard(
                    title: "히트율",
                    kingfisherValue: kingfisher.hitRate,
                    nukeValue: nuke.hitRate,
                    unit: "%",
                    higherIsBetter: true
                )
                
                // 메모리 사용량 비교
                comparisonCard(
                    title: "메모리 사용량",
                    kingfisherValue: kingfisher.currentMemoryUsageMB,
                    nukeValue: nuke.currentMemoryUsageMB,
                    unit: "MB",
                    higherIsBetter: false
                )
                
                // 디스크 사용량 비교
                comparisonCard(
                    title: "디스크 사용량",
                    kingfisherValue: kingfisher.currentDiskUsageMB,
                    nukeValue: nuke.currentDiskUsageMB,
                    unit: "MB",
                    higherIsBetter: false
                )
                
                // 요청 수 비교
                VStack(alignment: .leading, spacing: 12) {
                    Label("요청 통계", systemImage: "chart.bar")
                        .font(.headline)
                    
                    HStack {
                        statColumn(
                            title: "Kingfisher",
                            value: "\(kingfisher.totalRequests)회",
                            color: .blue
                        )
                        
                        Spacer()
                        
                        statColumn(
                            title: "Nuke",
                            value: "\(nuke.totalRequests)회",
                            color: .green
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // 분석 버튼
                Button(action: showComparison) {
                    Label("상세 비교 분석", systemImage: "chart.line.uptrend.xyaxis")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // MARK: - UI Components
    
    private func cacheStatsCard(
        title: String,
        memoryUsage: Double,
        memoryLimit: Double,
        diskUsage: Double,
        diskLimit: Double,
        hitRate: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "externaldrive.fill")
                .font(.headline)
            
            // 메모리
            progressRow(
                title: "메모리",
                current: memoryUsage,
                total: memoryLimit,
                color: .blue
            )
            
            // 디스크
            progressRow(
                title: "디스크",
                current: diskUsage,
                total: diskLimit,
                color: .purple
            )
            
            // 히트율
            HStack {
                Text("히트율")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", hitRate))%")
                    .fontWeight(.bold)
                    .foregroundColor(hitRateColor(hitRate))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func progressRow(title: String, current: Double, total: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", current)) / \(String(format: "%.0f", total)) MB")
                    .font(.caption)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * min(current / total, 1.0))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
    
    private func hitRateCard(totalRequests: Int, memoryHits: Int, diskHits: Int, misses: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("요청 상세", systemImage: "list.bullet")
                .font(.headline)
            
            HStack {
                statColumn(title: "총 요청", value: "\(totalRequests)회", color: .primary)
                statColumn(title: "메모리", value: "\(memoryHits)회", color: .blue)
                statColumn(title: "디스크", value: "\(diskHits)회", color: .purple)
                statColumn(title: "미스", value: "\(misses)회", color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func statColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func actionButtons(
        onClearMemory: @escaping () -> Void,
        onClearDisk: @escaping () -> Void,
        onClearAll: @escaping () -> Void,
        onResetStats: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: onClearMemory) {
                    Label("메모리 삭제", systemImage: "memorychip")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: onClearDisk) {
                    Label("디스크 삭제", systemImage: "internaldrive")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 8) {
                Button(action: onClearAll) {
                    Label("전체 삭제", systemImage: "trash")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Button(action: onResetStats) {
                    Label("통계 초기화", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func summaryCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("요약", systemImage: "doc.text")
                .font(.headline)
            
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func systemResourceCard(
        title: String,
        icon: String,
        color: Color,
        current: Double,
        total: Double,
        unit: String,
        divisor: Double = 1
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)
            
            let currentValue = current / divisor
            let totalValue = total / divisor
            let percentage = (current / total) * 100
            
            HStack {
                Text("\(String(format: "%.1f", currentValue)) / \(String(format: "%.1f", totalValue)) \(unit)")
                    .font(.title3)
                    .fontWeight(.medium)
                Spacer()
                Text("\(String(format: "%.0f", percentage))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * min(current / total, 1.0))
                }
            }
            .frame(height: 12)
            .cornerRadius(6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func comparisonCard(
        title: String,
        kingfisherValue: Double,
        nukeValue: Double,
        unit: String,
        higherIsBetter: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "arrow.left.arrow.right")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Kingfisher")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", kingfisherValue))\(unit)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(isBetter(kingfisherValue, than: nukeValue, higherIsBetter: higherIsBetter) ? .green : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Nuke")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", nukeValue))\(unit)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(isBetter(nukeValue, than: kingfisherValue, higherIsBetter: higherIsBetter) ? .green : .primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func isBetter(_ value1: Double, than value2: Double, higherIsBetter: Bool) -> Bool {
        if higherIsBetter {
            return value1 > value2
        } else {
            return value1 < value2
        }
    }
    
    private func hitRateColor(_ rate: Double) -> Color {
        if rate >= 90 { return .green }
        if rate >= 70 { return .orange }
        return .red
    }
    
    // MARK: - Actions
    
    private func toggleMonitoring() {
        isMonitoring.toggle()
        
        if isMonitoring {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        isMonitoring = true
        memoryMonitor.startMonitoring(interval: 2.0)
    }
    
    private func stopMonitoring() {
        isMonitoring = false
        memoryMonitor.stopMonitoring()
    }
    
    private func showComparison() {
        print(analyzer.compareLibraries())
    }
}

// MARK: - Preview

#Preview {
    CacheMonitorView()
}

















