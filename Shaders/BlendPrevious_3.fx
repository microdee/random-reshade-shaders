/** BlendPrevious

Save a previous stage of your reshade pipeline into a texture and blend it
on top of the current color buffer. Duplicate this shader and name your
texture with BLEND_TEXTURE_NAME to do this multiple times.

MIT License
do whatever you want, i don't care
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

#define BLEND_ID 3

#if !defined(REUSE_TARGET)
#define REUSE_TARGET 0
#endif

#ifndef BLEND_TEXTURE_NAME

#if REUSE_TARGET
#define BLEND_TEXTURE_NAME BlendTex_0
#else
#define BLEND_TEXTURE_NAME BlendTex_3
#endif
#endif

uniform int BlendMode <
	ui_type = "combo";
	ui_items =
		"Blend"
		"\0Add"
		"\0Multiply"
		"\0Lighten"
		"\0Darken"
		"\0Difference"
		"\0Negation"
		"\0Exclusion"
		"\0Overlay"
		"\0Reflect"
		"\0Freeze"
		"\0Colorwrap\0"
	;
	ui_label = "Blend Mode";
> = 0;

uniform int BlendOrder <
	ui_type = "combo";
	ui_items ="Current <- Previous\0Previous <- Current\0";
	ui_label = "Blend Order";
> = 0;

uniform float Mix<
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
> = 0.5;

uniform bool ClampIn <
	ui_type = "checkbox";
	ui_label = "Clamp Input";
> = false;

uniform bool ClampOut <
	ui_type = "checkbox";
	ui_label = "Clamp Output";
> = false;

namespace BlendPrevious
{
	texture BLEND_TEXTURE_NAME { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA16F; MipLevels = 1; };
	sampler Sampler { Texture = BLEND_TEXTURE_NAME; };
}

float4 VS(in uint id : SV_VertexID) : SV_Position
{
	const float2 vertexPos[3] = {
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	return float4(vertexPos[id], 0f, 1f);
}

float4 PS_Write(float4 pixelPos : SV_Position) : SV_Target
{
	uint2 pixelCoord = uint2(pixelPos.xy);
	float4 result = tex2Dfetch(ReShade::BackBuffer, pixelCoord);
	result = lerp(result, saturate(result), ClampIn);
	return result;
}

float4 BlendWithMiddle(float4 left, float4 right, float4 middle, float alpha)
{
	float4 result = lerp(left, middle, saturate(alpha * 2));
	result = lerp(result, right, saturate(alpha * 2-1));
	return lerp(result, saturate(result), ClampOut);
}

float4 PS_Blend(float4 pixelPos : SV_Position) : SV_Target
{
	uint2 pixelCoord = uint2(pixelPos.xy);
	float4 left, right;
	if (BlendOrder > 0)
	{
		left = tex2Dfetch(BlendPrevious::Sampler, pixelCoord);
		right = tex2Dfetch(ReShade::BackBuffer, pixelCoord);
	}
	else
	{
		left = tex2Dfetch(ReShade::BackBuffer, pixelCoord);
		right = tex2Dfetch(BlendPrevious::Sampler, pixelCoord);
	}
	float ff = BlendOrder > 0 ? 1 - Mix : Mix;
	if (BlendMode == 0)
	{
		return lerp(left, right, ff);
	}
	if (BlendMode == 1)
	{
		return BlendWithMiddle(left, right, left + right, ff);
	}
	if (BlendMode == 2)
	{
		return BlendWithMiddle(left, right, left * right, ff);
	}
	if (BlendMode == 3)
	{
		return BlendWithMiddle(left, right, max(left, right), ff);
	}
	if (BlendMode == 4)
	{
		return BlendWithMiddle(left, right, min(left, right), ff);
	}
	if (BlendMode == 5)
	{
		return BlendWithMiddle(left, right, abs(left - right), ff);
	}
	if (BlendMode == 6)
	{
		return BlendWithMiddle(left, right, 1 - abs(1 - left - right), ff);
	}
	if (BlendMode == 7)
	{
		return BlendWithMiddle(left, right, left + right - 2 * left * right, ff);
	}
	if (BlendMode == 8)
	{
		float4 middle = float4(0,0,0,1);
		middle.r= (left.r < 0.5) ? (2 * left.r * right.r) : (1 - 2 * (1 - left.r) * (1 - right.r));
		middle.g= (left.g < 0.5) ? (2 * left.g * right.g) : (1 - 2 * (1 - left.g) * (1 - right.g));
		middle.b= (left.b < 0.5) ? (2 * left.b * right.b) : (1 - 2 * (1 - left.b) * (1 - right.b));
		return BlendWithMiddle(left, right, saturate(middle), ff);
	}
	if (BlendMode == 9)
	{
		float4 middle = float4(0,0,0,1);
		middle.r = (right.r == 1) ? 1 : pow(left.r,2)/(1-right.r);
		middle.g = (right.g == 1) ? 1 : pow(left.g,2)/(1-right.g);
		middle.b = (right.b == 1) ? 1 : pow(left.b,2)/(1-right.b);
		return BlendWithMiddle(left, right, saturate(middle), ff);
	}
	if (BlendMode == 10)
	{
		float4 middle = 1 - pow(1 - left, 2) / max(right, 0.0001);
		return BlendWithMiddle(left, right, saturate(middle), ff);
	}
	if (BlendMode == 11)
	{
		int4 ip;
		float4 middle = float4(lerp(max(modf(left + ff, ip), left), right, ff).rgb, 1);
		return BlendWithMiddle(left, right, saturate(middle), ff);
	}
	return lerp(left, saturate(left), ClampOut);
}

technique BlendPrevious_Write_3
{
	pass MainPass
	{
		VertexShader = VS;
		PixelShader = PS_Write;
		RenderTarget = BlendPrevious::BLEND_TEXTURE_NAME;
		GenerateMipMaps = false;
	}
}

technique BlendPrevious_Blend_3
{
	pass MainPass
	{
		VertexShader = VS;
		PixelShader = PS_Blend;
	}
}