//CanvasMasking by originalnicodr, based in the AdaptiveFog shader by otis and inspired by the BeforeAfterWithDepth shader from Jacob Maximilian Fober

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
	ui_label = "Gradient Type";
	ui_category = "Gradient controls";
	ui_items = "Linear \0Radial \0Strip \0";
> = false;

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


// First pass render target
texture BeforeTarget { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler BeforeSampler { Texture = BeforeTarget; };

  //////////////
 /// SHADER ///
//////////////

#include "ReShade.fxh"

void BeforePS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab screen texture
	Image = tex2D(ReShade::BackBuffer, UvCoord).rgb;
}

void AfterPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target){
    fragment.rgba = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
	float fogFactor = clamp(saturate(depth - FogStart) * FogCurve, 0.0, MaxFogFactor);

	if (FlipFog) {fogFactor = 1-clamp(saturate(depth - FogStart) * FogCurve, 0.0, 1-MaxFogFactor);}

    switch (GradientType){
		case 0: {
	        float2 origin = float2(0.5, 0.5);
	        float2 uvtest= float2(texcoord.x-origin.x,texcoord.y-origin.y);
	        float angulo=radians(Axis);
            uvtest = float2(cos(angulo) * uvtest.x-sin(angulo)*uvtest.y, sin(angulo)*uvtest.y +cos(angulo)*uvtest.x)+Offset;
	        float test= saturate(uvtest.x*pow(2,abs(Scale))+Offset);
	        if (Scale<0){
	        	test= saturate(uvtest.x*(-pow(2,abs(Scale)))+Offset);
	        }

	        fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*lerp(AlphaA, AlphaB, test));break;
        }
        case 1:{
			float distfromcenter=distance(float2(Originc.x*Modifierc.x, Originc.y*Modifierc.y), float2(((texcoord.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT)*Modifierc.x,texcoord.y*Modifierc.y));
			
			float angulo=radians(AnguloR);

			float2 uvtemp=float2(((texcoord.x*BUFFER_WIDTH-(BUFFER_WIDTH-BUFFER_HEIGHT)/2)/BUFFER_HEIGHT),texcoord.y);

			float dist2 = distance(Originc*Modifierc,rotate(uvtemp,Originc,angulo)*Modifierc);

			float testc=saturate((dist2-Size)*(pow(2,abs(Scale))));
			if (Scale<0){
				testc=saturate((dist2-Size)*(-pow(2,abs(Scale))));
			}
			fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*lerp(AlphaA, AlphaB, testc));break;
        }
        case 2:{
            float2 ubs = texcoord;
			ubs.y = 1.0 - ubs.y;
			float tests = saturate((DistToLine(PositionS, float2(PositionS.x-sin(radians(AnguloR)),PositionS.y-cos(radians(AnguloR))), ubs) * 2.0)*(pow(2,Scale+2))-SizeS);
			fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, fogFactor*lerp(AlphaA, AlphaB, tests));break;
        }
    }
}


  //////////////
 /// OUTPUT ///
//////////////

technique BeforeCanvasMask < ui_tooltip = "Place this technique before effects you want compare.\nThen move technique 'After'"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BeforePS;
		RenderTarget = BeforeTarget;
	}
}
technique AfterCanvasMask < ui_tooltip = "Place this technique after effects you want compare.\nThen move technique 'Before'"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AfterPS;
	}
}
