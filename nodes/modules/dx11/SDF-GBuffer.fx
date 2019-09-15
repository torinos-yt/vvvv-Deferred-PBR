#if !defined(ITE)
#define ITE 32
#endif

#if !defined(VEC_ITE)
#define VEC_ITE 32
#endif

#define EPS 0.0003
float mindist<float uistep = .0001;> = .0001;

bool IsBump = true;
float bumps<string uiname = "BumpMap Strength"; float uimin = 0.0; float uimax = 5.0;> = 1;

float emit <string uiname = "Emission Stlength";> = 1.0;
float stepLength<string uiname = "StepLength";> = 1.0;

bool VelocityMarching = false;

SamplerState linearSampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;	
	float4x4 tVPI : VIEWPROJECTIONINVERSE;
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tPI : PROJECTIONINVERSE;
	float4x4 tVI : VIEWINVERSE;
	float4x4 ptVP : PREVIOUSVIEWPROJECTION;
	float4x4 ptVI : PREVIOUSVIEWINVERSE;
	float4x4 ptVPI : PREVIOUSVIEWPROJECTIONINVERSE;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tWI : WORLDINVERSE;
	float4x4 ptW;
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
};
struct vs2ps
{
	float4 Pos: SV_Position;
	float2 uv: TEXCOORD0;
};

struct PSout{
	float4 color : SV_Target0;
	float4 normal : SV_Target1;
	float4 MRVel : SV_Target2;
	float3 position : SV_Target3;
	float depth : SV_Depth;
};


float3 getNormal(float3 p) {
    float2 e = float2(1.0, -1.0) * EPS;
	float d = 0;
    return normalize(
        e.xyy * DistanceFunction(p + e.xyy, d) +
        e.yxy * DistanceFunction(p + e.yxy, d) +
        e.yyx * DistanceFunction(p + e.yyx, d) +
        e.xxx * DistanceFunction(p + e.xxx, d)
    );
}

vs2ps VS(VS_IN input)
{
	vs2ps output;
	output.Pos  = input.PosO;
	output.uv = input.TexCd.xy;
	return output;
}

PSout PS(vs2ps In){
	PSout gbuffer;
	Info info = (Info)0;
	OutputData o = (OutputData)0;

	float2 u = mul(float4(In.uv, 1, 1), texW).xy;
	
	float2 rayDir = (In.uv * 2 - 1) * float2(1, -1);
	float4 rayDirVP = mul(float4(rayDir, 1, 1), tVPI);
	//float3 ray = 
	//info.rayDir = normalize(mul(normalize(mul(float4(mul(float4(rayDir, 0, 0), tPI).xy, 1, 0), tVI).xyz), tWI));
	
	float3 ray = 
	info.rayDir = normalize(mul(float4(normalize(rayDirVP.xyz / rayDirVP.w), 1), tWI).xyz);
	
	float3 rayPos = mul(float4(tVI[3].xyz, 1), tWI).xyz;
	info.posOrigin = tVI[3].xyz;

	float maxdist = -(tP[3].z / (tP[2].z - 1));
	
	float3 normal = 0;
	bool hit = false;
	float dist = 0;
	float total = 0;
	float id = 0;
	for(int i = 0; i < ITE; i++){
		dist = DistanceFunction(rayPos, id);
		
		if(dist < mindist * max(total, 1)){ 
			normal = normalize(max(min(getNormal(rayPos), 1), -1));
			normal = normalize(mul(normal, (float3x3)tW));
			hit = true;

			break;
		}
		rayPos += ray * dist * stepLength;
		total += dist * stepLength;
		if(total > maxdist) break;
	}
	
	info.maxLoop = ITE;
	info.loop = i;
	info.totalDistance = total;
	info.normal = normal;
	info.Material = id;

	float3 endPos = mul(float4(rayPos, 1), tW).xyz;
	info.posEnd = endPos;
	float4 possc = mul(float4(endPos, 1), tVP);
	gbuffer.depth = 
	info.depth = possc.z / possc.w;
	
	PostFunction(info, o);
	
	gbuffer.color = float4((o.Albedo + o.Emission * emit) * hit, hit);
	gbuffer.normal = float4(normal, o.Reflectance) * hit;
	gbuffer.position = endPos * hit;

	if(hit && VelocityMarching){
		rayPos = ptVI[3].xyz;
		total = dist = 0;
		rayDirVP = mul(float4(rayDir, 1, 1), ptVPI);
		rayDir = normalize(mul(float4(normalize(rayDirVP.xyz / rayDirVP.w), 1), tWI).xyz);
		float dumm = 0;
		for(i = 0; i < VEC_ITE; i++){
			dist = DistanceFunction(rayPos, dumm);

			if(dist < mindist * max(total, 1)) break;
			rayPos += ray * dist * stepLength;
			total += dist * stepLength;
			if(total > maxdist) break;
		}
	}
	float4 prevPosVP = mul(float4(mul(float4(rayPos, 1), ptW).xyz, 1), ptVP);
	float2 prevpossc = prevPosVP.xy / prevPosVP.w;
	float2 velxy = (possc.xy / possc.w) - prevpossc;
	velxy *= .5;
	velxy += .5;
	
	gbuffer.MRVel = float4(o.Metalness, o.Roughness, velxy) * hit;
	
	if(IsBump){
		float3 p_dx = ddx(gbuffer.position);
		float3 p_dy = ddy(gbuffer.position);

		float2 tc_dx = ddx(o.uv);
		float2 tc_dy = ddy(o.uv);

		float3 t = normalize( tc_dy.y * p_dx - tc_dx.y * p_dy );
		float3 b = normalize( tc_dy.x * p_dx - tc_dx.x * p_dy ); 

		float3 n = normalize(normal);
		float3 x = cross(n, t);
		t = cross(x, n);
		t = normalize(t);

		x = cross(b, n);
		b = cross(n, x);
		b = normalize(b);
		
		float3 nmap = BumpTex.Sample(linearSampler, o.uv).xyz;
		nmap = nmap * 2.0 - 1.0;
		gbuffer.normal = float4(normalize(gbuffer.normal.xyz + (nmap.x * t + nmap.y * b) * bumps), o.Reflectance) * hit;
	}
	return gbuffer;
}

technique10 GBuffer
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




