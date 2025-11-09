//
//  GaussianBlur.metal
//  day13
//
//  Created on 11/10/25.
//

#include <metal_stdlib>
using namespace metal;

/// 수평 방향 Gaussian Blur 커널
kernel void gaussianBlurHorizontal(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float *weights [[buffer(0)]],
    constant int &radius [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
)
{
    // 텍스처 범위 체크
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = float4(0.0);
    float totalWeight = 0.0;
    
    // 수평 방향으로 블러 적용
    for (int i = -radius; i <= radius; i++) {
        int x = int(gid.x) + i;
        
        // 텍스처 경계 처리 (클램핑)
        x = clamp(x, 0, int(inTexture.get_width() - 1));
        
        uint2 coord = uint2(x, gid.y);
        float4 sample = inTexture.read(coord);
        float weight = weights[i + radius];
        
        color += sample * weight;
        totalWeight += weight;
    }
    
    // 정규화
    if (totalWeight > 0.0) {
        color /= totalWeight;
    }
    
    outTexture.write(color, gid);
}

/// 수직 방향 Gaussian Blur 커널
kernel void gaussianBlurVertical(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float *weights [[buffer(0)]],
    constant int &radius [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
)
{
    // 텍스처 범위 체크
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = float4(0.0);
    float totalWeight = 0.0;
    
    // 수직 방향으로 블러 적용
    for (int i = -radius; i <= radius; i++) {
        int y = int(gid.y) + i;
        
        // 텍스처 경계 처리 (클램핑)
        y = clamp(y, 0, int(inTexture.get_height() - 1));
        
        uint2 coord = uint2(gid.x, y);
        float4 sample = inTexture.read(coord);
        float weight = weights[i + radius];
        
        color += sample * weight;
        totalWeight += weight;
    }
    
    // 정규화
    if (totalWeight > 0.0) {
        color /= totalWeight;
    }
    
    outTexture.write(color, gid);
}

