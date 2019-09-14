#ifndef GBUFFERCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\GBuffer_Common.fxh>
#endif
//Available Uniform Parameters
//
//float Time
//float DeltaTime
//float4 Variable : User Variable Controlled on vvvv patch

//Available Matelial Data
//float4 colorTex(float2 uv)
//float metalTex(float2 uv)
//float roughTex(float2 uv)
//float3 emissionTex(float2 uv)
//float Reflectance;

//struct Light{
//	float3 pos;
//	float3 amb;
//	float3 diff;
//	float4x4 VP;
//};
//StructuredBuffer<Light> lights : Light List;

//Input Data Struct
//struct Info{
//	float3 Pos;
//  float2 posScreen;
//	float3 camPos;
//	float3 Normal;
//  float2 uv;
//  float2 Velocity;
//  float3 vertexColor; : if vertex color is none : vertexColor = 1.0;
//};

//Output Data Struct
//struct OutputData{
//	float3 Albedo;
//	float3 Emission;
//	float Metalness;
//	float Roughness;
//	float Reflectance;
//	
//	float2 uv; : Already Set Model Texture Coordinate
//};



void PostFunction(Info i, inout OutputData o){
	//Write your own post function!!

	o.Albedo = colorTex(i.uv).rgb * i.vertexColor;
	o.Emission = emissionTex(i.uv);
	o.Metalness = metalTex(i.uv);
	o.Roughness = roughTex(i.uv);
	o.Reflectance = Reflectance;
}

technique11 RemoveMe{}



