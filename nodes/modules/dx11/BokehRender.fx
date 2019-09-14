Texture2D BokehTex <string uiname="Texture";>;
#define PI 3.14159265
struct BokehData{
	float2 position;
	float3 color;
	float CoC;
};

float rotation<string uiname = "Bokeh Rotation"; float uistep = 1.0;> = 0;
float aspect;

StructuredBuffer<BokehData> BokehBuffer;

SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct vs2gs{
    float4 pos: POSITION0;
	float size : TEXCOORD0;
	float4 col : COLOR1;
};

struct gs2ps{
	float4 pos: SV_Position;
	float2 uv: TEXCOORD1;
	float4 col: TEXCOORD2;
	float CoC : TEXCOORD3;
};

float2x2 rot2D(float angle){
	angle *= PI/180;
	return float2x2(cos(angle), -sin(angle),
					sin(angle), cos(angle));
}

vs2gs VS(uint iid : SV_InstanceID){
    vs2gs output;
    output.pos  = float4(BokehBuffer[iid].position, 0, 1);
	//output.pos = float4(0,0,0,1);
    output.size = BokehBuffer[iid].CoC;
	output.col = float4(BokehBuffer[iid].color, 1);
    return output;
}

[maxvertexcount(4)]
void GS(point vs2gs input[1], inout TriangleStream<gs2ps> gsout){
	gs2ps o = (gs2ps)0;
	float4 pos = input[0].pos;
	float size = abs(input[0].size)*.5;
	float2 asp = float2(aspect, 1);
	float2x2 mRot = rot2D(-sign(input[0].size) * rotation - 180*(sign(input[0].size)*.5+.5));
	
	o.col = input[0].col;
	o.pos = float4(0,0,pos.z,1);
	o.CoC = abs(input[0].size)*.5;
		
	o.pos.xy = pos.xy + mul(float2(-1,1)*size, mRot)*asp;
	o.uv = float2(0,0);
	gsout.Append(o);
	o.pos.xy = pos.xy + mul(float2(-1,-1)*size, mRot)*asp;
	o.uv = float2(0,1);
	gsout.Append(o);
	o.pos.xy = pos.xy + mul(float2(1,1)*size, mRot)*asp;
	o.uv = float2(1,0);
	gsout.Append(o);
	o.pos.xy = pos.xy + mul(float2(1,-1)*size, mRot)*asp;
	o.uv = float2(1,1);
	gsout.Append(o);
		
	gsout.RestartStrip();
}

float4 PS(gs2ps In): SV_Target{
    float4 col = BokehTex.Sample(linearSampler,In.uv) * In.col * min(1.0, 1.0 / (In.CoC*150));
    return col;
}

technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




