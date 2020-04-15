#ifndef UNITY_POSTFX_GAUSSIAN_DEPTH_OF_FIELD
#define UNITY_POSTFX_GAUSSIAN_DEPTH_OF_FIELD

#include "../StdLib.hlsl"
#include "../Colors.hlsl"
#include "../Sampling.hlsl"
//#include "GaussianKernels.hlsl"

TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
float4 _MainTex_TexelSize;

TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);

TEXTURE2D_SAMPLER2D(_CoCTex, sampler_CoCTex);

TEXTURE2D_SAMPLER2D(_DepthOfFieldTex, sampler_DepthOfFieldTex);
float4 _DepthOfFieldTex_TexelSize;

// Camera parameters
float4 _DofDepth;

// 9-tap filters
static const int kGaussianSampleCount = 3;
static const float kGaussianOffsets[kGaussianSampleCount] = {
	0.0,
	1.3846153846,
	3.2307692308
};
static const float kGaussianWeights[kGaussianSampleCount] = {
	0.2270270270,
	0.3162162162,
	0.0702702703
};

float calculateBlurAmount(float2 texcoord)
{
	float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, texcoord));
	float f0 = 1.0f - saturate((depth - _DofDepth.x) / max(_DofDepth.y - _DofDepth.x, 0.01f));
	float f1 = saturate((depth - _DofDepth.z) / max(_DofDepth.w - _DofDepth.z, 0.01f));
	return saturate(f0 + f1);
}

// CoC calculation
half4 FradDepthBlurGeneration(VaryingsSimple i) : SV_Target
{
	float blur = calculateBlurAmount(i.texcoord);
	return half4(blur, 0, 0, 0);
}


// ----------------------------------------------------------------------------------------
// Downsample
half4 FragDownsample(VaryingsSimple i) : SV_Target
{
	return DownsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0, 1);
}

// ----------------------------------------------------------------------------------------
// Upsample

half4 FragUpsample(VaryingsSimple i) : SV_Target
{
	return UpsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0, 1);
}


half3 DOFBlur(VaryingsSimple i, float2 texScale) 
{
	half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).xyz * kGaussianWeights[0];
	color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + kGaussianOffsets[1] * texScale).xyz * kGaussianWeights[1];
	color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord - kGaussianOffsets[1] * texScale).xyz * kGaussianWeights[1];
	color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + kGaussianOffsets[2] * texScale).xyz * kGaussianWeights[2];
	color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord - kGaussianOffsets[2] * texScale).xyz * kGaussianWeights[2];
	return color;
}

// Horizontal DOF blur
half4 FragDOFBlurH(VaryingsSimple i) : SV_Target
{
	return half4(DOFBlur(i, float2(_MainTex_TexelSize.x, 0)), 1.0);
}

// Vertical DOF blur
half4 FragDOFBlurV(VaryingsSimple i) : SV_Target
{
	return half4(DOFBlur(i, float2(0, _MainTex_TexelSize.y)), 1.0);
}

// Depth of field using gaussian blur
half4 FragDOFComposite(VaryingsSimple i) : SV_Target
{
	// Sample the original texture
	half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).xyz;

	//// Sample the depth, and compute the blur value
	//half blur = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, i.texcoord).r;
	float blur = calculateBlurAmount(i.texcoord);

	//// Sample the blurred texture
	//half3 blurred_color = SAMPLE_TEXTURE2D(_DepthOfFieldTex, sampler_DepthOfFieldTex, i.texcoord).rgb;
	half3 blurred_color = UpsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0, 1).rgb;

	// Lerp based on the blur factor
	half3 finalColor = lerp(color, blurred_color, blur);

	return half4(finalColor, 1.0f);
}

#endif // UNITY_POSTFX_GAUSSIAN_DEPTH_OF_FIELD
