#if !defined(ITE)
#define ITE 32
#endif

Texture2D texture2d <string uiname="Texture";>;

#define depthOffset 0.0001
#define EPS 0.0001
float mindist<float uistep = .001;> = .01;

float  shadowThreshold = 1.0f; 
float  bias			   = 0.01f; 
float  slopeScaledBias = 0.01f; 
float  depthBiasClamp  = 0.1f;

float stepLength = 1.0;

SamplerState linearSampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

StructuredBuffer<float4x4> tVPI : LIGHTVIEWPROJECTIONINVERSE;
int vpindex;
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV : LAYERVIEW;
	float4x4 tVP : LAYERVIEWPROJECTION;	
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tWI : WORLDINVERSE;
};


struct VS_IN
{
	float4 PosO : POSITION;
	float2 uv : TEXCOORD0;

};

struct vs2ps
{
	float4 PosWVP : SV_Position;
	float2 uv : TECXOORD0;
};

vs2ps VS(VS_IN input)
{
	vs2ps output;
	output.PosWVP = input.PosO;
	output.uv = input.uv;
	return output;
}


float2 PS(vs2ps In): SV_Target
{
	float3 rayPos = mul(float4(lights[vpindex].pos, 1), tWI);
	
	float2 rayDir = (In.uv * 2 - 1) * float2(1, -1);
	float4 rs =  mul(float4(rayDir, 1, 1), tVPI[vpindex]);
	float3 ray = normalize(mul(normalize(rs.xyz / rs.w), tWI));
	
	float maxdist = 50;
	float3 normal = 0;
	float alpha = 0;
	
	float dist = 0;
	float total = 0;

	float id = 0;
	for(int i = 0; i < ITE; i++){
		dist = DistanceFunction(rayPos, id);
		
		if(dist < mindist * max(total, 1)){ 
			alpha = 1;
			
			break;
		}
		rayPos += ray * dist * stepLength;
		total += dist;
		if(total > maxdist) break;
	}
	float2 col = 0;
	float ldist = distance(lights[vpindex].pos, mul(float4(rayPos, 1), tW).xyz) + depthOffset;
	float  maxDepthSlope = max( abs( ddx( ldist ) ), abs( ddy( ldist ) ) );
	
	float  shadowBias = bias + slopeScaledBias * maxDepthSlope;
	shadowBias = min( shadowBias, depthBiasClamp );
	
	col.r = ldist - shadowBias;
	col.g = ldist * ldist;
	return col * alpha;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




