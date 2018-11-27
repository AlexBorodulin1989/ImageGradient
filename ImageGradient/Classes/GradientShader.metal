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

struct Vertex
{
    float4 position [[position]];
    float gradient;
    float2 texCoord;
};

vertex Vertex gradientVertex(const device VertexIn* vertex_array [[ buffer(0) ]],
                             unsigned int vid [[ vertex_id ]]) {
    VertexIn vertexIn = vertex_array[vid];
    Vertex vertexOut;
    vertexOut.texCoord = vertexIn.texCoord;
    vertexOut.position = float4(vertexIn.position, 1.0);
    float gradient = (vertexOut.position.y + 1) * 0.5;
    vertexOut.gradient = gradient;
    return vertexOut;
}

fragment float4 gradientFragment(Vertex inVertex [[stage_in]],
                                texture2d<float> tex [[texture(0)]],
                                sampler samplr [[sampler(0)]]) {
    float3 imageColor = tex.sample(samplr, inVertex.texCoord).rgb;
    return float4(imageColor, inVertex.gradient);
}
