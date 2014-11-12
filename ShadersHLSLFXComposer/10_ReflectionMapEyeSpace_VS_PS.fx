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
float4x4 world         : World;
float4x4 worldViewIT   : WorldViewInverseTranspose;

/*********** Vertex shader ******/

float3 MY_reflect(float3 v, float3 n)
{
	return v - 2 * dot(v, n) * n;
}

void reflectionVS(float4 position   : POSITION,
                  float4 normal     : NORMAL,
     	
              out float4 clipPosition     : POSITION,
              out float3 reflectDirection : TEXCOORD0) {

  // compute standard clip position
  clipPosition = mul(position, worldViewProj);

  // In order to complete this exercise, you need to add some
  // code to this vertex shader in order to compute 
  // the reflected direction of a ray from the viewing 
  // direction and normal vector, both expressed in the 
  // world coordinate system. Then, repeat the exercise, but this
  // computing both the viewing direction and the normal in the
  // camera coordinate system
  
  //EYE SPACE
  float3 eyeSurfaceNormal = normalize(mul(normal, worldViewIT).xyz);
  float3 eyeSurfacePosition = mul(position, worldView).xyz;
  float3 viewingDirection = normalize(-eyeSurfacePosition);
  //reflectDirection = MY_reflect(viewingDirection, eyeSurfaceNormal);
  reflectDirection = reflect(viewingDirection, eyeSurfaceNormal);
  reflectDirection = mul(-reflectDirection, viewI).xyz;
  
}

void reflectionPS(float3 reflectDirection : TEXCOORD0,
              out float4 color            : COLOR)
{

  color = texCUBE(environmentTexture, reflectDirection);
}


technique reflection {
   pass p0 {		
      VertexShader = compile vs_1_1 reflectionVS();    
      PixelShader  = compile ps_1_1 reflectionPS();
    }    
}
