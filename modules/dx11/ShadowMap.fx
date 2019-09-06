//@author: vux
//@help: template for standard shaders
//@tags: template
//@credits: 

Texture2D texture2d <string uiname="Texture";>;

#define depthOffset 0.0001

float  shadowThreshold = 1.0f; 
float  bias			   = 0.01f; 
float  slopeScaledBias = 0.01f; 
float  depthBiasClamp  = 0.1f;

SamplerState linearSampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

struct Light{
	float3 pos;
	float3 amb;
	float3 diff;
	float4x4 VP;
};

StructuredBuffer<Light> lights : LIGHTBUFFER;
int vpindex;
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV : LAYERVIEW;
	float4x4 tVP : LAYERVIEWPROJECTION;	
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
};


struct VS_IN
{
	float4 PosO : POSITION;

};

struct vs2ps
{
	float4 PosW: POSITION;
	float4 PosWVP : SV_Position;
};

vs2ps VS(VS_IN input)
{
	vs2ps output;
	output.PosW  = mul(input.PosO, tW);
	output.PosWVP = mul(input.PosO,mul(tW,lights[vpindex].VP));
	return output;
}




float2 PS(vs2ps In): SV_Target
{
	float2 col = 0;
	float dist = distance(lights[vpindex].pos, In.PosW.xyz) + depthOffset;
	float  maxDepthSlope = max( abs( ddx( dist ) ), abs( ddy( dist ) ) );
	
	float  shadowBias = bias + slopeScaledBias * maxDepthSlope;
	shadowBias = min( shadowBias, depthBiasClamp );
	
	col.r = dist - shadowBias;
	col.g = dist * dist;
	return col;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




