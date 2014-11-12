string description = "Gouraud Shading: Per-vertex Phong lighting";

/************* NON-TWEAKABLES **************/
float4x4 worldViewProj  : WorldViewProjection;
float4x4 world          : World;
float4x4 worldIT        : WorldInverseTranspose;
float4x4 viewI          : ViewInverse;

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
              out float4 color          : COLOR)
{

    // compute standard clip position
    clipPosition = mul(position, worldViewProj);
    
    
    // compute the necessary positions and directions in world space  
    float3 worldSurfacePosition = mul(position, world).xyz;
    float3 worldLightPosition   = lightPosition.xyz;
    
    float3 worldViewerDirection = normalize(viewI[3].xyz - worldSurfacePosition.xyz);
    float3 worldSurfaceNormal   = normalize(mul(normal, worldIT).xyz);
    float3 worldLightDirection  = normalize(worldLightPosition - worldSurfacePosition);
    float3 worldHalfAngle       = normalize(worldViewerDirection + worldLightDirection);
    
    // compute phong reflection
    color = phongReflection(materialDiffuse, ambientLight,
                            materialDiffuse, materialSpecular, shininess,
                            worldSurfaceNormal, worldHalfAngle,
                            worldLightDirection, lightColor);
    
    
}


/*********** Pixel shader ******/
void gouraudPS(float4 inColor   : COLOR,
           out float4 outColor  : COLOR)
{
    outColor.xyzw = inColor.zyxw;
}

technique gouraud
{
    pass p0
    {		
        VertexShader = compile vs_1_1 gouraudVS();
        PixelShader = compile ps_1_1 gouraudPS();
        ZWriteEnable = true;
        ZFunc = LessEqual;
        CullMode = None;
    }    
}
