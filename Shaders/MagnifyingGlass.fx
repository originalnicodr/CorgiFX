//Made by originalnicodr
//Based on https://www.shadertoy.com/view/3sdyRH by oneshade

namespace MagnifyingGlass
{

#include "ReShade.fxh"

uniform float2 MouseCoords < source = "mousepoint"; >;
uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = false; >;

#ifndef MAGNIFYING_GLASS_MAX_ZOOM
	#define MAGNIFYING_GLASS_MAX_ZOOM 5
#endif

uniform float3 lensBorderColor <
	ui_label = "Border color";
    ui_type = "color";
> = float3(0.0, 0.0, 0.0);

uniform bool invertColorBackground <
	ui_label = "Use the inverse of the background for border color instead";
> = false;

uniform bool useUICoords <
	ui_label = "Use coordinates instead of mouse position";
> = false;

uniform float2 magnifyingGlassUICoords <
	ui_label = "Coordinates";
	ui_type = "slider";
    ui_step = 0.01;
    ui_min = 0.0; ui_max = 1.0;
> = float2(0.5, 0.5);

uniform bool showWhenClick <
	ui_label = "Display the magnifying glass on click";
> = false;

uniform float lensBorderWidth <
	ui_label = "Lens border width";
	ui_type = "slider";
    ui_step = 0.001;
    ui_min = 0.0; ui_max = 0.1;
> = 0.003;

uniform float lensRadius <
	ui_label = "Lens radius";
	ui_type = "slider";
    ui_min = 0.0; ui_max = 0.5;
    ui_step = 0.01;
> = 0.1;

uniform float lensZoom <
	ui_label = "Zoom power";
	ui_type = "slider";
    ui_min = 1; ui_max = MAGNIFYING_GLASS_MAX_ZOOM;
    ui_step = 0.01;
> = 2.0;

float3 MagnifyingGlass_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    const float halfBorderWidth = lensBorderWidth / 2.0;
	const float innerRadius = lensRadius - halfBorderWidth;
	const float outerRadius = lensRadius + halfBorderWidth;

	float2 magnifyingGlassPos = useUICoords ? magnifyingGlassUICoords : MouseCoords * BUFFER_PIXEL_SIZE;

	float dist = sqrt(pow(texcoord.x - magnifyingGlassPos.x, 2.0)*BUFFER_ASPECT_RATIO + pow(texcoord.y - magnifyingGlassPos.y, 2.0));

    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 realBorderColor = invertColorBackground ? 1 - color : lensBorderColor;

	if (!showWhenClick || LeftMouseDown){
		if (dist <= innerRadius) {
			texcoord = (magnifyingGlassPos + ((texcoord - magnifyingGlassPos) / lensZoom));
			color = tex2D(ReShade::BackBuffer, texcoord).rgb;
		}
    
		if (dist > innerRadius && dist <= outerRadius) {
			color = realBorderColor;
		}

	}

    return color;
}


technique MagnifyingGlass
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MagnifyingGlass_PS;
	}
}

}
