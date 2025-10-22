//
//  BasicEXIFView.swift
//  day04
//
//  기본 EXIF 정보를 표시하는 뷰
//

import SwiftUI

struct BasicEXIFView: View {
    @State private var exifData: EXIFData?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("📷 기본 EXIF 정보")
                        .font(.title2)
                        .bold()
                    
                    Text("샘플 이미지에서 기본적인 EXIF 메타데이터를 읽어옵니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // 이미지 표시
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                
                // EXIF 정보 표시
                if let data = exifData {
                    VStack(spacing: 16) {
                        // 기본 정보
                        SectionView(title: "기본 정보") {
                            if let dimensions = data.formattedDimensions {
                                InfoRow(label: "이미지 크기", value: dimensions)
                            }
                            if let colorModel = data.colorModel {
                                InfoRow(label: "색상 모델", value: colorModel)
                            }
                            if let dpi = data.dpi {
                                InfoRow(label: "해상도", value: "\(dpi) DPI")
                            }
                            if let orientation = data.orientation {
                                InfoRow(label: "방향", value: orientationDescription(orientation))
                            }
                        }
                        
                        // 카메라 정보
                        if data.cameraMake != nil || data.cameraModel != nil {
                            SectionView(title: "카메라 정보") {
                                if let make = data.cameraMake {
                                    InfoRow(label: "제조사", value: make)
                                }
                                if let model = data.cameraModel {
                                    InfoRow(label: "모델", value: model)
                                }
                                if let software = data.software {
                                    InfoRow(label: "소프트웨어", value: software)
                                }
                            }
                        }
                        
                        // 촬영 설정
                        if data.iso != nil || data.fNumber != nil || data.exposureTime != nil {
                            SectionView(title: "촬영 설정") {
                                if let iso = data.formattedISO {
                                    InfoRow(label: "ISO", value: iso)
                                }
                                if let aperture = data.formattedAperture {
                                    InfoRow(label: "조리개", value: aperture)
                                }
                                if let shutter = data.formattedShutterSpeed {
                                    InfoRow(label: "셔터속도", value: shutter)
                                }
                                if let focal = data.formattedFocalLength {
                                    InfoRow(label: "초점거리", value: focal)
                                }
                            }
                        }
                        
                        // 날짜/시간
                        if let dateTime = data.formattedDateTime {
                            SectionView(title: "촬영 일시") {
                                InfoRow(label: "촬영 날짜", value: dateTime)
                            }
                        }
                        
                        // GPS (기본 정보만)
                        if let coord = data.formattedCoordinate {
                            SectionView(title: "위치 정보") {
                                InfoRow(label: "좌표", value: coord)
                                if let alt = data.formattedAltitude {
                                    InfoRow(label: "고도", value: alt)
                                }
                            }
                        }
                    }
                } else {
                    Text("EXIF 데이터가 없습니다.")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // 샘플 로드 버튼
                Button(action: loadSampleEXIF) {
                    Label("샘플 이미지 로드", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("기본 EXIF")
        .onAppear {
            loadSampleEXIF()
        }
    }
    
    // MARK: - Functions
    
    private func loadSampleEXIF() {
        // Assets에서 샘플 이미지 로드
        if let image = UIImage(named: "sample-exif") {
            selectedImage = image
            
            // UIImage에서 직접 EXIF 읽기 시도
            exifData = EXIFReader.loadEXIFData(from: image)
            
            if exifData == nil {
                print("⚠️ UIImage에서 EXIF를 읽을 수 없습니다. 번들 URL을 시도합니다.")
                
                // 번들에서 URL로 직접 읽기
                if let url = Bundle.main.url(forResource: "sample-exif", withExtension: "jpg") {
                    exifData = EXIFReader.loadEXIFData(from: url)
                }
            }
        }
    }
    
    private func orientationDescription(_ value: Int) -> String {
        switch value {
        case 1: return "정상 (1)"
        case 3: return "180° 회전 (3)"
        case 6: return "90° 시계방향 (6)"
        case 8: return "90° 반시계방향 (8)"
        default: return "기타 (\(value))"
        }
    }
}

// MARK: - Components

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

#Preview {
    NavigationView {
        BasicEXIFView()
    }
}

