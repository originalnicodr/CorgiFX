	//texture Stageplus_texturedepth : COLOR <source=StageTexPlusDepth;>;
	//sampler Stageplus_depthsampler { Texture = Stageplus_texturedepth; };


#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    #define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
    #define RESHADE_DEPTH_INPUT_IS_REVERSED 1
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
    #define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
    #define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif
#ifndef RESHADE_USE_FAKE_DEPTH
    #define RESHADE_USE_FAKE_DEPTH 0
#endif

#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BUFFER_SCREEN_SIZE float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define BUFFER_ASPECT_RATIO (BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

texture Test_Tex <
    source = "Depth.png";
> {
    Format = RGBA8;
    Width  = 1920;
    Height = 1080;
};

sampler Test_Sampler
{
    Texture  = Test_Tex;
    AddressU = BORDER;
    AddressV = BORDER;
};

#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    #define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
    #define RESHADE_DEPTH_INPUT_IS_REVERSED 1
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
    #define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
    #define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif
#ifndef RESHADE_USE_FAKE_DEPTH
    #define RESHADE_USE_FAKE_DEPTH 0
#endif

#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BUFFER_SCREEN_SIZE float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define BUFFER_ASPECT_RATIO (BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

    uniform float ImageDepth_offset <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
    > = 0;

float GetLinearizedDepth(float2 texcoord)
{
float depthimage= saturate(tex2D(Test_Sampler,texcoord).x-ImageDepth_offset);
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    texcoord.y = 1.0 - texcoord.y;
#endif
    
    float depth = tex2Dlod(DepthBuffer, float4(texcoord, 0, 0)).x;
#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
    const float C = 0.01;
    depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
    depthimage= (exp(depthimage * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
    depth = 1.0 - depth;
    depthimage=1.0-depthimage;
#endif
    const float N = 1.0;
    depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);
    depthimage /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depthimage * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);
    return min(depth,depthimage);
}



