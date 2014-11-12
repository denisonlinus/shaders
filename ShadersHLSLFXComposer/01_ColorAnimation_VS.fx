// An empty material, which simply transforms the vertex and sets the color.

//------------------------------------
float4x4 ModelViewProj : WorldViewProjection;

float Time : Time;

//------------------------------------
void mainVS(float4 position : POSITION,

        out float4 clipPosition : POSITION,
        out float4 color        : COLOR)
{
    //clipPosition = mul( float4(position.xyz , 1.0) , ModelViewProj);
    clipPosition = mul( position , ModelViewProj);
    float factor = (1+sin(5*Time))/2;
    color = lerp(float4(1.0, 1.0, 0.0, 1.0), float4(1.0, 0.0, 0.0, 1.0), factor);
}



//-----------------------------------
technique simple
{
    pass p0 
    {		
		VertexShader = compile vs_1_1 mainVS();
		   ZWriteEnable = true;
		   ZFunc = LessEqual;
		   CullMode = None;
    }
}
