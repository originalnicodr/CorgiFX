//CanvasMasking by originalnicodr, based in the AdaptiveFog shader by otis wich also use his code from Emphasize.fx, and inspired by the BeforeAfterWithDepth shader from Jacob Maximilian Fober

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

  ////////////
 /// MENU ///
////////////

#include "ReShadeUI.fxh"

uniform float AlphaA < __UNIFORM_COLOR_FLOAT4
	ui_label = "Alpha gradient A";
	ui_category = "Gradient controls";
> = 1.0;

uniform float AlphaB < __UNIFORM_COLOR_FLOAT4
	ui_label = "Alpha gradient B";
	ui_category = "Gradient controls";
> = 0.0;

uniform bool Flip <
	ui_label = "Color flip";
	ui_category = "Gradient controls";
> = false;

uniform int GradientType <
	ui_type = "combo";
	ui_label = "Masking type";
	ui_category = "Gradient controls";
	ui_items = "Linear\0Radial\0Strip\0Color\0";
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

uniform float3 ColorMask < __UNIFORM_COLOR_FLOAT4
	ui_label = "Color mask";
    ui_type = "Color";
	ui_category = "Color masking controls";
> = float3(1.0, 0.0, 0.0);

uniform bool FlipColorMask <
	ui_label = "Color mask flip";
	ui_category = "Color masking controls";
> = false;

uniform float HueRange <
	ui_category = "Color masking controls";
	ui_label = "Hue Range";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0; ui_max = 360;
> = 0.0;

uniform float SaturationRange <
	ui_category = "Color masking controls";
	ui_label = "Saturation Range";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0; ui_max = 1;
> = 0.0;

uniform float BrigtnessRange <
	ui_category = "Color masking controls";
	ui_label = "Brightness Range";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0; ui_max = 1;
> = 0.0;

uniform bool Colorp<
	ui_label = "Color picker";
	ui_category = "Color masking controls";
	ui_tooltip = "Select a color from the screen to be used instead of ColorMask. Left-click to sample. \nIts recommended to assign a hotkey.";
> = false;

uniform int FogType <
	ui_type = "combo";
	ui_label = "Fog type";
	ui_category = "Fog controls";
	ui_items = "Adaptive Fog\0Emphasize Fog\0";
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
> = 1.0;

uniform float FogCurve <
	ui_type = "slider";
	ui_min = 0.00; ui_max=175.00;
	ui_step = 0.01;
	ui_tooltip = "The curve how quickly distant objects get fogged. A low value will make the fog appear just slightly. A high value will make the fog kick in rather quickly. The max value in the rage makes it very hard in general to view any objects outside fog.";
	ui_category = "AdaptiveFog controls";
> = 70.0;

uniform float FogStart <
	ui_type = "slider";
	ui_min = 0.000; ui_max=1.000;
	ui_step = 0.001;
	ui_category = "AdaptiveFog controls";
	ui_tooltip = "Start of the fog. 0.0 is at the camera, 1.0 is at the horizon, 0.5 is halfway towards the horizon. Before this point no fog will appear.";
> = 0.180;

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
> = 0.180;

uniform float FocusRangeDepth <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.000;
	ui_step = 0.001;
	ui_tooltip = "The depth of the range around the manual focus depth which should be emphasized. Outside this range, de-emphasizing takes place";
	ui_category = "EmphasizeFog controls";
> = 0.010;

uniform float FocusEdgeDepth <
	ui_type = "slider";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "The depth of the edge of the focus range. Range from 0.00, which means no depth, so at the edge of the focus range, the effect kicks in at full force,\ntill 1.00, which means the effect is smoothly applied over the range focusRangeEdge-horizon.";
	ui_category = "EmphasizeFog controls";
	ui_step = 0.001;
> = 0.070;

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

float fmod(float a, float b)
{
    return (a - b * floor(a / b));
}

float3 rgb2hsv(float3 color){
	float3 hsv;
	float M=max(color.r,max(color.g,color.b));
	float m=min(color.r,min(color.g,color.b));
	float c= M-m;
	float v=M;
	float h= (c==0) ? 0 :
			 (M==color.r) ? fmod(((color.g-color.b)/c),6)*60 :
			 (M==color.g) ? ((color.b-color.r)/c+2)*60 : ((color.r-color.g)/c+4)*60;
	float s=(M==0) ? 0 : (c/v)*100;
	return float3(h,s,v*100);
}

float3 rgb2hsv2(float3 color){
	float3 hsv;
	float M=max(color.r,max(color.g,color.b));
	float m=min(color.r,min(color.g,color.b));
	float c= M-m;
	float v=M;
	float h= (c==0) ? 0 :
			 (M==color.r) ? fmod(((color.g-color.b)/c),6)*60 :
			 (M==color.g) ? ((color.b-color.r)/c+2)*60 : ((color.r-color.g)/c+4)*60;
	float s=(M==0) ? 0 : (c/v);
	return float3(h,s,v);
}

