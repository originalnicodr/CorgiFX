//Made by originalnicdor. Heavely based in the ColorIsolation shader from Daodan317081, all kudos to him.
//Color convertion functions from xIddqDx, props to him.


	  ////////////
	 /// MENU ///
	////////////

//If you want to use multiple instances of the shader you have to rename the namespace and the name of the technique
namespace ColorMask
{
#include "ReShadeUI.fxh"

#define COLORISOLATION_CATEGORY_SETUP "Setup"
#define COLORISOLATION_CATEGORY_DEBUG "Debug"

uniform bool axisColorSelectON <
	ui_category = COLORISOLATION_CATEGORY_SETUP;
	ui_label = "Use the color eyedropper instead of HUE selection";
> = false;

uniform bool drawColorSelectON <
	ui_category = COLORISOLATION_CATEGORY_SETUP;
	ui_label = "Draw some lines showing the color eyedropper position";
> = false;

uniform float2 axisColorSelectAxis <
	ui_category = COLORISOLATION_CATEGORY_SETUP;
	ui_label = "Color eyedropper position";
	ui_type = "drag";
	ui_step = 0.001;
	ui_min = 0.000; ui_max = 1.000;
> = float2(0.5, 0.5);

uniform float fUITargetHueTwo <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Target Hue";
    ui_tooltip = "Set the desired color.\nEnable \"Show Debug Overlay\" for visualization.";
    ui_min = 0.0; ui_max = 360.0; ui_step = 0.5;
> = 0.0;

uniform int cUIWindowFunctionTwo <
    ui_type = "combo";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Window Function";
    ui_items = "Gauss\0Triangle\0";
> = 0;

uniform float fUIOverlapTwo <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Hue Overlap";
    ui_tooltip = "The likeness of the 'objective color'";
    ui_min = 0.001; ui_max = 2.0;
    ui_step = 0.001;
> = 0.3;

uniform float fUIWindowHeightTwo <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Curve Steepness";
	ui_tooltip = "The brightness of the colors accepted by the mask";
    ui_min = 0.0; ui_max = 10.0;
    ui_step = 0.01;
> = 1.0;

uniform int iUITypeTwo <
    ui_type = "combo";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Isolate / Reject Hue";
    ui_items = "Isolate\0Reject\0";
> = 0;

uniform float maskStrength <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Mask Strngth";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform bool bUIShowDiffTwo <
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "Show Hue Difference";
> = false;

uniform bool bUIShowDebugOverlayTwo <
    ui_label = "Show Debug Overlay";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
> = false;

uniform float2 fUIOverlayPosTwo <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "Overlay: Position";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = float2(0.0, 0.0);

uniform int2 iUIOverlaySizeTwo <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "Overlay: Size";
    ui_tooltip = "x: width\nz: height";
    ui_min = 50; ui_max = BUFFER_WIDTH;
    ui_step = 1;
> = int2(600, 100);

uniform float fUIOverlayOpacityTwo <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "Overlay Opacity";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

// First pass render target
texture BeforeTarget { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
texture Texture1		{ Width = 1; Height = 1;};		// for storing the new color value
texture Texture2		{ Width = 1; Height = 1;};		// for storing the old color value
sampler BeforeSampler { Texture = BeforeTarget; };


	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

// Overlay blending mode
float Overlay(float LayerAB)
{
	float MinAB = min(LayerAB, 0.5);
	float MaxAB = max(LayerAB, 0.5);
	return 2.0 * (MinAB * MinAB + MaxAB + MaxAB - MaxAB * MaxAB) - 1.5;
}


	  //////////////
	 /// SHADER ///
	//////////////

#include "ReShade.fxh"

//Original function made by prod80
float3 RGBToHCV( in float3 RGB )
{
    // Based on work by Sam Hocevar and Emil Persson
    float4 P         = ( RGB.g < RGB.b ) ? float4( RGB.bg, -1.0f, 2.0f/3.0f ) : float4( RGB.gb, 0.0f, -1.0f/3.0f );
    float4 Q1        = ( RGB.r < P.x ) ? float4( P.xyw, RGB.r ) : float4( RGB.r, P.yzx );
    float C          = Q1.x - min( Q1.w, Q1.y );
    float H          = abs(( Q1.w - Q1.y ) / ( 6.0f * C + 0.000001f ) + Q1.z );
    return float3( H, C, Q1.x );
}

//These RGB/HSV conversion functions are based on the blogpost from:
//http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
float3 RGBtoHSVTwo(float3 c) {
    const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

	float4 p;
	if (c.g < c.b)
		p = float4(c.bg, K.wz);
	else
		p = float4(c.gb, K.xy);

	float4 q;
	if (c.r < p.x)
		q = float4(p.xyw, c.r);
	else
		q = float4(c.r, p.yzx);

    const float d = q.x - min(q.w, q.y);
    const float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVtoRGBTwo(float3 c) {
    const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    const float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float MapTwo(float value, float2 span_old, float2 span_new) {
	float span_old_diff;
    if (abs(span_old.y - span_old.x) < 1e-6)
		span_old_diff = 1e-6;
	else
		span_old_diff = span_old.y - span_old.x;
    return lerp(span_new.x, span_new.y, (clamp(value, span_old.x, span_old.y)-span_old.x)/(span_old_diff));
}

#define GAUSS(x,height,offset,overlap) (height * exp(-((x - offset) * (x - offset)) / (2 * overlap * overlap)))
#define TRIANGLE(x,height,offset,overlap) saturate(height * ((2 / overlap) * ((overlap / 2) - abs(x - offset))))

float CalculateValueTwo(float x, float height, float offset, float overlap) {
    float retVal;
    //Add three curves together, two of them are moved by 1.0 to the left and to the right respectively
    //in order to account for the borders at 0.0 and 1.0
    if(cUIWindowFunctionTwo == 0) {
        //Scale overlap so the gaussian has roughly the same span as the triangle
        overlap /= 5.0;
        retVal = saturate(GAUSS(x-1.0, height, offset, overlap) + GAUSS(x, height, offset, overlap) + GAUSS(x+1.0, height, offset, overlap));
    }
    else {
        retVal = saturate(TRIANGLE(x-1.0, height, offset, overlap) + TRIANGLE(x, height, offset, overlap) + TRIANGLE(x+1.0, height, offset, overlap));
    }
    
    if(iUITypeTwo == 1)
        return 1.0 - retVal;
    
    return retVal;
}

float3 DrawDebugOverlayTwo(float3 background, float3 param, float2 pos, int2 size, float opacity, int2 vpos, float2 texcoord) {
    float x, y, value, luma;
    float3 overlay, hsvStrip;

	const float2 overlayPos = pos * (ReShade::ScreenSize - size);

    if(all(vpos.xy >= overlayPos) && all(vpos.xy < overlayPos + size))
    {
        x = MapTwo(texcoord.x, float2(overlayPos.x, overlayPos.x + size.x) / BUFFER_WIDTH, float2(0.0, 1.0));
        y = MapTwo(texcoord.y, float2(overlayPos.y, overlayPos.y + size.y) / BUFFER_HEIGHT, float2(0.0, 1.0));
        hsvStrip = HSVtoRGBTwo(float3(x, 1.0, 1.0));
        luma = dot(hsvStrip, float3(0.2126, 0.7151, 0.0721));
        value = CalculateValueTwo(x, param.z, param.x, 1.0 - param.y);
        overlay = lerp(luma.rrr, hsvStrip, value);
        overlay = lerp(overlay, 0.0.rrr, exp(-size.y * length(float2(x, 1.0 - y) - float2(x, value))));
        background = lerp(background, overlay, opacity);
    }

    return background;
}

void BeforePS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab screen texture
	Image = tex2D(ReShade::BackBuffer, UvCoord).rgb;
}

void AfterPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float3 fragment : SV_Target)
{
	float3 actual=tex2D(BeforeSampler, texcoord).rgb;
    const float3 luma = dot(actual, float3(0.2126, 0.7151, 0.0721)).rrr;

	float3 param;

	if (axisColorSelectON) {
		float3 coloraxis = tex2D(BeforeSampler, axisColorSelectAxis).rgb;
		coloraxis=RGBToHCV(coloraxis);
		param = float3(coloraxis.x, fUIOverlapTwo, fUIWindowHeightTwo);
	}
	else{
		param = float3(fUITargetHueTwo / 360.0, fUIOverlapTwo, fUIWindowHeightTwo);
	}
    
    float value = CalculateValueTwo(RGBtoHSVTwo(actual).x, param.z, param.x, 1.0 - param.y);

	fragment=lerp(actual,tex2D(ReShade::BackBuffer, texcoord).rgb, maskStrength*value);

    if(bUIShowDiffTwo)
        fragment = value.rrr;
    
    if(bUIShowDebugOverlayTwo)
    {
        fragment = DrawDebugOverlayTwo(fragment, param, fUIOverlayPosTwo, iUIOverlaySizeTwo, fUIOverlayOpacityTwo, vpos.xy, texcoord);
    }

	if(axisColorSelectON && drawColorSelectON){
		fragment=lerp(fragment,float4(1.0, 0.0, 0.0, 1.0),(abs(texcoord.x - axisColorSelectAxis.x)<0.0005 || abs(texcoord.y - axisColorSelectAxis.y)<0.001 ) ? 1 : 0);
	}

}

	  //////////////
	 /// OUTPUT ///
	//////////////

technique BeforeColorMask < ui_tooltip = "Place this technique before effects you want compare.\nThen move technique 'After'"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BeforePS;
		RenderTarget = BeforeTarget;
	}
}
technique AfterColorMask < ui_tooltip = "Place this technique after effects you want compare.\nThen move technique 'Before'"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AfterPS;
	}
}

}