Texture2D albtex;
Texture2D ntex<string uiname = "Normal Pass";>;
Texture2D postex<string uiname = "Position Pass";>;
Texture2D specroug<string uiname = "SpecRough Map";>;
Texture2DArray shadowmap<string uiname = "Shadow Map";>;
Texture2D brdfLUT;
TextureCube EnvMap<string uiname = "Environment Map";>;

#define PI 3.14159265359
#ifndef NUMSAMPLE
#define NUMSAMPLE 16
#endif

#define minVariance 0.0



SamplerState linearSampler : IMMUTABLE{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

SamplerState shadowSampler : immutable{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = BORDER;
	AddressV = BORDER;
	AddressW = BORDER;
	BorderColor = float4(1,1,1,0);

};

float4x4 tW : WORLD;
float4x4 tVP : VIEWPROJECTION;

struct Light{
	float3 pos;
	float3 amb;
	float3 diff;
};

StructuredBuffer<float4x4> LightVP;
float LightBleedingLimit = .9;

float3 campos;

StructuredBuffer<Light> lights;
uint num<string uiname = "Light Count";>;

float iblint<string uiname = "IBL intensity"; float uimin = 0.0;> = 1;
bool EmvLod = 1;

float linstep(float mini, float maxi, float v){
	return clamp((v - mini) / (maxi - mini), 0, 1);
}

float ReduceLightBleeding(float p_max, float Amount){
	return linstep(Amount, 1, p_max);
}

float ChebyshevUpperBound(float2 Moments, float t, float LightBleedingLimit){
	float p = (t <= Moments.x);
	
	float Variance = Moments.y - (Moments.x * Moments.x);
	Variance = max(Variance, minVariance);
	
	float d = t - Moments.x;
	float p_max = Variance / (Variance + d * d);
	p_max = ReduceLightBleeding(p_max, LightBleedingLimit);
	
	return max(p, p_max);
}

float ShadowContribution(float3 LightCd, float LightDist, int i, float LightBleedingLimit){
	float2 Moments = shadowmap.SampleLevel(shadowSampler, float3(LightCd.xy, i), 0).xy;
	return ChebyshevUpperBound(Moments, LightDist, LightBleedingLimit);
}

float3 fresnelSphericalGaussian(float dotVH, float3 F0){
	return F0 + (1.0 - F0) * exp2((-5.55473 * dotVH - 6.98316) * dotVH);
}  

float sqr(float x) { return x*x; }

float D_GGX(float3 N, float3 H, float alpha){
	float cosThetaM = dot(N, H);
	float CosSquared = cosThetaM*cosThetaM;
	float TanSquared = (1-CosSquared)/CosSquared;
	return (1.0/PI) * sqr(alpha/(CosSquared * (alpha*alpha + TanSquared)));
}

float GeometrySchlickGGX(float NdotV, float roughness){
	float r = (roughness + 1.0);
	float k = (r*r) / 8.0;

	float nom   = NdotV;
	float denom = NdotV * (1.0 - k) + k;
	
	return nom / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness){
	float dotNV = max(dot(N, V), 0.0);
	float dotNL = max(dot(N, L), 0.0);
	float ggx2  = GeometrySchlickGGX(dotNV, roughness);
	float ggx1  = GeometrySchlickGGX(dotNL, roughness);
	
	return ggx1 * ggx2;
}

float3 CookTorrance(float3 V, float3 L, float3 N, float3 H, float roughness, float3 diff, float3 ambient,float3 ldiff, float shadow, float3 spec){
	float3 f = fresnelSphericalGaussian(max(dot(V, H), 0.0), spec);
	float d = D_GGX(N, H, sqr(roughness));
	float g = GeometrySmith(N, V, L, roughness);
	float3 nominator  = d * g * f;
	float denominator = 4 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001; 
	float3 spe = nominator / denominator;
	ldiff *= shadow + diff * .1;
	float3 dif = diff * (1.0 / PI) + spe ;
	float ndl = max(dot(N, L), 0.0);
 
	return (dif* ldiff * ndl + ambient) ;
}


float3 ImportanceSampleGGX( float2 Xi, float Roughness , float3 N ){
	float a = Roughness * Roughness;
	
	float Phi = 2 * PI * Xi.x;
	float CosTheta = sqrt( (1 - Xi.y) / ( 1 + (a*a - 1) * Xi.y ) );
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );
	
	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float3 UpVector = abs(N.z) < 0.999 ? float3(0,0,1) : float3(1,0,0);
	float3 TangentX = normalize( cross( UpVector , N ) );
	float3 TangentY = cross( N, TangentX );
	// Tangent to world space
	return TangentX * H.x + TangentY * H.y + N * H.z;
}

