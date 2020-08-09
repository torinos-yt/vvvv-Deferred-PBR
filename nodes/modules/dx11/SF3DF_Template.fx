#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
#endif
//Available Uniform Parameters
//
//float Time
//float DeltaTime
//float4 Variable : User Variable Controlled on vvvv patch

#ifndef SF3D
#define SF3D dPlane
#endif

float DistanceFunction(float3 p, inout float Material){
	//Write your own distance function!!
	
    return SF3D(p);
}

technique11 RemoveMe{}



