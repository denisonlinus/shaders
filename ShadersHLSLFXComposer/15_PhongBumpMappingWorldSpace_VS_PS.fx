//
//  Exercício: Complete os programas a seguir para
//  implementar normal-map bump mapping sobre objetos poligonais
//  arbitrários utilizando o espaço tangente do objeto.
//
//  Este programa estende o programa anterior que voces já fizeram
//  para implementar mapeamento de texturas com Phong shading.
//  Neste caso, entretanto, ao invés de usar as normais do próprio modelo,
//  estas terão suas direções redefinidas por uma textura chamada 
//  "normal map". As componentes (r,g,b) de um normal map armazenam as
//  componentes do vetor normal nas direções (x,y,z), respectivamente.
//   
//  O espaço das componentes de um vetor normalizado varia de [-1,1]. 
//  Entretanto, por uma questão de compatibilidade com programas que
//  geram normal maps sem sinal, as componentes costumam ser remapeadas
//  para o espaço [0,1], o que deve ser compensado pelo seu programa.
//
//  Os valores dos componentes lidos de um normal map são utilizados
//  para definir um novo vetor normal para o fragmento. O novo vetor
//  normal é obtido por meio de uma combinação linear dos vetores do
//  espaço tangente, sendo que os valores lidos do normal map correspondem
//  aos coeficientes desta combinação linear. Mais especificamente, tem-se:
//
//  Nova_normal = nm.r*TANGENT + nm.g*BINORMAL + nm.b*NORMAL
//
//  Manuel Menezes de Oliveira Neto
//
//  Setembro de 2005
// 

string description = "Phong Shading: Per-pixel Phong lighting";

/************* NON-TWEAKABLES **************/
float4x4 world         : World;
float4x4 worldIT       : WorldInverseTranspose;
float4x4 worldView     : WorldView;
float4x4 worldViewIT   : WorldViewInverseTranspose;
float4x4 worldViewProj : WorldViewProjection;
float4x4 view          : View;
float4x4 ViewI         : ViewInverse;

/************* Variables **************/
float4 lightPosition : Position = {1.0f, 3.0f, 1.0f, 1.0f};
float4 lightColor    : Diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
float4 ambientLight  : Ambient = {0.5f, 0.5f, 0.5f, 1.0f};

//float4 Kd  : Diffuse = {0.0f, 0.0f, 1.0f, 1.0f};
float4 Ks : Specular = {1.0f, 1.0f, 1.0f, 1.0f};
float shininess : SpecularPower 
<
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 256.0;
    float UIStep = 1.0;
    string UIName = "specular power";
> = 60.0;

texture color_texture
<
   string ResourceName = "DefaultColor.dds";
>;

sampler sampler_texture = sampler_state
{
   texture   = <color_texture>;
   AddressU  = CLAMP;
   AddressV  = CLAMP;
   MIPFILTER = LINEAR;
   MINFILTER = LINEAR;
   MAGFILTER = LINEAR;
};

texture normalMap_texture
<

 string ResourceName = "DefaultBumpNormal.dds";

>;
sampler normal_sampler = sampler_state
{
   texture   = <normalMap_texture>;
   MIPFILTER = LINEAR;
   MINFILTER = LINEAR;
   MAGFILTER = LINEAR;
};

float Bumpy
<
    string UIWidget = "slider";
    float UIMin = -3.0;
    float UIMax = 3.0;
    float UIStep = 0.1;
    string UIName =  "bump power";
> = 1.0;

/*********** Functions implementing the Phong lighting model ******/

float4 ambientReflection(float4 surfaceColor,
                    	 float4 lightColor) {
  return lightColor * surfaceColor;

}

float4 diffuseReflection(float4 Kd,
           				 float3 surfaceNormal,
                    	 float4 lightColor,
                    	 float3 lightDirection) {
  float diffuseFactor = max(0, dot(lightDirection, surfaceNormal));
  return lightColor * Kd * diffuseFactor;
}

float4 specularReflection(float4 surfaceColor,
                          float  surfaceShininess,
               		      float3 surfaceNormal,
                    	  float4 lightColor,
                    	  float3 halfAngle) {
  float specularFactor = pow(max(0, dot(halfAngle, surfaceNormal)), surfaceShininess);
  return lightColor * surfaceColor * specularFactor;       
}

float4 phongReflection(float4 ambientSurfaceColor,
                       float4 ambientLightColor,
                       float4 diffuseSurfaceColor,
                       float4 specularSurfaceColor,
                       float  surfaceShininess,
                       float3 surfaceNormal,
                       float3 halfAngle,
                       float3 lightDirection,
                       float4 lightColor) {
                       
  float4 ambient = ambientReflection(ambientSurfaceColor, ambientLightColor);

  float4 diffuse = diffuseReflection(diffuseSurfaceColor, surfaceNormal,
                                     lightColor, lightDirection);
                                     
  float4 specular;

  if (dot(lightDirection, surfaceNormal) <= 0) 
     specular = float4(0,0,0,0);
  else
     specular = specularReflection(specularSurfaceColor, surfaceShininess, surfaceNormal,
                                       lightColor, halfAngle);
          
  return ambient + diffuse + specular;
}



