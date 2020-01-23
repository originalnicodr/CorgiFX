//SunsetFog shader by originalnicodr, a modified version of Adaptive fog by Otis with some code from the SunsetFilter by Jacob Maximilian Fober, all credits goes to them

///////////////////////////////////////////////////////////////////
// Simple depth-based fog powered with bloom to fake light diffusion.
// The bloom is borrowed from SweetFX's bloom by CeeJay.
//
// As Reshade 3 lets you tweak the parameters in-game, the mouse-oriented
// feature of the v2 Adaptive Fog is no longer needed: you can select the
// fog color in the reshade settings GUI instead.
//
///////////////////////////////////////////////////////////////////
// By Otis / Infuse Project
///////////////////////////////////////////////////////////////////

/* 
SunsetFilter PS v1.0.0 (c) 2018 Jacob Maximilian Fober, 

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/
// Lightly optimized by Marot Satil for the GShade project.

#include "Reshade.fxh"
#include "ReShadeUI.fxh"

uniform float3 ColorA < __UNIFORM_COLOR_FLOAT3
	ui_label = "Colour (A)";
    ui_type = "color";
	ui_category = "Colors";
> = float3(1.0, 0.0, 0.0);

uniform float3 ColorB < __UNIFORM_COLOR_FLOAT3
	ui_label = "Colour (B)";
	ui_type = "color";
	ui_category = "Colors";
> = float3(0.0, 0.0, 0.0);

uniform bool Flip <
	ui_label = "Color flip";
	ui_category = "Colors";
> = false;

uniform bool Screenb <
	ui_label = "Screen mode";
	ui_category = "Colors";
> = false;

uniform int Axis < __UNIFORM_SLIDER_INT1
	ui_label = "Angle";
	#if __RESHADE__ < 40000
		ui_step = 1;
	#endif
	ui_min = -180; ui_max = 180;
	ui_category = "Color controls";
> = -7;

uniform float Scale < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Gradient sharpness";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.005;
	ui_category = "Color controls";
> = 1.0;

uniform float Offset < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Position";
	#if __RESHADE__ < 40000
		ui_step = 0.002;
	#endif
	ui_min = 0.0; ui_max = 0.5;
	ui_category = "Color controls";
> = 0.0;

uniform float MaxFogFactor <
	ui_type = "slider";
	ui_min = 0.000; ui_max=1.000;
	ui_tooltip = "The maximum fog factor. 1.0 makes distant objects completely fogged out, a lower factor will shimmer them through the fog.";
	ui_step = 0.001;
	ui_category = "Fog controls";
> = 0.8;

uniform float FogCurve <
	ui_type = "slider";
	ui_min = 0.00; ui_max=175.00;
	ui_step = 0.01;
	ui_tooltip = "The curve how quickly distant objects get fogged. A low value will make the fog appear just slightly. A high value will make the fog kick in rather quickly. The max value in the rage makes it very hard in general to view any objects outside fog.";
	ui_category = "Fog controls";
> = 1.5;

uniform float FogStart <
	ui_type = "slider";
	ui_min = 0.000; ui_max=1.000;
	ui_step = 0.001;
	ui_tooltip = "Start of the fog. 0.0 is at the camera, 1.0 is at the horizon, 0.5 is halfway towards the horizon. Before this point no fog will appear.";
> = 0.050;

uniform float BloomThreshold <
	ui_type = "slider";
	ui_min = 0.00; ui_max=50.00;
	ui_step = 0.1;
	ui_tooltip = "Threshold for what is a bright light (that causes bloom) and what isn't.";
	ui_category = "Bloom controls";
> = 10.25;

uniform float BloomPower <
	ui_type = "slider";
	ui_min = 0.000; ui_max=100.000;
	ui_step = 0.1;
	ui_tooltip = "Strength of the bloom";
	ui_category = "Bloom controls";
> = 10.0;

uniform float BloomWidth <
	ui_type = "slider";
	ui_min = 0.0000; ui_max=1.0000;
	ui_tooltip = "Width of the bloom";
	ui_category = "Bloom controls";
> = 0.2;

// Overlay blending mode
float Overlay(float Layer)
{
	float Min = min(Layer, 0.5);
	float Max = max(Layer, 0.5);
	return 2 * (Min * Min + 2 * Max - Max * Max) - 1.5;
}

// Screen blending mode
float3 Screen(float3 LayerA, float3 LayerB)
{ return 1.0 - (1.0 - LayerA) * (1.0 - LayerB); }

//////////////////////////////////////
// textures
//////////////////////////////////////
texture   Otis_BloomTarget 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};	

//////////////////////////////////////
// samplers
//////////////////////////////////////
sampler2D Otis_BloomSampler { Texture = Otis_BloomTarget; };

// pixel shader which performs bloom, by CeeJay. 
void PS_Otis_AFG_PerformBloom(float4 position : SV_Position, float2 texcoord : TEXCOORD0, out float4 fragment: SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);
	float3 BlurColor2 = 0;
	float3 Blurtemp = 0;
	const float MaxDistance = 8*BloomWidth;
	float CurDistance = 0;
	const float Samplecount = 25.0;
	const float2 blurtempvalue = texcoord * ReShade::PixelSize * BloomWidth;
	float2 BloomSample = float2(2.5,-2.5);
	float2 BloomSampleValue;
	
	for(BloomSample.x = (2.5); BloomSample.x > -2.0; BloomSample.x = BloomSample.x - 1.0)
	{
		BloomSampleValue.x = BloomSample.x * blurtempvalue.x;
		float2 distancetemp = BloomSample.x * BloomSample.x * BloomWidth;
		
		for(BloomSample.y = (- 2.5); BloomSample.y < 2.0; BloomSample.y = BloomSample.y + 1.0)
		{
			distancetemp.y = BloomSample.y * BloomSample.y;
			CurDistance = (distancetemp.y * BloomWidth) + distancetemp.x;
			BloomSampleValue.y = BloomSample.y * blurtempvalue.y;
			Blurtemp.rgb = tex2D(ReShade::BackBuffer, float2(texcoord + BloomSampleValue)).rgb;
			BlurColor2.rgb += lerp(Blurtemp.rgb,color.rgb, sqrt(CurDistance / MaxDistance));
		}
	}
	BlurColor2.rgb = (BlurColor2.rgb / (Samplecount - (BloomPower - BloomThreshold*5)));
	const float Bloomamount = (dot(color.rgb,float3(0.299f, 0.587f, 0.114f)));
	const float3 BlurColor = BlurColor2.rgb * (BloomPower + 4.0);
	color.rgb = lerp(color.rgb,BlurColor.rgb, Bloomamount);	
	fragment = saturate(color);
}

void PS_Otis_AFG_BlendFogWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{

    // Grab screen texture
	fragment.rgb = tex2D(ReShade::BackBuffer, texcoord).rgb;

	// Correct Aspect Ratio
	float2 UvCoordAspect = texcoord;
	UvCoordAspect.y += ReShade::AspectRatio * 0.5 - 0.5;
	UvCoordAspect.y /= ReShade::AspectRatio;
    // Center coordinates
	UvCoordAspect = UvCoordAspect * 2 - 1;
	UvCoordAspect *= Scale;

	// Tilt vector
	float Angle = radians(-Axis);
	float2 TiltVector = float2(sin(Angle), cos(Angle));
	// Blend Mask
	float BlendMask = dot(TiltVector, UvCoordAspect) + Offset;

	BlendMask = Overlay(BlendMask * 0.5 + 0.5); // Linear coordinates

	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
	const float fogFactor = clamp(saturate(depth - FogStart) * FogCurve, 0.0, MaxFogFactor);
	if (!Screenb) {
		fragment = lerp(tex2D(ReShade::BackBuffer, texcoord), lerp(tex2D(Otis_BloomSampler, texcoord), lerp(ColorA.rgb, ColorB.rgb, Flip ? 1 - BlendMask : BlendMask), fogFactor), fogFactor);
	}
	else {
		fragment = Screen(fragment.rgb,lerp(tex2D(ReShade::BackBuffer, texcoord), lerp(tex2D(Otis_BloomSampler, texcoord), lerp(ColorA.rgb, ColorB.rgb, Flip ? 1 - BlendMask : BlendMask), fogFactor), fogFactor));
	}
}

technique SunsetFog
{
	pass Otis_AFG_PassBloom0
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_AFG_PerformBloom;
		RenderTarget = Otis_BloomTarget;
	}
	
	pass Otis_AFG_PassBlend
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_AFG_BlendFogWithNormalBuffer;
	}
}
