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

struct Input{
	float3 pos;
};

RWStructuredBuffer<Trail> TrailBuffer : TRAILBUFFER;
RWStructuredBuffer<Node> _NodeBuffer : NODEBUFFER;
RWStructuredBuffer<OutBuf> OutBuffer : BACKBUFFER;
StructuredBuffer<float3> InputBuffer;


float Time;
uint TrailNum;
uint NodeNumPerTrail;
float UpdateDistanceMin;
bool init;

int ToNodeBufIdx(int trailIdx, int nodeIdx){
	nodeIdx %= NodeNumPerTrail;
	return trailIdx * NodeNumPerTrail + nodeIdx;
}

bool IsValid(Node node){
	return node.time >= 0;
}

Node GetNode(int trailIdx, int nodeIdx){
	return _NodeBuffer[ToNodeBufIdx(trailIdx, nodeIdx)];
}

void SetNode(Node node, int trailIdx, int nodeIdx){
	OutBuffer[ToNodeBufIdx(trailIdx, nodeIdx)].node = node;
}

[numthreads(256, 1, 1)]
void CS(uint3 dtid : SV_DispatchThreadID){
	uint trailIdx = dtid.x;
	if(trailIdx < TrailNum){
		Trail trail;
		trail = OutBuffer[trailIdx].trail;
		int currentNodeIdx = trail.currentNodeIdx;
		Input input;
	    input.pos = InputBuffer[trailIdx];
		
		bool update = true;
		if(init) trail.currentNodeIdx = -1;
		if(trail.currentNodeIdx >= 0){
			Node node = GetNode(trailIdx, currentNodeIdx);
			float dist = distance(input.pos, node.pos);
			update = dist > UpdateDistanceMin;
		}
		
		if(update){
			Node node;
			node.time = Time;
			node.pos = input.pos;
			
			currentNodeIdx++;
			currentNodeIdx %= NodeNumPerTrail;
			
			SetNode(node, trailIdx, currentNodeIdx);
			
			trail.currentNodeIdx = currentNodeIdx;
			OutBuffer[trailIdx].trail = trail;
		}
	}
}

technique11 Trail_CS {
	
	pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );
	
		
	}
}

