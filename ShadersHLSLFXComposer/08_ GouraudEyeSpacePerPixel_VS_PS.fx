string description = "Gouraud Shading: Per-pixel Phong lighting";

/************* NON-TWEAKABLES **************/
float4x4 worldView      : WorldView;
float4x4 worldViewIT    : WorldViewInverseTranspose;
float4x4 worldViewProj  : WorldViewProjection;
float4x4 view           : View;

/************* Variables **************/
float4 lightPosition    : Position = {1.0f, -3.0f, 1.0f, 1.0f};
float4 lightColor       : Diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
float4 ambientLight     : Ambient = {0.0f, 0.0f, 0.5f, 1.0f};

float4 materialDiffuse  : Diffuse = {0.0f, 0.0f, 1.0f, 1.0f};
float4 materialSpecular : Specular = {1.0f, 1.0f, 1.0f, 1.0f};
float shininess         : SpecularPower = 60.0;

/*********** Functions implementing the Phong lighting model ******/
float4 ambientReflection(float4 surfaceColor,
                         float4 lightColor)
{
    return lightColor * surfaceColor;
}

float4 diffuseReflection(float4 surfaceColor,
                         float3 surfaceNormal,
                         float4 lightColor,
                         float3 lightDirection)
{
    float diffuseFactor = max(0, dot(lightDirection, surfaceNormal));
    return lightColor * surfaceColor * diffuseFactor;
}

float4 specularReflection(float4 surfaceColor,
                          float  surfaceShininess,
                          float3 surfaceNormal,
                          float4 lightColor,
                          float3 halfAngle)
{
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
                       float4 lightColor)
{
                       
    float4 ambient = ambientReflection(ambientSurfaceColor, ambientLightColor);
    
    float4 diffuse = diffuseReflection(diffuseSurfaceColor, surfaceNormal, lightColor, lightDirection);
                                     
    float4 specular;
    
    if (dot(lightDirection, surfaceNormal) <= 0)
        specular = float4(0,0,0,0);
    else
        specular = specularReflection(specularSurfaceColor, surfaceShininess, surfaceNormal, lightColor, halfAngle);
                                       
    return ambient + diffuse + specular;
}

/*********** Vertex shader ******/
void gouraudVS(in float4 position       : POSITION,
               in float4 normal         : NORMAL,
              out float4 clipPosition   : POSITION,
              out float4 outPosition    : TEXCOORD0,
              out float4 outNormal      : TEXCOORD1)
{

    // compute standard clip position
    clipPosition = mul(position, worldViewProj);
    outPosition = position;
    outNormal = normal;
   
}


/*********** Pixel shader ******/
void gouraudPS(in float4 position    : TEXCOORD0,
               in float4 normal      : TEXCOORD1,
              out float4 outColor    : COLOR)
{
    // compute the necessary positions and directions in eye space  
    float3 eyeSurfacePosition = mul(position, worldView).xyz;
    float3 eyeLightPosition   = mul(lightPosition, view).xyz;
    
    float3 eyeViewerDirection = normalize(-eyeSurfacePosition);
    float3 eyeSurfaceNormal   = normalize(mul(normal, worldViewIT).xyz);
    float3 eyeLightDirection  = normalize(eyeLightPosition - eyeSurfacePosition);
    float3 eyeHalfAngle       = normalize(eyeViewerDirection + eyeLightDirection);
    
    // compute phong reflection
    outColor = phongReflection(materialDiffuse, ambientLight,
                            materialDiffuse, materialSpecular, shininess,
                            eyeSurfaceNormal, eyeHalfAngle,
                           eyeLightDirection, lightColor);
                           
    outColor.xyzw = outColor.zyxw;
}

technique gouraud
{
    pass p0
    {		
        VertexShader = compile vs_2_0 gouraudVS();
        PixelShader = compile ps_2_0 gouraudPS();
        ZWriteEnable = true;
        ZFunc = LessEqual;
        CullMode = None;
    }    
}
