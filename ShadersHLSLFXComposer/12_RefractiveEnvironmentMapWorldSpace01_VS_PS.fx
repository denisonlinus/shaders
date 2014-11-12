texture theEnvironmentCube
<
    string ResourceName = "DefaultReflection.dds";
    string TextureType = "CUBE";
>;

samplerCUBE environmentTexture = sampler_state
{
    Texture = <theEnvironmentCube>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;
};

/************* NON-TWEAKABLES **************/
float4x4 viewI         : ViewInverse            < string UIWidget="None"; >;
float4x4 worldIT       : WorldInverseTranspose  < string UIWidget="None"; >;
float4x4 worldView     : WorldView              < string UIWidget="None"; >;
float4x4 worldViewProj : WorldViewProjection    < string UIWidget="None"; >;

float4x4 worldViewIT   : WorldViewInverseTranspose;
float4x4 world         : World;
float4x4 view          : View;

float etaRatio = 1.5;

/*********** Vertex shader ******/

void refractionVS(float4 position   : POSITION,
                  float4 normal     : NORMAL,
     	
              out float4 clipPosition     : POSITION,
              out float4 obj_position     : TEXCOORD0,
              out float4 obj_normal       : TEXCOORD1)
{

  // compute standard clip position
  clipPosition = mul(position, worldViewProj);
  
  obj_position = position;
  obj_normal   = normal;
}

void refractionPS(float4 obj_position : TEXCOORD0,
                  float4 obj_normal   : TEXCOORD1,
              out float4 color        : COLOR)
{

  float3 worldSurfacePosition = mul(obj_position, world).xyz;
  float3 worldEyePosition = viewI[3].xyz;
  float3 worldSurfaceNormal = normalize(mul(obj_normal, worldIT).xyz);
  float3 refractDirection = refract((worldSurfacePosition - worldEyePosition), normalize(worldSurfaceNormal), etaRatio);

  color = texCUBE(environmentTexture, refractDirection);
}


technique refraction {
   pass p0 {		
      VertexShader = compile vs_1_1 refractionVS();    
      PixelShader  = compile ps_2_0 refractionPS();
    }    
}
