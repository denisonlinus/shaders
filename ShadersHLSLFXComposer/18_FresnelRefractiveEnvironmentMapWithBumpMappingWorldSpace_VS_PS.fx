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

texture theNormalMap
<

 string ResourceName = "DefaultBumpNormal.dds";

>;
sampler normalMapTexture = sampler_state
{
   texture   = <theNormalMap>;
   MIPFILTER = LINEAR;
   MINFILTER = LINEAR;
   MAGFILTER = LINEAR;
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

float SurfaceNormalBias
<
  string UIWidget = "slider";
  float UIMin = 0.0;
  float UImax = 1.0;
  float UIStep = 0.001;
  string UIName = "Surface Normal Bias";
> = 0.5;

float4 lightPosition : Position = {1.0f, 3.0f, 1.0f, 1.0f};

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

void refractionVS(	in float4 position				: POSITION,
					in float4 normal				: NORMAL,
					in float4 tangent				: TANGENT0,
					in float4 binormal				: BINORMAL0,
					in float2 texCoord				: TEXCOORD0,
					out float4 clipPosition			: POSITION,
					out float4 worldSurfacePosition	: TEXCOORD0,
					out float3 worldNormal			: TEXCOORD1,
					out float3 worldTangent			: TEXCOORD2,
					out float3 worldBinormal		: TEXCOORD3,
					out float2 texCoordOut			: TEXCOORD4)
{
	
	// compute standard clip position
	clipPosition = mul(position, worldViewProj);
  
	// compute the necessary positions and directions in eye space  
	worldSurfacePosition = mul(position, world);
	float3 worldEyePosition = viewI[3].xyz;
	
	worldNormal          = mul(normal, worldIT).xyz;
	worldTangent         = mul(tangent, worldIT).xyz;
	worldBinormal        = mul(binormal, worldIT).xyz;
	
	texCoordOut = texCoord;
  
}
//
//  Expands a normal vector with each component defined in the range [-1,1]
//  but stored in the normal map in the range [0,1]. Since the compression
//  was obtaned as (([-1,1])/2.0 + 0.5) the expansion
//  can be obtained as (([0,1] - 0.5)*2.0)
// 
float3 expand(float3 vec)
{
  return(vec - 0.5)* 2.0;
}

/*********** Fragment shader ******/

void refractionPS(	in float4 worldSurfacePosition	: TEXCOORD0,
					in float4 worldNormal			: TEXCOORD1,
					in float3 worldTangent			: TEXCOORD2,
					in float3 worldBinormal			: TEXCOORD3,
					in float2 texCoord				: TEXCOORD4,
					out float4 color				: COLOR)
{
	//
	//	computes the bump normal
	//
	float3 Bump = normalize(expand(tex2D(normalMapTexture, texCoord))).xyz;
	float3 T = normalize(worldTangent);
	float3 B = normalize(worldBinormal);
	float3 N = normalize(worldNormal);
	float3 Nb = Bump.r * T + Bump.g * B + Bump.b * N;
	Nb = normalize(Nb);
	//
	//
	//
	float4 RefractColor;
	float4 ReflectColor;
	float3 worldEyePosition = viewI[3].xyz;
	float3 worldSurfaceNormal = lerp(worldNormal, Nb, SurfaceNormalBias);
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
      PixelShader  = compile ps_3_0 refractionPS();
    }    
}
