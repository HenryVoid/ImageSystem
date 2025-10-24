//
//  EXIFReader.swift
//  day04
//
//  EXIF 메타데이터를 읽는 핵심 로직
//

import Foundation
import UIKit
import ImageIO
import CoreLocation

/// EXIF 데이터를 구조화한 모델
struct EXIFData {
    // 기본 정보
    var pixelWidth: Int?
    var pixelHeight: Int?
    var dpi: Int?
    var orientation: Int?
    var colorModel: String?
    
    // 카메라 정보 (TIFF)
    var cameraMake: String?
    var cameraModel: String?
    var software: String?
    
    // 촬영 설정 (EXIF)
    var iso: [Int]?
    var fNumber: Double?
    var exposureTime: Double?
    var focalLength: Double?
    var lensModel: String?
    var flash: Int?
    var whiteBalance: Int?
    var meteringMode: Int?
    
    // 날짜/시간
    var dateTimeOriginal: String?
    var dateTimeDigitized: String?
    
    // GPS
    var coordinate: CLLocationCoordinate2D?
    var altitude: Double?
    var speed: Double?
    var direction: Double?
    var gpsTimestamp: String?
    
    // 원본 딕셔너리 (모든 데이터)
    var rawProperties: [String: Any]?
    var rawEXIF: [String: Any]?
    var rawTIFF: [String: Any]?
    var rawGPS: [String: Any]?
}

/// EXIF 데이터를 읽는 리더
class EXIFReader {
    
    /// URL에서 EXIF 데이터 로드
    static func loadEXIFData(from url: URL) -> EXIFData? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("❌ CGImageSource 생성 실패")
            return nil
        }
        
        return extractEXIFData(from: source)
    }
    
    /// UIImage에서 EXIF 데이터 로드
    /// 주의: UIImage는 EXIF를 보존하지 않으므로, 가능하면 URL을 사용하세요
    static func loadEXIFData(from image: UIImage) -> EXIFData? {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            print("❌ JPEG 데이터 변환 실패")
            return nil
        }
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("❌ CGImageSource 생성 실패")
            return nil
        }
        
        return extractEXIFData(from: source)
    }
    
    /// Data에서 EXIF 데이터 로드
    static func loadEXIFData(from data: Data) -> EXIFData? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("❌ CGImageSource 생성 실패")
            return nil
        }
        
        return extractEXIFData(from: source)
    }
    
    // MARK: - Private
    
    /// CGImageSource에서 EXIF 추출
    private static func extractEXIFData(from source: CGImageSource) -> EXIFData? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            print("❌ 속성 추출 실패")
            return nil
        }
        
        var exifData = EXIFData()
        
        // 기본 속성
        exifData.pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int
        exifData.pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int
        exifData.dpi = properties[kCGImagePropertyDPIWidth] as? Int
        exifData.orientation = properties[kCGImagePropertyOrientation] as? Int
        exifData.colorModel = properties[kCGImagePropertyColorModel] as? String
        
        // TIFF 딕셔너리 (카메라 정보)
        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            exifData.cameraMake = tiff[kCGImagePropertyTIFFMake] as? String
            exifData.cameraModel = tiff[kCGImagePropertyTIFFModel] as? String
            exifData.software = tiff[kCGImagePropertyTIFFSoftware] as? String
            exifData.rawTIFF = convertToStringDict(tiff)
        }
        
        // EXIF 딕셔너리 (촬영 설정)
        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            exifData.iso = exif[kCGImagePropertyExifISOSpeedRatings] as? [Int]
            exifData.fNumber = exif[kCGImagePropertyExifFNumber] as? Double
            exifData.exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double
            exifData.focalLength = exif[kCGImagePropertyExifFocalLength] as? Double
            exifData.lensModel = exif[kCGImagePropertyExifLensModel] as? String
            exifData.flash = exif[kCGImagePropertyExifFlash] as? Int
            exifData.whiteBalance = exif[kCGImagePropertyExifWhiteBalance] as? Int
            exifData.meteringMode = exif[kCGImagePropertyExifMeteringMode] as? Int
            exifData.dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal] as? String
            exifData.dateTimeDigitized = exif[kCGImagePropertyExifDateTimeDigitized] as? String
            exifData.rawEXIF = convertToStringDict(exif)
        }
        
        // GPS 딕셔너리
        if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            exifData.coordinate = extractCoordinate(from: gps)
            exifData.altitude = gps[kCGImagePropertyGPSAltitude] as? Double
            exifData.speed = gps[kCGImagePropertyGPSSpeed] as? Double
            exifData.direction = gps[kCGImagePropertyGPSImgDirection] as? Double
            exifData.gpsTimestamp = gps[kCGImagePropertyGPSTimeStamp] as? String
            exifData.rawGPS = convertToStringDict(gps)
        }
        
        // 원본 딕셔너리
        exifData.rawProperties = convertToStringDict(properties)
        
        return exifData
    }
    
    /// GPS 딕셔너리에서 좌표 추출
    private static func extractCoordinate(from gps: [CFString: Any]) -> CLLocationCoordinate2D? {
        guard let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String else {
            return nil
        }
        
        // 방향에 따라 부호 결정
        let latitude = latRef == "N" ? lat : -lat
        let longitude = lonRef == "E" ? lon : -lon
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// CFString 키를 String 키로 변환
    private static func convertToStringDict(_ dict: [CFString: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key as String] = value
        }
        return result
    }
}

