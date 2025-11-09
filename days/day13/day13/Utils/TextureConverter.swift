//
//  TextureConverter.swift
//  day13
//
//  Created on 11/10/25.
//

import UIKit
import Metal
import MetalKit
import CoreGraphics

/// UIImage와 MTLTexture 간 변환을 담당하는 유틸리티
final class TextureConverter {
    private let device: MTLDevice
    private let textureLoader: MTKTextureLoader
    
    init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
    }
    
    /// UIImage를 MTLTexture로 변환
    func makeTexture(from image: UIImage) -> MTLTexture? {
        guard let cgImage = image.cgImage else {
            print("❌ CGImage 변환 실패")
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // 텍스처 디스크립터 생성
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            print("❌ Texture 생성 실패")
            return nil
        }
        
        // CGImage 데이터를 텍스처에 복사
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("❌ CGContext 생성 실패")
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else {
            print("❌ Context 데이터 추출 실패")
            return nil
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(
            region: region,
            mipmapLevel: 0,
            withBytes: data,
            bytesPerRow: bytesPerRow
        )
        
        return texture
    }
    
    /// MTLTexture를 UIImage로 변환
    func makeImage(from texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let imageByteCount = bytesPerRow * height
        
        // 텍스처 데이터 읽기
        var imageBytes = [UInt8](repeating: 0, count: imageByteCount)
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(
            &imageBytes,
            bytesPerRow: bytesPerRow,
            from: region,
            mipmapLevel: 0
        )
        
        // CGImage 생성
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let provider = CGDataProvider(
            data: Data(bytes: imageBytes, count: imageByteCount) as CFData
        ) else {
            print("❌ DataProvider 생성 실패")
            return nil
        }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            print("❌ CGImage 생성 실패")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 빈 텍스처 생성 (중간 결과 저장용)
    func makeEmptyTexture(width: Int, height: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        return device.makeTexture(descriptor: textureDescriptor)
    }
}

