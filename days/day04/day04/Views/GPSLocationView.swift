//
//  GPSLocationView.swift
//  day04
//
//  EXIF GPS 데이터를 지도에 표시하는 뷰
//

import SwiftUI
import MapKit
import PhotosUI

struct GPSLocationView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var exifData: EXIFData?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [LocationAnnotation] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("🗺️ GPS 위치 정보")
                        .font(.title2)
                        .bold()
                    
                    Text("이미지의 EXIF GPS 태그를 읽어 촬영 위치를 지도에 표시합니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                // PhotosPicker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("위치 정보가 있는 사진 선택")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        await loadPhotoWithGPS(from: newItem)
                    }
                }
                
                // 지도
                if !annotations.isEmpty {
                    VStack(spacing: 12) {
                        Text("📍 촬영 위치")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
                            MapMarker(coordinate: annotation.coordinate, tint: .red)
                        }
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 2)
                        )
                    }
                }
                
                // 선택된 이미지 썸네일
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                
                // GPS 상세 정보
                if let data = exifData, data.coordinate != nil {
                    VStack(spacing: 16) {
                        Divider()
                        
                        Text("📊 GPS 상세 정보")
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        GPSInfoCard(data: data)
                        
                        // 원본 GPS 딕셔너리
                        if let gps = data.rawGPS {
                            DisclosureGroup("🔍 원본 GPS 데이터 (\(gps.count)개 필드)") {
                                VStack(spacing: 8) {
                                    ForEach(gps.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        HStack {
                                            Text(key)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("\(value)")
                                                .font(.caption)
                                                .bold()
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                } else if selectedImage != nil {
                    VStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("GPS 정보가 없습니다")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GPS 정보가 없는 이유:")
                                .font(.subheadline)
                                .bold()
                            
                            Text("• 위치 서비스가 꺼진 상태에서 촬영")
                            Text("• 스크린샷 또는 편집된 이미지")
                            Text("• 개인정보 보호를 위해 제거됨")
                            Text("• 카메라 앱에서 GPS 권한 없음")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "location.north.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("사진을 선택하세요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("💡 Tip: 기본 카메라 앱으로 촬영한 사진은 GPS 정보가 포함되어 있습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }
            }
            .padding()
        }
        .navigationTitle("GPS 위치")
    }
    
    // MARK: - Functions
    
    private func loadPhotoWithGPS(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // UIImage 생성
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
                
                // EXIF 데이터 추출
                if let exif = EXIFReader.loadEXIFData(from: data) {
                    await MainActor.run {
                        exifData = exif
                        
                        // GPS 좌표가 있으면 지도 업데이트
                        if let coordinate = exif.coordinate {
                            updateMap(with: coordinate)
                        }
                    }
                }
            }
        } catch {
            print("❌ 사진 로드 실패: \(error)")
        }
    }
    
    private func updateMap(with coordinate: CLLocationCoordinate2D) {
        // 지역 설정
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // 마커 추가
        annotations = [LocationAnnotation(coordinate: coordinate)]
        
        print("✅ 지도 업데이트: \(coordinate.latitude), \(coordinate.longitude)")
    }
}

// MARK: - Models

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Components

struct GPSInfoCard: View {
    let data: EXIFData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 좌표
            if let coord = data.coordinate {
                VStack(alignment: .leading, spacing: 8) {
                    Label("좌표", systemImage: "location.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("위도 (Latitude)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.6f° %@", abs(coord.latitude), coord.latitude >= 0 ? "N" : "S"))
                                .font(.callout)
                                .bold()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("경도 (Longitude)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.6f° %@", abs(coord.longitude), coord.longitude >= 0 ? "E" : "W"))
                                .font(.callout)
                                .bold()
                        }
                    }
                }
            }
            
            Divider()
            
            // 고도
            if let altitude = data.altitude {
                HStack {
                    Label("고도", systemImage: "mountain.2.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Spacer()
                    Text(String(format: "%.1fm", altitude))
                        .bold()
                }
            }
            
            // 속도
            if let speed = data.speed {
                HStack {
                    Label("속도", systemImage: "speedometer")
                        .font(.headline)
                        .foregroundColor(.green)
                    Spacer()
                    Text(String(format: "%.1f km/h", speed))
                        .bold()
                }
            }
            
            // 촬영 방향
            if let direction = data.direction {
                HStack {
                    Label("촬영 방향", systemImage: "location.north.fill")
                        .font(.headline)
                        .foregroundColor(.purple)
                    Spacer()
                    Text(String(format: "%.1f°", direction))
                        .bold()
                    Text(directionName(direction))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // GPS 시간
            if let timestamp = data.gpsTimestamp {
                HStack {
                    Label("GPS 시간", systemImage: "clock")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Spacer()
                    Text(timestamp)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func directionName(_ degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5) / 45.0) % 8
        return directions[index]
    }
}

#Preview {
    NavigationView {
        GPSLocationView()
    }
}

