//
//  ShaderTypes.h
//  LearningMetal
//
//  Created by Kai Chen on 8/20/22.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float2 position;
    vector_float4 color;
    vector_float2 textureCoordinate;
} Vertex;


#endif /* ShaderTypes_h */
