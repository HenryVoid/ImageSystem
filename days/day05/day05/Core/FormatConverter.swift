//
//  FormatConverter.swift
//  day05
//
//  이미지 포맷 변환 로직 - JPEG/PNG/HEIC
//

import UIKit
import ImageIO
import AVFoundation
import UniformTypeIdentifiers

/// 이미지 포맷
enum ImageFormat: Equatable {
    case jpeg(quality: CGFloat)
    case png
    case heic(quality: CGFloat)
    
    var displayName: String {
        switch self {
        case .jpeg(let quality):
            return "JPEG \(Int(quality * 100))%"
        case .png:
            return "PNG"
        case .heic(let quality):
            return "HEIC \(Int(quality * 100))%"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        }
    }
    
    var utType: CFString {
        switch self {
        case .jpeg:
            return kUTTypeJPEG
        case .png:
            return kUTTypePNG
        case .heic:
            if #available(iOS 11.0, *) {
                return AVFileType.heic as CFString
            } else {
                return kUTTypeJPEG  // 폴백
            }
        }
    }
}

/// 포맷 변환기
class FormatConverter {
    
    // MARK: - 변환
    
    /// 이미지를 특정 포맷으로 변환
    static func convert(_ image: UIImage, to format: ImageFormat) -> Data? {
        switch format {
        case .jpeg(let quality):
            return convertToJPEG(image: image, quality: quality)
        case .png:
            return convertToPNG(image: image)
        case .heic(let quality):
            return convertToHEIC(image: image, quality: quality)
        }
    }
    
    /// JPEG로 변환
    private static func convertToJPEG(image: UIImage, quality: CGFloat) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    /// PNG로 변환
    private static func convertToPNG(image: UIImage) -> Data? {
        return image.pngData()
    }
    
    /// HEIC로 변환 (iOS 11+)
    private static func convertToHEIC(image: UIImage, quality: CGFloat) -> Data? {
        guard #available(iOS 11.0, *) else {
            print("⚠️ HEIC는 iOS 11+ 필요, JPEG로 폴백")
            return convertToJPEG(image: image, quality: quality)
        }
        
        guard let cgImage = image.cgImage else { return nil }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data,
            AVFileType.heic as CFString,
            1,
            nil
        ) else {
            print("❌ CGImageDestination 생성 실패")
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            print("❌ CGImageDestination finalize 실패")
            return nil
        }
        
        return data as Data
    }
    
    // MARK: - 파일 크기 추정
    
    /// 포맷별 예상 파일 크기 (바이트)
    static func estimateFileSize(for image: UIImage, format: ImageFormat) -> Int? {
        return convert(image, to: format)?.count
    }
    
    // MARK: - 포맷 감지
    
    /// 데이터에서 이미지 포맷 감지
    static func detectFormat(from data: Data) -> String? {
        guard data.count > 12 else { return nil }
        
        let bytes = [UInt8](data.prefix(12))
        
        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return "JPEG"
        }
        
        // PNG: 89 50 4E 47
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "PNG"
        }
        
        // HEIC: 'ftyp' at offset 4
        if bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            // 추가 확인: heic, heix, hevc, hevx
            let subtype = String(bytes: bytes[8...11], encoding: .ascii)
            if subtype?.starts(with: "hei") == true || subtype?.starts(with: "hev") == true {
                return "HEIC"
            }
        }
        
        return "Unknown"
    }
    
    // MARK: - 메타데이터 보존
    
    /// 원본 메타데이터를 보존하며 변환
    static func convertPreservingMetadata(
        image: UIImage,
        originalURL: URL,
        to format: ImageFormat
    ) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        // 원본 메타데이터 읽기
        guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            print("⚠️ 메타데이터 읽기 실패, 메타데이터 없이 변환")
            return convert(image, to: format)
        }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data,
            format.utType,
            1,
            nil
        ) else {
            return nil
        }
        
        // 품질 옵션 추가
        var options = metadata
        switch format {
        case .jpeg(let quality), .heic(let quality):
            options[kCGImageDestinationLossyCompressionQuality] = quality
        case .png:
            break
        }
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
    
    // MARK: - 투명도 처리
    
    /// PNG의 투명 배경을 색상으로 채우기
    static func removeAlpha(from image: UIImage, backgroundColor: UIColor = .white) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale
        
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

// MARK: - 벤치마크

extension FormatConverter {
    
    /// 포맷 변환 벤치마크 결과
    struct BenchmarkResult {
        let format: ImageFormat
        let data: Data?
        let duration: TimeInterval  // 초
        let fileSize: Int          // 바이트
        
