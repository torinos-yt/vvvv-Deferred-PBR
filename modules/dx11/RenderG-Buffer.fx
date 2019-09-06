Texture2D coltex <string uiname="Texture";>;
Texture2D BumpTex <string uiname="Bump Texture";>;
Texture2D metaltex <string uiname = "Metalness Map";>;
Texture2D roughtex <string uiname = "Roughness Map";>;
Texture2D emission <string uiname = "Emission Map";>;
float reflectance<string uiname = "Reflectance";> = .5;

bool IsBump = true;
float bumps<string uiname = "BumpMap Strength"; float uimin = 0.0; float uimax = 5.0;> = 1;

float emit <string uiname = "Emission Stlength";> = 1.0;

SamplerState linearSampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;	
	float4x4 tV : VIEW;
	float4x4 ptVP : PREVIOUSVIEWPROJECTION;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tWIT: WORLDLAYERINVERSETRANSPOSE;
	float4x4 ptW;
	float4x4 texW;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
	float3 Norm : NORMAL;
	float3 tangent : TANGENT;
	#if USECOLOR
		float3 color : COLOR;
	#endif
};

struct VS_INTNB
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
	float3 Norm : NORMAL;
	#if USECOLOR
		float3 color : COLOR;
	#endif
};

struct vs2ps
{
	float4 PosWVP: SV_Position;
	float4 PosW : TEXCOORD1;
	float2 velocity : TEXCOORD2;
	float4 uv: TEXCOORD0;
	float3 tangent : TEXCOORD3;
	float3 NormW : NORMAL;
	#if USECOLOR
		float3 color : COLOR;
	#endif
};

struct vs2pstnb
{
	float4 PosWVP: SV_Position;
	float4 PosW : TEXCOORD1;
	float2 velocity : TEXCOORD2;
	float4 uv: TEXCOORD0;
	float3 NormW : NORMAL;
	#if USECOLOR
		float3 color : COLOR;
	#endif
};

struct PSout{
	float4 color : SV_Target0;
	float4 normal : SV_Target1;
	float4 MRVel : SV_Target2;
	float3 position : SV_Target3;
};

vs2ps VS(VS_IN input)
{
	vs2ps output;
	output.PosWVP  = mul(input.PosO,mul(tW,tVP));
	float4 PosW = mul(input.PosO, tW);
	
	float4 velocity = mul(input.PosO, ptW);
	output.PosW = PosW;
	
	float4 posV = mul(PosW, tVP);
	float4 vel = mul(velocity, ptVP);
	float2 possc = posV.xy / posV.w;
	float2 velxy = possc - (vel / vel.w).xy;
	velxy *= .5;
	velxy += .5;
	output.velocity = velxy;
	
	output.uv = mul(input.TexCd, texW);;
	output.NormW = normalize(mul(input.Norm, (float3x3)tWIT));
	output.tangent = normalize(mul(input.tangent, (float3x3)tW).xyz);
	#if USECOLOR
		output.color =  input.color;
	#endif
	return output;
}

vs2pstnb VS_TNB(VS_INTNB input)
{
	vs2pstnb output;
	output.PosWVP  = mul(input.PosO,mul(tW,tVP));
	float4 PosW = mul(input.PosO, tW);
	
	float4 velocity = mul(input.PosO, ptW);
	output.PosW = PosW;
	
	float4 posV = mul(PosW, tVP);
	float4 vel = mul(velocity, ptVP);
	float2 possc = posV.xy / posV.w;
	float2 velxy = possc - (vel / vel.w).xy;
	velxy *= .5;
	velxy += .5;
	output.velocity = velxy;
	
	output.uv = mul(input.TexCd, texW);
	output.NormW = normalize(mul(input.Norm, (float3x3)tWIT));
	#if USECOLOR
		output.color =  input.color;
	#endif
	return output;
}

PSout PS(vs2ps In){
	
	PSout gbuffer;

	float4 emissive = float4(emission.Sample(linearSampler, In.uv.xy).rgb * emit, 0);
	gbuffer.color = coltex.Sample(linearSampler, In.uv.xy) + emissive;
	#if USECOLOR
		gbuffer.color *=  float4(In.color, 1);
	#endif
	
	float4 norm = float4(In.NormW, reflectance);
	gbuffer.normal = norm;
	
	float metal = metaltex.Sample(linearSampler, In.uv.xy).r;
	float rough = roughtex.Sample(linearSampler, In.uv.xy).r;
	
	gbuffer.position = In.PosW.xyz;
	gbuffer.MRVel = float4(metal, rough, In.velocity);
	
	if(IsBump){
		float3 bnormal = normalize(cross(In.NormW, In.tangent));
		float3 nmap = BumpTex.Sample(linearSampler, In.uv.xy).xyz;
		nmap = nmap * 2.0 - 1.0;
		gbuffer.normal = float4(normalize(norm.xyz + (nmap.x * In.tangent + nmap.y * bnormal) * bumps), reflectance);
	}
	return gbuffer;
}

PSout PS_TNB(vs2pstnb In){
	PSout gbuffer;
	
	float4 emissive = float4(emission.Sample(linearSampler, In.uv.xy).rgb * emit, 0);
	gbuffer.color = coltex.Sample(linearSampler, In.uv.xy) + emissive;
	#if USECOLOR
		gbuffer.color *=  float4(In.color, 1);
	#endif
	
	float4 norm = float4(In.NormW, reflectance);
	gbuffer.normal = norm;
	
	float metal = metaltex.Sample(linearSampler, In.uv.xy).r;
	float rough = roughtex.Sample(linearSampler, In.uv.xy).r;
	
	gbuffer.position = In.PosW.xyz;
	gbuffer.MRVel = float4(metal, rough, In.velocity);
	
	if(IsBump){
		float3 p_dx = ddx(In.PosW.xyz);
		float3 p_dy = ddy(In.PosW.xyz);

		float2 tc_dx = ddx(In.uv.xy);
		float2 tc_dy = ddy(In.uv.xy);

		float3 t = normalize( tc_dy.y * p_dx - tc_dx.y * p_dy );
		float3 b = normalize( tc_dy.x * p_dx - tc_dx.x * p_dy ); 

		float3 n = normalize(In.NormW);
		float3 x = cross(n, t);
		t = cross(x, n);
		t = normalize(t);

		x = cross(b, n);
		b = cross(n, x);
		b = normalize(b);
		
		float3 nmap = BumpTex.Sample(linearSampler, In.uv.xy).xyz;
		nmap = nmap * 2.0 - 1.0;
		gbuffer.normal = float4(normalize(norm.xyz + (nmap.x * t + nmap.y * b) * bumps), reflectance);
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

technique10 GBufferNoTangent
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_TNB() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_TNB() ) );
	}
}




