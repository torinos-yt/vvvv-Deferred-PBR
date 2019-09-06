struct Particle {
	#if defined(COMPOSITESTRUCT)
  		COMPOSITESTRUCT
 	#else
		float3 position;
	#endif
};

struct Trail{
	int currentNodeIdx;
};

struct Node{
	float time;
	float3 pos;
};

StructuredBuffer<Particle> ParticleBuffer;
StructuredBuffer<uint> AlivePointerBuffer;


RWStructuredBuffer<Trail> TrailBuffer : TRAILBUFFER;
RWStructuredBuffer<Node> _NodeBuffer : NODEBUFFER;


float Time;
uint TrailNum;
uint NodeNumPerTrail;
float UpdateDistanceMin;
bool init;



int ToNodeBufIdx(int trailIdx, int nodeIdx)
{
	nodeIdx %= NodeNumPerTrail;
	return trailIdx * NodeNumPerTrail + nodeIdx;
}

bool IsValid(Node node)
{
	return node.time >= 0;
}

Node GetNode(int trailIdx, int nodeIdx)
{
	return _NodeBuffer[ToNodeBufIdx(trailIdx, nodeIdx)];
}

void SetNode(Node node, int trailIdx, int nodeIdx)
{
	_NodeBuffer[ToNodeBufIdx(trailIdx, nodeIdx)] = node;
}


[numthreads(256, 1, 1)]
void CS_particle(uint3 dtid : SV_DispatchThreadID)
{
	uint trailIdx = dtid.x;
	if(trailIdx < TrailNum){
		Trail trail;
		trail = TrailBuffer[trailIdx];
		int currentNodeIdx = trail.currentNodeIdx;
		float3 pos;
	    pos = ParticleBuffer[trailIdx].position;
		
		bool update = true;
		if(init) trail.currentNodeIdx = -1;
		if(trail.currentNodeIdx >= 0){
			Node node = GetNode(trailIdx, currentNodeIdx);
			float dist = distance(pos, node.pos);
			update = dist > UpdateDistanceMin;
		}
		
		if(update){
			Node node;
			node.time = Time;
			node.pos = pos;
			
			currentNodeIdx++;
			currentNodeIdx %= NodeNumPerTrail;
			
			SetNode(node, trailIdx, currentNodeIdx);
			
			trail.currentNodeIdx = currentNodeIdx;
			TrailBuffer[trailIdx] = trail;
		}
	}
}

technique11 Trail_DX11Particles {
	
	pass P0{SetComputeShader( CompileShader( cs_5_0, CS_particle() ) );
	
		
	}
}

