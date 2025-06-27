/** FastMotionBlur

Fast and dead simple motion blur

MIT License
do whatever you want, i don't care

Dead simple motion blur with 1..4 number of color samples + 2 bluenoise fetches
Requires a motion vector provider using texMotionVectors before this shader
you can choose between these public options afaik:

* https://github.com/microdee/iMMERSE/blob/microdee/restore-previous-launchpad/Shaders/MartysMods_VELOCITY.fx
  * USE_OLD_LAUNCHPAD_VELOCITY

* https://github.com/martymcmodding/iMMERSE/blob/main/Shaders/MartysMods_LAUNCHPAD.fx
  * USE_LAUNCHPAD

* Legacy:
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

#ifndef PROVIDE_RETAINED_VELOCITY
#define PROVIDE_RETAINED_VELOCITY 1
#endif

#define IS_MULTI_FRAME FRAME_GATHER_COUNT > 1
#define IS_SINGLE_FRAME FRAME_GATHER_COUNT <= 1

uniform uint rsFramecount < source = "framecount"; >;
uniform float rsFrameTime < source = "frametime"; >;

uniform float Amount <
	ui_type = "slider";
	ui_min = 0; ui_max = 2.25;
> = 1.333;

uniform float FrameTimeThreshold <
	ui_type = "slider";
	ui_tooltip = "Don't do framerate limitting if actual frame time is below given ms";
	ui_min = 0; ui_max = 100;
	ui_step = 1;
> = 33;

#define __DEFAULT_VELOCITY_TEXTURE LaunchPad_Old()
#define __VELOCITY_SAMPLER(texture) sMotionVectorTex { Texture = texture; }
#include "VelocitySelector.fxh"

texture texOutput { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; MipLevels = 1; };
sampler sOutput { Texture = texOutput; };

#if PROVIDE_RETAINED_VELOCITY
texture texRetainedVelocityGather { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler sRetainedVelocityGather { Texture = texRetainedVelocityGather; };
texture texRetainedVelocity { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; MipLevels = 4; };
#endif

texture texPresent { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; MipLevels = 1; };
sampler sPresent { Texture = texPresent; };

#if FRAME_COUNTER_SOURCE
texture1D texCounter { Width = 1; Format = R32I; MipLevels = 1; };
storage1D<int> storCounter   { Texture = texCounter; };
sampler1D<int> sCounter   { Texture = texCounter; SRGBTexture = false; };
#endif

int framecount()
{
#if FRAME_COUNTER_SOURCE
	int count = tex1Dfetch(sCounter, 0) % FRAME_GATHER_COUNT;
#else
	int count = rsFramecount % FRAME_GATHER_COUNT;
#endif
	return rsFrameTime <= FrameTimeThreshold ? count : 0;
}

void getOutput(inout float3 output, float4 noiseIn, float2 uv, float2 pixelVel, int step)
{
	float noise = noiseIn[step%4u] - 0.5;
	output += tex2Dlod(ReShade::BackBuffer, float4(uv - pixelVel * noise * Amount, 0, 0)).rgb / MB_PASSES;
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

#include "FullscreenTriangle.fxh"

[shader("pixel")]
void clearPs(
	out float4 colorGather : SV_Target0
#if PROVIDE_RETAINED_VELOCITY
	, out float4 velocityGather : SV_Target1
#endif
) {
	int frameRef = framecount();
	if (rsFrameTime <= FrameTimeThreshold && frameRef != 0) discard;
	colorGather = float4(0,0,0,1);
#if PROVIDE_RETAINED_VELOCITY
	velocityGather = float4(0,0,0,0);
#endif
}

[shader("pixel")]
void mainPs(
	float4 pixelPos : SV_Position
	, out float4 colorGather : SV_Target0
#if PROVIDE_RETAINED_VELOCITY
	, out float4 velocityGather : SV_Target1
#endif
) {
	uint2 pixelCoord = uint2(pixelPos.xy);
	
	float2 uv = pixelPos.xy * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 vel = tex2Dfetch(sMotionVectorTex, pixelCoord).xy;

#if PROVIDE_RETAINED_VELOCITY
	velocityGather = float4(vel, 0, 0);
#endif
	
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
		colorGather = float4(1,1,1,1);
		return;
	}
	
	colorGather = float4(output, 1);
}

[shader("pixel")]
void writePs(
	float4 pixelPos : SV_Position
	, out float4 colorOutput : SV_Target0
#if PROVIDE_RETAINED_VELOCITY
	, out float4 velocityOutput : SV_Target1
#endif
) {
	int frameRef = framecount();
	if (rsFrameTime <= FrameTimeThreshold && frameRef != (FRAME_GATHER_COUNT - 1)) discard;
	float counter = tex2Dfetch(sOutput, uint2(0,0)).r;
	// if (counter < FRAME_GATHER_COUNT) discard;
	uint2 pixelCoord = uint2(pixelPos.xy);
	colorOutput = float4(tex2Dfetch(sOutput, pixelCoord).rgb / counter, 1);
#if PROVIDE_RETAINED_VELOCITY
	velocityOutput = float4(tex2Dfetch(sRetainedVelocityGather, pixelCoord).rg, 0, 0);
#endif
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
#if PROVIDE_RETAINED_VELOCITY
		RenderTarget1 = texRetainedVelocity;
#endif
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
		RenderTarget0 = texOutput;
#if PROVIDE_RETAINED_VELOCITY
		RenderTarget1 = texRetainedVelocityGather;
#endif
		ClearRenderTargets = false;
		GenerateMipMaps = false;
	}
	pass MainPass
	{
		VertexShader = mainVs;
		PixelShader = mainPs;
		RenderTarget0 = texOutput;
#if PROVIDE_RETAINED_VELOCITY
		RenderTarget1 = texRetainedVelocityGather;
#endif
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
		RenderTarget0 = texPresent;
#if PROVIDE_RETAINED_VELOCITY
		RenderTarget1 = texRetainedVelocity;
#endif
	}
	pass PresentPass
	{
		VertexShader = mainVs;
		PixelShader = presentPs;
	}
#endif
}
