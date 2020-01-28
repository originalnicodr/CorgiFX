//SunsetFog shader by originalnicodr, a modified version of Adaptive fog by Otis, all credits goes to him

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

#include "Reshade.fxh"
#include "ReShadeUI.fxh"


uniform float4 ColorA < __UNIFORM_COLOR_FLOAT4
	ui_label = "Colour (A)";
    ui_type = "color";
	ui_category = "Gradient controls";
> = float4(1.0, 0.0, 0.0, 1.0);

uniform float4 ColorB < __UNIFORM_COLOR_FLOAT4
	ui_label = "Colour (B)";
	ui_type = "color";
	ui_category = "Gradient controls";
> = float4(0.0, 1.0, 0.0, 0.0);

uniform bool Flip <
	ui_label = "Color flip";
	ui_category = "Gradient controls";
> = false;

uniform int GradientType <
	ui_type = "combo";
	ui_label = "Gradient Type";
	ui_category = "Gradient controls";
	ui_items = "Linear \0Radial \0Strip \0";
> = false;

uniform int BlendM <
	ui_type = "combo";
	ui_label = "Blending Mode";
	ui_tooltip = "Select the blending mode used with the gradient on the screen.";
	ui_items = "Normal \0Multiply \0Screen \0Overlay \0Darken \0Lighten \0Color Dodge \0Color Burn \0Hard Light \0Soft Light \0Difference \0Exclusion \0Hue \0Saturation \0Color \0Luminosity";
	ui_category = "Gradient controls";
> = 0;

uniform float Scale < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Gradient sharpness";
	ui_min = -10.0; ui_max = 10.0; ui_step = 0.01;
	ui_category = "Gradient controls";
> = 1.0;




uniform float Axis < __UNIFORM_SLIDER_INT1
	ui_label = "Angle";
	#if __RESHADE__ < 40000
		ui_step = 0.1;
	#endif
	ui_min = -180.0; ui_max = 180.0;
	ui_category = "Linear gradient control";
> = 0.0;

uniform float Offset < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Position";
	#if __RESHADE__ < 40000
		ui_step = 0.002;
	#endif
	ui_min = -0.5; ui_max = 0.5;
	ui_category = "Linear gradient control";
> = 0.0;

uniform float Size < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Size";
	#if __RESHADE__ < 40000
		ui_step = 0.002;
	#endif
	ui_min = 0.0; ui_max = 1.0;
	ui_category = "Radial gradient control";
> = 0.0;

uniform float2 Originc <
	ui_category = "Radial gradient control";
	ui_label = "Position";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = -1.5; ui_max = 2;
> = float2(0.5, 0.5);

uniform float2 Modifierc <
	ui_category = "Radial gradient control";
	ui_label = "Modifier";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0.000; ui_max = 10.000;
> = float2(1.0, 1.0);

uniform float AnguloR <
	ui_category = "Radial gradient control";
	ui_label = "Angle";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0; ui_max = 360;
> = 0.0;



uniform float2 PositionS <
	ui_category = "Strip gradient control";
	ui_label = "Position";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0; ui_max = 1;
> = float2(0.5, 0.5);

uniform float AnguloS <
	ui_category = "Strip gradient control";
	ui_label = "Angle";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0; ui_max = 360;
> = 0.0;


uniform float SizeS <
	ui_category = "Strip gradient control";
	ui_label = "Size";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0; ui_max = 100;
> = 0.0;


uniform int FogType <
	ui_type = "combo";
	ui_label = "Fog type";
	ui_category = "Fog controls";
	ui_items = "Adaptive Fog \0Emphasize Fog \0";
> = false;

uniform bool FlipFog <
	ui_label = "Fog flip";
	ui_category = "Fog controls";
> = false;



uniform float MaxFogFactor <
	ui_type = "slider";
	ui_min = 0.000; ui_max=1.000;
	ui_tooltip = "The maximum fog factor. 1.0 makes distant objects completely fogged out, a lower factor will shimmer them through the fog.";
	ui_step = 0.001;
	ui_category = "AdaptiveFog controls";
