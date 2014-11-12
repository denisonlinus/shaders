string description = "Basic Vertex Lighting with a Texture";

//------------------------------------
float4x4 worldViewProj : WorldViewProjection;
float4x4 world   : World;
float4x4 worldInverseTranspose : WorldInverseTranspose;
float4x4 viewInverse : ViewInverse;

texture diffuseTexture : Diffuse
<
	string ResourceName = "DefaultColor.dds";
>;

float4 lightDir : Direction
<
	string Object = "DirectionalLight";
    string Space = "World";
> = {1.0f, -1.0f, 1.0f, 0.0f};

float4 lightColor : Diffuse
<
    string UIName = "Diffuse Light Color";
    string Object = "DirectionalLight";
> = {1.0f, 1.0f, 1.0f, 1.0f};

float4 lightAmbient : Ambient
<
    string UIWidget = "Ambient Light Color";
    string Space = "material";
> = {0.0f, 0.0f, 0.0f, 1.0f};

float4 materialDiffuse : Diffuse
<
    string UIWidget = "Surface Color";
    string Space = "material";
> = {1.0f, 1.0f, 1.0f, 1.0f};

float4 materialSpecular : Specular
<
	string UIWidget = "Surface Specular";
	string Space = "material";
> = {1.0f, 1.0f, 1.0f, 1.0f};

float shininess : SpecularPower
<
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 128.0;
    float UIStep = 1.0;
    string UIName = "specular power";
> = 30.0;


//------------------------------------
struct vertexInput {
    float3 position				: POSITION;
    float3 normal				: NORMAL;
    float4 texCoordDiffuse		: TEXCOORD0;
};

struct vertexOutput {
    float4 hPosition		: POSITION;
    float4 texCoordDiffuse	: TEXCOORD0;
    float4 clipPosition		: TEXCOORD1;
    float4 diffAmbColor		: COLOR0;
    float4 specCol			: COLOR1;
};


//------------------------------------
vertexOutput VS_TransformAndTexture(vertexInput IN) 
{
    vertexOutput OUT;
    OUT.hPosition = mul( float4(IN.position.xyz , 1.0) , worldViewProj);
    OUT.clipPosition = mul( float4(IN.position.xyz , 1.0) , worldViewProj);
    
    OUT.texCoordDiffuse = IN.texCoordDiffuse;

	//calculate our vectors N, E, L, and H
	float3 worldEyePos = viewInverse[3].xyz;
    float3 worldVertPos = mul(IN.position, world).xyz;
	float4 N = mul(IN.normal, worldInverseTranspose); //normal vector
    float3 E = normalize(worldEyePos - worldVertPos); //eye vector
    float3 L = normalize( -lightDir.xyz); //light vector
    float3 H = normalize(E + L); //half angle vector

	//calculate the diffuse and specular contributions
    float  diff = max(0 , dot(N,L));
    float  spec = pow( max(0 , dot(N,H) ) , shininess );
    if( diff <= 0 )
    {
        spec = 0;
    }

	//output diffuse
    float4 ambColor = materialDiffuse * lightAmbient;
    float4 diffColor = materialDiffuse * diff * lightColor ;
    OUT.diffAmbColor = diffColor + ambColor;

	//output specular
    float4 specColor = materialSpecular * lightColor * spec;
    OUT.specCol = specColor;

    return OUT;
}


//------------------------------------
sampler TextureSampler = sampler_state 
{
    texture = <diffuseTexture>;
    AddressU  = CLAMP;        
    AddressV  = CLAMP;
    AddressW  = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};


//-----------------------------------
float4 PS_Textured( vertexOutput IN): COLOR
{
  IN.clipPosition /= IN.clipPosition.w;
  float4 diffuseTexture = float4(tex2D( TextureSampler, (float2(IN.clipPosition.x,-IN.clipPosition.y)+1.0)/2.0 ).rgb,1.0);
  return IN.diffAmbColor * diffuseTexture + IN.specCol;
}


//-----------------------------------
technique textured
{
    pass p0 
    {		
		VertexShader = compile vs_1_1 VS_TransformAndTexture();
		PixelShader  = compile ps_2_0 PS_Textured();
    }
}