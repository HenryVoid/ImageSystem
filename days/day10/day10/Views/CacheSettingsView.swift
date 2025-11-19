//
//  CacheSettingsView.swift
//  day10
//
//  캐시 설정 UI
//

import SwiftUI

struct CacheSettingsView: View {
    // MARK: - Properties
    
    @State private var selectedPreset: CachePreset = .balanced
    @State private var customConfig = CacheConfiguration.recommended()
    @State private var selectedLibrary: CacheLibrary = .kingfisher
    @State private var showingResetAlert = false
    
    enum CacheLibrary: String, CaseIterable {
        case kingfisher = "Kingfisher"
        case nuke = "Nuke"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // 라이브러리 선택
                librarySection
                
                // 프리셋 선택
                presetSection
                
                // 커스텀 설정
                if selectedPreset == .custom {
                    customSettingsSection
                }
                
                // 고급 옵션
                advancedOptionsSection
                
                // 액션
                actionsSection
            }
            .navigationTitle("캐시 설정")
            .navigationBarTitleDisplayMode(.inline)
            .alert("설정 초기화", isPresented: $showingResetAlert) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive, action: resetSettings)
            } message: {
                Text("캐시 설정을 기본값으로 초기화하시겠습니까?")
            }
        }
    }
    
    // MARK: - Library Section
    
    private var librarySection: some View {
        Section {
            Picker("라이브러리", selection: $selectedLibrary) {
                ForEach(CacheLibrary.allCases, id: \.self) { library in
                    Text(library.rawValue).tag(library)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("캐시 라이브러리")
        } footer: {
            Text("Kingfisher와 Nuke 중 선택하세요")
        }
    }
    
    // MARK: - Preset Section
    
    private var presetSection: some View {
        Section {
            Picker("프리셋", selection: $selectedPreset) {
                ForEach(CachePreset.allCases, id: \.self) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .onChange(of: selectedPreset) { newValue in
                if newValue != .custom {
                    customConfig = newValue.configuration
                }
            }
            
            // 프리셋 설명
            VStack(alignment: .leading, spacing: 8) {
                presetDescription
            }
            .padding(.vertical, 8)
        } header: {
            Text("캐시 프리셋")
        }
    }
    
    private var presetDescription: some View {
        Group {
            switch selectedPreset {
            case .minimal:
                Label("저사양 기기에 적합", systemImage: "iphone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .balanced:
                Label("일반적인 사용에 권장", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            case .aggressive:
                Label("고성능 기기에 최적화", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .custom:
                Label("사용자 정의 설정", systemImage: "gearshape.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Custom Settings Section
    
    private var customSettingsSection: some View {
        Group {
            Section {
                // 메모리 캐시
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("메모리 캐시")
                        Spacer()
                        Text("\(customConfig.memoryCacheSizeMB) MB")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(customConfig.memoryCacheSizeMB) },
                            set: { customConfig.memoryCacheSizeMB = Int($0) }
                        ),
                        in: 10...300,
                        step: 10
                    )
                }
                
                // 디스크 캐시
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("디스크 캐시")
                        Spacer()
                        Text("\(customConfig.diskCacheSizeMB) MB")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(customConfig.diskCacheSizeMB) },
                            set: { customConfig.diskCacheSizeMB = Int($0) }
                        ),
                        in: 50...2000,
                        step: 50
                    )
                }
                
                // 이미지 개수 제한
                Stepper(
                    value: $customConfig.imageCountLimit,
                    in: 10...500,
                    step: 10
                ) {
                    HStack {
                        Text("이미지 개수")
                        Spacer()
                        Text("\(customConfig.imageCountLimit)개")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("용량 설정")
            }
            
            Section {
                // TTL 설정
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("TTL (Time To Live)")
                        Spacer()
                        Text(ttlDescription)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("", selection: $customConfig.ttlSeconds) {
                        Text("5분").tag(TimeInterval(300))
                        Text("1시간").tag(TimeInterval(3600))
                        Text("1일").tag(TimeInterval(86400))
                        Text("7일").tag(TimeInterval(604800))
                        Text("무제한").tag(TimeInterval.infinity)
                    }
                    .pickerStyle(.segmented)
                }
            } header: {
                Text("만료 설정")
            } footer: {
                Text("캐시된 이미지의 유효 기간을 설정합니다")
            }
        }
    }
    
    private var ttlDescription: String {
        if customConfig.ttlSeconds.isInfinite {
            return "무제한"
        } else if customConfig.ttlSeconds < 3600 {
            return "\(Int(customConfig.ttlSeconds / 60))분"
        } else if customConfig.ttlSeconds < 86400 {
            return "\(Int(customConfig.ttlSeconds / 3600))시간"
        } else {
            return "\(Int(customConfig.ttlSeconds / 86400))일"
        }
    }
    
    // MARK: - Advanced Options Section
    
    private var advancedOptionsSection: some View {
        Section {
            Toggle("자동 정리", isOn: $customConfig.autoCleanupEnabled)
            Toggle("메모리 경고 시 삭제", isOn: $customConfig.clearOnMemoryWarning)
            Toggle("백그라운드 시 메모리 정리", isOn: $customConfig.clearMemoryOnBackground)
        } header: {
            Text("고급 옵션")
        } footer: {
            Text("자동 캐시 관리 옵션을 설정합니다")
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        Section {
            Button(action: applySettings) {
                Label("설정 적용", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: { showingResetAlert = true }) {
                Label("설정 초기화", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            
            Button(action: showCurrentSettings) {
                Label("현재 설정 보기", systemImage: "info.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Actions
    
    private func applySettings() {
        let config = selectedPreset == .custom ? customConfig : selectedPreset.configuration
        
        switch selectedLibrary {
        case .kingfisher:
            KingfisherCacheManager.shared.configure(with: config)
        case .nuke:
            NukeCacheManager.shared.configure(with: config)
        }
        
        print("✅ 설정 적용 완료")
        print(config.summary())
    }
    
    private func resetSettings() {
        selectedPreset = .balanced
        customConfig = CacheConfiguration.recommended()
        applySettings()
        print("🔄 설정 초기화 완료")
    }
    
    private func showCurrentSettings() {
        let config = selectedPreset == .custom ? customConfig : selectedPreset.configuration
        print(config.summary())
    }
}

// MARK: - Preview

#Preview {
    CacheSettingsView()
}




























