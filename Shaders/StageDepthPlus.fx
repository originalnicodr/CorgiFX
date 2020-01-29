//Shader edited originalnicodr

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


#include "Reshade.fxh"

#if LAYER_SINGLECHANNEL
    #define TEXFORMAT R8
#else
    #define TEXFORMAT RGBA8
#endif

#ifndef StageTexPlus
#define StageTexPlus "Stageplus.png"//Put your image file name here or remplace the original image
#endif

uniform float Stage_Opacity <
    ui_label = "Opacity";
    ui_tooltip = "Set the transparency of the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float2 Layer_Scale <
  	ui_type = "slider";
	ui_label = "Scale";
	ui_min = 0.01; ui_max = 5.0;
	ui_step = 0.01;
> = (1.001,1.001);

uniform float2 Layer_Pos <
  	ui_type = "slider";
	ui_label = "Position";
	ui_min = -1.5; ui_max = 1.5;
	ui_step = 0.001;
> = (0,0);

uniform float Axis <
	ui_type = "slider";
	ui_label = "Angle";
	#if __RESHADE__ < 40000
		ui_step = 0.1;
	#endif
	ui_min = -180.0; ui_max = 180.0;
> = 0.0;

uniform int BlendM <
	ui_type = "combo";
	ui_label = "Blending Mode";
	ui_tooltip = "Select the blending mode used with the gradient on the screen.";
	ui_items = "Normal\0Multiply\0Screen\0Overlay\0Darken\0Lighten\0Color Dodge\0Color Burn\0Hard Light\0Soft Light\0Difference\0Exclusion\0Hue\0Saturation\0Color\0Luminosity\0";
> = 0;

uniform float Stage_depth <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Depth";
> = 0.97;

texture Stage_texture <source=StageTexPlus;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };

sampler Stage_sampler { Texture = Stage_texture; };

//Blending modes functions

// Screen blending mode
float3 Screen(float3 LayerA, float3 LayerB)
{ return 1.0 - (1.0 - LayerA) * (1.0 - LayerB); }

// Multiply blending mode
float3 Multiply(float3 LayerA, float3 LayerB)
{ return LayerA * LayerB; }

// Darken blending mode
float3 Darken(float3 LayerA, float3 LayerB)
{ return min(LayerA,LayerB); }

// Lighten blending mode
float3 Lighten(float3 LayerA, float3 LayerB)
{ return max(LayerA,LayerB); }

// Color Dodge blending mode
float3 ColorDodge(float3 LayerA, float3 LayerB)
{ return (LayerB.r < 1 && LayerB.g < 1 && LayerB.b < 1) ? min(1.0,LayerA/(1.0-LayerB)) : 1.0;}

// Color Burn blending mode
float3 ColorBurn(float3 LayerA, float3 LayerB)
{ return (LayerB.r > 0 && LayerB.g > 0 && LayerB.b > 0) ? 1.0-min(1.0,(1.0-LayerA)/LayerB) : 0;}

// Hard light blending mode
float3 HardLight(float3 LayerA, float3 LayerB)
{ return (LayerB.r <= 0.5 && LayerB.g <=0.5 && LayerB.b <= 0.5) ? clamp(Multiply(LayerA,2*LayerB),0,1) : clamp(Multiply(LayerA,2*LayerB-1),0,1);}

float3 Aux(float3 x)
{ return (x.r<=0.25 && x.g<=0.25 && x.b<=0.25) ? ((16.0*x-12.0)*x+4)*x : sqrt(x);}

// Soft light blending mode
float3 SoftLight(float3 LayerA, float3 LayerB)
{ return (LayerB.r <= 0.5 && LayerB.g <=0.5 && LayerB.b <= 0.5) ? clamp(LayerA-(1.0-2*LayerB)*LayerA*(1-LayerA),0,1) : clamp(LayerA+(2*LayerB-1.0)*(Aux(LayerA)-LayerA),0,1);}


// Difference blending mode
float3 Difference(float3 LayerA, float3 LayerB)
{ return LayerA-LayerB; }

// Exclusion blending mode
float3 Exclusion(float3 LayerA, float3 LayerB)
{ return LayerA+LayerB-2*LayerA*LayerB; }

// Overlay blending mode
float3 Overlay(float3 LayerA, float3 LayerB)
{ return HardLight(LayerB,LayerA); }


float Lum(float3 c){
	return (0.3*c.r+0.59*c.g+0.11*c.b);}

float min3 (float a, float b, float c){
	return min(a,(min(b,c)));
}

float max3 (float a, float b, float c){
	return max(a,(max(b,c)));
}

float Sat(float3 c){
	return max3(c.r,c.g,c.b)-min3(c.r,c.g,c.b);}

