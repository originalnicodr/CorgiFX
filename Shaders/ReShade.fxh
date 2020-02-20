//Reshade.fxh with FakeDOF extension
//Reshade.fxh source at https://github.com/crosire/reshade-shaders by crosire

#pragma once

#if !defined(__RESHADE__) || __RESHADE__ < 30000
    #error "ReShade 3.0+ is required to use this header file"
#endif

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

namespace ReShade
{
    // Global variables
#if defined(__RESHADE_FXC__)
    float GetAspectRatio() { return BUFFER_WIDTH * BUFFER_RCP_HEIGHT; }
    float2 GetPixelSize() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
    float2 GetScreenSize() { return float2(BUFFER_WIDTH, BUFFER_HEIGHT); }
    #define AspectRatio BUFFER_ASPECT_RATIO
    #define PixelSize BUFFER_PIXEL_SIZE
    #define ScreenSize BUFFER_SCREEN_SIZE
#else
    static const float AspectRatio = BUFFER_ASPECT_RATIO;
    static const float2 PixelSize = BUFFER_PIXEL_SIZE;
    static const float2 ScreenSize = BUFFER_SCREEN_SIZE;
#endif

    // Global textures and samplers
    texture BackBufferTex : COLOR;
    texture DepthBufferTex : DEPTH;

    sampler BackBuffer { Texture = BackBufferTex; };
    sampler DepthBuffer { Texture = DepthBufferTex; };

	//texture Stageplus_texturedepth : COLOR <source=StageTexPlusDepth;>;
	//sampler Stageplus_depthsampler { Texture = Stageplus_texturedepth; };

texture Test_Tex <
    source = "depthmap.png";
> {
    Format = RGBA8;
    Width  = 1024;
    Height = 768;
};

sampler Test_Sampler
{
    Texture  = Test_Tex;
    AddressU = BORDER;
    AddressV = BORDER;
};




#if RESHADE_USE_FAKE_DEPTH
    #include "Imagedepthf.fxh";
    float GetLinearizedDepth(float2 texcoord)
    {
    float depthimage= saturate(tex2D(Test_Sampler,getValuesImageDepthMap(texcoord)).x-ImageDepth_offset);
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
#else
    // Helper functions
    float GetLinearizedDepth(float2 texcoord)
    {

    #if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
        texcoord.y = 1.0 - texcoord.y;
    #endif
        float depth = tex2Dlod(DepthBuffer, float4(texcoord, 0, 0)).x;

    #if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
        const float C = 0.01;
        depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
    #endif
    #if RESHADE_DEPTH_INPUT_IS_REVERSED
        depth = 1.0 - depth;
    #endif
        const float N = 1.0;
        depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);
        return depth;
    }
#endif
}


// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}
