//
//  Simple Texture Mapping 
//  Manuel Menezes de Oliveira Neto
//
string description = "Texture mapping";

float4x4 worldViewProj : WorldViewProjection;

texture theColorTexture
<
  string ResourceName = "DefaultColor.dds";		
>;

sampler colorTexture = sampler_state 
{
    texture = <theColorTexture>;
    AddressU  = CLAMP;        
    AddressV  = CLAMP;
    AddressW  = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

/*********** Vertex shader ******/

void  textureVS(float4 position   : POSITION,
                float2 texCoord   : TEXCOORD0,
                out float4 clipPosition : POSITION,
                out float2 texCoordOut  : TEXCOORD1)
{
    // compute standard clip position
    clipPosition = mul(position, worldViewProj);
    // pass on the texture coordinate
    texCoordOut = texCoord;
}

/*********** Pixel shader ******/

void texturePS(float2 texCoord  : TEXCOORD1,
               out float4 color : COLOR)
{  
    color = tex2D(colorTexture, texCoord);
}

technique texturing {
    pass p0
    {		
        VertexShader = compile vs_1_1 textureVS();    
        ZWriteEnable = true;
        ZFunc = LessEqual;
        CullMode = None;
        PixelShader  = compile ps_1_1 texturePS();
    }    
}

