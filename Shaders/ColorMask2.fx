//Made by originalnicdor. Based in PD80_04_Color_Isolation.fx from prod80, props to him.
//Another take in the ColorMask shader, take in mind none of the are finished and they are work in progress


/*
    Description : PD80 04 Color Isolation for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80


    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    
*/


	  ////////////
	 /// MENU ///
	////////////

#include "ReShadeUI.fxh"
#include "ReShade.fxh"

/*uniform bool Colorp<
	ui_label = "Color picker";
	ui_category = "Color masking controls";
	ui_tooltip = "Select a color from the screen to be used instead of ColorMask. Left-click to sample. \nIts recommended to assign a hotkey.";
> = false;*/



uniform float hueMid <
    ui_label = "Hue Selection (Middle)";
    ui_category = "Color Mask";
    ui_tooltip = "0 = Red, 0.167 = Yellow, 0.333 = Green, 0.5 = Cyan, 0.666 = Blue, 0.833 = Magenta";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.0;
uniform float hueRange <
    ui_label = "Hue Range Selection";
    ui_category = "Color Mask";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.167;

uniform float satMid <
    ui_label = "Saturation Selection (Middle)";
    ui_category = "Color Mask";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.0;
uniform float satRange <
    ui_label = "Saturation Range Selection";
    ui_category = "Color Mask";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.167;

uniform float lumMid <
    ui_label = "Lighting Selection (Middle)";
    ui_category = "Color Mask";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.0;
uniform float lumRange <
    ui_label = "Lighting Range Selection";
    ui_category = "Color Mask";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.167;

uniform float fxcolorMix <
    ui_label = "Strength of the mask";
    ui_category = "Color Mask";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 1.0;

uniform bool InvertHUE <
    ui_category = "Color Mask";
    ui_label = "Invert the Hue selection";
> = false;
uniform bool InvertSAT <
    ui_category = "Color Mask";
    ui_label = "Invert the Saturation selection";
> = false;
uniform bool InvertLUM <
    ui_category = "Color Mask";
    ui_label = "Invert the Lighting selection";
> = false;

// First pass render target
texture BeforeTarget { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
texture Texture1		{ Width = 1; Height = 1;};		// for storing the new color value
texture Texture2		{ Width = 1; Height = 1;};		// for storing the old color value
sampler BeforeSampler { Texture = BeforeTarget; };
sampler Colorsavernew		{ Texture = Texture1; };
sampler Colorsaverold		{ Texture = Texture2; };



//// TEXTURES ///////////////////////////////////////////////////////////////////
texture texColorBuffer : COLOR;
//// SAMPLERS ///////////////////////////////////////////////////////////////////
sampler samplerColor { Texture = texColorBuffer; };
//// DEFINES ////////////////////////////////////////////////////////////////////
#define LumCoeff float3(0.212656, 0.715158, 0.072186)
//// FUNCTIONS //////////////////////////////////////////////////////////////////
float getLuminance( in float3 x )
{
    return dot( x, LumCoeff );
}
float3 HUEToRGB( in float H )
{
    float R          = abs(H * 6.0f - 3.0f) - 1.0f;
    float G          = 2.0f - abs(H * 6.0f - 2.0f);
    float B          = 2.0f - abs(H * 6.0f - 4.0f);
    return saturate( float3( R,G,B ));
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
float3 RGBToHSL( in float3 RGB )
{
    RGB.xyz          = max( RGB.xyz, 0.000001f );
    float3 HCV       = RGBToHCV(RGB);
    float L          = HCV.z - HCV.y * 0.5f;
    float S          = HCV.y / ( 1.0f - abs( L * 2.0f - 1.0f ) + 0.000001f);
    return float3( HCV.x, S, L );
}
float3 HSLToRGB( in float3 HSL )
{
    float3 RGB       = HUEToRGB(HSL.x);
    float C          = ( 1.0f - abs( 2.0f * HSL.z - 1.0f )) * HSL.y;
    return ( RGB - 0.5f ) * C + HSL.z;
}
float smootherstep( float x )
{
    return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
}
float fmod(float a, float b)
{
    return (a - b * floor(a / b));
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

	float4 color     = tex2D( samplerColor, texcoord );
	//color=tex2D(ReShade::BackBuffer, texcoord).rgb;
    color.xyz        = saturate( color.xyz ); //Can't work with HDR
	float3 hsl=RGBToHSL( actual.xyz );
    float hue        = fmod(hsl.x-0.5,1);//shifting the HUE so the mask affects the desired color
	float sat= hsl.y;
	float lum= hsl.z;

    float r          = rcp( hueRange );
    float3 w         = max( 1.0f - abs(( hue - hueMid        ) * r ), 0.0f );
    w.y              = max( 1.0f - abs(( hue + 1.0f - hueMid ) * r ), 0.0f );
    w.z              = max( 1.0f - abs(( hue - 1.0f - hueMid ) * r ), 0.0f );
    float weight1     = dot( w.xyz, 1.0f );
	weight1= InvertHUE ? 1-smootherstep(weight1 ) : smootherstep(weight1 );

	r          = rcp( satRange );
    w.x         = max( 1.0f - abs(( sat - satMid        ) * r ), 0.0f );
    w.y              = max( 1.0f - abs(( sat + 1.0f - satMid ) * r ), 0.0f );
    w.z              = max( 1.0f - abs(( sat + 1.0f - satMid ) * r ), 0.0f );
    float weight2     = dot( w.xyz, 1.0f );
	weight2= InvertSAT ? 1-smootherstep( weight2 ) : smootherstep( weight2 );

	r          = rcp( lumRange );
    w.x         = max( 1.0f - abs(( lum - lumMid        ) * r ), 0.0f );
    w.y              = max( 1.0f - abs(( lum + 1.0f - lumMid ) * r ), 0.0f );
    w.z              = max( 1.0f - abs(( lum + 1.0f - lumMid ) * r ), 0.0f );
    float weight3     = dot( w.xyz, 1.0f );
	weight3= InvertLUM ? 1-smootherstep( weight3 ) : smootherstep( weight3 );
    
    float3 newc      = lerp( actual, color.xyz, saturate(weight1 * weight2 * weight3) );
    color.xyz        = lerp( color.xyz, newc.xyz, fxcolorMix );
    fragment=color.xyz;

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

technique BeforeColorMask2 < ui_tooltip = "Place this technique before effects you want compare.\nThen move technique 'After'"; >
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
technique AfterColorMask2 < ui_tooltip = "Place this technique after effects you want compare.\nThen move technique 'Before'"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AfterPS;
	}
}