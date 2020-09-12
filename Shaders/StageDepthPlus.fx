//Shader edited originalnicodr

//If you want to have multiple instances of StageDepthPlus you will have to change the following lines in every copy of the shader:
//- Line 43: change "StageDepthPlus" to anything else (any namespace that you arent using in other shader).
//- Line 54: change the "Stageplus.png" name file for the name of the image you want to use in this instance
//- Line 425: change the name of the technique

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

namespace StageDepthPlus
{
	#include "Reshade.fxh"

	#if LAYER_SINGLECHANNEL
	    #define TEXFORMAT R8
	#else
	    #define TEXFORMAT RGBA8
	#endif

	#ifndef StageTexPlus
	#define StageTexPlus "Stageplus.png"//Put your image file name here or remplace the original image
	#endif

	  ////////////
	 /// MENU ///
	////////////

	uniform bool DepthMapY < 
		ui_label = "Use depth map";
	    ui_category = "Controls";
	> = true;

	uniform bool FlipH < 
		ui_label = "Flip Horizontal";
	    ui_category = "Controls";
	> = false;

	uniform bool FlipV < 
		ui_label = "Flip Vertical";
	    ui_category = "Controls";
	> = false;

	uniform float Stage_Opacity <
	    ui_type = "slider";
	    ui_label = "Opacity";
	    ui_min = 0.0; ui_max = 1.0;
	    ui_step = 0.002;
	    ui_tooltip = "Set the transparency of the image.";
	> = 1.0;

	uniform float2 Layer_Scale <
	  	ui_type = "slider";
		ui_label = "Scale";
		ui_step = 0.01;
		ui_min = 0.01; ui_max = 5.0;
	> = (1.001,1.001);

	uniform float2 Layer_Pos <
	  	ui_type = "slider";
		ui_label = "Position";
		ui_step = 0.001;
		ui_min = -1.5; ui_max = 1.5;
	> = (0,0);	

	uniform float Axis <
		ui_type = "slider";
		ui_label = "Angle";
		ui_step = 0.1;
		ui_min = -180.0; ui_max = 180.0;
	> = 0.0;

	uniform int BlendM <
		ui_type = "combo";
		ui_label = "Blending Mode";
		ui_tooltip = "Select the blending mode used with the gradient on the screen.";
		ui_items = "Normal\0Multiply\0Screen\0Overlay\0Darken\0Lighten\0Color Dodge\0Color Burn\0Hard Light\0Soft Light\0Difference\0Exclusion\0Hue\0Saturation\0Color\0Luminosity\0Linear burn\0Linear dodge\0Vivid light\0Linearlight\0Pin light\0Hardmix\0Reflect\0Glow";
		ui_category = "Gradient controls";
	> = 0;

	uniform float Stage_depth <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1.0;
		ui_label = "Depth";
	> = 0.97;

	//////////////////////////////////////
	// textures
	//////////////////////////////////////
	#if ((3*BUFFER_WIDTH <= 8192) && (3*BUFFER_WIDTH <= 8192))
	texture Stageplus_texture <source=StageTexPlus;> { Width = BUFFER_WIDTH*3; Height = BUFFER_HEIGHT*3; Format=TEXFORMAT; };
	#else
	#if ((2*BUFFER_WIDTH <= 8192) && (2*BUFFER_WIDTH <= 8192))
	texture Stageplus_texture <source=StageTexPlus;> { Width = BUFFER_WIDTH*2; Height = BUFFER_HEIGHT*2; Format=TEXFORMAT; };
	#else
	texture Stageplus_texture <source=StageTexPlus;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
	#endif
	#endif

	//////////////////////////////////////
	// samplers
	//////////////////////////////////////
	sampler Stageplus_sampler { Texture = Stageplus_texture; };

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

	//Blend functions priveded by prod80

