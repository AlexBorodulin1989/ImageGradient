//
//  GradientShader.metal
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 08/11/2018.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    packed_float2 position;
    packed_float2 texCoord;
    float alpha;
};

struct Pixel
{
    float4 position [[position]];
    float2 texCoord;
    float alpha;
};

vertex Pixel gradientVertex(const device Vertex* vertex_array [[ buffer(0) ]],
                             unsigned int vid [[ vertex_id ]]) {
    Vertex vert = vertex_array[vid];
    Pixel pixel;
    pixel.texCoord = vert.texCoord;
    pixel.position = float4(vert.position, 0.5, 1.0);
    pixel.alpha = vert.alpha;
    return pixel;
}

fragment float4 gradientFragment(Pixel pixel [[stage_in]],
                                texture2d<float> tex [[texture(0)]],
                                sampler samplr [[sampler(0)]]) {
    float3 pixelColor = tex.sample(samplr, pixel.texCoord).rgb;
    return float4(pixelColor, pixel.alpha);
}
