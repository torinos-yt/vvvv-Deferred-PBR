#include "../fxh/ao.fxh"

Texture2D AlbedoTex : ALBEDO;
Texture2D normalTex : NORMAL;

struct psInput{
	float4 p : SV_Position;
	float2 uv : TEXCOORD0;
};

float4x4 tIV;

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

psInput VS(VS_IN input)
{
    psInput output;
    output.p  = input.PosO;
    output.uv = input.TexCd.xy;
    return output;
}

struct aoout{
	float4 ao : SV_Target0;
	float4 bentNormal : SV_Target1;
	float depth : SV_Target2;
};

aoout PS_AO(psInput input){
	aoout ao;
	float4 albedo = AlbedoTex.Sample(linearSampler, input.uv);
	float3 normal = normalTex.Sample(linearSampler, input.uv).xyz;
	float depth;
	float4 GTAO = gtao(normal, input.uv, NumCircle, NumSlice, depth);
	ao.ao = float4(Multibounce(GTAO.w, albedo.xyz).xxx, 1.0);
	ao.bentNormal = float4(mul(GTAO.xyz*float3(1,-1,1), (float3x3)tIV), 1.0);
	ao.depth = depth;
	return ao;
}

technique10 GTAO{
	pass P0{
		SetVertexShader(CompileShader(vs_4_0,VS()));
		SetPixelShader(CompileShader(ps_4_0,PS_AO()));
	}
}




