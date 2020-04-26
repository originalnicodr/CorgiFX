//Made by originalnicdor. Heavely based in the ColorIsolation shader from Daodan317081, all kudos to him.
//Color convertion functions from xIddqDx, props to him.


	  ////////////
	 /// MENU ///
	////////////

//If you want to use multiple instances of the shader you have to rename the namespace and the name of the technique
namespace ColorMask
{
#include "ReShadeUI.fxh"

/*uniform bool Colorp<
	ui_label = "Color picker";
	ui_category = "Color masking controls";
	ui_tooltip = "Select a color from the screen to be used instead of ColorMask. Left-click to sample. \nIts recommended to assign a hotkey.";
> = false;*/



#define COLORISOLATION_CATEGORY_SETUP "Setup"
#define COLORISOLATION_CATEGORY_DEBUG "Debug"

uniform bool axisColorSelectON <
	ui_category = COLORISOLATION_CATEGORY_SETUP;
	ui_label = "Use mouse-driven auto-focus";
> = false;

uniform bool drawColorSelectON <
	ui_category = COLORISOLATION_CATEGORY_SETUP;
	ui_label = "Draw some lines showing the color dropper position";
> = false;

uniform float2 axisColorSelectAxis <
	ui_category = COLORISOLATION_CATEGORY_SETUP;
	ui_label = "Take hue from pixel";
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
sampler Colorsavernew		{ Texture = Texture1; };
sampler Colorsaverold		{ Texture = Texture2; };


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

float fmod(float a, float b)
{
    return (a - b * floor(a / b));
}

float distancespe(float3 actualcolor,float3 desirecolor, float hm, float sm, float vm){//Both color must be in hsv
	//float h= (actualcolor.x>=(desirecolor.x-hm) && actualcolor.x<=(desirecolor.x+hm)) ? 0 : min(distance(actualcolor.x,fmod(desirecolor.x-hm,1)),distance(actualcolor.x,fmod(desirecolor.x+hm,1)));
    float h= (actualcolor.x>=(desirecolor.x-hm) && actualcolor.x<=(desirecolor.x+hm)) ? 0 : min(distance(actualcolor.x,desirecolor.x-hm),distance(actualcolor.x,desirecolor.x+hm));
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

float distancespe6(float3 actualcolor,float3 desirecolor, float sm, float vm){//Both color must be in hsv, es distance 3 con rgb2hsv2
	float3 nactualcolor=actualcolor-desirecolor;//centro de mi cubo
	float d=sqrt(pow(max(0,(abs(nactualcolor.y))-sm),2)+pow(max(0,(abs(nactualcolor.z))-vm),2));
	return d;
}


float GradientHueToRGB(float f1, float f2, float hue)
{
	if (hue < 0.0)
		hue += 1.0; 
	else if (hue > 1.0)
		hue -= 1.0; 
	float res; 
	if ((6.0 * hue) < 1.0)
		res = f1 + (f2 - f1) * 6.0 * hue; 
	else if ((2.0 * hue) < 1.0)
		res = f2; 
	else if ((3.0 * hue) < 2.0)
		res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0; 
	else
		res = f1; 
	return res; 
}

float3 rgb2hsl(float3 color)
{
	float3 hsl;  // init to 0 to avoid warnings ? (and reverse if + remove first part)
	
	float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
	float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
	float delta = fmax - fmin;              //Delta RGB value

	hsl.z = (fmax + fmin) / 2.0;  // Luminance

	if (delta == 0.0)		//This is a gray, no chroma...
	{
		hsl.x = 0.0; 	// Hue
		hsl.y = 0.0; 	// Saturation
	}
	else                                    //Chromatic data...
	{
		if (hsl.z < 0.5)
			hsl.y = delta / (fmax + fmin); // Saturation
		else
			hsl.y = delta / (2.0 - fmax - fmin); // Saturation
		
		float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta; 
		float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta; 
		float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta; 

		if (color.r == fmax )
			hsl.x = deltaB - deltaG;  // Hue
		else if (color.g == fmax)
			hsl.x = (1.0 / 3.0) + deltaR - deltaB;  // Hue
		else if (color.b == fmax)
			hsl.x = (2.0 / 3.0) + deltaG - deltaR;  // Hue

		if (hsl.x < 0.0)
			hsl.x += 1.0;  // Hue
		else if (hsl.x > 1.0)
			hsl.x -= 1.0;  // Hue
	}

	return hsl; 
}

float3 rgb2hcv(in float3 RGB)
{
	RGB = saturate(RGB);
	float Epsilon = 1e-10;
    	// Based on work by Sam Hocevar and Emil Persson
	float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
	float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
	float C = Q.x - min(Q.w, Q.y);
	float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
	return float3(H, C, Q.x);
}

float3 hsl2rgb(float3 hsl)
{
	float3 rgb; 
	
	if (hsl.y == 0.0)
		rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance
	else
	{
		float f2; 
		
		if (hsl.z < 0.5)
			f2 = hsl.z * (1.0 + hsl.y);
		else
			f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
			
		float f1 = 2.0 * hsl.z - f2; 
		
		rgb.r = GradientHueToRGB(f1, f2, hsl.x + (1.0/3.0));
		rgb.g = GradientHueToRGB(f1, f2, hsl.x);
		rgb.b= GradientHueToRGB(f1, f2, hsl.x - (1.0/3.0));
	}
	
	return rgb; 
}

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


//Mouse inputs to select color

uniform float2 MouseCoords < source = "mousepoint"; >;
uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = false; >;

void BeforePS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab screen texture
	Image = tex2D(ReShade::BackBuffer, UvCoord).rgb;
}

void AfterPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float3 fragment : SV_Target)
{
    /*float3 desire=rgb2hcv((Colorp) ? tex2D(Colorsavernew, float2(0,0)).rgb : ColorMask);
	float3 actual=rgb2hcv(tex2D(BeforeSampler, texcoord).rgb);
	float dist=distancespe4(actual,desire,HueRange,SaturationRange,BrigtnessRange);
    //dist=distance(colors,ColorMask);
	dist=FlipColorMask ? saturate(dist) : 1-saturate(dist);
	fragment=lerp(tex2D(BeforeSampler, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb, dist);*/



	float3 actual=tex2D(BeforeSampler, texcoord).rgb;
    const float3 luma = dot(actual, float3(0.2126, 0.7151, 0.0721)).rrr;

	float3 param;

	if (axisColorSelectON) {
		float3 coloraxis = tex2D(BeforeSampler, axisColorSelectAxis).rgb;
		//float3 coloraxis = tex2D(BeforeSampler, MouseCoords*ReShade::PixelSize).rgb;
		coloraxis=RGBToHCV(coloraxis);
		param = float3(coloraxis.x, fUIOverlapTwo, fUIWindowHeightTwo);
	}
	else{
		param = float3(fUITargetHueTwo / 360.0, fUIOverlapTwo, fUIWindowHeightTwo);
	}
    
    float value = CalculateValueTwo(RGBtoHSVTwo(actual).x, param.z, param.x, 1.0 - param.y);
	//float value2=distancespe4(RGBtoHSVTwo(actual), RGBtoHSVTwo(float3(255,0,0)),0,SaturationRange,BrigtnessRange);
	//value2=FlipColorMask ? value2 : 1-value2;

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

technique BeforeColorMask < ui_tooltip = "Place this technique before effects you want compare.\nThen move technique 'After'"; >
{
	pass
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
technique AfterColorMask < ui_tooltip = "Place this technique after effects you want compare.\nThen move technique 'Before'"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AfterPS;
	}
}

}