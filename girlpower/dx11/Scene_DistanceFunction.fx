#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
#endif

float DistanceFunction(float3 p, inout float Material){
	float str = .6;
	float f = 3.5;
	
	float3 noisepos = float3(noise(p*f + Time*0.5)*str, noise(p*f+sin( Time * .1))*str, noise(p*f * .3)*str);
    return dBox(p + noisepos, .6) - .1;
}

technique11 RemoveMe{}