float radicalInverse_VdC(uint bits) {
	 bits = (bits << 16u) | (bits >> 16u);
	 bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
	 bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
	 bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
	 bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
	 return float(bits) * 2.3283064365386963e-10; // / 0x100000000
 }

float2 Hammersley(uint i, uint N) {
	 return float2(float(i)/float(N), radicalInverse_VdC(i));
 }

float3 PrefilterEnvMap( float Roughness , float3 R ){
	float3 N = R;
	float3 V = R;
	float3 PrefilteredColor = 0;
	float TotalWeight = 0;
	for( uint i = 0; i < NUMSAMPLE; i++ ){
		float2 Xi = Hammersley( i, NUMSAMPLE );
		float3 H = ImportanceSampleGGX( Xi, Roughness , N );
		float3 L = 2 * dot( V, H ) * H - V;
		float NoL = saturate( dot( N, L ) );
		if( NoL > 0 ){
			PrefilteredColor += EnvMap.SampleLevel(linearSampler , L, 0 ).rgb * NoL;
			TotalWeight += NoL;
		}
	}
	return PrefilteredColor / TotalWeight;
}

float3 ApproximateSpecularIBL( float3 SpecularColor , float Roughness , float3 N, float3 V ){
	float NoV = saturate( dot( N, V ) );
	float3 R = 2 * dot( V, N ) * N - V;
	float3 PrefilteredColor = float3(0,0,0);
	if(EmvLod){
		float2 Xi = Hammersley( 1, NUMSAMPLE );
		float3 H = ImportanceSampleGGX( Xi, Roughness , N );
		float3 L = 2 * dot( V, H ) * H - V;
		PrefilteredColor = EnvMap.SampleLevel(linearSampler, L, Roughness * 9).rgb;
	}else{
		PrefilteredColor = PrefilterEnvMap( Roughness , R );
	}
	float2 EnvBRDF  = brdfLUT.Sample(linearSampler, float2(max(dot(N, V), 0.0)-.01,Roughness)*float2(1,-1)).rg;
	//float2 EnvBRDF = IntegrateBRDF( Roughness , NoV, N );
	return PrefilteredColor * ( SpecularColor * EnvBRDF.x + EnvBRDF.y );
}


struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct psInput
{
	float4 p : SV_Position;
	float2 uv : TEXCOORD0;
};

psInput VS(VS_IN input)
{
	psInput output;
	output.p  = mul(input.PosO,mul(tW,tVP));
	output.uv = input.TexCd.xy;
	return output;
}

float4 PS(psInput input) : SV_Target{
	float3 pos = float3(postex.Sample(linearSampler, input.uv).rgb);
	float3 N = ntex.Sample(linearSampler, input.uv).rgb;
	float3 V = normalize(campos - pos);
	float4 albedo = albtex.Sample(linearSampler,input.uv);
	float3 Specular = specroug.Sample(linearSampler, input.uv).rgb;
	float Roughness = specroug.Sample(linearSampler, input.uv).a;
	Roughness = clamp(Roughness, .01, .95);
	albedo.xyz = clamp(albedo.xyz, .025, .98);
	
	float3 lighting = float3(0,0,0);
	for(uint i = 0; i < num; i++){
		//float4 alb = albedo * float4(lights[i].diff, 1);
		float3 L = normalize(lights[i].pos - pos);
		float3 H = normalize(V + L);
		
		//LightCoord
		float LightDist = length(lights[i].pos - pos);
		float4 Vpos = mul(float4(pos, 1), LightVP[i]);
		float3 LightCd = 0;
		LightCd.x =  Vpos.x / Vpos.w / 2.0f + 0.5f;
		LightCd.y = -Vpos.y / Vpos.w / 2.0f + 0.5f;	
		LightCd.z =  Vpos.z / Vpos.w / 2.0f + 0.5f;
		
		float shadow = ShadowContribution(LightCd, LightDist, i, LightBleedingLimit);
	
		lighting += CookTorrance(V, L, N, H, Roughness, albedo.xyz, lights[i].amb, lights[i].diff, shadow, Specular);
		
	}
	
	lighting += ApproximateSpecularIBL(Specular, Roughness, N, V) * iblint;
	//lighting *= albedo.a;
	
	return float4(lighting, albedo.a);
}





technique10 SpotLighting
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




