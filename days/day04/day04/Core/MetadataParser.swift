//
//  MetadataParser.swift
//  day04
//
//  다양한 메타데이터 포맷(EXIF, IPTC, XMP)을 통합 처리하는 파서
//

import Foundation
import ImageIO
import CoreLocation

/// 통합 메타데이터 모델
struct ImageMetadata {
    // EXIF
    var exifData: EXIFData?
    
    // IPTC
    var iptcData: IPTCData?
    
    // XMP (추후 확장)
    var rawXMP: String?
    
    // 파일 정보
    var fileSize: Int?
    var fileType: String?
    var fileCreationDate: Date?
}

/// IPTC 메타데이터 (저작권, 키워드 등)
struct IPTCData {
    var keywords: [String]?
    var caption: String?
    var creator: String?
    var copyright: String?
    var credit: String?
    var source: String?
    var headline: String?
    var city: String?
    var country: String?
    var dateCreated: String?
    
    var rawIPTC: [String: Any]?
}

/// 메타데이터 파서
class MetadataParser {
    
    /// URL에서 모든 메타데이터 로드
    static func loadMetadata(from url: URL) -> ImageMetadata? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("❌ CGImageSource 생성 실패")
            return nil
        }
        
        var metadata = ImageMetadata()
        
        // EXIF 데이터
        metadata.exifData = EXIFReader.loadEXIFData(from: url)
        
        // 전체 속성 가져오기
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return metadata
        }
        
        // IPTC 데이터
        metadata.iptcData = extractIPTCData(from: properties)
        
        // 파일 타입
        if let type = CGImageSourceGetType(source) {
            metadata.fileType = type as String
        }
        
        // 파일 정보
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            metadata.fileSize = attributes[.size] as? Int
            metadata.fileCreationDate = attributes[.creationDate] as? Date
        } catch {
            print("⚠️ 파일 속성 읽기 실패: \(error)")
        }
        
        return metadata
    }
    
    /// Data에서 모든 메타데이터 로드
    static func loadMetadata(from data: Data) -> ImageMetadata? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("❌ CGImageSource 생성 실패")
            return nil
        }
        
        var metadata = ImageMetadata()
        
        // EXIF 데이터
        metadata.exifData = EXIFReader.loadEXIFData(from: data)
        
        // 전체 속성 가져오기
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return metadata
        }
        
        // IPTC 데이터
        metadata.iptcData = extractIPTCData(from: properties)
        
        // 파일 타입
        if let type = CGImageSourceGetType(source) {
            metadata.fileType = type as String
        }
        
        // 파일 크기
        metadata.fileSize = data.count
        
        return metadata
    }
    
    // MARK: - IPTC
    
    /// IPTC 데이터 추출
    private static func extractIPTCData(from properties: [CFString: Any]) -> IPTCData? {
        guard let iptc = properties[kCGImagePropertyIPTCDictionary] as? [CFString: Any] else {
            return nil
        }
        
        var iptcData = IPTCData()
        
        // 키워드
        iptcData.keywords = iptc[kCGImagePropertyIPTCKeywords] as? [String]
        
        // 캡션/설명
        iptcData.caption = iptc[kCGImagePropertyIPTCCaptionAbstract] as? String
        
        // 작성자
        iptcData.creator = iptc[kCGImagePropertyIPTCCreatorContactInfo] as? String
        if iptcData.creator == nil {
            iptcData.creator = iptc[kCGImagePropertyIPTCByline] as? String
        }
        
        // 저작권
        iptcData.copyright = iptc[kCGImagePropertyIPTCCopyrightNotice] as? String
        
        // 크레딧
        iptcData.credit = iptc[kCGImagePropertyIPTCCredit] as? String
        
        // 출처
        iptcData.source = iptc[kCGImagePropertyIPTCSource] as? String
        
        // 헤드라인
        iptcData.headline = iptc[kCGImagePropertyIPTCHeadline] as? String
        
        // 위치
        iptcData.city = iptc[kCGImagePropertyIPTCCity] as? String
        iptcData.country = iptc[kCGImagePropertyIPTCCountryPrimaryLocationName] as? String
        
        // 날짜
        iptcData.dateCreated = iptc[kCGImagePropertyIPTCDateCreated] as? String
        
        // 원본 딕셔너리
        iptcData.rawIPTC = convertToStringDict(iptc)
        
        return iptcData
    }
    
    // MARK: - Utilities
    
    /// CFString 키를 String 키로 변환
    private static func convertToStringDict(_ dict: [CFString: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key as String] = value
        }
        return result
    }
    
    /// 날짜 문자열 파싱 (EXIF 포맷: "2025:10:22 14:30:45")
    static func parseEXIFDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
    
    /// Date를 EXIF 포맷으로 변환
    static func formatToEXIFDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - ImageMetadata Extensions

extension ImageMetadata {
    
    /// 파일 크기를 사람이 읽기 쉬운 형태로 변환
    var formattedFileSize: String? {
        guard let size = fileSize else { return nil }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    /// 파일 타입을 사람이 읽기 쉬운 형태로 변환
    var formattedFileType: String? {
        guard let type = fileType else { return nil }
        
        switch type {
        case "public.jpeg": return "JPEG"
        case "public.png": return "PNG"
        case "public.heic": return "HEIC"
        case "public.heif": return "HEIF"
        case "public.tiff": return "TIFF"
        case "com.adobe.raw-image": return "RAW"
        default: return type
        }
    }
    
    /// 파일 생성 날짜 포맷
    var formattedCreationDate: String? {
        guard let date = fileCreationDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    /// 모든 메타데이터 존재 여부
    var hasMetadata: Bool {
        return exifData != nil || iptcData != nil || rawXMP != nil
    }
    
    /// 요약 텍스트
    var summary: String {
        var lines: [String] = []
        
        if let exif = exifData {
            if let camera = exif.cameraModel {
                lines.append("📷 \(camera)")
            }
            if let dateTime = exif.formattedDateTime {
                lines.append("📅 \(dateTime)")
            }
            if let dimensions = exif.formattedDimensions {
                lines.append("📐 \(dimensions)")
            }
        }
        
        if let iptc = iptcData {
            if let creator = iptc.creator {
                lines.append("✍️ \(creator)")
            }
            if let copyright = iptc.copyright {
                lines.append("© \(copyright)")
            }
        }
        
        if let size = formattedFileSize {
            lines.append("💾 \(size)")
        }
        
        return lines.isEmpty ? "메타데이터 없음" : lines.joined(separator: "\n")
    }
}

// MARK: - IPTCData Extensions

extension IPTCData {
    
    /// 키워드 문자열
    var formattedKeywords: String? {
        guard let keywords = keywords, !keywords.isEmpty else { return nil }
        return keywords.joined(separator: ", ")
    }
    
    /// 위치 문자열
    var formattedLocation: String? {
        var components: [String] = []
        
        if let city = city {
            components.append(city)
        }
        if let country = country {
            components.append(country)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}


