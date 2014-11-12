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

float etaRatioR
<
    string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 5.0;
    float UIStep = 0.001;
    string UIName = "etaRatioR";
> = 0.65;
float etaRatioG
<
    string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 5.0;
    float UIStep = 0.001;
    string UIName = "etaRatioG";
> = 0.67;
float etaRatioB
<
    string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 5.0;
    float UIStep = 0.001;
    string UIName = "etaRatioB";
> = 0.69;

float FresnelPower
<
    string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 5.0;
    float UIStep = 0.001;
    string UIName = "FresnelPower";
> = 5.0;




/*********** Vertex shader ******/

void refractionVS(in float4 position		: POSITION,
                  in float4 normal			: NORMAL,
                  out float4 clipPosition	: POSITION,
                  out float4 obj_position	: TEXCOORD0,
                  out float4 obj_normal		: TEXCOORD1)
{

  // compute standard clip position
  clipPosition = mul(position, worldViewProj);
  
  obj_position = position;
  obj_normal   = normal;
}

float3 MY_reflect(float3 I, float3 N)
{
	return I - 2 * (dot(I, N)) * N;	
}

float3 MY_refract(float3 I, float3 N, float eta)
{
	float IdotN = dot(I, N);
	float k = 1 - eta * eta * (1 - IdotN * IdotN);
	return k < 0 ? float3(0,0,0) : eta * I - (eta * IdotN + sqrt(k)) * N;
}

float3 MY_mix(float3 a, float3 b, float d)
{
	float inv = 1.0 - d;
	return float3(b.x * inv + a.x * d, b.y * inv + a.y * d, b.z * inv + a.z * d);
}

void refractionPS(in float4 obj_position	: TEXCOORD0,
                  in float4 obj_normal		: TEXCOORD1,
                  out float4 color			: COLOR)
{

  float3 worldSurfacePosition = mul(obj_position, world).xyz;
  float3 worldEyePosition = viewI[3].xyz;
  float3 worldSurfaceNormal = normalize(mul(obj_normal, worldIT).xyz);
  float3 viewingDirection = worldSurfacePosition - worldEyePosition;
  
  float F  = ((1.0-etaRatioG) * (1.0-etaRatioG)) / ((1.0+etaRatioG) * (1.0+etaRatioG));
  float Ratio   = F + (1.0 - F) * pow((1.0 - dot(-viewingDirection, normalize(worldSurfaceNormal))), FresnelPower);
  
  float3 refractDirectionR = MY_refract(viewingDirection, normalize(worldSurfaceNormal), etaRatioR);
  float3 refractDirectionG = MY_refract(viewingDirection, normalize(worldSurfaceNormal), etaRatioG);
  float3 refractDirectionB = MY_refract(viewingDirection, normalize(worldSurfaceNormal), etaRatioB);
  
  float3 reflectDirection = MY_reflect(viewingDirection, normalize(worldSurfaceNormal));
  
  float3 refractColor, reflectColor;

  refractColor.r = texCUBE(environmentTexture, refractDirectionR).r;
  refractColor.g = texCUBE(environmentTexture, refractDirectionG).g;
  refractColor.b = texCUBE(environmentTexture, refractDirectionB).b;
  
  reflectColor = texCUBE(environmentTexture, reflectDirection);
  
  color.xyz = MY_mix(refractColor, reflectColor, Ratio);
  color.a = 1;
  
}



technique refraction
{
   pass p0
   {		
      VertexShader = compile vs_1_0 refractionVS();    
      PixelShader  = compile ps_2_0 refractionPS();
    }    
}