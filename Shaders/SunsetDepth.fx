//SunsetDepth by originalnicodr, based on the code of Sunset Filter from Jacob Maximilian Fiber and Stage Depth from Marot Satil, all the credits goes to them.
//I wanted the Sunset Filter shader to work with the depth buffer, so i editen the original Sunset Filter shader, enjoy.

// Made by Marot Satil for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
// Follow @GPOSERS_FFXIV on Twitter and join us on Discord (https://discord.gg/39WpvU2)
// for the latest GShade package updates!
//
// This shader was designed in the same vein as GreenScreenDepth.fx, but instead of applying a
// green screen with adjustable distance, it applies a PNG texture with adjustable opacity.
//
// PNG transparency is fully supported, so you could for example add another moon to the sky
// just as readily as create a "green screen" stage like in real life.
//
// Copyright (c) 2019, Marot Satil
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/* 
SunsetFilter PS v1.0.1 (c) 2018 Jacob Maximilian Fober, 
This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/


	  ////////////
	 /// MENU ///
	////////////

#include "ReShadeUI.fxh"

uniform float3 ColorA < __UNIFORM_COLOR_FLOAT3
	ui_label = "Colour (A)";
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

uniform int Axis < __UNIFORM_SLIDER_INT1
	ui_label = "Angle";
	#if __RESHADE__ < 40000
		ui_step = 1;
	#endif
	ui_min = -180; ui_max = 180;
	ui_category = "Controls";
> = -7;

uniform float Scale < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Gradient sharpness";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.005;
	ui_category = "Controls";
> = 1.0;

uniform float Offset < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Position";
	#if __RESHADE__ < 40000
		ui_step = 0.002;
	#endif
	ui_min = 0.0; ui_max = 0.5;
	ui_category = "Controls";
> = 0.0;




uniform float Stage_Opacity <
    ui_label = "Opacity";
    ui_tooltip = "Set the transparency of the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float Stage_depth <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Depth";
> = 0.97;


	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

#include "ReShade.fxh"

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


	  //////////////
	 /// SHADER ///
	//////////////

void SunsetDepth(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab screen texture
	Image.rgb = tex2D(ReShade::BackBuffer, UvCoord).rgb;
	// Correct Aspect Ratio
	float2 UvCoordAspect = UvCoord;
	UvCoordAspect.y += ReShade::AspectRatio * 0.5 - 0.5;
	UvCoordAspect.y /= ReShade::AspectRatio;
	// Center coordinates
	UvCoordAspect = UvCoordAspect * 2 - 1;
	UvCoordAspect *= Scale;

	// Tilt vector
	float Angle = radians(-Axis);
	float2 TiltVector = float2(sin(Angle), cos(Angle));
	
	float depth = 1 - ReShade::GetLinearizedDepth(UvCoord).r;

	// Blend Mask
	float BlendMask = dot(TiltVector, UvCoordAspect) + Offset;
    if( depth < Stage_depth )
	{
	    BlendMask = Overlay(BlendMask * 0.5 + 0.5); // Linear coordinates
	    Image = Screen(Image.rgb, lerp(ColorA.rgb, ColorB.rgb, Flip ? 1 - BlendMask : BlendMask)* Stage_Opacity);
    }

	// Color image
}
	  //////////////
	 /// OUTPUT ///
	//////////////

technique SunsetDepth < ui_label = "Sunset Depth"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SunsetDepth;
	}
}

