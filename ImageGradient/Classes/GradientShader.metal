//
//  File.metal
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 08/11/2018.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 gradientVertex(const device packed_float3* vertex_array [[ buffer(0) ]],
                             unsigned int vid [[ vertex_id ]]) {
    return float4(vertex_array[vid], 1.0);
}

fragment half4 gradientFragment() {
    return half4(1.0, 0.5, 0.5, 1);
}