	// Linearburn
	float3 Linearburn(float3 c, float3 b) 	{ return max(c+b-1.0f, 0.0f);}
	// Lineardodge
	float3 Lineardodge(float3 c, float3 b) 	{ return min(c+b, 1.0f);}
	// Vividlight
	float3 Vividlight(float3 c, float3 b) 	{ return b<0.5f ? ColorBurn(c, (2.0f*b)):ColorDodge(c, (2.0f*(b-0.5f)));}
	// Linearlight
	float3 Linearlight(float3 c, float3 b) 	{ return b<0.5f ? Linearburn(c, (2.0f*b)):Lineardodge(c, (2.0f*(b-0.5f)));}
	// Pinlight
	float3 Pinlight(float3 c, float3 b) 	{ return b<0.5f ? Darken(c, (2.0f*b)):Lighten(c, (2.0f*(b-0.5f)));}
	// Hard Mix
	float3 Hardmix(float3 c, float3 b)      { return Vividlight(c,b)<0.5f ? 0.0 : 1.0;}
	// Reflect
	float3 Reflect(float3 c, float3 b)      { return b>=0.999999f ? b:saturate(c*c/(1.0f-b));}
	// Glow
	float3 Glow(float3 c, float3 b)         { return Reflect(b, c);}

	//rotate vector spec
	float2 rotate(float2 v,float2 o, float a){
		float2 v2= v-o;
		v2=float2((cos(a) * v2.x-sin(a)*v2.y),sin(a)*v2.x +cos(a)*v2.y);
		v2=v2+o;
		return v2;
	}

	  //////////////
	 /// SHADER ///
	//////////////

	texture Test_Tex <
	    source = "depthmap.png";
	> {
	    Format = RGBA8;
	    Width  = BUFFER_WIDTH;
	    Height = BUFFER_HEIGHT;
	};

	sampler Test_Sampler
	{
	    Texture  = Test_Tex;
	    AddressU = BORDER;
	    AddressV = BORDER;
	};

	void PS_StageDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
	{
		float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgba;
		float depth = 1 - ReShade::GetLinearizedDepth(texcoord).r;
		float2 uvtemp=texcoord;
		if (FlipH) {uvtemp.x = 1-uvtemp.x;}//horizontal flip
	    if (FlipV) {uvtemp.y = 1-uvtemp.y;} //vertical flip

		float2 Layer_Scalereal= float2 (Layer_Scale.x-0.44,(Layer_Scale.y-0.44)*BUFFER_WIDTH/BUFFER_HEIGHT);
	    float2 Layer_Posreal= float2((FlipH) ? -Layer_Pos.x : Layer_Pos.x, (FlipV) ? Layer_Pos.y:-Layer_Pos.y);

		uvtemp= float2(((uvtemp.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT),uvtemp.y);
		uvtemp=(rotate(uvtemp,Layer_Posreal+0.5,radians(Axis))*Layer_Scalereal-((Layer_Posreal+0.5)*Layer_Scalereal-0.5));
		const float4 layer     = tex2D(Stageplus_sampler, uvtemp).rgba;
		float4 precolor   = lerp(backbuffer, layer, layer.a * Stage_Opacity);

		float ImageDepthMap_depth = DepthMapY ? tex2D(Test_Sampler,uvtemp).x : 0;

		if( depth < saturate(ImageDepthMap_depth+Stage_depth))
		{	
			if (uvtemp.x>0 && uvtemp.y>0  && uvtemp.x<1 && uvtemp.y<1){
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
					case 16:{color = lerp(backbuffer, Lineardodge(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
					case 17:{color = lerp(backbuffer, Linearburn(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
					case 18:{color = lerp(backbuffer, Vividlight(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
					case 19:{color = lerp(backbuffer, Linearlight(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
					case 20:{color = lerp(backbuffer, Pinlight(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
					case 21:{color = lerp(backbuffer, Hardmix(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
					case 22:{color = lerp(backbuffer, Reflect(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
					case 23:{color = lerp(backbuffer, Glow(backbuffer.rgb, precolor.rgb), layer.a * Stage_Opacity);break;}
				}
			}
		}
		color.a = backbuffer.a;
	}


	technique StageDepthPlus
		#if __RESHADE__ >= 40000
		< ui_tooltip = 
				"If you want to have the depth map affecting the image and the depth buffer make\n"
				"sure to change the RESHADE_MIX_STAGE_DEPTH_PLUS_MAP value to 1 in the\n"
				"Edit global proccesor definitions section and change the values\n"
				"from the Fake Depth buffer controls to match the ones in the shader.\n"; >
		#endif
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_StageDepth;
		}
	}
}