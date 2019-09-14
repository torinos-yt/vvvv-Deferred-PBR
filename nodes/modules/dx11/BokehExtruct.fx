struct BokehData{
	float2 position;
	float3 color;
	float CoC;
};

SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState colSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

AppendStructuredBuffer<BokehData> BokehBuffer : BACKBUFFER;

Texture2D inTex;
Texture2D depthTex;
Texture2D CoCTex;

float4x4 tIP;

uint2 R;
float2 iR;
float2 rpc;
float maxCoC = .02;

StructuredBuffer<float> fdepth;

static const float thresh = .2;
static const float cocthresh = .001;

float LinearDepth(float2 uv, float depth){
	float4 p = mul(float4(uv, depth, 1.0), tIP);
	return p.z / p.w;
}

[numthreads(8, 8, 1)]
void CS(uint3 dtid : SV_DispatchThreadID){
	if(dtid.x > R.x || dtid.y > R.y) return;
	BokehData data;
	float d = depthTex.SampleLevel(linearSampler, dtid.xy*iR, 0).r;
	float depth = LinearDepth(dtid.xy*iR, d)*100;
	float focusdepth = fdepth[0]*100;
	
	float CoC = CoCTex.SampleLevel(linearSampler, dtid.xy*iR, 0).r * maxCoC;
	
	float3 center = inTex.SampleLevel(linearSampler, dtid.xy*iR, 0).xyz;
	float3 NeighbourAve = 0;
	
	for(float i = -1.5; i <= 1.5; i++){
		for(float j = -1.5; j <= 1.5; j++){
			if(i == .5 || j == .5) continue;
			
			NeighbourAve += inTex.SampleLevel(linearSampler, dtid.xy*iR + float2(i, j)*rpc, 0).xyz;
		}
	}
	NeighbourAve /= 9.0;
	
	float3 lumCoeff = float3(.299, .587, .144);
	float cLum = dot(center, lumCoeff);
	if(cLum - dot(NeighbourAve, lumCoeff) > thresh 
		&& abs(CoC) > cocthresh && cLum > .75){
		data.position = float2(((dtid.xy * iR) * 2 - 1) * float2(1,-1));
		data.color = saturate(center);
		data.CoC = CoC;
		BokehBuffer.Append(data);
	}
}

technique11 cExtruct { 
	pass P0{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}