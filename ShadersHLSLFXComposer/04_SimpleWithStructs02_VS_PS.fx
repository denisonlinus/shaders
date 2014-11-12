/*********** Parameters ******/

float4x4 ModelViewProj : WorldViewProjection;



/*********** Vertex shader ******/

struct inVS {
    float4 position : POSITION;
};

struct outVS {
    float4 clipPosition : POSITION;
    float4 color        : COLOR;
};

outVS simpleVS(inVS input_vs)
{
    outVS output_vs;
    output_vs.clipPosition = mul( input_vs.position , ModelViewProj);
    output_vs.color = float4(0.9, 0.9, 0.5, 1.0);
    
    return output_vs;
}

/*********** Pixel shader ******/

struct inPS {
    float4 incolor      : COLOR;
};

struct outPS {
    float4 outcolor      : COLOR;
};

outPS simplePS(inPS input_ps)
{
  outPS output_ps;
  
  output_ps.outcolor = float4(0.0, 0.9, 0.5, 1.0);

  return output_ps;
}

/*********** Definition of the Techniques ******/

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
