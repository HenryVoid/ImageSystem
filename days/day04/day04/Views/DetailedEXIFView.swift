//
//  DetailedEXIFView.swift
//  day04
//
//  섹션별로 상세한 EXIF 메타데이터를 표시하는 뷰
//

import SwiftUI

struct DetailedEXIFView: View {
    @State private var exifData: EXIFData?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔍 상세 EXIF 정보")
                        .font(.title2)
                        .bold()
                    
                    Text("EXIF, TIFF, GPS 등 모든 메타데이터를 섹션별로 표시합니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                
                // 이미지 썸네일
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                
                // 상세 정보 표시
                if let data = exifData {
                    VStack(spacing: 16) {
                        // 기본 속성
                        DetailSection(title: "📐 기본 속성", icon: "info.circle.fill", color: .blue) {
                            if let width = data.pixelWidth {
                                DetailRow(key: "PixelWidth", value: "\(width)", description: "이미지 너비")
                            }
                            if let height = data.pixelHeight {
                                DetailRow(key: "PixelHeight", value: "\(height)", description: "이미지 높이")
                            }
                            if let dpi = data.dpi {
                                DetailRow(key: "DPI", value: "\(dpi)", description: "인치당 픽셀")
                            }
                            if let colorModel = data.colorModel {
                                DetailRow(key: "ColorModel", value: colorModel, description: "색상 모델")
                            }
                            if let orientation = data.orientation {
                                DetailRow(key: "Orientation", value: "\(orientation)", description: orientationDesc(orientation))
                            }
                        }
                        
                        // TIFF 딕셔너리
                        if let tiff = data.rawTIFF, !tiff.isEmpty {
                            DetailSection(title: "📷 TIFF (카메라)", icon: "camera.fill", color: .green) {
                                ForEach(tiff.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    DetailRow(key: key, value: "\(value)", description: tiffDescription(key))
                                }
                            }
                        }
                        
                        // EXIF 딕셔너리
                        if let exif = data.rawEXIF, !exif.isEmpty {
                            DetailSection(title: "⚙️ EXIF (촬영 설정)", icon: "gearshape.fill", color: .orange) {
                                ForEach(exif.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    DetailRow(
                                        key: key,
                                        value: formatValue(value, for: key),
                                        description: exifDescription(key)
                                    )
                                }
                            }
                        }
                        
                        // GPS 딕셔너리
                        if let gps = data.rawGPS, !gps.isEmpty {
                            DetailSection(title: "🗺️ GPS (위치)", icon: "location.fill", color: .red) {
                                ForEach(gps.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    DetailRow(key: key, value: "\(value)", description: gpsDescription(key))
                                }
                            }
                        }
                        
                        // 원본 딕셔너리 (고급)
                        if let props = data.rawProperties {
                            DisclosureGroup("🔧 전체 속성 (\(props.count)개)") {
                                VStack(spacing: 8) {
                                    ForEach(props.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        if !["Exif", "TIFF", "GPS"].contains(where: { key.contains($0) }) {
                                            HStack(alignment: .top) {
                                                Text(key)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 100, alignment: .leading)
                                                
                                                Text("\(value)")
                                                    .font(.caption)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .padding()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                } else {
                    Text("EXIF 데이터가 없습니다.")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // 샘플 로드 버튼
                Button(action: loadSampleEXIF) {
                    Label("샘플 이미지 로드", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("상세 EXIF")
        .onAppear {
            loadSampleEXIF()
        }
    }
    
    // MARK: - Functions
    
    private func loadSampleEXIF() {
        if let image = UIImage(named: "sample-exif") {
            selectedImage = image
            exifData = EXIFReader.loadEXIFData(from: image)
            
            if exifData == nil {
                if let url = Bundle.main.url(forResource: "sample-exif", withExtension: "jpg") {
                    exifData = EXIFReader.loadEXIFData(from: url)
                }
            }
        }
    }
    
    private func formatValue(_ value: Any, for key: String) -> String {
        if key.contains("ExposureTime"), let time = value as? Double {
            if time >= 1 {
                return String(format: "%.1fs", time)
            } else {
                return "1/\(Int(1.0/time))s"
            }
        }
        
        if key.contains("FNumber"), let f = value as? Double {
            return String(format: "f/%.1f", f)
        }
        
        if key.contains("FocalLength"), let focal = value as? Double {
            return String(format: "%.1fmm", focal)
        }
        
        return "\(value)"
    }
    
    // MARK: - Descriptions
    
    private func orientationDesc(_ value: Int) -> String {
        switch value {
        case 1: return "정상"
        case 3: return "180° 회전"
        case 6: return "90° 시계방향"
        case 8: return "90° 반시계방향"
        default: return "기타"
        }
    }
    
    private func tiffDescription(_ key: String) -> String {
        switch key {
        case "Make": return "카메라 제조사"
        case "Model": return "카메라 모델명"
        case "Software": return "펌웨어/소프트웨어"
        case "DateTime": return "수정 날짜"
        case "XResolution": return "가로 해상도"
        case "YResolution": return "세로 해상도"
        case "ResolutionUnit": return "해상도 단위"
        default: return ""
        }
    }
    
    private func exifDescription(_ key: String) -> String {
        switch key {
        case "ISOSpeedRatings": return "ISO 감도"
        case "FNumber": return "조리개 값 (F-stop)"
        case "ExposureTime": return "셔터속도 (노출 시간)"
        case "FocalLength": return "초점거리"
        case "LensModel": return "렌즈 모델"
        case "Flash": return "플래시 사용 여부"
        case "WhiteBalance": return "화이트밸런스 설정"
        case "MeteringMode": return "측광 모드"
        case "DateTimeOriginal": return "원본 촬영 일시"
        case "DateTimeDigitized": return "디지털화 일시"
        case "ExposureProgram": return "노출 프로그램"
        case "ExposureBiasValue": return "노출 보정"
        case "MaxApertureValue": return "최대 조리개"
        case "SubjectDistance": return "피사체 거리"
        case "LightSource": return "광원"
        case "ColorSpace": return "색 공간"
        case "PixelXDimension": return "유효 너비"
        case "PixelYDimension": return "유효 높이"
        case "SensingMethod": return "센서 방식"
        case "SceneType": return "장면 유형"
        case "ExposureMode": return "노출 모드"
        case "DigitalZoomRatio": return "디지털 줌 비율"
        case "FocalLenIn35mmFilm": return "35mm 환산 초점거리"
        case "SceneCaptureType": return "장면 캡처 유형"
        case "Contrast": return "대비"
        case "Saturation": return "채도"
        case "Sharpness": return "선명도"
        default: return ""
        }
    }
    
    private func gpsDescription(_ key: String) -> String {
        switch key {
        case "Latitude": return "위도 (도)"
        case "LatitudeRef": return "위도 방향 (N/S)"
        case "Longitude": return "경도 (도)"
        case "LongitudeRef": return "경도 방향 (E/W)"
        case "Altitude": return "고도 (미터)"
        case "AltitudeRef": return "고도 기준 (해발/해저)"
        case "TimeStamp": return "GPS 시간"
        case "DateStamp": return "GPS 날짜"
        case "Speed": return "이동 속도"
        case "SpeedRef": return "속도 단위"
        case "ImgDirection": return "촬영 방향 (도)"
        case "ImgDirectionRef": return "방향 기준"
        case "DestBearing": return "목적지 방위"
        case "DestBearingRef": return "방위 기준"
        default: return ""
        }
    }
}

// MARK: - Components

struct DetailSection<Content: View>: View {
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
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 4) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let key: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(key)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.callout)
                    .bold()
            }
            
            if !description.isEmpty {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        DetailedEXIFView()
    }
}