        var formattedDuration: String {
            String(format: "%.2f ms", duration * 1000)
        }
        
        var formattedFileSize: String {
            if fileSize < 1024 {
                return "\(fileSize) B"
            } else if fileSize < 1024 * 1024 {
                return String(format: "%.1f KB", Double(fileSize) / 1024.0)
            } else {
                return String(format: "%.2f MB", Double(fileSize) / (1024.0 * 1024.0))
            }
        }
        
        /// 크기 비율 (JPEG 100% 기준)
        func sizeRatio(baseline: Int) -> Double {
            guard baseline > 0 else { return 0 }
            return Double(fileSize) / Double(baseline)
        }
    }
    
    /// 벤치마크 실행
    static func benchmark(_ image: UIImage, format: ImageFormat) -> BenchmarkResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let data = convert(image, to: format)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        return BenchmarkResult(
            format: format,
            data: data,
            duration: duration,
            fileSize: data?.count ?? 0
        )
    }
    
    /// 여러 포맷을 한번에 벤치마크
    static func benchmarkAll(_ image: UIImage) -> [BenchmarkResult] {
        let formats: [ImageFormat] = [
            .jpeg(quality: 1.0),
            .jpeg(quality: 0.9),
            .jpeg(quality: 0.8),
            .jpeg(quality: 0.7),
            .jpeg(quality: 0.5),
            .png,
            .heic(quality: 0.9),
            .heic(quality: 0.8),
            .heic(quality: 0.7)
        ]
        
        return formats.map { format in
            benchmark(image, format: format)
        }
    }
}

// MARK: - 적응형 품질 조절

extension FormatConverter {
    
    /// 타겟 파일 크기에 맞게 자동으로 품질 조절
    static func adaptiveCompress(
        _ image: UIImage,
        targetFileSize: Int,
        format: ImageFormat = .jpeg(quality: 1.0),
        maxAttempts: Int = 10
    ) -> Data? {
        var low: CGFloat = 0.1
        var high: CGFloat = 1.0
        var bestData: Data?
        
        for _ in 0..<maxAttempts {
            let quality = (low + high) / 2
            
            let testFormat: ImageFormat
            switch format {
            case .jpeg:
                testFormat = .jpeg(quality: quality)
            case .heic:
                testFormat = .heic(quality: quality)
            case .png:
                // PNG는 품질 조절 불가
                return convertToPNG(image: image)
            }
            
            guard let data = convert(image, to: testFormat) else { continue }
            
            let currentSize = data.count
            
            // 타겟의 90~100% 범위면 성공
            if currentSize <= targetFileSize && currentSize >= Int(Double(targetFileSize) * 0.9) {
                return data
            }
            
            // 이진 탐색
            if currentSize > targetFileSize {
                high = quality
            } else {
                low = quality
                bestData = data  // 타겟보다 작지만 가장 가까운 결과 저장
            }
        }
        
        return bestData
    }
}

// MARK: - 배치 변환

extension FormatConverter {
    
    /// 여러 이미지 일괄 변환
    static func batchConvert(
        images: [UIImage],
        to format: ImageFormat,
        progress: ((Int, Int) -> Void)? = nil
    ) -> [Data] {
        var results: [Data] = []
        
        for (index, image) in images.enumerated() {
            autoreleasepool {
                if let data = convert(image, to: format) {
                    results.append(data)
                }
                
                progress?(index + 1, images.count)
            }
        }
        
        return results
    }
    
    /// 병렬 배치 변환
    static func batchConvertConcurrent(
        images: [UIImage],
        to format: ImageFormat,
        progress: @escaping (Int, Int) -> Void,
        completion: @escaping ([Data]) -> Void
    ) {
        let queue = DispatchQueue(label: "format.conversion", attributes: .concurrent)
        let group = DispatchGroup()
        
        var results: [Int: Data] = [:]
        let lock = NSLock()
        var completed = 0
        
        for (index, image) in images.enumerated() {
            group.enter()
            queue.async {
                autoreleasepool {
                    if let data = convert(image, to: format) {
                        lock.lock()
                        results[index] = data
                        completed += 1
                        let current = completed
                        lock.unlock()
                        
                        DispatchQueue.main.async {
                            progress(current, images.count)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // 순서대로 정렬
            let sortedResults = results.sorted(by: { $0.key < $1.key }).map { $0.value }
            completion(sortedResults)
        }
    }
}

