//
//  File.metal
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 08/11/2018.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
    half4 color;
};

vertex Vertex gradientVertex(const device packed_float3* vertex_array [[ buffer(0) ]],
                             unsigned int vid [[ vertex_id ]]) {
    Vertex vertexOut;
    vertexOut.position = float4(vertex_array[vid], 1.0);
    float gradient = (vertexOut.position.y + 1) * 0.5;
    vertexOut.color = half4(0.0, 1.0, 0.0, gradient);
    return vertexOut;
}

fragment half4 gradientFragment(Vertex inVertex [[stage_in]]) {
    return inVertex.color;
}
