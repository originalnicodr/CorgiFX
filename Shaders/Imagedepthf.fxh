	//texture Stageplus_texturedepth : COLOR <source=StageTexPlusDepth;>;
	//sampler Stageplus_depthsampler { Texture = Stageplus_texturedepth; };

    uniform bool ImageDepth_FlipH < 
	ui_label = "Flip Horizontal";
    ui_category = "Fake Depth buffer controls";
    > = false;

    uniform bool ImageDepth_FlipV < 
	ui_label = "Flip Vertical";
    ui_category = "Fake Depth buffer controls";
    > = false;

    uniform float ImageDepth_offset <
	ui_type = "slider";
    ui_category = "Fake Depth buffer controls";
	ui_min = 0.0; ui_max = 1.0;
    > = 0;

    uniform float2 ImageDepth_Scale <
    ui_category = "Fake Depth buffer controls";
  	ui_type = "slider";
	ui_label = "Scale";
	ui_step = 0.01;
	ui_min = 0.01; ui_max = 5.0;
    > = (1.001,1.001);

    uniform float2 ImageDepth_Pos <
    ui_category = "Fake Depth buffer controls";
  	ui_type = "slider";
	ui_label = "Position";
	ui_step = 0.001;
	ui_min = -1.5; ui_max = 1.5;
    > = (0,0);	

    uniform float ImageDepth_Axis <
    ui_category = "Fake Depth buffer controls";
	ui_type = "slider";
	ui_label = "Angle";
	ui_step = 0.1;
	ui_min = -180.0; ui_max = 180.0;
    > = 0.0;

float2 rotateImageDepthMap(float2 v,float2 o, float a){
	float2 v2= v-o;
	v2=float2((cos(a) * v2.x-sin(a)*v2.y),sin(a)*v2.x +cos(a)*v2.y);
	v2=v2+o;
	return v2;
}

float2 getValuesImageDepthMap(float2 uv)
{
	float2 uvtemp=uv;
	if (ImageDepth_FlipH) {uvtemp.x = 1-uvtemp.x;}//horizontal flip
    if (ImageDepth_FlipV) {uvtemp.y = 1-uvtemp.y;} //vertical flip
	
    float2 Layer_Scalereal= float2 (ImageDepth_Scale.x-0.44,(ImageDepth_Scale.y-0.44)*BUFFER_WIDTH/BUFFER_HEIGHT);
    float2 Layer_Posreal= float2((ImageDepth_FlipH) ? -ImageDepth_Pos.x : ImageDepth_Pos.x, (ImageDepth_FlipV) ? ImageDepth_Pos.y:-ImageDepth_Pos.y);

    uvtemp= float2(((uvtemp.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT),uvtemp.y);
    uvtemp=rotateImageDepthMap(uvtemp,Layer_Posreal+0.5,radians(ImageDepth_Axis))*Layer_Scalereal-((Layer_Posreal+0.5)*Layer_Scalereal-0.5);
    return uvtemp;
}
/*
float2 test(float2 v){
    return float2(0,0);
}*/