> = 0.8;

uniform float FogCurve <
	ui_type = "slider";
	ui_min = 0.00; ui_max=175.00;
	ui_step = 0.01;
	ui_tooltip = "The curve how quickly distant objects get fogged. A low value will make the fog appear just slightly. A high value will make the fog kick in rather quickly. The max value in the rage makes it very hard in general to view any objects outside fog.";
	ui_category = "AdaptiveFog controls";
> = 1.5;

uniform float FogStart <
	ui_type = "slider";
	ui_min = 0.000; ui_max=1.000;
	ui_step = 0.001;
	ui_category = "AdaptiveFog controls";
	ui_tooltip = "Start of the fog. 0.0 is at the camera, 1.0 is at the horizon, 0.5 is halfway towards the horizon. Before this point no fog will appear.";
> = 0.050;



uniform float BloomThreshold <
	ui_type = "slider";
	ui_min = 0.00; ui_max=50.00;
	ui_step = 0.1;
	ui_tooltip = "Threshold for what is a bright light (that causes bloom) and what isn't.";
	ui_category = "AdaptiveFog-Bloom controls";
> = 10.25;

uniform float BloomPower <
	ui_type = "slider";
	ui_min = 0.000; ui_max=100.000;
	ui_step = 0.1;
	ui_tooltip = "Strength of the bloom";
	ui_category = "AdaptiveFog-Bloom controls";
> = 10.0;

uniform float BloomWidth <
	ui_type = "slider";
	ui_min = 0.0000; ui_max=1.0000;
	ui_tooltip = "Width of the bloom";
	ui_category = "AdaptiveFog-Bloom controls";
> = 0.2;


uniform float FocusDepth <
	ui_type = "slider";
	ui_min = 0.000; ui_max = 1.000;
	ui_step = 0.001;
	ui_tooltip = "Manual focus depth of the point which has the focus. Range from 0.0, which means camera is the focus plane, till 1.0 which means the horizon is focus plane.";
	ui_category = "EmphasizeFog controls";
> = 0.026;
uniform float FocusRangeDepth <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.000;
	ui_step = 0.001;
	ui_tooltip = "The depth of the range around the manual focus depth which should be emphasized. Outside this range, de-emphasizing takes place";
	ui_category = "EmphasizeFog controls";
> = 0.001;
uniform float FocusEdgeDepth <
	ui_type = "slider";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "The depth of the edge of the focus range. Range from 0.00, which means no depth, so at the edge of the focus range, the effect kicks in at full force,\ntill 1.00, which means the effect is smoothly applied over the range focusRangeEdge-horizon.";
	ui_category = "EmphasizeFog controls";
	ui_step = 0.001;
> = 0.050;
uniform bool Spherical <
	ui_tooltip = "Enables Emphasize in a sphere around the focus-point instead of a 2D plane";
	ui_category = "EmphasizeFog controls";
> = false;
uniform int Sphere_FieldOfView <
	ui_type = "slider";
	ui_min = 1; ui_max = 180;
	ui_tooltip = "Specifies the estimated Field of View you are currently playing with. Range from 1, which means 1 Degree, till 180 which means 180 Degree (half the scene).\nNormal games tend to use values between 60 and 90.";
	ui_category = "EmphasizeFog controls";
> = 75;
uniform float Sphere_FocusHorizontal <
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Specifies the location of the focuspoint on the horizontal axis. Range from 0, which means left screen border, till 1 which means right screen border.";
	ui_category = "EmphasizeFog controls";
> = 0.5;
uniform float Sphere_FocusVertical <
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Specifies the location of the focuspoint on the vertical axis. Range from 0, which means upper screen border, till 1 which means bottom screen border.";
	ui_category = "EmphasizeFog controls";
> = 0.5;
uniform float3 BlendColor <
	ui_type = "color";
	ui_tooltip = "Specifies the blend color to blend with the rest of the scene. in (Red, Green, Blue). Use dark colors to darken further away objects";
	ui_category = "EmphasizeFog controls";
