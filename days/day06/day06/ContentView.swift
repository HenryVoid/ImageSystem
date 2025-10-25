//
//  ContentView.swift
//  day06
//
//  메인 네비게이션 뷰
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🎨 Day 6")
                            .font(.title)
                            .bold()
                        Text("SwiftUI 이미지 렌더링 옵션")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("resizable, aspectRatio, interpolation, renderingMode 등을 실습합니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                }
                
                Section("렌더링 모드") {
                    NavigationLink {
                        RenderingModeComparisonView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rendering Mode 비교")
                                    .font(.headline)
                                Text(".original vs .template")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "paintbrush.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Section("보간 품질") {
                    NavigationLink {
                        InterpolationQualityView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Interpolation 품질 비교")
                                    .font(.headline)
                                Text(".none, .low, .medium, .high")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "aspectratio.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Section("Aspect Ratio & Resizable") {
                    NavigationLink {
                        AspectRatioTestView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Aspect Ratio 테스트")
                                    .font(.headline)
                                Text(".fit vs .fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "rectangle.compress.vertical")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    NavigationLink {
                        ResizableOptionsView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Resizable 옵션")
                                    .font(.headline)
                                Text("capInsets, resizingMode")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .foregroundStyle(.purple)
                        }
                    }
                }
                
                Section("성능") {
                    NavigationLink {
                        PerformanceBenchmarkView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("성능 벤치마크")
                                    .font(.headline)
                                Text("렌더링 옵션별 성능 측정")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "speedometer")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                Section("가이드 문서") {
                    Link(destination: URL(string: "https://developer.apple.com/documentation/swiftui/image")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SwiftUI Image 문서")
                                    .font(.headline)
                                Text("Apple 공식 문서")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Day 6: Image 렌더링")
        }
    }
}

#Preview {
    ContentView()
}
