#ifndef RAYMARCHCOMMON
	#include <packs\PBRRenderer\nodes\modules\fxh\Raymarch_Common.fxh>
#endif
//Available Uniform Parameters
//
//float Time
//float DeltaTime
//float4 Variable : User Variable Controlled on vvvv patch

// 4DPolytopes Distance Estimation by Syntopia : Mikael H Christensen
// https://syntopia.github.io/Polytopia/polytopes.html

// Parameters from Render Semantics
int deg : DEGREES; // [2 - 5]

float3 rotate : ROTATION; // [0 - 1]
float angle : ANGLE;  // [0 - 360]

float vRad : VERTEXRADIUS; // [0 - .2]
float sRad : SEGMENTRADIUS; // [0 - .2]

// [0 - 1]
float u : U;
float v : V;
float w : W;
float t : T;

float4 fold(float4 pos, float4 nc, float4 nd) {
	for(int i = 0; i < 25; i++){
		float4 tmp = pos;
		pos.xy=abs(pos.xy);
		
		float t = -2. * min(0., dot(pos,nc));
		pos += t * nc;
		
		t = -2. * min(0., dot(pos, nd));
		pos += t * nd;
		
		if (tmp.x == pos.x &&
			tmp.y == pos.y &&
			tmp.z == pos.z &&
			tmp.w == pos.w) { return pos; }
	}
	return pos;
}

float DD(float ca, float sa, float r){
	//magic formula to convert from spherical distance to planar distance.
	//involves transforming from 3-plane to 3-sphere, getting the distance
	//on the sphere then going back to the 3-plane.
	return r-(2.*r*ca-(1.-r*r)*sa)/((1.-r*r)*ca+2.*r*sa+1.+r*r);
}

float dist2Vertex(float4 p, float4 z, float r, float vRadius){
	float ca=dot(z,p), sa=0.5*length(p-z)*length(p+z);//sqrt(1.-ca*ca);//
	return DD(ca,sa,r)-vRadius;
}

float dist2Segment(float4 p, float4 z, float4 n, float r, float sRadius){
	//pmin is the orthogonal projection of z onto the plane defined by p and n
	//then pmin is projected onto the unit sphere
	float zn=dot(z,n),zp=dot(z,p),np=dot(n,p);
	float alpha=zp-zn*np, beta=zn-zp*np;
	float4 pmin=normalize(alpha*p+min(0.,beta)*n);
	//ca and sa are the cosine and sine of the angle between z and pmin. This is the spherical distance.
	float ca=dot(z,pmin), sa=0.5*length(pmin-z)*length(pmin+z);//sqrt(1.-ca*ca);//
	float factor = 1.0;// DD(ca,sa,r)/DD(ca+0.01,sa,r);
	return (DD(ca,sa,r)-sRadius*factor)*min(1.0/factor,1.0);
	
}

float dist2Segments(float4 p, float4 z, float r, float4 nc, float4 nd, float srad){
	float da=dist2Segment(p, z, float4(1.,0.,0.,0.), r, srad);
	float db=dist2Segment(p, z, float4(0.,1.,0.,0.), r, srad);
	float dc=dist2Segment(p, z, nc, r, srad);
	float dd=dist2Segment(p, z, nd, r, srad);
	
	return min(min(da,db),min(dc,dd));
}

float DE(float4 p, float3 pos, float3x3 rot, float4 nc, float4 nd, float vrad, float srad, inout float m) {
	
	float r=length(pos);
	float4 z4=float4(2.*pos,1.-r*r)*1./(1.+r*r);//Inverse stereographic projection of pos: z4 lies onto the unit 3-sphere centered at 0.
	z4.xyw=mul(z4.xyw, rot);
	z4=fold(z4, nc, nd);//fold it
	float d=10000.;
	
	d = min(d, dist2Vertex(p, z4,r, vrad));
	m = 1.;
	
	float seg = dist2Segments(p, z4, r, nc, nd, srad);
	if(d > seg){
		d = seg;
		m = 0.;
	}
	return d ;
}

float DistanceFunction(float3 p, inout float Material){	
	float rotX = rotate.x;   // [0 - 1]
	float rotY = rotate.y;   // [0 - 1]
	float rotZ = rotate.z;   // [0 - 1]
	
	// init
	float3x3 rot;
	float4 nc, nd, wp;
	
	float cospin=cos(PI/float(deg)), isinpin=1./sin(PI/float(deg));
	float scospin=sqrt(2./3.-cospin*cospin), issinpin=1./sqrt(3.-4.*cospin*cospin);

	nc=0.5*float4(0,-1,sqrt(3.),0.);
	nd=float4(-cospin,-0.5,-0.5/sqrt(3.),scospin);

	float4 pabc,pbdc,pcda,pdba;
	pabc=float4(0.,0.,0.,1.);
	pbdc=0.5*sqrt(3.)*float4(scospin,0.,0.,cospin);
	pcda=isinpin*float4(0.,0.5*sqrt(3.)*scospin,0.5*scospin,1./sqrt(3.));
	pdba=issinpin*float4(0.,0.,2.*scospin,1./sqrt(3.));
	
	wp=normalize(v*pabc+u*pbdc+w*pcda+t*pdba);

	rot = rot3D(normalize(float3(rotX,rotY,rotZ)), PI*(angle/360.0));//in reality we need a 4D rotation
	
    return DE(wp, p, rot, nc, nd, vRad, sRad, Material);
}

technique11 RemoveMe{}



