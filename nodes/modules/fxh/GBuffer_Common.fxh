#ifndef GBUFFERCOMMON
#define GBUFFERCOMMON
#endif

float Time<bool visible = false;> = 0;
float DeltaTime<bool visible = false;> = 0;

float4 Variable<bool visible = false;>;

Texture2D BumpTex <string uiname="Bump Texture";bool visible = false;>;
Texture2D MetalnessTex <string uiname = "Metalness Map";bool visible = false;>;
Texture2D RoughnessTex <string uiname = "Roughness Map";bool visible = false;>;
Texture2D EmissionTex <string uiname = "Emission Map";bool visible = false;>;
float Reflectance<string uiname = "Reflectance";bool visible = false> = .5;

SamplerState tSampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

float4 colorTex(float2 uv){
    return ColorTex.Sample(tSampler, uv);
}

float metalTex(float2 uv){
    return MetalnessTex.Sample(tSampler, uv).r;
}

float roughTex(float2 uv){
    return RoughnessTex.Sample(tSampler, uv).r;
}

float3 emissionTex(float2 uv){
    return EmissionTex.Sample(tSampler, uv).rgb;
}

struct Info{
	float3 Pos;
    float2 posScreen;
	float3 camPos;
	float3 Normal;
    float2 uv;
    float2 Velocity;
    float3 vertexColor;
};

struct OutputData{
	float3 Albedo;
	float3 Emission;
	float Metalness;
	float Roughness;
	float Reflectance;
	float2 uv;
};

struct Light{
	float3 pos;
	float3 amb;
	float3 diff;
	float4x4 VP;
};

StructuredBuffer<Light> lights : LIGHTBUFFER;

#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define HALF_PI 1.57079632679

float2 hash(float2 x){
    float2 k = float2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*frac( 16.0 * k*frac( x.x*x.y*(x.x+x.y)) );
}

float2x2 rot2D(float a) {
	float c = cos(a);
	float s = sin(a);
	return float2x2(c, s,
					-s, c);
}

float3x3 rot3D(float3 axis, float angle){
    float c, s;
    sincos(angle, s, c);

    float t = 1 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3(
        t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
        t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
        t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
    );
}

float3 TriPlanner(Texture2D t, float3 p, float3 n){
    n = max(abs(n), 0.001);
    n /= (n.x + n.y + n.z );  
	p = (t.Sample(tSampler, p.yz)*n.x + t.Sample(tSampler, p.zx)*n.y + t.Sample(tSampler, p.xy)*n.z).xyz;
    return p*p;
}

float3 HSVToRGB(float h, float s, float v){
    float4 t = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(float3(h,h,h) + t.xyz) * 6.0 - float3(t.w, t.w, t.w));
    return v * lerp(float3(t.x,t.x,t.x), clamp(p - float3(t.x,t.x,t.x), 0.0, 1.0), s);
}

