//
//  MetalBlurProcessor.swift
//  day13
//
//  Created on 11/10/25.
//

import UIKit
import Metal
import MetalKit

/// Metal Compute Shader로 Gaussian Blur를 수행하는 프로세서
final class MetalBlurProcessor {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let textureConverter: TextureConverter
    
    private var horizontalPipelineState: MTLComputePipelineState?
    private var verticalPipelineState: MTLComputePipelineState?
    
    init?() {
        guard let context = MetalContext.shared else {
            print("❌ MetalContext 초기화 실패")
            return nil
        }
        
        self.device = context.device
        self.commandQueue = context.commandQueue
        self.textureConverter = TextureConverter(device: device)
        
        setupPipeline(library: context.library)
    }
    
    /// 파이프라인 상태 생성
    private func setupPipeline(library: MTLLibrary) {
        do {
            // 수평 블러 파이프라인
            guard let horizontalFunction = library.makeFunction(name: "gaussianBlurHorizontal") else {
                print("❌ gaussianBlurHorizontal 함수를 찾을 수 없습니다")
                return
            }
            horizontalPipelineState = try device.makeComputePipelineState(function: horizontalFunction)
            
            // 수직 블러 파이프라인
            guard let verticalFunction = library.makeFunction(name: "gaussianBlurVertical") else {
                print("❌ gaussianBlurVertical 함수를 찾을 수 없습니다")
                return
            }
            verticalPipelineState = try device.makeComputePipelineState(function: verticalFunction)
            
            print("✅ Metal 파이프라인 생성 성공")
        } catch {
            print("❌ 파이프라인 생성 실패: \(error)")
        }
    }
    
    /// 이미지에 블러 적용
    func blur(image: UIImage, radius: Int) -> BlurResult? {
        let startTime = CACurrentMediaTime()
        
        guard let inputTexture = textureConverter.makeTexture(from: image) else {
            print("❌ 입력 텍스처 생성 실패")
            return nil
        }
        
        // 중간 텍스처 생성 (수평 블러 결과 저장)
        guard let intermediateTexture = textureConverter.makeEmptyTexture(
            width: inputTexture.width,
            height: inputTexture.height
        ) else {
            print("❌ 중간 텍스처 생성 실패")
            return nil
        }
        
        // 최종 출력 텍스처 생성
        guard let outputTexture = textureConverter.makeEmptyTexture(
            width: inputTexture.width,
            height: inputTexture.height
        ) else {
            print("❌ 출력 텍스처 생성 실패")
            return nil
        }
        
        // Gaussian 가중치 계산
        let weights = createGaussianWeights(radius: radius)
        
        guard let weightsBuffer = device.makeBuffer(
            bytes: weights,
            length: weights.count * MemoryLayout<Float>.stride,
            options: .storageModeShared
        ) else {
            print("❌ 가중치 버퍼 생성 실패")
            return nil
        }
        
        var radiusValue = Int32(radius)
        guard let radiusBuffer = device.makeBuffer(
            bytes: &radiusValue,
            length: MemoryLayout<Int32>.stride,
            options: .storageModeShared
        ) else {
            print("❌ 반경 버퍼 생성 실패")
            return nil
        }
        
        // 커맨드 버퍼 생성
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let horizontalEncoder = commandBuffer.makeComputeCommandEncoder(),
              let horizontalPipeline = horizontalPipelineState else {
            print("❌ 수평 블러 인코더 생성 실패")
            return nil
        }
        
        // 1st Pass: 수평 블러
        horizontalEncoder.setComputePipelineState(horizontalPipeline)
        horizontalEncoder.setTexture(inputTexture, index: 0)
        horizontalEncoder.setTexture(intermediateTexture, index: 1)
        horizontalEncoder.setBuffer(weightsBuffer, offset: 0, index: 0)
        horizontalEncoder.setBuffer(radiusBuffer, offset: 0, index: 1)
        
        let threadGroupSize = MTLSize(
            width: min(16, horizontalPipeline.threadExecutionWidth),
            height: min(16, horizontalPipeline.maxTotalThreadsPerThreadgroup / 16),
            depth: 1
        )
        let threadGroups = MTLSize(
            width: (inputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (inputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        horizontalEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        horizontalEncoder.endEncoding()
        
        // 2nd Pass: 수직 블러
        guard let verticalEncoder = commandBuffer.makeComputeCommandEncoder(),
              let verticalPipeline = verticalPipelineState else {
            print("❌ 수직 블러 인코더 생성 실패")
            return nil
        }
        
        verticalEncoder.setComputePipelineState(verticalPipeline)
        verticalEncoder.setTexture(intermediateTexture, index: 0)
        verticalEncoder.setTexture(outputTexture, index: 1)
        verticalEncoder.setBuffer(weightsBuffer, offset: 0, index: 0)
        verticalEncoder.setBuffer(radiusBuffer, offset: 0, index: 1)
        verticalEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        verticalEncoder.endEncoding()
        
        // 실행 및 완료 대기
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let endTime = CACurrentMediaTime()
        let processingTime = (endTime - startTime) * 1000.0  // 밀리초로 변환
        
        // 결과 이미지 생성
        guard let resultImage = textureConverter.makeImage(from: outputTexture) else {
            print("❌ 결과 이미지 생성 실패")
            return nil
        }
        
        return BlurResult(
            image: resultImage,
            processingTime: processingTime,
            method: .metal,
            radius: radius
        )
    }
    
    /// Gaussian 가중치 배열 생성
    private func createGaussianWeights(radius: Int) -> [Float] {
        let sigma = Float(radius) / 3.0
        let twoSigmaSquare = 2.0 * sigma * sigma
        let kernelSize = 2 * radius + 1
        var weights = [Float](repeating: 0, count: kernelSize)
        var sum: Float = 0
        
        for i in 0..<kernelSize {
            let x = Float(i - radius)
            let weight = exp(-(x * x) / twoSigmaSquare)
            weights[i] = weight
            sum += weight
        }
        
        // 정규화
        for i in 0..<kernelSize {
            weights[i] /= sum
        }
        
        return weights
    }
}

