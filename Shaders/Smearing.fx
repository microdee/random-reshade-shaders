/** Smearing

Distortion effect in the direction of motion for stylized reshade presets

MIT License
do whatever you want, i don't care

Requires a motion vector provider before this shader you can choose between these public options afaik:

* https://github.com/microdee/iMMERSE/blob/microdee/restore-previous-launchpad/Shaders/MartysMods_VELOCITY.fx
  * USE_OLD_LAUNCHPAD_VELOCITY

* https://github.com/martymcmodding/iMMERSE/blob/main/Shaders/MartysMods_LAUNCHPAD.fx
  * USE_LAUNCHPAD

* Legacy:
  * https://github.com/JakobPCoder/ReshadeMotionEstimation
  * https://gist.github.com/martymcmodding/69c775f844124ec2c71c37541801c053

when using this with FastMotionBlur it's recommended to set USE_RETAUNED_VELOCITY to sync with
artificially lowered framerate.
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform uint rsFramecount < source = "framecount"; >;

uniform float Frequency<
	ui_type = "slider";
	ui_min = 6; ui_max = 100;
> = 20;

uniform float Amount<
	ui_type = "slider";
	ui_min = 0; ui_max = 4;
> = 0.3;

uniform float Shape<
	ui_type = "slider";
	ui_min = 0.1; ui_max = 10;
> = 1;

#define __DEFAULT_VELOCITY_TEXTURE LaunchPad_Old()
#define __VELOCITY_SAMPLER(texture) sMotionVectorTex { Texture = texture; }
#include "VelocitySelector.fxh"

#define VS_SHADER_NAME() mainVs
#include "FullscreenTriangle.fxh"

#ifndef VELOCITY_BLUR
#define VELOCITY_BLUR 4
#endif

#if VELOCITY_BLUR > 0

#if VELOCITY_BLUR == 1
#define KERNEL_SIZE 23
#endif

#if VELOCITY_BLUR == 2
#define KERNEL_SIZE 33
#endif

#if VELOCITY_BLUR == 3
#define KERNEL_SIZE 35
#endif

#if VELOCITY_BLUR == 4
#define KERNEL_SIZE 65
#endif

#if KERNEL_SIZE == 23
#define PIXEL_START 11
static const float KERNEL[KERNEL_SIZE] =
{
	0.002436706343803515,
	0.004636114237302254,
	0.008296608238596322,
	0.013965003570314828,
	0.022109289813789203,
	0.032923196406968135,
	0.0461130337346424,
	0.06074930837220863,
	0.07527587082752966,
	0.08773365683170255,
	0.09617695873269712,

	0.09916850578089087,

	0.09617695873269712,
	0.08773365683170255,
	0.07527587082752966,
	0.06074930837220863,
	0.0461130337346424,
	0.032923196406968135,
	0.022109289813789203,
	0.013965003570314828,
	0.008296608238596322,
	0.004636114237302254,
	0.002436706343803515,
};

#elif KERNEL_SIZE == 33
#define PIXEL_START 16
static const float KERNEL[KERNEL_SIZE] =
{
	0.001924,
	0.002957,
	0.004419,
	0.006424,
	0.009084,
	0.012493,
	0.016713,
	0.021747,
	0.027524,
	0.033882,
	0.04057,
	0.04725,
	0.053526,
	0.058978,
	0.063209,
	0.065892,

	0.066812,

	0.065892,
	0.063209,
	0.058978,
	0.053526,
	0.04725,
	0.04057,
	0.033882,
	0.027524,
	0.021747,
	0.016713,
	0.012493,
	0.009084,
	0.006424,
	0.004419,
	0.002957,
	0.001924,
};

#elif KERNEL_SIZE == 35
#define PIXEL_START 17
static const float KERNEL[KERNEL_SIZE] =
{
	0.00131687903069317,
	0.00205870530023407,
	0.0031324441255622245,
	0.004638874539538358,
	0.006686232410653146,
	0.0093797098953999,
	0.01280666839519681,
	0.017018514961456375,
	0.02201131599327036,
	0.027708274880658742,
	0.03394786563326623,
	0.040481381619799764,
	0.0469827265022342,
	0.053071451295281444,
	0.05834759746582313,
	0.0624343492097772,
	0.06502246303378822,

	0.0659090914147332,
	
	0.06502246303378822,
	0.0624343492097772,
	0.05834759746582313,
	0.053071451295281444,
	0.0469827265022342,
	0.040481381619799764,
	0.03394786563326623,
	0.027708274880658742,
	0.02201131599327036,
	0.017018514961456375,
	0.01280666839519681,
	0.0093797098953999,
	0.006686232410653146,
	0.004638874539538358,
	0.0031324441255622245,
	0.00205870530023407,
	0.00131687903069317,
};

#elif KERNEL_SIZE == 65
#define PIXEL_START 32
static const float KERNEL[KERNEL_SIZE] =
{
	0.000958,
	0.001192,
	0.001473,
	0.001808,
	0.002203,
	0.002666,
	0.003204,
	0.003825,
	0.004534,
	0.005337,
	0.006239,
	0.007243,
	0.00835,
	0.009561,
	0.010871,
	0.012274,
	0.013764,
	0.015327,
	0.01695,
	0.018614,
	0.020302,
	0.021988,
	0.023651,
	0.025262,
	0.026798,
	0.028229,
	0.029532,
	0.030681,
	0.031655,
	0.032433,
	0.033001,
	0.033346,

	0.033462,
	
	0.033346,
	0.033001,
	0.032433,
	0.031655,
	0.030681,
	0.029532,
	0.028229,
	0.026798,
	0.025262,
	0.023651,
	0.021988,
	0.020302,
	0.018614,
	0.01695,
	0.015327,
	0.013764,
	0.012274,
	0.010871,
	0.009561,
	0.00835,
	0.007243,
	0.006239,
	0.005337,
	0.004534,
	0.003825,
	0.003204,
	0.002666,
	0.002203,
	0.001808,
	0.001473,
	0.001192,
	0.000958,
};

#endif

texture texVelocityBlur_H { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
texture texVelocityBlur_V { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };

sampler sVelocityBlur_H { Texture = texVelocityBlur_H; };
sampler sVelocityBlur_V { Texture = texVelocityBlur_V; };

#define SMEAR_SAMPLER sVelocityBlur_V

[shader("pixel")]
float4 blurPS_H(float4 pixelPos : SV_Position) : SV_Target
{
	uint2 pixelCoord = uint2(pixelPos.xy);
	float2 output = 0;

	[unroll]
	for (int i = 0; i<KERNEL_SIZE; i++)
	{
		float kernel = KERNEL[i];
		output += tex2Dfetch(sMotionVectorTex, pixelCoord + uint2(i - PIXEL_START, 0)).xy * kernel;
	}
	return float4(output, 0, 0);
}

[shader("pixel")]
float4 blurPS_V(float4 pixelPos : SV_Position) : SV_Target
{
	uint2 pixelCoord = uint2(pixelPos.xy);
	float2 output = 0;

	[unroll]
	for (int i = 0; i<KERNEL_SIZE; i++)
	{
		float kernel = KERNEL[i];
		output += tex2Dfetch(sVelocityBlur_H, pixelCoord + uint2(0, i - PIXEL_START)).xy * kernel;
	}
	return float4(output, 0, 0);
}

#else
#define SMEAR_SAMPLER sMotionVectorTex
#endif

[shader("pixel")]
float4 mainPs(float4 pixelPos : SV_Position) : SV_Target
{
	uint2 pixelCoord = uint2(pixelPos.xy);
	float2 uv = pixelPos.xy * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 velocity = tex2Dlod(SMEAR_SAMPLER, float4(uv, 0, 0)).xy;
	float speed = length(velocity);
	if (speed < 0.001) discard;
	float motionRad = atan2(velocity.y, velocity.x);
	float2x2 rotator = float2x2(cos(motionRad), -sin(motionRad), sin(motionRad), cos(motionRad));
	float2x2 rotatorInv = float2x2(cos(-motionRad), -sin(-motionRad), sin(-motionRad), cos(-motionRad));
	uv = mul(uv, rotator);
	float distortion = pow(abs(sin(uv.y * 3.14 * Frequency)), Shape) * Amount * speed;
	uv.x += distortion;
	uv = mul(uv, rotatorInv);
	
	return saturate(tex2Dlod(ReShade::BackBuffer, float4(uv, 0, 0)));
}

technique Smearing
{
#if VELOCITY_BLUR
	pass BlurVel_H
	{
		VertexShader = mainVs;
		PixelShader = blurPS_H;
		RenderTarget = texVelocityBlur_H;
	}
	pass BlurVel_V
	{
		VertexShader = mainVs;
		PixelShader = blurPS_V;
		RenderTarget = texVelocityBlur_V;
	}
#endif
	pass MainPass
	{
		VertexShader = mainVs;
		PixelShader = mainPs;
	}
}
