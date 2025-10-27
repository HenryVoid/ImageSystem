//
//  BenchmarkView.swift
//  day07
//
//  성능 벤치마크 뷰
//

import SwiftUI

/// 벤치마크 뷰
struct BenchmarkView: View {
    @StateObject private var runner = BenchmarkRunner()
    
    var body: some View {
        NavigationStack {
            List {
                // 실행 버튼 섹션
                Section {
                    Button {
                        runImageLoadingBenchmark()
                    } label: {
                        Label("이미지 로딩 테스트", systemImage: "photo")
                    }
                    .disabled(runner.isRunning)
                    
                    Button {
                        runFilterChainBenchmark()
                    } label: {
                        Label("필터 체인 테스트", systemImage: "wand.and.stars")
                    }
                    .disabled(runner.isRunning)
                    
                    Button {
                        runThumbnailBenchmark()
                    } label: {
                        Label("썸네일 생성 테스트", systemImage: "square.grid.3x3")
                    }
                    .disabled(runner.isRunning)
                    
                    Button {
                        runner.runAllBenchmarks()
                    } label: {
                        Label("전체 테스트 실행", systemImage: "play.fill")
                            .bold()
                    }
                    .disabled(runner.isRunning)
                } header: {
                    Text("벤치마크 실행")
                } footer: {
                    if runner.isRunning {
                        HStack {
                            ProgressView()
                            Text("테스트 실행 중...")
                        }
                    }
                }
                
                // 결과 섹션
                if !runner.results.isEmpty {
                    Section("결과") {
                        ForEach(runner.results) { result in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(result.name)
                                    .font(.headline)
                                
                                HStack {
                                    Label("평균", systemImage: "timer")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(result.formattedAverageTime)
                                        .font(.caption)
                                        .bold()
                                }
                                
                                HStack {
                                    Label("범위", systemImage: "arrow.up.arrow.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(String(format: "%.2f", result.minTime * 1000))ms ~ \(String(format: "%.2f", result.maxTime * 1000))ms")
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Label("반복", systemImage: "repeat")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(result.iterations)회")
                                        .font(.caption)
                                }
                                
                                if result.memoryUsed > 0 {
                                    HStack {
                                        Label("메모리", systemImage: "memorychip")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(result.formattedMemory)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            runner.results.removeAll()
                        } label: {
                            Label("결과 지우기", systemImage: "trash")
                        }
                    }
                }
                
                // 가이드 섹션
                Section("Instruments 연결") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Xcode 메뉴: Product > Profile (⌘I)")
                            .font(.caption)
                        Text("2. Time Profiler 또는 Logging 선택")
                            .font(.caption)
                        Text("3. 앱 실행 후 벤치마크 실행")
                            .font(.caption)
                        Text("4. os_signpost 로그 확인")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("성능 벤치마크")
        }
    }
    
    private func runImageLoadingBenchmark() {
        runner.benchmarkImageLoading(imageNames: ["sample", "sample2"])
    }
    
    private func runFilterChainBenchmark() {
        let filterChains: [[FilterType]] = [
            [.blur],
            [.sepia],
            [.sepia, .vignette],
            [.colorControls, .sharpen, .vignette]
        ]
        runner.benchmarkFilterChains(imageName: "sample", filterChains: filterChains)
    }
    
    private func runThumbnailBenchmark() {
        runner.benchmarkThumbnailGeneration(imageNames: ["sample", "sample2"], sizes: [100, 200, 300])
    }
}

#Preview {
    BenchmarkView()
}

