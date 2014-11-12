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
    float UIMax = 10.0;
    float UIStep = 0.01;
    string UIName = "etaRatioR";
> = 1.5;
float etaRatioG
<
    string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 10.0;
    float UIStep = 0.01;
    string UIName = "etaRatioG";
> = 1.5;
float etaRatioB
<
    string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 10.0;
    float UIStep = 0.01;
    string UIName = "etaRatioB";
> = 1.5;


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

void refractionPS(in float4 obj_position	: TEXCOORD0,
                  in float4 obj_normal		: TEXCOORD1,
                  out float4 color			: COLOR)
{

  float3 worldSurfacePosition = mul(obj_position, world).xyz;
  float3 worldEyePosition = viewI[3].xyz;
  float3 worldSurfaceNormal = normalize(mul(obj_normal, worldIT).xyz);
  float3 viewingDirection = worldSurfacePosition - worldEyePosition;
  float3 refractDirectionR = MY_refract(viewingDirection, normalize(worldSurfaceNormal), etaRatioR);
  float3 refractDirectionG = MY_refract(viewingDirection, normalize(worldSurfaceNormal), etaRatioG);
  float3 refractDirectionB = MY_refract(viewingDirection, normalize(worldSurfaceNormal), etaRatioB);

  color.r = texCUBE(environmentTexture, refractDirectionR).r;
  color.g = texCUBE(environmentTexture, refractDirectionG).g;
  color.b = texCUBE(environmentTexture, refractDirectionB).b;
  color.a = 1.0;
  
}


technique refraction
{
   pass p0
   {		
      VertexShader = compile vs_1_0 refractionVS();    
      PixelShader  = compile ps_2_0 refractionPS();
    }    
}