> = float3(0.0, 0.0, 0.0);
uniform float BlendFactor <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Specifies the factor BlendColor is blended. Range from 0.0, which means no color blending, till 1.0 which means full blend of the BlendColor";
	ui_category = "EmphasizeFog controls";
> = 0.0;
uniform float EffectFactor <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Specifies the factor the blending is applied. Range from 0.0, which means the effect is off (normal image), till 1.0 which means the blended parts are\nfull blended";
	ui_category = "EmphasizeFog controls";
> = 0.9;


#ifndef M_PI
	#define M_PI 3.1415927
#endif


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
{ if (LayerB.r < 1 && LayerB.g < 1 && LayerB.b < 1){
	return min(1.0,LayerA/(1.0-LayerB));
	}
  else {//LayerB=1
	return 1.0;
  }
}

// Color Burn blending mode
float3 ColorBurn(float3 LayerA, float3 LayerB)
{ if (LayerB.r > 0 && LayerB.g > 0 && LayerB.b > 0){
	return 1.0-min(1.0,(1.0-LayerA)/LayerB);
	}
  else {//LayerB=0
	return 0;
  }
}

// Hard light blending mode
float3 HardLight(float3 LayerA, float3 LayerB)
{ if (LayerB.r <= 0.5 && LayerB.g <=0.5 && LayerB.b <= 0.5){
	return clamp(Multiply(LayerA,2*LayerB),0,1);
	}
  else {//LayerB>5
	return clamp(Multiply(LayerA,2*LayerB-1),0,1);
  }
}

float3 Aux(float3 x)
{
	if (x.r<=0.25 && x.g<=0.25 && x.b<=0.25) {
		return ((16.0*x-12.0)*x+4)*x;
	}
	else {
		return sqrt(x);
	}
}

// Soft light blending mode
float3 SoftLight(float3 LayerA, float3 LayerB)
{ if (LayerB.r <= 0.5 && LayerB.g <=0.5 && LayerB.b <= 0.5){
	return clamp(LayerA-(1.0-2*LayerB)*LayerA*(1-LayerA),0,1);
	}
  else {//LayerB>5
	return clamp(LayerA+(2*LayerB-1.0)*(Aux(LayerA)-LayerA),0,1);
  }
}


// Difference blending mode
float3 Difference(float3 LayerA, float3 LayerB)
{ return LayerA-LayerB; }

// Exclusion blending mode
float3 Exclusion(float3 LayerA, float3 LayerB)
{ return LayerA+LayerB-2*LayerA*LayerB; }

// Overlay blending mode
float3 OverlayM(float3 LayerA, float3 LayerB)
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


//Aux function for strip gradient
float DistToLine(float2 pt1, float2 pt2, float2 testPt)
{
  float2 lineDir = pt2 - pt1;
  float2 perpDir = float2(lineDir.y, -lineDir.x);
  float2 dirToPt1 = pt1 - testPt;
  return abs(dot(normalize(perpDir), dirToPt1));
}




//rotate vector spec
float2 rotate(float2 v,float2 o, float a){
	float2 v2= v-o;
	v2=float2((cos(a) * v2.x-sin(a)*v2.y),sin(a)*v2.x +cos(a)*v2.y);
	v2=v2+o;
	return v2;
}




//Auxiliar lagrange formulas

float lagrangeg(float x0, float x1, float x2){
	return((x0-x1)/(x0-x1))*((x0-x2)/(x0-x2));
}




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

