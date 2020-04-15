Shader "Hidden/PostProcessing/DepthOfField"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

		Pass // 0
		{
			Name "Downsample"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDownsample
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 1
		{
			Name "Upsample"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragUpsample
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 2
		{
			Name "Depth Blur"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FradDepthBlurGeneration
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 3
		{
			Name "Horizontal Blur (small)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurH
				#define KERNEL_SMALL
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 4
		{
			Name "Vertical Blur (small)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurV
				#define KERNEL_SMALL
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 5
		{
			Name "Horizontal Blur (medium)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurH
				#define KERNEL_MEDIUM
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 6
		{
			Name "Vertical Blur (medium)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurV
				#define KERNEL_MEDIUM
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 7
		{
			Name "Horizontal Blur (large)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurH
				#define KERNEL_LARGE
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 8
		{
			Name "Vertical Blur (large)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurV
				#define KERNEL_LARGE
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 9
		{
			Name "Horizontal Blur (large)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurH
				#define KERNEL_VERYLARGE
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 10
		{
			Name "Vertical Blur (large)"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFBlurV
				#define KERNEL_VERYLARGE
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}

		Pass // 11
		{
			Name "Composite"

			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex VertSimple
				#pragma fragment FragDOFComposite
				#include "GaussianDepthOfField.hlsl"
			ENDHLSL
		}
    }
}
