///////////////////////////////////////////////////////////////////////////
// State matrices declaration
///////////////////////////////////////////////////////////////////////////
float4x4 World               : WORLD < string UIWidget="None"; >;
float4x4 WorldIT             : WORLDINVERSETRANSPOSE < string UIWidget="None"; >;
float4x4 ViewI               : VIEWINVERSE < string UIWidget="None"; >;
float4x4 WorldViewProjection : WORLDVIEWPROJECTION < string UIWidget="None"; >;
///////////////////////////////////////////////////////////////////////////
// Some global parameters
 ///////////////////////////////////////////////////////////////////////////
static const float pi
<
	string UIWidget="None";
> = 3.14159f;
///////////////////////////////////////////////////////////////////////////
float4 ambientLightColor : AMBIENT
<
	string UIName =  "Ambient - Light Color";
> = {0.1f, 0.1f, 0.1f, 1.0f};
///////////////////////////////////////////////////////////////////////////
float4 lampLightColor
<
	string UIName = "Lamp - Light Color";
	string UIWidget = "Color";
> = {1.0f, 1.0f, 1.0f, 1.0f};
///////////////////////////////////////////////////////////////////////////
float lampSolidAngle
<
	string UIName = "Lamp - Solid Angle";
> = {1.0f};
///////////////////////////////////////////////////////////////////////////
float4 lampWorldPosition : POSITION
<
    string Object = "PointLight";
    string Space = "World";
    string UIName = "Incident Light - Position (world)";
> = {1.0f, -3.0f, 1.0f, 0.0f};
///////////////////////////////////////////////////////////////////////////
float4 surfaceAmbientReflectance
<
	string UIName =  "Surface - Ambient Reflectance";
> = {0.2f, 0.2f, 1.0f, 1.0f};
///////////////////////////////////////////////////////////////////////////
float4 surfaceDiffuseReflectance
<
	string UIName =  "Surface - Diffuse Reflectance";
> = {0.2f, 0.2f, 1.0f, 1.0f};
///////////////////////////////////////////////////////////////////////////
float3 surfaceRefractionIndex
<
	string UIName = "Surface - Refraction Index";
> = {1.8f, 1.8f, 1.8f};
///////////////////////////////////////////////////////////////////////////
float surfaceSpecularFraction
<
	string UIName =  "Surface - Specular Fraction";
> = {100.8f};
///////////////////////////////////////////////////////////////////////////
float surfaceDiffuseFraction
<
	string UIName =  "Surface - Diffuse Fraction";
> = {0.2f};
///////////////////////////////////////////////////////////////////////////
float surfaceFacetsRootMeanSquareSlopeX
<
	string UIWidget="Slider";
	string UIName="mx";
	float UIMin = 1.0f;
	float UIMax = 200.0f;
	float UIStep = 5.0f;
> = { 100.0 };
///////////////////////////////////////////////////////////////////////////
float surfaceFacetsRootMeanSquareSlopeY
<
	string UIWidget="Slider";
	string UIName="my";
	float UIMin = 1.0f;
	float UIMax = 200.0f;
	float UIStep = 10.0f;
