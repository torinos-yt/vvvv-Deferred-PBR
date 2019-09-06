#ifndef NOISEFUNC
#define NOISEFUNC

//
// GLSL textureless classic 2D noise "cnoise",
// with an RSL-style periodic variant "pnoise".
// Author:  Stefan Gustavson (stefan.gustavson@liu.se)
// Version: 2011-08-22
//
// Many thanks to Ian McEwan of Ashima Arts for the
// ideas for permutation and gradient selection.
//
// Copyright (c) 2011 Stefan Gustavson. All rights reserved.
// Distributed under the MIT license. See LICENSE file.
// https://github.com/stegu/webgl-noise
//

float3 mod(float3 x, float3 y)
{
  return x - y * floor(x/y);
}

// 289の剰余を求める
float mod289(float x)
{
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float2 mod289(float2 x)
{
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float3 mod289(float3 x)
{
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x)
{
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// 0～288の重複なく並べ替えられた数を返す
float permute(float x)
{
	return mod289(((x * 34.0) + 1.0) * x);
}

float2 permute(float2 x)
{
	return mod289(((x * 34.0) + 1.0) * x);
}

float3 permute(float3 x)
{
	return mod289(((x * 34.0) + 1.0) * x);
}

float4 permute(float4 x)
{
	return mod289(((x * 34.0) + 1.0) * x);
}

// rは0.7近辺の値として 1.0/sqrt(r) のテイラー展開による近似
float taylorInvSqrt(float r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float3 taylorInvSqrt(float3 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float4 taylorInvSqrt(float4 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

// 4次元の勾配ベクトル
float4 grad4(float j, float4 ip)
{
	const float4 ones = float4(1.0, 1.0, 1.0, -1.0);
	float4 p, s;
	p.xyz = floor(frac((float3)j * ip.xyz) * 7.0) * ip.z - 1.0;
	p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
	// lessthan GLSL -> HLSL
	// https://gist.github.com/fadookie/25adf86ae7e2753d717c
	s = float4(1.0 - step((float4)0.0, p));
	p.xyz = p.xyz + (s.xyz * 2.0 - 1.0) * s.www;
	return p;
}

// (sqrt(5.0) - 1.0) / 4.0 = F4
#define F4 0.309016994374947451

// 補間関数 5次エルミート曲線
float2 fade(float2 t)
{
	return t*t*t*(t*(t*6.0 - 15.0) + 10.0);
}

float3 fade(float3 t)
{
	return t*t*t*(t*(t*6.0 - 15.0) + 10.0);
}

float4 fade(float4 t) {
	return t*t*t*(t*(t*6.0 - 15.0) + 10.0);
}

float rand(float2 co)
{
	return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
}

float2 pseudoRandom(float2 v)
{
	v = float2(dot(v, float2(127.1, 311.7)), dot(v, float2(269.5, 183.3)));
	return -1.0 + 2.0 * frac(sin(v) * 43758.5453123);
}

float3 pseudoRandom(float3 v)
{
	v = float3(dot(v, float3(127.1, 311.7, 542.3)), dot(v, float3(269.5, 183.3, 461.7)), dot(v, float3(732.1, 845.3, 231.7)));
	return -1.0 + 2.0 * frac(sin(v) * 43758.5453123);
}

float4 pseudoRandom(float4 v)
{
	v = float4(
		dot(v, float4(127.1, 311.7, 542.3, 215.1)), 
		dot(v, float4(269.5, 183.3, 461.7, 523.3)), 
		dot(v, float4(732.1, 845.3, 231.7, 641.1)),
		dot(v, float4(321.3, 195.7, 591.5, 104.3)));
	return -1.0 + 2.0 * frac(sin(v) * 43758.5453123);
}

float valueNoise(float2 x)
{
	// 整数部
	float2 i = floor(x);
	// 小数部
	float2 f = frac(x);

	// 格子点の座標値
	float2 i00 = i;
	float2 i10 = i + float2(1.0, 0.0);
	float2 i01 = i + float2(0.0, 1.0);
	float2 i11 = i + float2(1.0, 1.0);

	// 格子点の座標上での疑似乱数の値
	float n00 = pseudoRandom(i00).x;
	float n10 = pseudoRandom(i10).x;
	float n01 = pseudoRandom(i01).x;
	float n11 = pseudoRandom(i11).x;

	// 補間係数を求める
	float2 u = smoothstep(0, 1, f);
	// 2次元格子の補間
	return lerp(lerp(n00, n10, u.x), lerp(n01, n11, u.x), u.y);
}

float valueNoise(float3 x)
{
	// 整数部
	float3 i = floor(x);
	// 小数部
	float3 f = frac(x);

	// 格子点の座標値
	float3 i000	= i;
	float3 i100	= i + float3(1.0, 0.0, 0.0);
	float3 i010	= i + float3(0.0, 1.0, 0.0);
	float3 i110	= i + float3(1.0, 1.0, 0.0);
	float3 i001	= i + float3(0.0, 0.0, 1.0);
	float3 i101	= i + float3(1.0, 0.0, 1.0);
	float3 i011	= i + float3(0.0, 1.0, 1.0);
	float3 i111	= i + float3(1.0, 1.0, 1.0);

	// 格子点の座標上での疑似乱数の値
	float n000 = pseudoRandom(i000).x;
	float n100 = pseudoRandom(i100).x;
	float n010 = pseudoRandom(i010).x;
	float n110 = pseudoRandom(i110).x;
	float n001 = pseudoRandom(i001).x;
	float n101 = pseudoRandom(i101).x;
	float n011 = pseudoRandom(i011).x;
	float n111 = pseudoRandom(i111).x;

	// 補間係数を求める
	float3 u = smoothstep(0, 1, f);
	// 3次元格子の補間	
	return lerp(lerp(lerp(n000, n100, u.x),
		   lerp(n010, n110, u.x), u.y),
		   lerp(lerp(n001, n101, u.x),
		   lerp(n011, n111, u.x), u.y), u.z);
}

float valueNoise(float4 x)
{
	// 整数部
	float4 i = floor(x);
	// 小数部
	float4 f = frac(x);

	// 格子点の座標値
	float4 i0000 = i;
	float4 i1000 = i + float4(1.0, 0.0, 0.0, 0.0);
	float4 i0100 = i + float4(0.0, 1.0, 0.0, 0.0);
	float4 i1100 = i + float4(1.0, 1.0, 0.0, 0.0);
	float4 i0010 = i + float4(0.0, 0.0, 1.0, 0.0);
	float4 i1010 = i + float4(1.0, 0.0, 1.0, 0.0);
	float4 i0110 = i + float4(0.0, 1.0, 1.0, 0.0);
	float4 i1110 = i + float4(1.0, 1.0, 1.0, 0.0);
	float4 i0001 = i + float4(0.0, 0.0, 0.0, 1.0);
	float4 i1001 = i + float4(1.0, 0.0, 0.0, 1.0);
	float4 i0101 = i + float4(0.0, 1.0, 0.0, 1.0);
	float4 i1101 = i + float4(1.0, 1.0, 0.0, 1.0);
	float4 i0011 = i + float4(0.0, 0.0, 1.0, 1.0);
	float4 i1011 = i + float4(1.0, 0.0, 1.0, 1.0);
	float4 i0111 = i + float4(0.0, 1.0, 1.0, 1.0);
	float4 i1111 = i + float4(1.0, 1.0, 1.0, 1.0);

	// 格子点の座標上での疑似乱数の値
	float n0000 = pseudoRandom(i0000).x;
	float n1000 = pseudoRandom(i1000).x;
	float n0100 = pseudoRandom(i0100).x;
	float n1100 = pseudoRandom(i1100).x;
	float n0010 = pseudoRandom(i0010).x;
	float n1010 = pseudoRandom(i1010).x;
	float n0110 = pseudoRandom(i0110).x;
	float n1110 = pseudoRandom(i1110).x;
	float n0001 = pseudoRandom(i0001).x;
	float n1001 = pseudoRandom(i1001).x;
	float n0101 = pseudoRandom(i0101).x;
	float n1101 = pseudoRandom(i1101).x;
	float n0011 = pseudoRandom(i0011).x;
	float n1011 = pseudoRandom(i1011).x;
	float n0111 = pseudoRandom(i0111).x;
	float n1111 = pseudoRandom(i1111).x;

	// 補間係数を求める
	float4 u = smoothstep(0, 1, f);
	// 4次元格子の補間	
	float4 n_0w   = lerp(float4(n0000, n1000, n0100, n1100), float4(n0001, n1001, n0101, n1101), u.w);
	float4 n_1w   = lerp(float4(n0010, n1010, n0110, n1110), float4(n0011, n1011, n0111, n1111), u.w);
	float4 n_zw   = lerp(n_0w, n_1w, u.z);
	float2 n_yzw  = lerp(n_zw.xy, n_zw.zw, u.y);
	float  n_xyzw = lerp(n_yzw.x, n_yzw.y, u.x);

	return n_xyzw;
}

float Perlin(float2 P)
{
	// 格子の整数部
	float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
	// 格子の小数部
	float4 Pf = frac(P.xyxy)  - float4(0.0, 0.0, 1.0, 1.0);
	Pi = mod289(Pi);	// インデックス並び替え処理（purmute）においての切り捨てを避けるため
	float4 ix = Pi.xzxz;// 整数部 x i0.x i1.x i2.x i3.x
	float4 iy = Pi.yyww;// 整数部 y i0.y i1.y i2.y i3.y
	float4 fx = Pf.xzxz;// 小数部 x f0.x f1.x f2.x f3.x
	float4 fy = Pf.yyww;// 小数部 y f0.y f1.y f2.y f3.y

	// シャッフルされた勾配のためのインデックスを計算
	float4 i = permute(permute(ix) + iy);

	// 勾配を計算
	// 2次元正軸体（45°回転した四角形）の境界に均一に分散した41個の点
	// 41という数字は、ほどよく分散しかつ、41×7=287と289 に近い数値であるから
	float4 gx = frac(i * (1.0 / 41.0)) * 2.0 - 1.0;
	float4 gy = abs(gx) - 0.5;
	float4 tx = floor(gx + 0.5);
	gx = gx - tx;

	// 勾配ベクトル
	float2 g00 = float2(gx.x, gy.x);
	float2 g10 = float2(gx.y, gy.y);
	float2 g01 = float2(gx.z, gy.z);
	float2 g11 = float2(gx.w, gy.w);

	// 正規化
	float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
	g00 *= norm.x;
	g01 *= norm.y;
	g10 *= norm.z;
	g11 *= norm.w;

	// 勾配ベクトルと各格子点から点Pへのベクトルとの内積
	float n00 = dot(g00, float2(fx.x, fy.x));
	float n10 = dot(g10, float2(fx.y, fy.y));
	float n01 = dot(g01, float2(fx.z, fy.z));
	float n11 = dot(g11, float2(fx.w, fy.w));

	// 補間
	float2 fade_xy = fade(Pf.xy);
	float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
	float  n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
	// [-1.0～1.0]の範囲で値を返すように調整
	return 2.3 * n_xy;
}

float Perlin(float3 P, float3 rep)
{
	// インデックス生成のための格子の整数部
	float3 Pi0 = mod(floor(P), rep);
	// 格子の整数部 + 1
	float3 Pi1 = mod(Pi0 + (float3)1.0, rep); // Integer part + 1

	Pi0 = mod289(Pi0); // インデックス並び替え処理（purmute）においての切り捨てを避けるため
	Pi1 = mod289(Pi1); // インデックス並び替え処理（purmute）においての切り捨てを避けるため
	// 補間のための格子の小数部
	float3 Pf0 = frac(P);
	// 格子の小数部 - 1
	float3 Pf1 = Pf0 - (float3)1.0;
	float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
	float4 iy = float4(Pi0.yy, Pi1.yy);
	float4 iz0 = Pi0.zzzz;
	float4 iz1 = Pi1.zzzz;

	// シャッフルされた勾配のためのインデックスを計算
	float4 ixy  = permute(permute(ix) + iy);
	float4 ixy0 = permute(ixy + iz0);
	float4 ixy1 = permute(ixy + iz1);

	// 勾配を計算
	// 3次元正軸体（八面体）の境界に均一に分散した点
	float4 gx0 = ixy0 * (1.0 / 7.0);
	float4 gy0 = frac(floor(gx0) * (1.0 / 7.0)) - 0.5;
	gx0 = frac(gx0);
	float4 gz0 = (float4)0.5 - abs(gx0) - abs(gy0);
	float4 sz0 = step(gz0, (float4)0.0);
	gx0 -= sz0 * (step(0.0, gx0) - 0.5);
	gy0 -= sz0 * (step(0.0, gy0) - 0.5);

	float4 gx1 = ixy1 * (1.0 / 7.0);
	float4 gy1 = frac(floor(gx1) * (1.0 / 7.0)) - 0.5;
	gx1 = frac(gx1);
	float4 gz1 = (float4)0.5 - abs(gx1) - abs(gy1);
	float4 sz1 = step(gz1, (float4)0.0);
	gx1 -= sz1 * (step(0.0, gx1) - 0.5);
	gy1 -= sz1 * (step(0.0, gy1) - 0.5);

	// 勾配ベクトル
	float3 g000 = float3(gx0.x, gy0.x, gz0.x);
	float3 g100 = float3(gx0.y, gy0.y, gz0.y);
	float3 g010 = float3(gx0.z, gy0.z, gz0.z);
	float3 g110 = float3(gx0.w, gy0.w, gz0.w);
	float3 g001 = float3(gx1.x, gy1.x, gz1.x);
	float3 g101 = float3(gx1.y, gy1.y, gz1.y);
	float3 g011 = float3(gx1.z, gy1.z, gz1.z);
	float3 g111 = float3(gx1.w, gy1.w, gz1.w);

	// 正規化
	float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
	g000 *= norm0.x;
	g010 *= norm0.y;
	g100 *= norm0.z;
	g110 *= norm0.w;
	float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
	g001 *= norm1.x;
	g011 *= norm1.y;
	g101 *= norm1.z;
	g111 *= norm1.w;

	// 勾配ベクトルと各格子点から点Pへのベクトルとの内積
	float n000 = dot(g000, Pf0);
	float n100 = dot(g100, float3(Pf1.x, Pf0.yz));
	float n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
	float n110 = dot(g110, float3(Pf1.xy, Pf0.z));
	float n001 = dot(g001, float3(Pf0.xy, Pf1.z));
	float n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
	float n011 = dot(g011, float3(Pf0.x, Pf1.yz));
	float n111 = dot(g111, Pf1);

	// 補間
	float3 fade_xyz = fade(Pf0);
	float4 n_z = lerp(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
	float2 n_yz = lerp(n_z.xy, n_z.zw, fade_xyz.y);
	float  n_xyz = lerp(n_yz.x, n_yz.y, fade_xyz.x);
	// [-1.0～1.0]の範囲で値を返すように調整
	return 2.2 * n_xyz;
}

float Perlin(float4 P)
{
	
	float4 Pi0 = floor(P);
	
	float4 Pi1 = Pi0 + 1.0;
	Pi0 = mod289(Pi0); 
	Pi1 = mod289(Pi1); 
	
	float4 Pf0 = frac(P);
	
	float4 Pf1 = Pf0 - 1.0;
	float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
	float4 iy = float4(Pi0.yy, Pi1.yy);
	float4 iz0 = float4(Pi0.zzzz);
	float4 iz1 = float4(Pi1.zzzz);
	float4 iw0 = float4(Pi0.wwww);
	float4 iw1 = float4(Pi1.wwww);

	
	float4 ixy   = permute(permute(ix) + iy);
	float4 ixy0  = permute(ixy + iz0);
	float4 ixy1  = permute(ixy + iz1);
	float4 ixy00 = permute(ixy0 + iw0);
	float4 ixy01 = permute(ixy0 + iw1);
	float4 ixy10 = permute(ixy1 + iw0);
	float4 ixy11 = permute(ixy1 + iw1);

	
	float4 gx00 = ixy00 * (1.0 / 7.0);
	float4 gy00 = floor(gx00) * (1.0 / 7.0);
	float4 gz00 = floor(gy00) * (1.0 / 6.0);
	gx00 = frac(gx00) - 0.5;
	gy00 = frac(gy00) - 0.5;
	gz00 = frac(gz00) - 0.5;
	float4 gw00 = (float4)0.75 - abs(gx00) - abs(gy00) - abs(gz00);
	float4 sw00 = step(gw00, (float4)0.0);
	gx00 -= sw00 * (step(0.0, gx00) - 0.5);
	gy00 -= sw00 * (step(0.0, gy00) - 0.5);

	float4 gx01 = ixy01 * (1.0 / 7.0);
	float4 gy01 = floor(gx01) * (1.0 / 7.0);
	float4 gz01 = floor(gy01) * (1.0 / 6.0);
	gx01 = frac(gx01) - 0.5;
	gy01 = frac(gy01) - 0.5;
	gz01 = frac(gz01) - 0.5;
	float4 gw01 = (float4)0.75 - abs(gx01) - abs(gy01) - abs(gz01);
	float4 sw01 = step(gw01, (float4)0.0);
	gx01 -= sw01 * (step(0.0, gx01) - 0.5);
	gy01 -= sw01 * (step(0.0, gy01) - 0.5);

	float4 gx10 = ixy10 * (1.0 / 7.0);
	float4 gy10 = floor(gx10) * (1.0 / 7.0);
	float4 gz10 = floor(gy10) * (1.0 / 6.0);
	gx10 = frac(gx10) - 0.5;
	gy10 = frac(gy10) - 0.5;
	gz10 = frac(gz10) - 0.5;
	float4 gw10 = (float4)0.75 - abs(gx10) - abs(gy10) - abs(gz10);
	float4 sw10 = step(gw10, (float4)0.0);
	gx10 -= sw10 * (step(0.0, gx10) - 0.5);
	gy10 -= sw10 * (step(0.0, gy10) - 0.5);

	float4 gx11 = ixy11 * (1.0 / 7.0);
	float4 gy11 = floor(gx11) * (1.0 / 7.0);
	float4 gz11 = floor(gy11) * (1.0 / 6.0);
	gx11 = frac(gx11) - 0.5;
	gy11 = frac(gy11) - 0.5;
	gz11 = frac(gz11) - 0.5;
	float4 gw11 = (float4)0.75 - abs(gx11) - abs(gy11) - abs(gz11);
	float4 sw11 = step(gw11, (float4)0.0);
	gx11 -= sw11 * (step(0.0, gx11) - 0.5);
	gy11 -= sw11 * (step(0.0, gy11) - 0.5);

	
	float4 g0000 = float4(gx00.x, gy00.x, gz00.x, gw00.x);
	float4 g1000 = float4(gx00.y, gy00.y, gz00.y, gw00.y);
	float4 g0100 = float4(gx00.z, gy00.z, gz00.z, gw00.z);
	float4 g1100 = float4(gx00.w, gy00.w, gz00.w, gw00.w);
	float4 g0010 = float4(gx10.x, gy10.x, gz10.x, gw10.x);
	float4 g1010 = float4(gx10.y, gy10.y, gz10.y, gw10.y);
	float4 g0110 = float4(gx10.z, gy10.z, gz10.z, gw10.z);
	float4 g1110 = float4(gx10.w, gy10.w, gz10.w, gw10.w);
	float4 g0001 = float4(gx01.x, gy01.x, gz01.x, gw01.x);
	float4 g1001 = float4(gx01.y, gy01.y, gz01.y, gw01.y);
	float4 g0101 = float4(gx01.z, gy01.z, gz01.z, gw01.z);
	float4 g1101 = float4(gx01.w, gy01.w, gz01.w, gw01.w);
	float4 g0011 = float4(gx11.x, gy11.x, gz11.x, gw11.x);
	float4 g1011 = float4(gx11.y, gy11.y, gz11.y, gw11.y);
	float4 g0111 = float4(gx11.z, gy11.z, gz11.z, gw11.z);
	float4 g1111 = float4(gx11.w, gy11.w, gz11.w, gw11.w);

	
	float4 norm00 = taylorInvSqrt(float4(dot(g0000, g0000), dot(g0100, g0100), dot(g1000, g1000), dot(g1100, g1100)));
	g0000 *= norm00.x;
	g0100 *= norm00.y;
	g1000 *= norm00.z;
	g1100 *= norm00.w;

	float4 norm01 = taylorInvSqrt(float4(dot(g0001, g0001), dot(g0101, g0101), dot(g1001, g1001), dot(g1101, g1101)));
	g0001 *= norm01.x;
	g0101 *= norm01.y;
	g1001 *= norm01.z;
	g1101 *= norm01.w;

	float4 norm10 = taylorInvSqrt(float4(dot(g0010, g0010), dot(g0110, g0110), dot(g1010, g1010), dot(g1110, g1110)));
	g0010 *= norm10.x;
	g0110 *= norm10.y;
	g1010 *= norm10.z;
	g1110 *= norm10.w;

	float4 norm11 = taylorInvSqrt(float4(dot(g0011, g0011), dot(g0111, g0111), dot(g1011, g1011), dot(g1111, g1111)));
	g0011 *= norm11.x;
	g0111 *= norm11.y;
	g1011 *= norm11.z;
	g1111 *= norm11.w;

	
	float n0000 = dot(g0000, Pf0);
	float n1000 = dot(g1000, float4(Pf1.x, Pf0.yzw));
	float n0100 = dot(g0100, float4(Pf0.x, Pf1.y, Pf0.zw));
	float n1100 = dot(g1100, float4(Pf1.xy, Pf0.zw));
	float n0010 = dot(g0010, float4(Pf0.xy, Pf1.z, Pf0.w));
	float n1010 = dot(g1010, float4(Pf1.x, Pf0.y, Pf1.z, Pf0.w));
	float n0110 = dot(g0110, float4(Pf0.x, Pf1.yz, Pf0.w));
	float n1110 = dot(g1110, float4(Pf1.xyz, Pf0.w));
	float n0001 = dot(g0001, float4(Pf0.xyz, Pf1.w));
	float n1001 = dot(g1001, float4(Pf1.x, Pf0.yz, Pf1.w));
	float n0101 = dot(g0101, float4(Pf0.x, Pf1.y, Pf0.z, Pf1.w));
	float n1101 = dot(g1101, float4(Pf1.xy, Pf0.z, Pf1.w));
	float n0011 = dot(g0011, float4(Pf0.xy, Pf1.zw));
	float n1011 = dot(g1011, float4(Pf1.x, Pf0.y, Pf1.zw));
	float n0111 = dot(g0111, float4(Pf0.x, Pf1.yzw));
	float n1111 = dot(g1111, Pf1);

	
	float4 fade_xyzw = fade(Pf0);
	float4 n_0w = lerp(float4(n0000, n1000, n0100, n1100), float4(n0001, n1001, n0101, n1101), fade_xyzw.w);
	float4 n_1w = lerp(float4(n0010, n1010, n0110, n1110), float4(n0011, n1011, n0111, n1111), fade_xyzw.w);
	float4 n_zw = lerp(n_0w, n_1w, fade_xyzw.z);
	float2 n_yzw = lerp(n_zw.xy, n_zw.zw, fade_xyzw.y);
	float  n_xyzw = lerp(n_yzw.x, n_yzw.y, fade_xyzw.x);
	
	return 2.2 * n_xyzw;
}

float simplexNoise(float2 v)
{
	// 定数
	const float4 C = float4
	(
		0.211324865405187,   // (3.0-sqrt(3.0))/6.0
		0.366025403784439,   // 0.5*(sqrt(3.0)-1.0)
		-0.577350269189626,  // -1.0 + 2.0 * C.x
		0.024390243902439    // 1.0 / 41.0
	);

	float2 i  = floor(v + dot(v, C.yy)); // 変形した座標の整数部
	float2 x0 = v - i + dot(i, C.xx);    // 単体1つめの頂点 
	float2 x1 = x0.xy + C.xx;			 // 単体2つめの頂点
	float2 x2 = x0.xy + C.zz;			 // 単体3つめの頂点

	// 単体のユニットの原点（x0）からの相対的なx, y成分を比較し、
	// 2つめの頂点の座標がどちらであるか判定
	float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
	x1 -= i1;

	// 勾配ベクトル計算時のインデックスを並べ替え
	i = mod289(i); // 並べ換え時、オーバーフローが起きないように値を0～288に制限
	float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0))
		+ i.x + float3(0.0, i1.x, 1.0));

	// 放射状円ブレンドカーネル（放射円状に減衰）
	float3 m = max(0.5 - float3(dot(x0, x0), dot(x1.xy, x1.xy), dot(x2.xy, x2.xy)), 0.0);
	m = m * m;
	m = m * m;

	// 勾配を計算
	// 2次元正軸体（45°回転した四角形）の境界に均一に分散した41個の点
	// 41という数字は、ほどよく分散しかつ、41×7=287と289 に近い数値であるから
	float3 x  = 2.0 * frac(p * C.www) - 1.0; // -1.0～1.0の範囲で41個に分布したx軸の値
	float3 h  = abs(x) - 0.5;				 // 勾配のy成分
	float3 ox = floor(x + 0.5);				 // 四捨五入(=round())
	float3 a0 = x - ox;						 // 勾配のx成分

	// mをスケーリングすることで、間接的に勾配ベクトルを正規化
	m *= taylorInvSqrt(a0*a0 + h*h);

	// 点Pにおけるノイズの値を計算
	float3 g;
	g.x  = a0.x  * x0.x               + h.x  * x0.y;
	g.yz = a0.yz * float2(x1.x, x2.x) + h.yz * float2(x1.y, x2.y);

	// 値の範囲が[-1, 1]となるように、任意の因数でスケーリング
	return 130.0 * dot(m, g);
}

float simplexNoise(float3 v)
{
	// 定数
	const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
	const float4 D = float4(0.0, 0.5, 1.0, 2.0);

	float3 i  = floor(v + dot(v, C.yyy)); // 変形した座標の整数部
	float3 x0 = v   - i + dot(i, C.xxx);  // 単体1つめの頂点 
	
	float3 g = step(x0.yzx, x0.xyz);	  // 成分比較
	float3 l = 1.0 - g;
	float3 i1 = min(g.xyz, l.zxy);
	float3 i2 = max(g.xyz, l.zxy);

	//     x0 = x0 - 0. + 0.0 * C       // 単体1つめの頂点 
	float3 x1 = x0 - i1 + 1.0 * C.xxx;	// 単体2つめの頂点 
	float3 x2 = x0 - i2 + 2.0 * C.xxx;	// 単体3つめの頂点 
	float3 x3 = x0 - 1. + 3.0 * C.xxx;	// 単体4つめの頂点 

	// 勾配ベクトル計算時のインデックスを並べ替え
	i = mod289(i);
	float4 p = permute(permute(permute(
		  i.z + float4(0.0, i1.z, i2.z, 1.0))
		+ i.y + float4(0.0, i1.y, i2.y, 1.0))
		+ i.x + float4(0.0, i1.x, i2.x, 1.0));

	// 勾配ベクトルを計算
	float  n_ = 0.142857142857; // 1.0 / 7.0
	float3 ns = n_ * D.wyz - D.xzx;

	float4 j = p - 49.0 * floor(p * ns.z * ns.z);	// fmod(p, 7*7)

	float4 x_ = floor(j * ns.z);
	float4 y_ = floor(j - 7.0 * x_); // fmod(j, N)

	float4 x = x_ * ns.x + ns.yyyy;
	float4 y = y_ * ns.x + ns.yyyy;
	float4 h = 1.0 - abs(x) - abs(y);

	float4 b0 = float4(x.xy, y.xy);
	float4 b1 = float4(x.zw, y.zw);

	float4 s0 = floor(b0) * 2.0 + 1.0;
	float4 s1 = floor(b1) * 2.0 + 1.0;
	float4 sh = -step(h, float4(0.0, 0.0, 0.0, 0.0));

	float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

	float3 p0 = float3(a0.xy, h.x);
	float3 p1 = float3(a0.zw, h.y);
	float3 p2 = float3(a1.xy, h.z);
	float3 p3 = float3(a1.zw, h.w);

	// 勾配を正規化
	float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	// 放射円状ブレンドカーネル（放射円状に減衰）
	float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	m = m * m;
	// 最終的なノイズの値を算出
	return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1),
		dot(p2, x2), dot(p3, x3)));
}

float simplexNoise(float4 v)
{
	// 定数
	const float4 C = float4(
		0.138196601125011,   // (5 - sqrt(5))/20  G4
		0.276393202250021,   // 2 * G4
		0.414589803375032,   // 3 * G4
		-0.447213595499958); // -1 + 4 * G4

	float4 i = floor(v + dot(v, (float4)F4)); // 変形した座標の整数部
	float4 x0 = v - i + dot(i, C.xxxx);       // 単体1つめの頂点
	
	// 点Pが属する単体の判定のための順序付け
	// by Bill Licea-Kane, AMD (formerly ATI)
	float4 i0;
	float3 isX = step(x0.yzw, x0.xxx);
	float3 isYZ = step(x0.zww, x0.yyz);
	// i0.x  = dot(isX, float3(1.0, 1.0, 1.0));
	i0.x = isX.x + isX.y + isX.z;
	i0.yzw = 1.0 - isX;
	// i0.y += dot(isYZ.xy, float2(1.0, 1.0));
	i0.y += isYZ.x + isYZ.y;
	i0.zw += 1.0 - isYZ.xy;
	i0.z += isYZ.z;
	i0.w += 1.0 - isYZ.z;

	// i0のそれぞれの成分に0,1,2,3のどれかの値を含む
	float4 i3 = clamp(i0, 0.0, 1.0);
	float4 i2 = clamp(i0 - 1.0, 0.0, 1.0);
	float4 i1 = clamp(i0 - 2.0, 0.0, 1.0);

	//     x0 = x0 - 0.0 + 0.0 * C.xxxx  // 単体1つめの頂点
	float4 x1 = x0 - i1 + 1.0 * C.xxxx;  // 単体2つめの頂点
	float4 x2 = x0 - i2 + 2.0 * C.xxxx;	 // 単体3つめの頂点
	float4 x3 = x0 - i3 + 3.0 * C.xxxx;	 // 単体4つめの頂点
	float4 x4 = x0 - 1. + 4.0 * C.xxxx;  // 単体5つめの頂点


	// 勾配ベクトル計算時のインデックスを並べ替え
	i = mod289(i);
	float  j0 = permute(permute(permute(permute(i.w) + i.z) + i.y) + i.x);
	float4 j1 = permute(permute(permute(permute(
		i.w + float4(i1.w, i2.w, i3.w, 1.0))
		+ i.z + float4(i1.z, i2.z, i3.z, 1.0))
		+ i.y + float4(i1.y, i2.y, i3.y, 1.0))
		+ i.x + float4(i1.x, i2.x, i3.x, 1.0));

	// 勾配ベクトルを計算
	float4 ip = float4(1.0 / 294.0, 1.0 / 49.0, 1.0 / 7.0, 0.0);

	float4 p0 = grad4(j0, ip);
	float4 p1 = grad4(j1.x, ip);
	float4 p2 = grad4(j1.y, ip);
	float4 p3 = grad4(j1.z, ip);
	float4 p4 = grad4(j1.w, ip);

	// 勾配ベクトルを正規化
	float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;
	p4 *= taylorInvSqrt(dot(p4, p4));

	// 放射円状ブレンドカーネル（放射円状に減衰）
	float3 m0 = max(0.6 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	float2 m1 = max(0.6 - float2(dot(x3, x3), dot(x4, x4)), 0.0);
	m0 = m0 * m0;
	m1 = m1 * m1;
	// 最終的なノイズの値を算出（5つの角からの影響を計算）
	return 49.0 * (
		  dot(m0 * m0, float3(dot(p0, x0), dot(p1, x1), dot(p2, x2)))
		+ dot(m1 * m1, float2(dot(p3, x3), dot(p4, x4)))
		);
}

#define EPSILON 1e-3

float3 curlNoise(float3 coord)
{
    float3 dx = float3(EPSILON, 0.0, 0.0);
    float3 dy = float3(0.0, EPSILON, 0.0);
    float3 dz = float3(0.0, 0.0, EPSILON);

    float3 dpdx0 = simplexNoise(coord - dx);
    float3 dpdx1 = simplexNoise(coord + dx);
    float3 dpdy0 = simplexNoise(coord - dy);
    float3 dpdy1 = simplexNoise(coord + dy);
    float3 dpdz0 = simplexNoise(coord - dz);
    float3 dpdz1 = simplexNoise(coord + dz);

    float x = dpdy1.z - dpdy0.z + dpdz1.y - dpdz0.y;
    float y = dpdz1.x - dpdz0.x + dpdx1.z - dpdx0.z;
    float z = dpdx1.y - dpdx0.y + dpdy1.x - dpdy0.x;

    return float3(x, y, z) / EPSILON * 2.0;
}

float fBm(float2 p, int oct, float freq, float lacun, float pers)
{
	float sum = 0;	
	float amp = 0.5;
	
	for(int i=0; i <= oct; i++) {
		sum += Perlin(p*freq)*amp * .5 + .5;
		freq *= lacun;
		amp *= pers;
	}
	return sum;
}

float fBm(float3 p, int oct, float freq, float lacun, float pers)
{
	float sum = 0;	
	float amp = 0.5;
	
	for(int i=0; i <= oct; i++) {
		sum += Perlin(p*freq)*amp * .5 + .5;
		freq *= lacun;
		amp *= pers;
	}
	return sum;
}

float fBm(float4 p, int oct, float freq, float lacun, float pers)
{
	float sum = 0;	
	float amp = 0.5;
	
	for(int i=0; i <= oct; i++) {
		sum += Perlin(p*freq)*amp * .5 + .5;
		freq *= lacun;
		amp *= pers;
	}
	return sum;
}

float pattern( in float2 p, int oct, float freq, float lacun, float pers)
  {
    float2 q = float2( fBm( p + float2(0.0,0.0), oct, freq, lacun, pers),
                   fBm( p + float2(5.2,1.3), oct, freq, lacun, pers));

    return fBm( p + 4.0*q , oct, freq, lacun, pers);
  }

float fnoise(float2 p, int oct, float freq, float pers){
    float t = 0.0;
    for(int i = 0; i < oct; i++){
        float ffreq = pow(abs(freq), float(i));
        float amp  = pow(abs(pers), float(oct - i));
        t += valueNoise(float2(p.x / ffreq, p.y / ffreq)) * amp;
    }
    return t;
}

// シームレスノイズ生成
float snoise(float2 p, float2 q, float2 r){
    return noise(float2(p.x,       p.y      )) *        q.x  *        q.y  +
           noise(float2(p.x,       p.y + r.y)) *        q.x  * (1.0 - q.y) +
           noise(float2(p.x + r.x, p.y      )) * (1.0 - q.x) *        q.y  +
           noise(float2(p.x + r.x, p.y + r.y)) * (1.0 - q.x) * (1.0 - q.y);
}


#endif