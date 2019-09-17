#ifndef RAYMARCHCOMMON
#define RAYMARCHCOMMON
#endif

float Time<bool visible = false;> = 0;
float DeltaTime<bool visible = false;> = 0;

float4 Variable<bool visible = false;>;

Texture2D ColorTex <string uiname="Texture"; bool visible = false;>;
Texture2D BumpTex <string uiname="Bump Texture"; bool visible = false;>;
Texture2D MetalnessTex <string uiname = "Metalness Map"; bool visible = false;>;
Texture2D RoughnessTex <string uiname = "Roughness Map"; bool visible = false;>;
Texture2D EmissionTex <string uiname = "Emission Map"; bool visible = false;>;
float Reflectance<string uiname = "Reflectance";  bool visible = false;> = .5;


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

float4x4 texW<bool visible = false;>;

struct Info{
	float3 camPos;
	float3 rayDir;
	int maxLoop;
	int loop;
    float Material;
	float3 Pos;
	float totalDistance;
	float Depth;
	float3 Normal;
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

// https://www.shadertoy.com/view/lttGDn
/*Copy & Paste into Post Function File
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
*/

float2 sphericalUV(float3 pos, float scale){
	float3 p = normalize(pos);
	return float2(.5+ atan2(p.x, p.z) / TWO_PI, .5 - asin(p.y) / PI) * scale;
}

float3 triPlanner(Texture2D t, float3 p, float3 n){
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

float opU( float d1, float d2 ){
    return (d1<d2) ? d1 : d2;
}

float2 opU( float2 d1, float2 d2 ){
    return (d1.x<d2.x) ? d1 : d2;
}

float opS( float d1, float d2 ){
    return max(-d1,d2);
}

float2 opS( float2 d1, float2 d2 ){
    return float2(max(-d1.x,d2.x),(-d1.x>d2.x) ? d1.y : d2.y);
}

float opI( float d1, float d2 ){
    return max(d1,d2);
}

float2 opI( float2 d1, float2 d2 ){
    return float2(max(d1.x,d2.x),(d1.x>d2.x) ? d1.y : d2.y);
}

//Basic Distance Function By iq
//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

float3 mod(float3 n, float d){
	return n - (d * floor(n / d));
}

float3 opRep(float3 p, float c) {
    return mod(p, c) - 0.5 * c;
}

//polar repetition adapted from MERCURY demoscene group
//http://mercury.sexy/hg_sdf/

float3 opRepPolar(float3 p, float repetitions,float radius) {
	float angle = 2*PI/repetitions;
	float a = atan2(p.z, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a =abs(fmod(a,angle)) - angle/2.;
	p.xz = float2(cos(a), sin(a))*r;
	p-=  float3(radius,0.,0.);
	//TODO:
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	//if (abs(c) >= (repetitions/2)) c = abs(c);
	return p;
}

//http://www.iquilezles.org/www/articles/smin/smin.htm
float opUsmin( float a, float b, float k ){
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return lerp( b, a, h ) - k*h*(1.0-h);
}

float opUsminExp( float a, float b, float k ){
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

float opUsminPow( float a, float b, float k ){
    a = pow( a, k ); b = pow( b, k );
    return pow( (a*b)/(a+b), 1.0/k );
}

//Super cool  union / intersect / substract functions by MERCURY demoscene group
//http://mercury.sexy/hg_sdf/
float opUstairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs((abs(fmod (u - a + s, 2 * s))) - s)));
}

float opIstairs(float a, float b, float r, float n) {
	return -opUstairs(-a, -b, r, n);
}

float opSstairs(float a, float b, float r, float n) {
	return -opUstairs(-a, b, r, n);
}
float opIsmin(float a, float b, float r) {
	return -opUsmin(-a, -b, r);
}

float opSsmin(float a, float b, float r) {
	return -opUsmin(-a, b, r);
}

float dPlane( float3 p ){
    return p.y;
}

float dSphere(float3 p, float s){
  return length(p)-s;
}

float dBox(float3 p, float3 size){
	float3 d = abs(p) - size;
	return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}

float dTorus(float3 p, float2 t){
  float2 q = float2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float dCapsule(float3 p, float3 a, float3 b, float r){
    float3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float dCylinder(float3 p, float3 c){
  return length(p.xz-c.xy)-c.z;
}

float dHexPrism( float3 p, float2 h ){
    float3 q = abs(p);
    float d1 = q.z-h.y;
    float d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(float2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float dTriPrism( float3 p, float2 h ){
    float3 q = abs(p);
    float d1 = q.z-h.y;
    float d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
    return length(max(float2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float dCone( float3 p, float3 c ){
    float2 q = float2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(float2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float dConeSection( float3 p, float h, float r1, float r2 ){
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5*(r1-r2)/h;
    float d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(float2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float dPyramid(float3 p, float3 h ) {
    float box = dBox( p - float3(0,-2.0*h.z,0),2.0*h.z); 
    float d = 0.0;
    d = max( d, abs( dot(p, float3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, float3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, float3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, float3(  0, h.y,-h.x )) ));
    float octa = d - h.z;
    return max(-box,octa);
 }

//@gam0022
float dMandelbox(float3 p, float scale, int n){
    float4 q0 = float4(p, 1);
    float4 q = q0;

    for(int i = 0; i < n; i++){
        q.xyz = clamp(q.xyz, -1, 1) * 2.0 - q.xyz;
        q = q * scale / clamp(dot(q.xyz, q.xyz), .5, 1.0) + q0;
    }

    return length(q.xyz) / abs(q.w);
}

float dMandelbulb(float3 rayPos, float3 size){
	float3 p = mod(rayPos, 2.0)-2.0*.5;
	//float3 p = rayPos;

	float mr = .1, mxr = 2;
	float4 scale = size.x, p0 = float4(0.3, 0.9, -1.4, 0.5);
	float4 z = float4(p, 1);
	for(int n = 0; n < 8; n++){
		z.xyz = clamp(z.xyz, -1.25, 1.5) * 2.1 - z.xyz;
		z *= scale / clamp(dot(z.xyz, z.xyz), mr, mxr) * 2;
		z += p0;
	}

	float ds = (length(max(abs(z.xyz), 0.0))) / z.w;
	return ds;
}

float dMenger(float3 rayPos, float3 offset, float3 scale, int ite) {
	scale.xyz = scale.x;
    float4 z = float4(rayPos, 1.0);
    for (int i = 0; i < ite; i++) {
        z = abs(z);
        if (z.x < z.y) z.xy = z.yx;
        if (z.x < z.z) z.xz = z.zx;
        if (z.y < z.z) z.yz = z.zy;

        z *= scale.x;
        z.xyz -= offset * (scale - 1.0);

        if (z.z < -0.3 * offset.z * (scale.x - 1.0)) {
            z.z += offset.z * (scale.x - 1.0);
        }
    }
    return length(max(abs(z.xyz) - float3(1,1,1), 0.0)) / z.w;
}

//Noise functions made by Inigo Quilez
//http://www.iquilezles.org/www/articles/morenoise/morenoise.htm
float iqhash( float n ){
	return frac(sin(n)*43758.5453);
	//OR, better: Dave Hoskins hash
	//BUT it's a bit slower... (no sin though)
	
	/*float3 p3  = frac(float3(n,n,n) * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);*/
}

float noise(float3 x){
	float3 p = floor(x);
	float3 f = frac(x);	
	f = f*f*(3.0-2.0*f);
	float n = p.x + p.y*57.0 + 113.0*p.z;
	return lerp(lerp(lerp( iqhash(n+0.0  ), iqhash(n+1.0  ),f.x),
	lerp( iqhash(n+57.0 ), iqhash(n+58.0 ),f.x),f.y),
	lerp(lerp( iqhash(n+113.0), iqhash(n+114.0),f.x),
	lerp( iqhash(n+170.0), iqhash(n+171.0),f.x),f.y),f.z);
}