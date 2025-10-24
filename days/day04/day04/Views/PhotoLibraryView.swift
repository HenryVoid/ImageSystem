//
//  PhotoLibraryView.swift
//  day04
//
//  사진 라이브러리에서 이미지를 선택하고 EXIF를 읽는 뷰
//

import SwiftUI
import PhotosUI
import Photos

struct PhotoLibraryView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var exifData: EXIFData?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("📱 사진 라이브러리")
                        .font(.title2)
                        .bold()
                    
                    Text("기기의 사진 라이브러리에서 이미지를 선택하여 EXIF 데이터를 읽어옵니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // PhotosPicker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("사진 선택하기")
                            .font(.headline)
                        
                        Text("카메라로 촬영한 사진은 EXIF가 포함되어 있습니다")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 2)
                            .opacity(0.3)
                    )
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        await loadPhotoData(from: newItem)
                    }
                }
                
                // 로딩 인디케이터
                if isLoading {
                    ProgressView("EXIF 데이터 읽는 중...")
                        .padding()
                }
                
                // 선택된 이미지
                if let image = selectedImage {
                    VStack(spacing: 12) {
                        Text("선택된 이미지")
                            .font(.headline)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                }
                
                // EXIF 데이터 표시
                if let data = exifData {
                    VStack(spacing: 16) {
                        Divider()
                        
                        Text("📊 EXIF 정보")
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 핵심 정보만 간단히 표시
                        if data.cameraMake != nil || data.cameraModel != nil {
                            InfoCard(title: "카메라", icon: "camera.fill", color: .blue) {
                                if let make = data.cameraMake {
                                    KeyValueRow(key: "제조사", value: make)
                                }
                                if let model = data.cameraModel {
                                    KeyValueRow(key: "모델", value: model)
                                }
                            }
                        }
                        
                        if data.iso != nil || data.fNumber != nil {
                            InfoCard(title: "촬영 설정", icon: "gear", color: .orange) {
                                if let iso = data.formattedISO {
                                    KeyValueRow(key: "ISO", value: iso)
                                }
                                if let aperture = data.formattedAperture {
                                    KeyValueRow(key: "조리개", value: aperture)
                                }
                                if let shutter = data.formattedShutterSpeed {
                                    KeyValueRow(key: "셔터속도", value: shutter)
                                }
                                if let focal = data.formattedFocalLength {
                                    KeyValueRow(key: "초점거리", value: focal)
                                }
                            }
                        }
                        
                        if let dimensions = data.formattedDimensions {
                            InfoCard(title: "이미지 정보", icon: "photo", color: .purple) {
                                KeyValueRow(key: "크기", value: dimensions)
                                if let dateTime = data.formattedDateTime {
                                    KeyValueRow(key: "촬영 일시", value: dateTime)
                                }
                            }
                        }
                        
                        if let coord = data.coordinate {
                            InfoCard(title: "위치 정보", icon: "location.fill", color: .red) {
                                KeyValueRow(key: "좌표", value: data.formattedCoordinate ?? "N/A")
                                if let alt = data.formattedAltitude {
                                    KeyValueRow(key: "고도", value: alt)
                                }
                            }
                        }
                    }
                } else if selectedImage != nil && !isLoading {
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
        .navigationTitle("사진 라이브러리")
    }
    
    // MARK: - Functions
    
    private func loadPhotoData(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 이미지 데이터 로드
            if let data = try await item.loadTransferable(type: Data.self) {
                // UIImage 생성
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
                
                // EXIF 데이터 추출
                let exif = EXIFReader.loadEXIFData(from: data)
                await MainActor.run {
                    exifData = exif
                }
                
                print("✅ EXIF 로드 성공: \(exif?.cameraMake ?? "N/A")")
            }
        } catch {
            print("❌ 사진 로드 실패: \(error)")
        }
    }
}

// MARK: - Components

struct InfoCard<Content: View>: View {
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

struct KeyValueRow: View {
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
        PhotoLibraryView()
    }
}