float CalculateDepthDiffCoC(float2 texcoord : TEXCOORD)
{
	const float scenedepth = ReShade::GetLinearizedDepth(texcoord);
	const float scenefocus =  FocusDepth;
	const float desaturateFullRange = FocusRangeDepth+FocusEdgeDepth;
	float depthdiff;
	
	if(Spherical == true)
	{
		texcoord.x = (texcoord.x-Sphere_FocusHorizontal)*ReShade::ScreenSize.x;
		texcoord.y = (texcoord.y-Sphere_FocusVertical)*ReShade::ScreenSize.y;
		const float degreePerPixel = Sphere_FieldOfView / ReShade::ScreenSize.x;
		const float fovDifference = sqrt((texcoord.x*texcoord.x)+(texcoord.y*texcoord.y))*degreePerPixel;
		depthdiff = sqrt((scenedepth*scenedepth)+(scenefocus*scenefocus)-(2*scenedepth*scenefocus*cos(fovDifference*(2*M_PI/360))));
	}
	else
	{
		depthdiff = abs(scenedepth-scenefocus);
	}

	if (depthdiff > desaturateFullRange)
		return saturate(1.0);
	else
		return saturate(smoothstep(0, desaturateFullRange, depthdiff));
}

void PS_Otis_AFG_BlendFogWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
    // Grab screen texture
	fragment.rgba = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
	float fogFactor;
	switch(FogType){
		case 0:{
			fogFactor=clamp(saturate(depth - FogStart) * FogCurve, 0.0, MaxFogFactor);break;
		}
		case 1:{
			fogFactor= 1-CalculateDepthDiffCoC(texcoord.xy);break;
		}
	}

	if (FlipFog) {fogFactor = 1-clamp(saturate(depth - FogStart) * FogCurve, 0.0, 1-MaxFogFactor);}
	
	switch (GradientType){
		case 0: {

			float2 origin = float2(0.5, 0.5);
			float2 uvtest= float2(texcoord.x-origin.x,texcoord.y-origin.y);
			float angulo=radians(Axis);

    		float len = length(uvtest);
    		uvtest = float2(cos(angulo) * uvtest.x-sin(angulo)*uvtest.y, sin(angulo)*uvtest.y +cos(angulo)*uvtest.x)+Offset;
			float test= saturate(uvtest.x*pow(2,abs(Scale))+Offset);
			if (Scale<0){
				test= saturate(uvtest.x*(-pow(2,abs(Scale)))+Offset);
			}
			

			float3 prefragment=lerp(tex2D(ReShade::BackBuffer, texcoord), lerp(tex2D(Otis_BloomSampler, texcoord), lerp(ColorA.rgb, ColorB.rgb, Flip ? 1 - test : test), fogFactor), fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));
			switch (BlendM){
				case 0:{fragment=prefragment;break;}
				case 1:{fragment=lerp(fragment.rgb,Multiply(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 2:{fragment=lerp(fragment.rgb,Screen(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 3:{fragment=lerp(fragment.rgb,OverlayM(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 4:{fragment=lerp(fragment.rgb,Darken(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 5:{fragment=lerp(fragment.rgb,Lighten(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 6:{fragment=lerp(fragment.rgb,ColorDodge(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 7:{fragment=lerp(fragment.rgb,ColorBurn(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 8:{fragment=lerp(fragment.rgb,HardLight(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 9:{fragment=lerp(fragment.rgb,SoftLight(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 10:{fragment=lerp(fragment.rgb,Difference(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 11:{fragment=lerp(fragment.rgb,Exclusion(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 12:{fragment=lerp(fragment.rgb,Hue(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 13:{fragment=lerp(fragment.rgb,Saturation(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 14:{fragment=lerp(fragment.rgb,ColorM(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
				case 15:{fragment=lerp(fragment.rgb,Luminosity(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - test : test));break;}
			}
			break;
		}
		case 1: {
			float distfromcenter=distance(float2(Originc.x*Modifierc.x, Originc.y*Modifierc.y), float2(((texcoord.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT)*Modifierc.x,texcoord.y*Modifierc.y));
			
			float angulo=radians(AnguloR);

			float2 uvtemp=float2(((texcoord.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT),texcoord.y);

			float dist2 = distance(Originc*Modifierc,rotate(uvtemp,Originc,angulo)*Modifierc);

			float dist3 = distance(float2(Originc.x*Modifierc.x+lagrangeg(0.5,0,1)*(0.5*(1-Modifierc.x))+lagrangeg(0,0.5,1)*(-0.39)+lagrangeg(1,0,0.5)*(1.39*(1.3-Modifierc.x)),Originc.y*Modifierc.y),rotate(uvtemp,Originc,angulo)*Modifierc);


			float testc=saturate((dist2-Size)*(exp(abs(Scale))));
			if (Scale<0){
				testc=saturate((dist2-Size)*(-exp(abs(Scale))));
			}

			float4 rColor = lerp(ColorA,ColorB, testc);
			float3 prefragment=lerp(tex2D(ReShade::BackBuffer, texcoord), lerp(tex2D(Otis_BloomSampler, texcoord), lerp(ColorA.rgb, ColorB.rgb, Flip ? 1 - testc : testc), fogFactor), fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));
			switch (BlendM){
				case 0:{fragment=prefragment;break;}
				case 1:{fragment=lerp(fragment.rgb,Multiply(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 2:{fragment=lerp(fragment.rgb,Screen(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 3:{fragment=lerp(fragment.rgb,OverlayM(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 4:{fragment=lerp(fragment.rgb,Darken(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 5:{fragment=lerp(fragment.rgb,Lighten(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 6:{fragment=lerp(fragment.rgb,ColorDodge(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 7:{fragment=lerp(fragment.rgb,ColorBurn(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 8:{fragment=lerp(fragment.rgb,HardLight(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 9:{fragment=lerp(fragment.rgb,SoftLight(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 10:{fragment=lerp(fragment.rgb,Difference(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 11:{fragment=lerp(fragment.rgb,Exclusion(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 12:{fragment=lerp(fragment.rgb,Hue(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 13:{fragment=lerp(fragment.rgb,Saturation(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 14:{fragment=lerp(fragment.rgb,ColorM(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
				case 15:{fragment=lerp(fragment.rgb,Luminosity(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - testc : testc));break;}
			}

			break;
		}
		case 2: {
			float2 ubs = texcoord;
			ubs.y = 1.0 - ubs.y;
			float tests = saturate((DistToLine(PositionS, float2(PositionS.x-sin(radians(AnguloR)),PositionS.y-cos(radians(AnguloR))), ubs) * 2.0)*(pow(2,Scale+2))-SizeS);//el numero sumando al scale es para mejorar la interfaz
			//probar tests con distance
			float3 prefragment=lerp(tex2D(ReShade::BackBuffer, texcoord), lerp(tex2D(Otis_BloomSampler, texcoord), lerp(ColorA.rgb, ColorB.rgb, Flip ? 1 - tests : tests), fogFactor), fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));
			switch (BlendM){
				case 0:{fragment=prefragment;break;}
				case 1:{fragment=lerp(fragment.rgb,Multiply(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 2:{fragment=lerp(fragment.rgb,Screen(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 3:{fragment=lerp(fragment.rgb,OverlayM(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 4:{fragment=lerp(fragment.rgb,Darken(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 5:{fragment=lerp(fragment.rgb,Lighten(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 6:{fragment=lerp(fragment.rgb,ColorDodge(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 7:{fragment=lerp(fragment.rgb,ColorBurn(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 8:{fragment=lerp(fragment.rgb,HardLight(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 9:{fragment=lerp(fragment.rgb,SoftLight(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 10:{fragment=lerp(fragment.rgb,Difference(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 11:{fragment=lerp(fragment.rgb,Exclusion(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 12:{fragment=lerp(fragment.rgb,Hue(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 13:{fragment=lerp(fragment.rgb,Saturation(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 14:{fragment=lerp(fragment.rgb,ColorM(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
				case 15:{fragment=lerp(fragment.rgb,Luminosity(fragment.rgb,prefragment),fogFactor*lerp(ColorA.a, ColorB.a, Flip ? 1 - tests : tests));break;}
			}
			break;
		}
	}
}


technique CanvasFog
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