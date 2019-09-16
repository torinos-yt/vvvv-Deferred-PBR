#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
#endif

float DistanceFunction(float3 p, inout float Material){
	float str = .6;
	float f = 3.5;
	
    return dSphere(p, 1.0) + .08;
}

technique11 RemoveMe{}