
/*********** Parameters ******/

float4x4 ModelViewProj : WorldViewProjection;



/*********** Vertex shader ******/

void simpleVS(float4 position : POSITION,

        out float4 clipPosition : POSITION,
        out float4 color        : COLOR)
{
    clipPosition = mul( position , ModelViewProj);
    color = position;
    //color = clipPosition;
}

void simplePS(float4 incolor      : COLOR,
              out float4 outcolor : COLOR)
{
  outcolor = incolor;
}


technique simple
{
    pass p0 
    {		
	VertexShader = compile vs_1_1 simpleVS();
		ZWriteEnable = true;
		ZFunc = LessEqual;
		CullMode = None;
	PixelShader  = compile ps_1_1 simplePS();
    }
}
