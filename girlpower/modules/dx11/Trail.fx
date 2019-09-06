struct Trail{
	int currentNodeIdx;
};

struct Node{
	float time;
	float3 pos;
};

struct OutBuf{
	Trail trail;
	Node node;
};


Texture2D texture2d <string uiname="Texture";>;
StructuredBuffer<Trail> TrailBuffer;
StructuredBuffer<Node> NodeBuffer;
StructuredBuffer<OutBuf> OutBuffer;

uint NodeCount;
float Life;
float ConnectDisMax;


float Time;

float wid;
bool sol<string uiname = "SizeofOverLife";> = 1;

float4 scol <bool color = true; string uiname = "Start Color";> = float4(1,1,1,1);
float4 ecol <bool color = true; string uiname = "End Color";> = float4(0,0,0,0);


float3 MakeCamPos(float4x4 View){
	float tx = -dot(View[0], View[3]);
	float ty = -dot(View[1], View[3]);
	float tz = -dot(View[2], View[3]);
	return float3(tx, ty, tz);
}

int ToNodeBufIdx(int trailIdx, int nodeIdx){
	nodeIdx %= NodeCount;
	return trailIdx * NodeCount + nodeIdx;
}

Node GetNode(int trailIdx, int nodeIdx){
	return OutBuffer[ToNodeBufIdx(trailIdx, nodeIdx)].node;
}

bool IsValid(Node node){
	return node.time > 0;
}

SamplerState linearSampler : IMMUTABLE{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

cbuffer cbPerDraw : register( b0 ){
	float4x4 tVP : LAYERVIEWPROJECTION;
};

cbuffer cbPerObj : register( b1 ){
	float4x4 tW : WORLD;
	float4x4 tV : VIEW;
	float4x4 tWVP : WORLDVIEWPROJECTION;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct VS_IN{
	uint id : SV_VertexID;
	uint iid : SV_InstanceID;
};

struct vsout {
	float4 pos : POSITION0;
	float3 dir : TANGENT0;
	float4 col : COLOR0;
	float4 posNext: POSITION1;
	float3 dirNext : TANGENT1;
	float4 colNext : COLOR1;
	float width : TEXCOORD2;
	float ageRate : TEXCOORD0;
	float ageRateNext : TEXCOORD1;
};

struct gsout {
	float4 pos : SV_POSITION;
	float4 col : COLOR;
};


vsout VS(VS_IN input){
	vsout output;
	Trail trail = OutBuffer[input.iid].trail;
	int currentNodeIdx = trail.currentNodeIdx;
	
	Node node0 = GetNode(input.iid, input.id - 1);
	Node node1 = GetNode(input.iid, input.id);
	Node node2 = GetNode(input.iid, input.id + 1);
	Node node3 = GetNode(input.iid, input.id + 2);
	
	bool isLastNode = (currentNodeIdx == (int)input.id);
	
	if(isLastNode || !IsValid(node1)){
		node0 = node1 = node2 = node3 = GetNode(input.iid, currentNodeIdx);
	}
	
	float3 pos1 = node1.pos;
	float3 pos0 = IsValid(node0) ? node0.pos : pos1;
	float3 pos2 = IsValid(node2) ? node2.pos : pos1;
	float3 pos3 = IsValid(node3) ? node3.pos : pos2;

	
	output.pos = float4(pos1, 1);
	output.posNext = float4(pos2, 1);
	
	output.dir = normalize(pos2 - pos0);
	output.dirNext = normalize(pos3 - pos1);
	
	float ageRate = saturate((Time - node1.time) / Life);
	float ageRateNext = saturate((Time - node2.time) / Life);
	output.ageRate = ageRate;
	output.ageRateNext = ageRateNext;
	
	output.col = lerp(scol, ecol, ageRate);
	output.colNext = lerp(scol, ecol, ageRateNext);
	
	output.width = 1;
	
	return output;
}

[maxvertexcount(4)]
void geom (point vsout input[1], inout TriangleStream<gsout> outStream){
	gsout output0, output1, output2, output3;
	float3 pos = input[0].pos.xyz;
	float3 dir = input[0].dir;
	float3 posNext = input[0].posNext.xyz;
	float3 dirNext = input[0].dirNext;
	
	if(distance(pos, posNext) > ConnectDisMax){
		posNext = pos;
	}
	
	float ageRate = sol ? 1 - input[0].ageRate : 1;
	float ageRateNext = sol ? 1 - input[0].ageRateNext : 1;
	
	float3 camPos = MakeCamPos(tV);
	float3 toCamDir = normalize(camPos - pos);
	float3 sideDir = normalize(cross(toCamDir, dir));
	
	float3 toCamDirNext = normalize(camPos - posNext);
	float3 sideDirNext = normalize(cross(toCamDirNext, dirNext));
	
	float width = wid * .01 * input[0].width;
	
	output0.pos = mul(float4(pos + (sideDir * width * ageRate), 1), tWVP);
	output1.pos = mul(float4(pos - (sideDir * width * ageRate), 1), tWVP);
	output2.pos = mul(float4(posNext + (sideDirNext * width * ageRateNext), 1), tWVP);
	output3.pos = mul(float4(posNext - (sideDirNext * width * ageRateNext), 1), tWVP);
	
	output0.col =
	output1.col = input[0].col;
	output2.col =
	output3.col = input[0].colNext;
	
	outStream.Append(output0);
	outStream.Append(output1);
	outStream.Append(output2);
	outStream.Append(output3);
	
	outStream.RestartStrip();
}

float4 PS(gsout In): SV_Target{
	return In.col;
}

technique10 CSTrail
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0,geom() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}