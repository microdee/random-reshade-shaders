/** FastMotionBlur

Fast and dead simple motion blur

MIT License
do whatever you want, i don't care

Dead simple motion blur with 1..4 number of color samples + 2 bluenoise fetches
Requires a motion vector provider using texMotionVectors before this shader
you can choose between these public options afaik:

* https://github.com/martymcmodding/iMMERSE/blob/main/Shaders/MartysMods_LAUNCHPAD.fx
* https://github.com/JakobPCoder/ReshadeMotionEstimation
* https://gist.github.com/martymcmodding/69c775f844124ec2c71c37541801c053

ColorAndDither.fxh by Fubaxiusz (Jakub Maksymilian Fober) is used for blue-noise implementation
*/

#define MB_PASSES 4

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ColorAndDither.fxh"

#define FRAME_COUNTER_SOURCE __RENDERER__ >= 0xb000

#ifndef FRAME_GATHER_COUNT
#define FRAME_GATHER_COUNT 1
#endif

#ifndef USE_LAUNCHPAD
#define USE_LAUNCHPAD 1
#endif

#define IS_MULTI_FRAME FRAME_GATHER_COUNT > 1
#define IS_SINGLE_FRAME FRAME_GATHER_COUNT <= 1

uniform uint rsFramecount < source = "framecount"; >;

uniform float Amount<
	ui_type = "slider";
	ui_min = 0; ui_max = 2.25;
> = 2;

#if USE_LAUNCHPAD
namespace Deferred 
{
	texture MotionVectorsTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
}
sampler sMotionVectorTex { Texture = Deferred::MotionVectorsTex; };
#else
texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler sMotionVectorTex { Texture = texMotionVectors; };
#endif

texture texOutput { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA16F; MipLevels = 1; };
sampler sOutput   { Texture = texOutput;   };

texture texPresent { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 1; };
sampler sPresent   { Texture = texPresent;   };

#if FRAME_COUNTER_SOURCE
texture1D texCounter { Width = 1; Format = R32I; MipLevels = 1; };
storage1D<int> storCounter   { Texture = texCounter; };
sampler1D<int> sCounter   { Texture = texCounter; SRGBTexture = false; };
#endif

int framecount()
{
#if FRAME_COUNTER_SOURCE
	return tex1Dfetch(sCounter, 0) % FRAME_GATHER_COUNT;
#else
	return rsFramecount % FRAME_GATHER_COUNT;
#endif
}

[shader("vertex")]
float4 mainVs(in uint id : SV_VertexID) : SV_Position
{
	const float2 vertexPos[3] = {
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	return float4(vertexPos[id], 0f, 1f);
}

void getOutput(inout float3 output, float4 noiseIn, float2 uv, float2 pixelVel, int step)
{
	float noise = noiseIn[step%4u] - 0.5;
	output += saturate(tex2Dlod(ReShade::BackBuffer, float4(uv - pixelVel * noise * Amount, 0, 0)).rgb) / MB_PASSES;
}

#if FRAME_COUNTER_SOURCE

[shader("compute")]
[numthreads(1, 1, 1)]
void countCs(uint3 tid : SV_GroupThreadID)
{
	int c = tex1Dfetch(storCounter, 0) + 1;
	tex1Dstore(storCounter, 0, c);
}

#endif

[shader("pixel")]
float4 clearPs(float4 pixelPos : SV_Position) : SV_Target
{
	int frameRef = framecount();
	if (frameRef != 0) discard;
	return float4(0,0,0,1);
}

[shader("pixel")]
float4 mainPs(float4 pixelPos : SV_Position) : SV_Target
{
	uint2 pixelCoord = uint2(pixelPos.xy);
	
	float2 uv = pixelPos.xy * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 vel = tex2Dfetch(sMotionVectorTex, pixelCoord).xy;
	
	uint offset = uint(4f*tex2Dfetch(BlueNoise::BlueNoiseTexSmp, pixelCoord/DITHER_SIZE_TEX%DITHER_SIZE_TEX).r);
	offset += rsFramecount;
	float4 noise = tex2Dfetch(BlueNoise::BlueNoiseTexSmp, pixelCoord%DITHER_SIZE_TEX);
	float3 output = 0;
	getOutput(output, noise, uv, vel, offset + 0);
	#if MB_PASSES > 1
	getOutput(output, noise, uv, vel, offset + 1);
	#endif
	#if MB_PASSES > 2
	getOutput(output, noise, uv, vel, offset + 2);
	#endif
	#if MB_PASSES > 3
	getOutput(output, noise, uv, vel, offset + 3);
	#endif
	
	if (all(pixelCoord == uint2(0,0)))
	{
		return float4(1,1,1,1);
	}
	
	return float4(output, 1);
}

[shader("pixel")]
float4 writePs(float4 pixelPos : SV_Position) : SV_Target
{
	int frameRef = framecount();
	if (frameRef != (FRAME_GATHER_COUNT - 1)) discard;
	float counter = tex2Dfetch(sOutput, uint2(0,0)).r;
	// if (counter < FRAME_GATHER_COUNT) discard;
	uint2 pixelCoord = uint2(pixelPos.xy);
	return float4(tex2Dfetch(sOutput, pixelCoord).rgb / counter, 1);
}

[shader("pixel")]
float4 presentPs(float4 pixelPos : SV_Position) : SV_Target
{
	uint2 pixelCoord = uint2(pixelPos.xy);
	if (all(pixelCoord == uint2(0,0)))
	{
		return tex2Dfetch(ReShade::BackBuffer, uint2(0,0));
	}
	return float4(tex2Dfetch(sPresent, pixelCoord).rgb, 1);
}

technique FastMotionBlur
{
#if IS_SINGLE_FRAME
	pass MainPass
	{
		VertexShader = mainVs;
		PixelShader = mainPs;
	}
#else
#if FRAME_COUNTER_SOURCE
	pass CountPass
	{
		DispatchSizeX = 1;
		DispatchSizeY = 1;
		DispatchSizeZ = 1;
		ComputeShader = countCs<1,1,1>;
	}
#endif
	pass ClearPass
	{
		VertexShader = mainVs;
		PixelShader = clearPs;
		RenderTarget = texOutput;
		ClearRenderTargets = false;
		GenerateMipMaps = false;
	}
	pass MainPass
	{
		VertexShader = mainVs;
		PixelShader = mainPs;
		RenderTarget = texOutput;
		ClearRenderTargets = false;
		GenerateMipMaps = false;
		BlendEnable = true;
		BlendOp = ADD;
		SrcBlend = ONE;
		DestBlend = ONE;
	}
	pass WritePass
	{
		VertexShader = mainVs;
		PixelShader = writePs;
		ClearRenderTargets = false;
		GenerateMipMaps = false;
		RenderTarget = texPresent;
	}
	pass PresentPass
	{
		VertexShader = mainVs;
		PixelShader = presentPs;
	}
#endif
}