// MARK: - 포맷 헬퍼

extension EXIFData {
    
    /// 셔터속도를 사람이 읽기 쉬운 형태로 변환
    var formattedShutterSpeed: String? {
        guard let exposureTime = exposureTime else { return nil }
        
        if exposureTime >= 1 {
            return String(format: "%.1fs", exposureTime)
        } else {
            let denominator = Int(1.0 / exposureTime)
            return "1/\(denominator)s"
        }
    }
    
    /// 조리개를 f/x.x 형태로 변환
    var formattedAperture: String? {
        guard let fNumber = fNumber else { return nil }
        return String(format: "f/%.1f", fNumber)
    }
    
    /// ISO를 문자열로 변환
    var formattedISO: String? {
        guard let iso = iso?.first else { return nil }
        return "ISO \(iso)"
    }
    
    /// 초점거리를 mm 형태로 변환
    var formattedFocalLength: String? {
        guard let focalLength = focalLength else { return nil }
        return String(format: "%.1fmm", focalLength)
    }
    
    /// 이미지 크기
    var formattedDimensions: String? {
        guard let width = pixelWidth, let height = pixelHeight else { return nil }
        return "\(width) × \(height)"
    }
    
    /// 촬영 날짜를 포맷 (EXIF: "2025:10:22 14:30:45" → "2025-10-22 14:30:45")
    var formattedDateTime: String? {
        guard let dateTime = dateTimeOriginal else { return nil }
        return dateTime.replacingOccurrences(of: ":", with: "-", options: [], range: dateTime.startIndex..<dateTime.index(dateTime.startIndex, offsetBy: 10))
    }
    
    /// GPS 좌표를 도분초 형태로 변환
    var formattedCoordinate: String? {
        guard let coordinate = coordinate else { return nil }
        
        let latDirection = coordinate.latitude >= 0 ? "N" : "S"
        let lonDirection = coordinate.longitude >= 0 ? "E" : "W"
        
        return String(format: "%.6f° %@, %.6f° %@",
                      abs(coordinate.latitude), latDirection,
                      abs(coordinate.longitude), lonDirection)
    }
    
    /// 고도를 m 형태로 변환
    var formattedAltitude: String? {
        guard let altitude = altitude else { return nil }
        return String(format: "%.1fm", altitude)
    }
    
    /// 플래시 상태
    var formattedFlash: String? {
        guard let flash = flash else { return nil }
        
        // 플래시 비트 플래그 해석
        let fired = (flash & 0x01) != 0
        return fired ? "발광됨" : "발광 안됨"
    }
    
    /// 화이트밸런스
    var formattedWhiteBalance: String? {
        guard let wb = whiteBalance else { return nil }
        return wb == 0 ? "자동" : "수동"
    }
}


