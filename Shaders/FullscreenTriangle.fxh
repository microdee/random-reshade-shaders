#ifndef VS_SHADER_NAME
#define VS_SHADER_NAME() mainVs
#endif

[shader("vertex")]
void VS_SHADER_NAME()(in uint id : SV_VertexID, out float4 pos : SV_Position, out float2 uv : TEXCOORD0)
{
	const float2 vertexPos[3] = {
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	const float2 vertexUv[3] = {
		float2(0f, 0f), // Top left
		float2(0f, 2f), // Bottom left
		float2(2f, 0f)  // Top right
	};
	pos = float4(vertexPos[id], 0f, 1f);
	uv = vertexUv[id];
}