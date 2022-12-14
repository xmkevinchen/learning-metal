//
//  Shaders.metal
//  LearningMetal
//
//  Created by Kai Chen on 8/20/22.
//

#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 textureCoordinate;
};

vertex VertexOut vertexShader(const device Vertex *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut out;
    
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = vertices[vid].position.xy;
    
    out.color = vertices[vid].color;
    
    out.textureCoordinate = vertices[vid].textureCoordinate;
    
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]], texture2d<half> colorTexture [[texture(0)]]) {
    
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);

    // return the color of the texture
    return float4(colorSample);
}


