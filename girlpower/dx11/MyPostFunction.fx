#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
	#define DistanceFunction
#endif
//Available Uniform Parameters
//
//float Time
//float DeltaTime
//float4x4 texW : Texture Transform
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
//	float3 posOrigin;
//	float3 rayDir;
//	int maxLoop;
//	int loop;
//	float3 posEnd;
//	float totalDistance;
//	float depth;
//	float3 normal;
//};

//Output Data Struct
//struct OutputData{
//	float3 Albedo;
//	float3 Emission;
//	float Metalness;
//	float Roughness;
//	float Reflectance;
//	
//	//If you want using Texturing, BumpMapping...
//	//Calc and output good uv coordinate.
//	float2 uv;
//};
float calcEdge(float3 p) {
    float edge = 0.0;
    float2 e = float2(.04, 0);
	float dum = 0;

    // Take some distance function measurements from either side of the hit point on all three axes.
	float d1 = DistanceFunction(p + e.xyy, dum), d2 = DistanceFunction(p - e.xyy, dum);
	float d3 = DistanceFunction(p + e.yxy, dum), d4 = DistanceFunction(p - e.yxy, dum);
	float d5 = DistanceFunction(p + e.yyx, dum), d6 = DistanceFunction(p - e.yyx, dum);
	float d = DistanceFunction(p, dum)*2.;	// The hit point itself - Doubled to cut down on calculations. See below.

    // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
    // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
    // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface
    // curves that register a discernible difference.
    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.

    // Once you have an edge value, it needs to normalized, and smoothed if possible. How you
    // do that is up to you. This is what I came up with for now, but I might tweak it later.
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));

    // Return the normal.
    // Standard, normalized gradient mearsurement.
    return edge;
}

void PostFunction(Info i, inout OutputData o){
	//Write your own post function!!
	
	o.uv = 0;
	float3 p = i.posEnd;
	float edge = calcEdge(p);
	o.Albedo = colorTex(o.uv).rgb * lerp(1, i.normal, .6);
	o.Emission = edge * pow(abs(sin(p + Time*50)), 8);
	o.Metalness = metalTex(o.uv);
	o.Roughness = edge+roughTex(o.uv)*.8;
	o.Reflectance = Reflectance;
}

technique11 RemoveMe{}