float3 ClipColor(float3 c){
	float l=Lum(c);
	float n=min3(c.r,c.g,c.b);
	float x=max3(c.r,c.g,c.b);
	float cr=c.r;
	float cg=c.g;
	float cb=c.b;
	if (n<0){
		cr=l+(((cr-l)*l)/(l-n));
		cg=l+(((cg-l)*l)/(l-n));
		cb=l+(((cb-l)*l)/(l-n));
	}
	if (x>1){
		cr=l+(((cr-l)*(1-l))/(x-l));
		cg=l+(((cg-l)*(1-l))/(x-l));
		cb=l+(((cb-l)*(1-l))/(x-l));
	}
	return float3(cr,cg,cb);
}

float3 SetLum (float3 c, float l){
	float d= l-Lum(c);
	return float3(c.r+d,c.g+d,c.b+d);
}

float3 SetSat(float3 c, float s){
	float cr=c.r;
	float cg=c.g;
	float cb=c.b;
	if (cr==max3(cr,cg,cb) && cb==min3(cr,cg,cb)){//caso r->max g->mid b->min
		if (cr>cb){
			cg=(((cg-cb)*s)/(cr-cb));
			cr=s;
		}
		else{
			cg=0;
			cr=0;
		}
		cb=0;
	}
	else{
		if (cr==max3(cr,cg,cb) && cg==min3(cr,cg,cb)){//caso r->max b->mid g->min
			if (cr>cg){
				cb=(((cb-cg)*s)/(cr-cg));
				cr=s;
			}
			else{
				cb=0;
				cr=0;
			}
			cg=0;
		}
		else{
			if (cg==max3(cr,cg,cb) && cb==min3(cr,cg,cb)){//caso g->max r->mid b->min
				if (cg>cb){
					cr=(((cr-cb)*s)/(cg-cb));
					cg=s;
				}
				else{
					cr=0;
					cg=0;
				}
				cb=0;
			}
			else{
				if (cg==max3(cr,cg,cb) && cr==min3(cr,cg,cb)){//caso g->max b->mid r->min
					if (cg>cr){
						cb=(((cb-cr)*s)/(cg-cr));
						cg=s;
					}
					else{
						cb=0;
						cg=0;
					}
					cr=0;
				}
				else{
					if (cb==max3(cr,cg,cb) && cg==min3(cr,cg,cb)){//caso b->max r->mid g->min
						if (cb>cg){
							cr=(((cr-cg)*s)/(cb-cg));
							cb=s;
						}
						else{
							cr=0;
							cb=0;
						}
						cg=0;
					}
					else{
						if (cb==max3(cr,cg,cb) && cr==min3(cr,cg,cb)){//caso b->max g->mid r->min
							if (cb>cr){
								cg=(((cg-cr)*s)/(cb-cr));
								cb=s;
							}
							else{
								cg=0;
								cb=0;
							}
							cr=0;
						}
					}
				}
			}
		}
	}
	return float3(cr,cg,cb);
}

float3 Hue(float3 b, float3 s){
	return SetLum(SetSat(s,Sat(b)),Lum(b));
}

float3 Saturation(float3 b, float3 s){
	return SetLum(SetSat(b,Sat(s)),Lum(b));
}

float3 ColorM(float3 b, float3 s){
	return SetLum(s,Lum(b));
}

float3 Luminosity(float3 b, float3 s){
	return SetLum(b,Lum(s));
}

//rotate vector spec
float2 rotate(float2 v,float2 o, float a){
	float2 v2= v-o;
	v2=float2((cos(a) * v2.x-sin(a)*v2.y),sin(a)*v2.x +cos(a)*v2.y);
	v2=v2+o;
	return v2;
}


void PS_StageDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{
	float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgba;
	float depth = 1 - ReShade::GetLinearizedDepth(texcoord).r;
	float2 uvtemp=float2(((texcoord.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT),texcoord.y);
	const float4 layer     = tex2D(Stage_sampler, (rotate(uvtemp,Layer_Pos+0.5,radians(Axis))*Layer_Scale-((Layer_Pos+0.5)*Layer_Scale-0.5))).rgba;
	float4 precolor   = lerp(backbuffer, layer, layer.a * Stage_Opacity);
	if( depth < Stage_depth )
	{
		switch (BlendM){
			case 0:{color = lerp(backbuffer.rgb, precolor.rgb, layer.a * Stage_Opacity);break;}
			case 1:{color = lerp(backbuffer, Multiply(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 2:{color = lerp(backbuffer, Screen(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 3:{color = lerp(backbuffer, Overlay(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 4:{color = lerp(backbuffer, Darken(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 5:{color = lerp(backbuffer, Lighten(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 6:{color = lerp(backbuffer, ColorDodge(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 7:{color = lerp(backbuffer, ColorBurn(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 8:{color = lerp(backbuffer, HardLight(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 9:{color = lerp(backbuffer, SoftLight(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 10:{color = lerp(backbuffer, Difference(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 11:{color = lerp(backbuffer, Exclusion(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 12:{color = lerp(backbuffer, Hue(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 13:{color = lerp(backbuffer, Saturation(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 14:{color = lerp(backbuffer, ColorM(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
			case 15:{color = lerp(backbuffer, Luminosity(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
		}
	}
	color.a = backbuffer.a;
}


technique StageDepthPlus
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_StageDepth;
	}
}
