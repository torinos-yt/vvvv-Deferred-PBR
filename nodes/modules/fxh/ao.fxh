#define PI 3.1415926535897932384626433832795
#define PI_HALF 1.5707963267948966192313216916398

Texture2D depthTex;
SamplerState linearSampler : IMMUTABLE{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

float2 RTargetSize : TARGETSIZE;
float2 RTexelSize : INVTARGETSIZE;

float aodistance<string uiname = "AO Distance";> = 1.0;
float aopower<string uiname = "AO Power";> = 1.0;
int NumCircle<float uimin = 0.0; float uimax = 15;> = 4;
int NumSlice<float uimin = 0.0; float uimax = 20;> = 8;

uint time;

float4x4 tV;
float4x4 tP;
float4x4 tIP;

float fastSqrt(float v){
	return asfloat(0x1FBD1DF5 + (asint(v) >> 1));
}

float2 fastSqrt(float2 v){
	v.x = asfloat(0x1FBD1DF5 + (asint(v.x) >> 1));
	v.y = asfloat(0x1FBD1DF5 + (asint(v.y) >> 1));
	return v;
}

float fastAcos(float v){
	float res = -.156583 * abs(v) + PI_HALF;
	res *= fastSqrt(1.0 - abs(v));
	v = v >= 0 ? res : PI - res;
	return v;
}

float2 fastAcos(float2 v){
	float2 res = -.156583 * abs(v) + PI_HALF;
	res *= fastSqrt(1.0 - abs(v));
	v.x = v.x >= 0 ? res.x : PI - res.x;
	v.y = v.y >= 0 ? res.y : PI - res.y;
	return v;
}

float3 getViewPos(float2 uv){
	float depth = depthTex.SampleLevel(linearSampler, uv, 0).r;
	float2 uvs = (uv*2.0-1.0)*float2(1.0, -1.0);
	float4 pr = mul(float4(uvs, depth, 1.0), tIP);
	return pr.xyz / pr.w;
}

float gtaoOffsets(float2 uv){
	int2 position = (int2)(uv * RTargetSize);
	return 0.25 * (float)((position.y - position.x) & 0x3);
}

float gtaoNoise(int2 position){
	return .0625 * ((((position.x + position.y) & 0x3) << 2) + (position.x & 0x3));
}

float IntegrateArcCosWeight(float2 h, float n){
    float2 Arc = -cos(2 * h - n) + cos(n) + 2 * h * sin(n);
    return 0.25 * (Arc.x + Arc.y);
}

float4 gtao(float3 normal, float2 uv, int NumCircle, int NumSlice, out float depth){
	float3 vPos = getViewPos(uv);
	float3 viewNormal = mul(normal, (float3x3)tV)*float3(1,-1,1);
	float3 viewDir = normalize(-vPos);

	float fov = 2 * atan(1 / tP[1][1]);
	float projScale = RTargetSize.y / (tan(fov * .5) * 2) * .5;
	float stepRadius = max(min((aodistance * projScale) / vPos.b, 512), (float)NumSlice);
	stepRadius /= ((float)NumSlice + 1);

	float noiseOffset = gtaoOffsets(uv);
	float noiseDirection = gtaoNoise(uv * RTargetSize);

	float SpatialOffsets[4] = {0, .5, .25, .75};
	float TemporalRotations[6] = {60, 300, 180, 240, 120, 0};
	float TemporalOffset = SpatialOffsets[(time / 6) % 4];
	float TemporalDirection = TemporalRotations[time % 6] / 360;

	float initialRayStep = frac(noiseOffset + TemporalOffset);

	float Occlusion, angle, bentAngle, wallDarkeningCorrection, projLength, n, cos_n;
	float2 slideDir_TexelSize, h, H, falloff, uvOffset, dsdt, dsdtLength;
	float3 sliceDir, ds, dt, planeNormal, tangent, projectedNormal, BentNormal;
	float4 uvSlice;

	if (depthTex.Sample(linearSampler, uv).r <= 1e-7){
		return 1;
	}

	[loop]
	for (int i = 0; i < NumCircle; i++){
		angle = (i + noiseDirection + TemporalDirection) * (PI / (float)NumCircle);
		sliceDir = float3(float2(cos(angle), sin(angle)), 0);
		slideDir_TexelSize = sliceDir.xy * RTexelSize;
		h = -1;

		[loop]
		for (int j = 0; j < NumSlice; j++){
			uvOffset = slideDir_TexelSize * max(stepRadius * (j + initialRayStep), 1 + j);
			uvSlice = uv.xyxy + float4(uvOffset.xy, -uvOffset);

			ds = getViewPos(uvSlice.xy) - vPos;
			dt = getViewPos(uvSlice.zw) - vPos;

			dsdt = float2(dot(ds, ds), dot(dt, dt));
			dsdtLength = rsqrt(dsdt);

			falloff = saturate(dsdt.xy * (2 / (aodistance * aodistance)));

			H = float2(dot(ds, viewDir), dot(dt, viewDir)) * dsdtLength;
			h.xy = (H.xy > h.xy) ? lerp(H, h, falloff) : h.xy;
		}

		planeNormal = normalize(cross(sliceDir, viewDir));
		tangent = cross(viewDir, planeNormal);
		projectedNormal = viewNormal - planeNormal * dot(viewNormal, planeNormal);
		projLength = length(projectedNormal);

		cos_n = clamp(dot(normalize(projectedNormal), viewDir), -1, 1);
		n = -sign(dot(projectedNormal, tangent)) * fastAcos(cos_n);

		h = fastAcos(clamp(h, -1, 1));
		h.x = n + max(-h.x - n, -PI_HALF);
		h.y = n + min(h.y - n, PI_HALF);

		bentAngle = (h.x + h.y) * 0.5;

		BentNormal += viewDir * cos(bentAngle) - tangent * sin(bentAngle);
		Occlusion += projLength * IntegrateArcCosWeight(h, n);
	}

	BentNormal = normalize(normalize(BentNormal) - viewDir * 0.5);
	Occlusion = saturate(pow(abs(Occlusion / (float)NumCircle), aopower));

	depth = vPos.z;

	return float4(BentNormal, Occlusion);
}

float Multibounce(float ao, float3 albedo){
  float lum = dot(albedo, float3(0.3333, .3333, .3333));

  float a = 2.0404 * lum - 0.3324;
  float b = -4.7951 * lum + 0.6417;
  float c = 2.7552 * lum + 0.6903;

  float x = ao;
  return max(x, ((x * a + b) * x + c) * x);
}