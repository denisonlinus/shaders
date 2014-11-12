//
//   Exercício: Complete os programas de vértice e
//              de fragmento a seguir para implementar o
//              efeito Fresnel com dispersão cromática 
//
//   Fresnel effect with chromatic dispersion
//
//   Written by Manuel Menezes de Oliveira Neto
//   September 2005
//

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

float3 etaRatios
<
  string UIName = "Refraction indices";
> = {0.85, 0.80, 0.9};

float fresnelBias
<
  string UIWidget = "slider";
  float UIMin = 0.0;
  float UImax = 2.0;
  float UIStep = 0.02;
  string UIName = "Fresnel Bias";
> = 0.16;

float fresnelScale
<
  string UIWidget = "slider";
  float UIMin = 0.0;
  float UImax = 8.0;
  float UIStep = 0.02;
  string UIName = "Fresnel Scale";
> = 0.62;

float fresnelPower
<
  string UIWidget = "slider";
  float UIMin = 0.0;
  float UImax = 20.0;
  float UIStep = 0.5;
  string UIName = "Fresnel Power";
> = 0.5;


float ReflectFactor;

/************* NON-TWEAKABLES **************/
float4x4 viewI         : ViewInverse            < string UIWidget="None"; >;
float4x4 worldIT       : WorldInverseTranspose  < string UIWidget="None"; >;
float4x4 worldView     : WorldView              < string UIWidget="None"; >;
float4x4 worldViewProj : WorldViewProjection    < string UIWidget="None"; >;

float4x4 worldViewIT   : WorldViewInverseTranspose;
float4x4 world         : World;
float4x4 view          : View;

/*********** Vertex shader ******/

void refractionVS(float4 position   : POSITION,
                  float4 normal     : NORMAL,
     	
              out float4 clipPosition     : POSITION,
              out float4 obj_position     : TEXCOORD0,
              out float4 obj_normal       : TEXCOORD1) {

  // compute standard clip position
  clipPosition = mul(position, worldViewProj);
  
  obj_position = position;
  obj_normal   = normal;
}


/*********** Fragment shader ******/

void refractionPS(float4 obj_position : TEXCOORD0,
                  float4 obj_normal   : TEXCOORD1,
              out float4 color        : COLOR) {
  
  float4 RefractColor;
  float4 ReflectColor;
   
  float3 worldSurfacePosition = mul(obj_position, world).xyz;
  float3 worldEyePosition = viewI[3].xyz;
  float3 worldSurfaceNormal = mul(obj_normal, worldIT).xyz;
  float3 viewDirection = normalize(worldSurfacePosition - worldEyePosition);
  //
  //   computes the directions of the refracted rays
  //
  float3 RefDir_Red   = refract(viewDirection, worldSurfaceNormal, etaRatios.r);
  float3 RefDir_Green = refract(viewDirection, worldSurfaceNormal, etaRatios.g);
  float3 RefDir_Blue  = refract(viewDirection, worldSurfaceNormal, etaRatios.b);
  //
  //   sample the cube map for the color components of the refracted rays
  //   resulting from the chromatic dispersion
  //
  RefractColor.r = texCUBE(environmentTexture, RefDir_Red).r;
  RefractColor.g = texCUBE(environmentTexture, RefDir_Green).g;
  RefractColor.b = texCUBE(environmentTexture, RefDir_Blue).b;
  RefractColor.a = 1;
  //
  //   compute the reflected direction and use it to compute the reflected color
  //
  float3 ReflectDir = reflect(viewDirection, worldSurfaceNormal);
  ReflectColor = texCUBE(environmentTexture, ReflectDir);
  //
  //   compute the reflection factor (refl_factor) using a cg approximantion 
  //   for the Fresnel equation
  //
  ReflectFactor = max(0, min(1, fresnelBias + fresnelScale * pow(1 + dot(viewDirection, worldSurfaceNormal), fresnelPower)));
  //
  //  Compute the final color as
  //   final_color = ReflecColor*(refl_factor) + RefractColor*(1-refl_factor)
  //
  color = lerp(RefractColor, ReflectColor, ReflectFactor);
}


technique refraction {
   pass p0 {		
      VertexShader = compile vs_1_1 refractionVS();    
      PixelShader  = compile ps_2_0 refractionPS();
    }    
}
