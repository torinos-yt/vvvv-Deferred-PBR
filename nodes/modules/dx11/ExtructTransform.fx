#include <packs\dx11.particles\nodes\modules\Core\fxh\AlgebraFunctions.fxh>

#ifndef MAXPARTICLECOUNT
#define MAXPARTICLECOUNT 1000
#endif

struct Particle {
	#if defined(COMPOSITESTRUCT)
  		COMPOSITESTRUCT
 	#else
		float3 position;
	#endif
};

StructuredBuffer<Particle> ParticleBuffer;
StructuredBuffer<uint> AlivePointerBuffer;
StructuredBuffer<uint> AliveCounterBuffer;

float4x4 defaultTransform;
uint cnt;

RWStructuredBuffer<float4x4> TransformBuffer : BACKBUFFER;

[numthreads(8, 1, 1)]
void CS(uint3 dtid : SV_DispatchThreadID)
{
	if(dtid.x >= AliveCounterBuffer[0] || dtid.x >= MAXPARTICLECOUNT) return;
	uint particleIndex = AlivePointerBuffer[dtid.x];
	
	float4x4 t = defaultTransform;
	
	#if defined(KNOW_SCALE)
		t = mul(t,MatrixScaling(ParticleBuffer[particleIndex].scale));
 	#endif
	#if defined(KNOW_ROTATION)
		t = mul(t,MatrixRotation(ParticleBuffer[particleIndex].rotation));
 	#endif
	t[3].xyz += ParticleBuffer[particleIndex].position;
	
	TransformBuffer[particleIndex] = t;
}

technique11 cst { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }