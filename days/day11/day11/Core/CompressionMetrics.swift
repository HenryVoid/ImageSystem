import Foundation
import UIKit

// MARK: - Image Format Enum

enum ImageFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
    case webp = "WebP"
    
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        case .webp: return "webp"
        }
    }
    
    var icon: String {
        switch self {
        case .jpeg: return "photo"
        case .png: return "square.on.circle"
        case .heic: return "cube.box"
        case .webp: return "globe"
        }
    }
    
    var color: UIColor {
        switch self {
        case .jpeg: return .systemBlue
        case .png: return .systemGreen
        case .heic: return .systemPurple
        case .webp: return .systemOrange
        }
    }
}

// MARK: - Compression Result

struct CompressionResult: Identifiable {
    let id = UUID()
    let format: ImageFormat
    let quality: Double
    let originalSize: Int
    let compressedSize: Int
    let compressionTime: TimeInterval
    let compressedImage: UIImage?
    
    var compressionRatio: Double {
        guard originalSize > 0 else { return 0 }
        return Double(compressedSize) / Double(originalSize)
    }
    
    var compressionPercentage: Double {
        return (1.0 - compressionRatio) * 100.0
    }
    
    var formattedOriginalSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(originalSize), countStyle: .file)
    }
    
    var formattedCompressedSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(compressedSize), countStyle: .file)
    }
    
    var formattedCompressionTime: String {
        return String(format: "%.1f ms", compressionTime * 1000)
    }
    
    var formattedCompressionRatio: String {
        return String(format: "%.1f%%", compressionPercentage)
    }
}

// MARK: - Benchmark Result

struct BenchmarkResult: Identifiable {
    let id = UUID()
    let format: ImageFormat
    let quality: Double
    let results: [CompressionResult]
    
    var averageSize: Int {
        guard !results.isEmpty else { return 0 }
        return results.map { $0.compressedSize }.reduce(0, +) / results.count
    }
    
    var averageTime: TimeInterval {
        guard !results.isEmpty else { return 0 }
        return results.map { $0.compressionTime }.reduce(0, +) / Double(results.count)
    }
    
    var averageCompressionRatio: Double {
        guard !results.isEmpty else { return 0 }
        return results.map { $0.compressionPercentage }.reduce(0, +) / Double(results.count)
    }
    
    var formattedAverageSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(averageSize), countStyle: .file)
    }
    
    var formattedAverageTime: String {
        return String(format: "%.1f ms", averageTime * 1000)
    }
    
    var formattedAverageCompressionRatio: String {
        return String(format: "%.1f%%", averageCompressionRatio)
    }
}

// MARK: - Quality Preset

enum QualityPreset: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var quality: Double {
        switch self {
        case .high: return 0.9
        case .medium: return 0.7
        case .low: return 0.5
        }
    }
    
    var description: String {
        switch self {
        case .high: return "90% - 최고 품질"
        case .medium: return "70% - 균형"
        case .low: return "50% - 높은 압축"
        }
    }
}

// MARK: - Image Resolution

enum ImageResolution: String, CaseIterable {
    case small = "300x300"
    case medium = "800x600"
    case large = "1920x1080"
    
    var size: CGSize {
        switch self {
        case .small: return CGSize(width: 300, height: 300)
        case .medium: return CGSize(width: 800, height: 600)
        case .large: return CGSize(width: 1920, height: 1080)
        }
    }
    
    var description: String {
        switch self {
        case .small: return "작게 (300×300)"
        case .medium: return "중간 (800×600)"
        case .large: return "크게 (1920×1080)"
        }
    }
}


