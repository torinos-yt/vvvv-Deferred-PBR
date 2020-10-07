RWStructuredBuffer<float> focusDepth : BACKBUFFER;
Texture2D DepthTex;
SamplerState s0 <string uiname="Sampler State";>
{Filter=MIN_MAG_MIP_POINT;AddressU=CLAMP;AddressV=CLAMP;};
float4x4 tPI;

float2 focus;

float damping;

[numthreads(1,1,1)]
void CS(uint3 dtid : SV_DispatchThreadID){
	float2 uv = focus*0.5*float2(1,-1)+0.5;
	float depth = DepthTex.SampleLevel(s0,uv,0).r;
	float4 pos = float4(focus, depth, 1);
	pos = mul(pos, tPI);
	depth = pos.z / pos.w;
	focusDepth[0] = lerp(focusDepth[0], depth, damping);
}

technique11 cst { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }