
/*********** Parameters ******/

float4x4 ModelViewProj : WorldViewProjection;


struct InputVS
{
    float4 Position         : POSITION;
};

struct OutputVS
{
    float4 ClipPosition     : POSITION;
    float4 OutColor         : COLOR;
    float4 Text             : TEXCOORD0;
};


/*********** Vertex shader ******/

OutputVS simpleVS(in InputVS input)
{
    OutputVS output;
    output.ClipPosition = mul(input.Position, ModelViewProj);
    output.OutColor = float4(0.2, 0.9, 0.5, 1.0);
    output.Text = output.ClipPosition;
    return output;
}

/*********** Pixel shader ******/

struct InputPS
{
    float4 InColor          : COLOR;
};

struct OutputPS
{
    float4 OutColor         : COLOR;
};

void simplePS(in InputPS input, out OutputPS output)
{
    output.OutColor = input.InColor;//float4(1.0, 0.9, 0.5, 1.0);
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