> = { 10.0 };
///////////////////////////////////////////////////////////////////////////
// Shirley-Ashkmin reflectance model
///////////////////////////////////////////////////////////////////////////
struct TBN
{
	float3 Normal;
	float3 Binormal;
	float3 Tangent;
};
///////////////////////////////////////////////////////////////////////////
float3 Fresnel(float3 n, float VdotH)
{
	float3 g = sqrt((n * n) + (VdotH * VdotH) - 1.0f);
	float3 gPlusC = g + VdotH;
	float3 gMinusC = g - VdotH;
	float3 temp = ((VdotH * gPlusC) - 1.0f) / ((VdotH * gMinusC) + 1.0f);
	return (0.5f * (gMinusC * gMinusC) / (gPlusC * gPlusC)) * (1.0f + (temp * temp));
}
///////////////////////////////////////////////////////////////////////////
TBN makeTBN ( float3 N )
{
	TBN 	OutTBN;
	float3 	y;           
	
   	y 	= float3(0,1,0);
   
	OutTBN.Normal = normalize(N);
	
	if (abs( dot(y, OutTBN.Normal) ) > (1 - 0.001)) 
	{
	     y = float3(0.1, 1, 0);
	}
	
	OutTBN.Tangent 	= cross(y, OutTBN.Normal);
	OutTBN.Binormal = cross(OutTBN.Normal, OutTBN.Tangent);
	
	OutTBN.Tangent 	= normalize(OutTBN.Tangent);
	OutTBN.Binormal = normalize(OutTBN.Binormal);       
	
	return OutTBN;
}
///////////////////////////////////////////////////////////////////////////
float4 Shading(float4 Ia, float4 I, float3 N, float3 L, float3 V, float3 H, float omega, float4 Ra, float4 Rd, float3 n, float mx, float my, float d, float s)
{

	N 	= normalize(N);
	TBN tbn;	
  	tbn = makeTBN(N);
  	float3 Bn 	= tbn.Binormal;
  	N 	= tbn.Normal;
  	float3 Tg	= tbn.Tangent; 

	float NdotL = saturate(dot(N, L));
	float NdotV = saturate(dot(N, V));
	float NdotH = saturate(dot(N, H));
	float VdotH = saturate(dot(V, H));
	float4 E = I * NdotL * omega;
  	float T1H 	= dot(Bn, H);
  	float T2H 	= dot(Tg, H);
	

	// Ambient reflection
	float4 ambient = Ia * Ra;
	
	// Diffuse reflection
	float4 diffuse = E * d * Rd;
	
	// Specular reflection
	float G = min(1.0f, (2.0f * NdotH / VdotH) * min(NdotV, NdotL));
	
	//Shirley-Ashkmin
	float D = (pow(NdotH,(mx * T1H * T1H + my * T2H * T2H) / (1 - NdotH * NdotH)));   

	//Cook-Torrance
	//float temp = tan(acos(NdotH)) / mx;
	//float D = exp(-(temp * temp)) / ((mx * mx) * (NdotH * NdotH));

	float3 F = Fresnel(n, VdotH);

	float4 Rs = float4((F / pi) * (D * G / (NdotL * NdotV)), 1.0f);
	
	float4 specular = E * s * Rs;
		
	// Final color
	return ambient + diffuse + specular;
	
}
///////////////////////////////////////////////////////////////////////////
// Vertex shader
///////////////////////////////////////////////////////////////////////////
void MainVS(float4 osPosition        : POSITION,
            float3 osNormal          : NORMAL,
        out float4 csPosition        : POSITION,
        out float3 wsNormal          : TEXCOORD0,
        out float3 wsLightDirection  : TEXCOORD1,
        out float3 wsViewerDirection : TEXCOORD2,
        out float3 wsHalfAngleVector : TEXCOORD3)
{
	// Compute standard clip position
	csPosition = mul(osPosition, WorldViewProjection);

	// Compute temporary variables
	float3 wsPosition = mul(osPosition,World).xyz;
	
	// Compute values to be interpolated
	wsNormal = normalize(mul(float4(osNormal, 0.0f), WorldIT).xyz);
	wsLightDirection = normalize(lampWorldPosition.xyz - wsPosition);
	wsViewerDirection = normalize(ViewI[3].xyz - wsPosition);
	wsHalfAngleVector = normalize(wsLightDirection + wsViewerDirection);
}
///////////////////////////////////////////////////////////////////////////
// Pixel shader
///////////////////////////////////////////////////////////////////////////
void MainPS(float3 wsNormal          : TEXCOORD0,
            float3 wsLightDirection  : TEXCOORD1,
            float3 wsViewerDirection : TEXCOORD2,
            float3 wsHalfAngleVector : TEXCOORD3,

        out float4 color             : COLOR)
{
	// Normalize some vectors
	wsNormal = normalize(wsNormal);
	wsLightDirection = normalize(wsLightDirection);
	wsViewerDirection = normalize(wsViewerDirection);
	wsHalfAngleVector = normalize(wsHalfAngleVector);
	
	// Compute final color
	color = Shading(
		ambientLightColor,
		lampLightColor,
    	
    	wsNormal,
    	wsLightDirection,
    	wsViewerDirection,
    	wsHalfAngleVector,
    	
    	lampSolidAngle,
    	
    	surfaceAmbientReflectance,
    	surfaceDiffuseReflectance,
    	surfaceRefractionIndex,
    	surfaceFacetsRootMeanSquareSlopeX,
    	surfaceFacetsRootMeanSquareSlopeY,
    	surfaceDiffuseFraction,
    	surfaceSpecularFraction);
}
///////////////////////////////////////////////////////////////////////////
// Technique declaration
///////////////////////////////////////////////////////////////////////////
technique CookTorrance
{
    pass p0
    {		
		VertexShader = compile vs_1_1 MainVS();
		PixelShader = compile ps_2_a MainPS();
    }
}
///////////////////////////////////////////////////////////////////////////