float3 hsv2rgb(float3 color){
	float c=color.z*color.y;
	float m=color.z-c;
	float x=c*(1-abs(fmod(color.x/60,2)-1));
	float r;
	float g;
	float b;
	float3 rgb=(color.x>=0 && color.x<=60) ? float3(c+m,x+m,m) :
			   (color.x>=60 && color.x<=120) ? float3(x+m,c+m,m) :
			   (color.x>=120 && color.x<=180) ? float3(m,c+m,x+m) :
			   (color.x>=180 && color.x<=240) ? float3(x+m,m,c+m) :
			   (color.x>=240 && color.x<=300) ? float3(c+m,m,x+m) :
			   (color.x>=300 && color.x<=360) ? float3(c+m,m,x+m) : float3(m,m,m);
	return rgb;
}

float distancespe(float3 actualcolor,float3 desirecolor, float hm, float sm, float vm){//Both color must be in hsv
	float h= (actualcolor.x>=(desirecolor.x-hm) && actualcolor.x<=(desirecolor.x+hm)) ? 0 : min(distance(actualcolor.x/360,fmod(desirecolor.x-hm,360)/360),distance(actualcolor.x/360,fmod(desirecolor.x+hm,360)));
	float s= (actualcolor.y>=(desirecolor.y-sm) && actualcolor.y<=(desirecolor.y+sm)) ? 0 : min(distance(actualcolor.y,desirecolor.y-sm),distance(actualcolor.y,desirecolor.y+sm));
	float v= (actualcolor.z>=(desirecolor.z-vm) && actualcolor.z<=(desirecolor.z+vm)) ? 0 : min(distance(actualcolor.z,desirecolor.z-vm),distance(actualcolor.z,desirecolor.z+vm));
	return length(float3(h,s,v));
}

float distancespe2(float3 actualcolor,float3 desirecolor, float hm, float sm, float vm){//Both color must be in hsv
	float3 nactualcolor=actualcolor-desirecolor;//centro de mi cubo
	float d;
	if (fmod(nactualcolor.x,360)<=hm){
		if (abs(nactualcolor.y)<=sm){
			d=abs(nactualcolor.z)-vm;
		}
		else{
			if (abs(nactualcolor.z)<=vm){
				d=abs(nactualcolor.y)-sm;
			}
			else {
				d=sqrt(pow(abs(nactualcolor.y)-sm,2)+pow(abs(nactualcolor.z)-vm,2));
			}
		}
	}
	else{
		if (abs(nactualcolor.y)<=sm){
			if (abs(nactualcolor.z)<=vm){
				d=abs(nactualcolor.y)-sm;
			}
			else {
				d=sqrt(pow(fmod(nactualcolor.x,360)-hm,2)+pow(abs(nactualcolor.z)-vm,2));
			}
		}
		else{
			if (abs(nactualcolor.z)<=vm){
				d=sqrt(pow(fmod(nactualcolor.x,360)-hm,2)+pow(abs(nactualcolor.y)-sm,2));
			}
			else {
				d=sqrt(pow(fmod(nactualcolor.x,360)-hm,2)+pow(abs(nactualcolor.y)-sm,2)+pow(abs(nactualcolor.z)-vm,2));
			}
		}
	}
	return d;
}

float distancespe3(float3 actualcolor,float3 desirecolor, float hm, float sm, float vm){//Both color must be in hsv
	float3 nactualcolor=actualcolor-desirecolor;//centro de mi cubo
	float d=sqrt(pow(max(0,(fmod(nactualcolor.x,360)-hm)/360),2)+pow(max(0,(abs(nactualcolor.y))-sm),2)+pow(max(0,(abs(nactualcolor.z))-vm),2));
	return d;
}

float distancespe4(float3 actualcolor,float3 desirecolor, float hm, float sm, float vm){//Both color must be in hsv, es distance 3 con rgb2hsv2
	float3 nactualcolor=actualcolor-desirecolor;//centro de mi cubo
	float d=sqrt(pow(max(0,(fmod(nactualcolor.x,1)-hm)),2)+pow(max(0,(abs(nactualcolor.y))-sm),2)+pow(max(0,(abs(nactualcolor.z))-vm),2));
	return d;
}

float distancespe5(float3 actualcolor,float3 desirecolor, float fuzziness){
	float rDelta = actualcolor.r - desirecolor.r;
	float gDelta = actualcolor.g - desirecolor.g;
	float bDelta = actualcolor.b - desirecolor.b;
	float maxDistance = fuzziness * 441; // max distance, black -> white
	float distance = sqrt(rDelta * rDelta + gDelta * gDelta + bDelta * bDelta);
	return (distance < maxDistance) ? 1 : 0;
}


//////////////////////////////////////
// textures
//////////////////////////////////////
texture   Otis_BloomTarget 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};
texture Texture1		{ Width = 1; Height = 1;};		// for storing the new color value
texture Texture2		{ Width = 1; Height = 1;};		// for storing the old color value
texture BeforeTarget { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };

//////////////////////////////////////
// samplers
//////////////////////////////////////
sampler2D Otis_BloomSampler { Texture = Otis_BloomTarget; };
sampler Colorsavernew		{ Texture = Texture1; };
sampler Colorsaverold		{ Texture = Texture2; };
sampler BeforeSampler { Texture = BeforeTarget; };

  //////////////
 /// SHADER ///
