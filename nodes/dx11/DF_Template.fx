#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
#endif
//Available Uniform Parameters
//
//float Time
//float DeltaTime
//float4 Variable : User Variable Controlled on vvvv patch

float DistanceFunction(float3 p, inout float Material){
	//Write your own distance function!!
	
    return dSphere(p, 1.0);
}

technique11 RemoveMe{}



