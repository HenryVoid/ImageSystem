//
//  ResizableOptionsView.swift
//  day06
//
//  Resizable 옵션 뷰 - resizable() 유무, capInsets, resizingMode
//

import SwiftUI

struct ResizableOptionsView: View {
    @State private var isResizable = true
    @State private var useCapInsets = false
    @State private var resizingMode: Image.ResizingMode = .stretch
    @State private var targetWidth: CGFloat = 250
    @State private var targetHeight: CGFloat = 60
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 제목 및 설명
                headerSection
                
                // Resizable 옵션
                resizableToggle
                
                // Cap Insets 옵션
                if isResizable {
                    capInsetsToggle
                    resizingModeSelector
                }
                
                // 실시간 비교
                comparisonSection
                
                // 크기 조절
                if isResizable {
                    sizeControls
                }
                
                // 설명 카드
                infoCard
                
                // 9-Patch 예제
                if useCapInsets {
                    ninePatchExample
                }
            }
            .padding()
        }
        .navigationTitle("Resizable 옵션")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("🔧 Resizable")
                .font(.largeTitle)
                .bold()
            
            Text("이미지 크기 조정 옵션")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Resizable Toggle
    
    private var resizableToggle: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isResizable) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("resizable() 적용")
                        .font(.headline)
                    Text(isResizable
                         ? "크기 조정 가능"
                         : "원본 크기 고정")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Cap Insets Toggle
    
    private var capInsetsToggle: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $useCapInsets) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("capInsets 사용 (9-patch)")
                        .font(.headline)
                    Text(useCapInsets
                         ? "가장자리 고정, 중앙만 늘어남"
                         : "전체 균일하게 늘어남")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Resizing Mode Selector
    
    private var resizingModeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resizing Mode")
                .font(.headline)
            
            Picker("Mode", selection: $resizingMode) {
                Text("Stretch").tag(Image.ResizingMode.stretch)
                Text("Tile").tag(Image.ResizingMode.tile)
            }
            .pickerStyle(.segmented)
            
            Text(resizingMode == .stretch
                 ? "이미지를 늘림 (기본값)"
                 : "이미지를 반복 (패턴)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Comparison Section
    
    private var comparisonSection: some View {
        VStack(spacing: 15) {
            Text("실시간 비교")
                .font(.headline)
            
            // 샘플 이미지 (체크무늬 패턴)
            checkeredPattern
                .if(isResizable && useCapInsets) { view in
                    view.resizable(capInsets: EdgeInsets(
                        top: 10, leading: 10, bottom: 10, trailing: 10
                    ), resizingMode: resizingMode)
                }
                .if(isResizable && !useCapInsets) { view in
                    view.resizable(resizingMode: resizingMode)
                }
                .frame(width: targetWidth, height: targetHeight)
                .border(Color.blue, width: 2)
            
            Text(isResizable
                 ? "resizable() 적용: 크기 조정됨"
                 : "resizable() 없음: 원본 크기 (\(Int(targetWidth)) × \(Int(targetHeight)) frame은 무시)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Size Controls
    
    private var sizeControls: some View {
        VStack(spacing: 15) {
            Text("크기 조절")
                .font(.headline)
            
            VStack(spacing: 10) {
                HStack {
                    Text("너비")
                        .frame(width: 50, alignment: .leading)
                    Slider(value: $targetWidth, in: 100...350)
                    Text("\(Int(targetWidth))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.blue)
                }
                
                HStack {
                    Text("높이")
                        .frame(width: 50, alignment: .leading)
                    Slider(value: $targetHeight, in: 40...150)
                    Text("\(Int(targetHeight))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📖 이해하기")
                .font(.title2)
                .bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("resizable() 없음", systemImage: "lock")
                    .font(.headline)
                Text("""
                • 원본 크기로 고정
                • frame()은 클리핑 영역만 지정
                • SF Symbols는 font()로 크기 조절
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("resizable() 있음", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.headline)
                Text("""
                • 크기 조정 가능
                • frame()에 맞게 늘어남
                • aspectRatio()와 조합 가능
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("capInsets (9-patch)", systemImage: "square.grid.3x3")
                    .font(.headline)
                Text("""
                • 가장자리는 늘어나지 않음
                • 중앙 부분만 늘어남
                • 버튼 배경, 말풍선에 사용
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Label("resizingMode", systemImage: "square.on.square")
                    .font(.headline)
                Text("""
                • .stretch: 늘림 (기본값)
                • .tile: 반복 (패턴)
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Nine Patch Example
    
    private var ninePatchExample: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("9-Patch 예제")
                .font(.title2)
                .bold()
            
            Text("버튼 배경처럼 가장자리는 유지하고 중앙만 늘어남")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 15) {
                // 작은 버튼
                buttonExample(width: 120, height: 44, title: "작은 버튼")
                
                // 중간 버튼
                buttonExample(width: 200, height: 44, title: "중간 크기 버튼")
                
                // 큰 버튼
                buttonExample(width: 300, height: 60, title: "큰 버튼")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func buttonExample(width: CGFloat, height: CGFloat, title: String) -> some View {
        ZStack {
            checkeredPattern
                .resizable(capInsets: EdgeInsets(
                    top: 10, leading: 10, bottom: 10, trailing: 10
                ))
                .frame(width: width, height: height)
            
            Text(title)
                .foregroundStyle(.white)
                .font(.headline)
        }
    }
    
    // MARK: - Checkered Pattern
    
    private var checkeredPattern: Image {
        // 체크무늬 패턴을 SF Symbol로 시뮬레이션
        Image(systemName: "checkered")
            .foregroundStyle(.blue)
    }
}

#Preview {
    NavigationStack {
        ResizableOptionsView()
    }
}

