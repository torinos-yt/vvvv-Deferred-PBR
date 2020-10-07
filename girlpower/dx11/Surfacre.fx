#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
	#define DistanceFunction
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
//	float3 camPos;
//	float3 rayDir;
//	int maxLoop;
//	int loop;
//  float Material
//	float3 Pos;
//	float totalDistance;
//	float Depth;
//	float3 Normal;
//};

//Output Data Struct
//struct OutputData{
//	float3 Albedo;
//	float3 Emission;
//	float Metalness;
//	float Roughness;
//  float3 BumpNormal;
//	float Reflectance;
//	
//	//If you want using Texturing, BumpMapping...
//	//Calc and output good uv coordinate.
//	float2 uv;
//};



void PostFunction(Info i, inout OutputData o){
	//Write your own post function!!
	
	o.uv = 0;
	o.Albedo = lerp(colorTex(o.uv).rgb, float3(.2, .08,.15), i.Material);
	o.Emission = emissionTex(o.uv);
	o.Metalness = lerp(metalTex(o.uv), .45, i.Material);
	o.Roughness = roughTex(o.uv);
	o.Reflectance = Reflectance;
}

technique11 RemoveMe{}



