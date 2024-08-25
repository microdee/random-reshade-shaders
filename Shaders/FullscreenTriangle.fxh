#ifndef VS_SHADER_NAME
#define VS_SHADER_NAME() mainVs
#endif

[shader("vertex")]
float4 VS_SHADER_NAME()(in uint id : SV_VertexID) : SV_Position
{
	const float2 vertexPos[3] = {
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	return float4(vertexPos[id], 0f, 1f);
}