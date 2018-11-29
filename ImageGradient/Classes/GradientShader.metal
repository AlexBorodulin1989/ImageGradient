//
//  GradientShader.metal
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 08/11/2018.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    packed_float3 position;
    packed_float2 texCoord;
};

struct VertexOut
{
    float4 position [[position]];
    float gradient;
    float2 texCoord;
};

vertex VertexOut gradientVertex(const device VertexIn* vertex_array [[ buffer(0) ]],
                             unsigned int vid [[ vertex_id ]]) {
    VertexIn vertexIn = vertex_array[vid];
    VertexOut vertexOut;
    vertexOut.texCoord = vertexIn.texCoord;
    vertexOut.position = float4(vertexIn.position, 1.0);
    float gradient = (vertexOut.position.y + 1) * 0.5;
    vertexOut.gradient = gradient;
    return vertexOut;
}

fragment float4 gradientFragment(VertexOut outVertex [[stage_in]],
                                texture2d<float> tex [[texture(0)]],
                                sampler samplr [[sampler(0)]]) {
    float3 pixelColor = tex.sample(samplr, outVertex.texCoord).rgb;
    return float4(pixelColor, outVertex.gradient);
}