/*********** Vertex shader ******/

void phongVS(float4 position     : POSITION,
               float4 normal     : NORMAL,
               float4 tangent    : TANGENT0,
               float4 binormal   : BINORMAL0, 
               float2 texCoord   : TEXCOORD0,
		     
           out float4 clipPosition         : POSITION,
           out float2 texCoordOut          : TEXCOORD0,
           out float3 worldViewerDirection : TEXCOORD1,
           out float3 worldNormal          : TEXCOORD2,
           out float3 worldTangent         : TEXCOORD3,
           out float3 worldBinormal        : TEXCOORD4,
           out float3 worldLightDirection  : TEXCOORD5,
           out float3 worldHalfAngle       : TEXCOORD6) {

  // compute standard clip position
  clipPosition = mul(position, worldViewProj);

  // compute the necessary positions and directions in world space  
  float3 worldSurfacePosition = mul(position, world).xyz;
//  float3 eyeLightPosition   = mul(lightPosition, view).xyz;
  float3 worldEyePosition = ViewI[3].xyz;
  
   worldViewerDirection = normalize(worldEyePosition-worldSurfacePosition);
   worldNormal          = mul(normal, worldIT).xyz;
   worldTangent         = mul(tangent, worldIT).xyz;
   worldBinormal        = mul(binormal, worldIT).xyz;
   worldLightDirection  = normalize(lightPosition.xyz - worldSurfacePosition);
   worldHalfAngle       = normalize(worldViewerDirection + worldLightDirection);                     
  
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

void phongPS(  float2 texCoord  : TEXCOORD0,
               float3 worldViewerDirection : TEXCOORD1,
               float3 worldNormal          : TEXCOORD2,
			   float3 worldTangent         : TEXCOORD3,
			   float3 worldBinormal        : TEXCOORD4,
               float3 worldLightDirection  : TEXCOORD5,
               float3 worldHalfAngle       : TEXCOORD6,
               out float4 colorOut : COLOR) 
{
  float4 tex_diffuse_color = tex2D(sampler_texture, texCoord);
  
	float3 Bump = normalize(expand(tex2D(normal_sampler, texCoord))).xyz;
	float3 T = normalize(worldTangent);
	float3 B = normalize(worldBinormal);
	float3 N = normalize(worldNormal);
	
	float3 Nb = Bump.r * T + Bump.g * B + Bump.b * N;
	Nb = normalize(Nb);
  
  //  Nova_normal = nm.r*TANGENT + nm.g*BINORMAL + nm.b*NORMAL
  
  

//
//  Sample the normal map using the instruction tex2D(normal_sampler, texCoord).rgb.
//  Then, you need to expand the components of the normal map using the "expand" function
//  provided in the code. Once you have this, you can computed the new "perturbed" normal
//  as a linear combination of the fragment's tangent-space vectors.
//
//  IMPORTANT: Don't forget that once interpolated by the rasterization process, the
//  vectors are not guaranteed to be normalized, so you have to enforce that. 
//  
//  Only after you complete the exercise, use the variable "Bumpy" to scale the values sampled from 
//  the normal map and see what happens. If nothing different happens (as you change the value of
//  "bump power"  through the FX Composer interface. 
//
 

//
//   In the computation of the new normal vector Nb (see below)
//   we use "Nn" as opposed to "bumps.b * Nn" as one would expect, only
//   in order to be able to scale the height of the bumps by the
//   the scaling factor "Bumpy". As we use "bumps.b * Nn", all three vectors
//   (Nn, Tn and Bn) will be scaled by "Bumpy". Since Nb is subsequently 
//   normalized (which neutralizes the effect of Bumpy, except for its sign), 
//   it would only set the bump effect in two different modes
//   (inside and outside) as the sign of the variable Bumpy changes its sign. 
//   By using simply "Nn", we provide for a smooth variation in the heights, which
//   continuously move from inside to outside. 
//   
    //float3 Nb = ...;
//
//  Perturbed normal
//
    //Nb = normalize(Nb);
  //  
  // compute phong reflection
  // Replace the original materialDiffuse color with tex_diffuse_color
  // 
  colorOut = phongReflection(tex_diffuse_color, ambientLight,
                           tex_diffuse_color, Ks, shininess,
                           Nb, normalize(worldHalfAngle),
                           normalize(worldLightDirection), lightColor);
}

technique Phong {
    pass p0 {		
	VertexShader = compile vs_1_1 phongVS();
	PixelShader  = compile ps_2_0 phongPS();
    }    
}
