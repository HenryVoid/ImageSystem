//
//  CustomKernelCode.swift
//  day24
//
//  Created on 12/01/25.
//

import Foundation

/// Metal Kernel 소스 코드를 문자열로 관리하는 구조체입니다.
/// 런타임 컴파일 방식(CIColorKernel(source:))을 사용합니다.
struct CustomKernelCode {
    
    /// 1. Pink Tint Kernel
    /// 입력 색상에 고정된 핑크빛을 곱합니다.
    static let pinkTint = """
    #include <CoreImage/CoreImage.h>
    extern "C" {
        namespace coreimage {
            float4 pinkTint(sample_t s) {
                // 핑크색상 정의 (R, G, B, A)
                float4 tintColor = float4(1.0, 0.7, 0.8, 1.0);
                
                // 원본 색상과 틴트 색상을 곱함 (Multiply blending)
                return s * tintColor;
            }
        }
    }
    """
    
    /// 2. Emotion Kernel (과제 A)
    /// 감정 점수(0~100)에 따라 색조를 변경합니다.
    /// 0.0 (우울): 차가운 파란색 톤
    /// 100.0 (기쁨): 따뜻한 오렌지/노란색 톤
    static let emotion = """
    #include <CoreImage/CoreImage.h>
    extern "C" {
        namespace coreimage {
            float4 emotionFilter(sample_t s, float emotionScore) {
                // emotionScore: 0.0 ~ 100.0 -> 정규화 0.0 ~ 1.0
                float factor = clamp(emotionScore / 100.0, 0.0, 1.0);
                
                // Cold Color (Blue-ish)
                float4 cold = float4(0.2, 0.4, 0.8, 1.0);
                
                // Warm Color (Orange-ish)
                float4 warm = float4(1.0, 0.8, 0.4, 1.0);
                
                // 점수에 따라 두 색상을 보간 (mix)
                float4 targetOverlay = mix(cold, warm, factor);
                
                // 원본 이미지와 오버레이 색상을 섞음 (Soft Light 느낌으로 0.5 정도 강도)
                // 여기서는 단순하게 mix를 사용하여 원본과 필터색을 50:50으로 섞거나,
                // 곱하기(multiply) 후 보간할 수도 있습니다.
                // 학습용으로 간단하게 원본 * 오버레이 결과를 원본과 mix합니다.
                
                float4 tinted = s * targetOverlay;
                return mix(s, tinted, 0.7); // 70% 강도로 필터 적용
            }
        }
    }
    """
    
    /// 3. Highlight Kernel (과제 B)
    /// 밝은 영역(Luminance가 높은 곳)에만 틴트를 적용합니다.
    static let highlight = """
    #include <CoreImage/CoreImage.h>
    extern "C" {
        namespace coreimage {
            // 밝기(Luminance) 계산 도우미 함수
            float getLuminance(float3 color) {
                return dot(color, float3(0.2126, 0.7152, 0.0722));
            }
            
            float4 highlightFilter(sample_t s) {
                // 1. 픽셀의 밝기 계산
                float luma = getLuminance(s.rgb);
                
                // 2. 하이라이트 마스크 생성 (밝기가 0.7 이상인 부분부터 적용)
                // smoothstep을 사용하여 경계면을 부드럽게 처리
                float mask = smoothstep(0.6, 0.9, luma);
                
                // 3. 적용할 하이라이트 색상 (Hot Pink)
                float4 highlightColor = float4(1.0, 0.2, 0.8, 1.0);
                
                // 4. 마스크 강도에 따라 원본과 하이라이트 색상을 믹스
                // 마스크가 1에 가까울수록 하이라이트 색상이 덮어씌워짐
                // (여기서는 하이라이트 색을 '더하는' 느낌보다는 틴트를 '입히는' 방식)
                
                float4 tinted = s * highlightColor;
                
                // 마스크만큼만 틴트 적용
                return mix(s, tinted, mask);
            }
        }
    }
    """
}

