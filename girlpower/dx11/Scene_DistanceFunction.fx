#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
#endif

float DistanceFunction(float3 p, inout float Material){
	float str = 2;
	float f = 7;
	
	float3 noisepos = float3(noise(p + Time*0.5)*str, noise(p+sin( Time * .1))*str, noise(p * .3)*str);
    return dBox(p, .6) - .1;
}

technique11 RemoveMe{}