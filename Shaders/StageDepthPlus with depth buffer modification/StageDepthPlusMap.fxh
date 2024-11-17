//De mas?
#ifndef RESHADE_MIX_STAGE_DEPTH_PLUS_MAP
#define RESHADE_MIX_STAGE_DEPTH_PLUS_MAP 0
#endif

	#ifndef STAGE_TEXTURE_WIDTH
	#define STAGE_TEXTURE_WIDTH BUFFER_WIDTH
	#endif

	#ifndef STAGE_TEXTURE_HEIGHT
	#define STAGE_TEXTURE_HEIGHT BUFFER_HEIGHT
	#endif

float2 rotate(float2 v,float2 o, float a){
	float2 v2= v-o;
	v2=float2((cos(a) * v2.x-sin(a)*v2.y),sin(a)*v2.x +cos(a)*v2.y);
	v2=v2+o;
	return v2;
}

float2 TextureCoordsModifier(float2 texcoord, float2 pos, float2 scale, float axis, bool fh, bool fv){
	float2 uvtemp=texcoord;
	
	if (fh) {uvtemp.x = 1-uvtemp.x;}
	if (fv) {uvtemp.y = 1-uvtemp.y;}

	float2 Layer_Posreal= float2((fh) ? -pos.x : pos.x, (fv) ? pos.y:-pos.y);
	
	uvtemp = (uvtemp - Layer_Posreal - 0.5f) * BUFFER_SCREEN_SIZE;
	
	uvtemp=rotate(uvtemp,(Layer_Posreal + 0.5f), radians(axis)) * scale / BUFFER_SCREEN_SIZE + float2(0.5f, 0.5f);

	return uvtemp;
}