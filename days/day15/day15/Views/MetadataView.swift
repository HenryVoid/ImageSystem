//
//  MetadataView.swift
//  day15
//
//  EXIF 메타데이터 표시
//

import SwiftUI
import Photos
import PhotosUI

struct MetadataView: View {
    @StateObject private var libraryManager = PhotoLibraryManager()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedAsset: PHAsset?
    @State private var exifData: EXIFData?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("📊 EXIF 메타데이터")
                        .font(.title2)
                        .bold()
                    
                    Text("선택한 이미지의 촬영 정보, 위치 정보 등을 확인할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                
                // 이미지 선택
                VStack(spacing: 12) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        Label("이미지 선택하기", systemImage: "photo.on.rectangle.angled")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            await loadMetadata(from: newItem)
                        }
                    }
                }
                
                // 로딩 인디케이터
                if isLoading {
                    ProgressView("메타데이터 읽는 중...")
                        .padding()
                }
                
                // 메타데이터 표시
                if let exifData = exifData {
                    VStack(spacing: 16) {
                        // 카메라 정보
                        if exifData.cameraMake != nil || exifData.cameraModel != nil {
                            MetadataSection(
                                title: "카메라",
                                icon: "camera.fill",
                                color: .blue
                            ) {
                                if let make = exifData.cameraMake {
                                    MetadataRow(key: "제조사", value: make)
                                }
                                if let model = exifData.cameraModel {
                                    MetadataRow(key: "모델", value: model)
                                }
                                if let software = exifData.software {
                                    MetadataRow(key: "소프트웨어", value: software)
                                }
                            }
                        }
                        
                        // 촬영 설정
                        if exifData.iso != nil || exifData.fNumber != nil {
                            MetadataSection(
                                title: "촬영 설정",
                                icon: "gear",
                                color: .orange
                            ) {
                                if let iso = exifData.formattedISO {
                                    MetadataRow(key: "ISO", value: iso)
                                }
                                if let aperture = exifData.formattedAperture {
                                    MetadataRow(key: "조리개", value: aperture)
                                }
                                if let shutter = exifData.formattedShutterSpeed {
                                    MetadataRow(key: "셔터속도", value: shutter)
                                }
                                if let focal = exifData.formattedFocalLength {
                                    MetadataRow(key: "초점거리", value: focal)
                                }
                            }
                        }
                        
                        // 이미지 정보
                        MetadataSection(
                            title: "이미지 정보",
                            icon: "photo",
                            color: .purple
                        ) {
                            if let dimensions = exifData.formattedDimensions {
                                MetadataRow(key: "크기", value: dimensions)
                            }
                            if let dateTime = exifData.formattedDateTime {
                                MetadataRow(key: "촬영 일시", value: dateTime)
                            }
                            if let orientation = exifData.orientation {
                                MetadataRow(key: "방향", value: "\(orientation)")
                            }
                        }
                        
                        // 위치 정보
                        if let coordinate = exifData.coordinate {
                            MetadataSection(
                                title: "위치 정보",
                                icon: "location.fill",
                                color: .red
                            ) {
                                MetadataRow(key: "좌표", value: exifData.formattedCoordinate ?? "N/A")
                                if let alt = exifData.formattedAltitude {
                                    MetadataRow(key: "고도", value: alt)
                                }
                            }
                        }
                    }
                } else if selectedItem != nil && !isLoading {
                    // 메타데이터 없음
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("EXIF 데이터가 없습니다")
                            .font(.headline)
                        
                        Text("스크린샷이나 편집된 이미지는 EXIF가 제거되었을 수 있습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("메타데이터")
    }
    
    // MARK: - Functions
    
    private func loadMetadata(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 이미지 데이터 로드
            if let data = try await item.loadTransferable(type: Data.self) {
                // EXIF 데이터 추출
                let exif = EXIFReader.loadEXIFData(from: data)
                await MainActor.run {
                    exifData = exif
                }
            }
        } catch {
            print("❌ 메타데이터 로드 실패: \(error)")
        }
    }
}

// MARK: - Metadata Section

struct MetadataSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Metadata Row

struct MetadataRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

#Preview {
    NavigationView {
        MetadataView()
    }
}