//////////////

//Mouse inputs to select color

uniform float2 MouseCoords < source = "mousepoint"; >;
uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = false; >;

#include "ReShade.fxh"

//Emphasize algorithm from Otis
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

void BeforePS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab screen texture
	Image = tex2D(ReShade::BackBuffer, UvCoord).rgb;
}

void AfterPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target){
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
            uvtest = float2(cos(angulo) * uvtest.x-sin(angulo)*uvtest.y, sin(angulo)*uvtest.y +cos(angulo)*uvtest.x)+Offset;
	        float gradient= (Scale<0) ? saturate(uvtest.x*(-pow(2,abs(Scale)))+Offset): saturate(uvtest.x*pow(2,abs(Scale))+Offset);
	        fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*lerp(AlphaA, AlphaB, gradient));break;
        }
        case 1:{
			float distfromcenter=distance(float2(Originc.x*Modifierc.x, Originc.y*Modifierc.y), float2(((texcoord.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT)*Modifierc.x,texcoord.y*Modifierc.y));
			float angulo=radians(AnguloR);
			float2 uvtemp=float2(((texcoord.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT),texcoord.y);
			float dist2 = distance(Originc*Modifierc,rotate(uvtemp,Originc,angulo)*Modifierc);
			float gradient=(Scale<0) ? saturate((dist2-Size)*(-pow(2,abs(Scale)))) : saturate((dist2-Size)*(pow(2,abs(Scale))));
			fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*lerp(AlphaA, AlphaB, gradient));break;
        }
        case 2:{
            float2 ubs = texcoord;
			ubs.y = 1.0 - ubs.y;
			float tests = saturate((DistToLine(PositionS, float2(PositionS.x-sin(radians(AnguloS)),PositionS.y-cos(radians(AnguloS))), ubs) * 2.0)*(pow(2,Scale+2))-SizeS);
			fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*lerp(AlphaA, AlphaB, tests));break;
        }
		case 3:{
			//float test=(tex2D(BeforeSampler, texcoord).rgb==float3(1,0,0)) ? 1 : 0;
			//test= FlipColorMask ? 1-test : 0;


			//Funca
			/*float dist=FlipColorMask ? 1-saturate(distance(ColorMask.rgb,tex2D(BeforeSampler, texcoord).rgb)) : saturate(distance(tex2D(BeforeSampler, texcoord).rgb,ColorMask.rgb));
			fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*dist);*/

			float3 Colorreal= (Colorp) ? tex2D(Colorsavernew, float2(0,0)).rgb : ColorMask;

			//Funca todo menos los controles de hue, saturacion y brillo
			/*float3 desire=rgb2hsv(Colorreal);
			float3 actual=rgb2hsv(tex2D(BeforeSampler, texcoord).rgb);
			//float dist=distancespe3(Colorreal,tex2D(BeforeSampler, texcoord).rgb,HueRange,SaturationRange,BrigtnessRange);
			float dist=distancespe3(actual,desire,HueRange,SaturationRange,BrigtnessRange);
			dist=FlipColorMask ? saturate(dist) : 1-saturate(dist);
			fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*dist);*/


			float3 desire=rgb2hsv(Colorreal);
			float3 actual=rgb2hsv(tex2D(BeforeSampler, texcoord).rgb);
			//float dist=distancespe3(Colorreal,tex2D(BeforeSampler, texcoord).rgb,HueRange,SaturationRange,BrigtnessRange);
			float dist=distancespe3(actual,desire,HueRange,SaturationRange,BrigtnessRange);
			dist=FlipColorMask ? saturate(dist) : 1-saturate(dist);
			fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*dist);

			break;
		}
    }
}

void Colorgrab(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab the color selected 
	Image = (LeftMouseDown) ? tex2D(ReShade::BackBuffer, MouseCoords*ReShade::PixelSize).rgb : tex2D(Colorsaverold, float2(0,0)).rgb;
}

void Colorcopy(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab the color selected 
	Image = tex2D(Colorsavernew, float2(0,0)).rgb;
}

  //////////////
 /// OUTPUT ///
//////////////

technique BeforeCanvasMask < ui_tooltip = "Place this technique before effects you want compare.\nThen move technique 'After'"; >
{
	pass Before
	{
		VertexShader = PostProcessVS;
		PixelShader = BeforePS;
		RenderTarget = BeforeTarget;
	}
	pass Colorpickercopy{
		VertexShader = PostProcessVS;
		PixelShader = Colorcopy;
		RenderTarget = Texture2;
	}
	pass Colorpicker{
		VertexShader = PostProcessVS;
		PixelShader = Colorgrab;
		RenderTarget = Texture1;
	}
}
technique AfterCanvasMask < ui_tooltip = "Place this technique after effects you want compare.\nThen move technique 'Before'"; >
{
	pass After
	{
		VertexShader = PostProcessVS;
		PixelShader = AfterPS;
	}
}
