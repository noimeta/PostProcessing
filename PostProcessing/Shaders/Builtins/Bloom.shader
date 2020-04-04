Shader "Hidden/PostProcessing/Bloom"
{
    HLSLINCLUDE
        
        #include "../StdLib.hlsl"
        #include "../Colors.hlsl"
        #include "../Sampling.hlsl"

        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        TEXTURE2D_SAMPLER2D(_BloomTex, sampler_BloomTex);
        TEXTURE2D_SAMPLER2D(_AutoExposureTex, sampler_AutoExposureTex);

        float4 _MainTex_TexelSize;
        float  _SampleScale;
        float4 _ColorIntensity;
        float4 _Threshold; // x: threshold value (linear), y: threshold - knee, z: knee * 2, w: 0.25 / knee
        float4 _Params; // x: clamp, yzw: unused

        // ----------------------------------------------------------------------------------------
        // Prefilter

        half4 Prefilter(half4 color, float2 uv)
        {
           return QuadraticThreshold(color, _Threshold.x, _Threshold.yzw);
        }

        half4 FragPrefilter(VaryingsDefault i) : SV_Target
        {
            half4 color = DownsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0);
            return Prefilter(SafeHDR(color), i.texcoord);
        }

        // ----------------------------------------------------------------------------------------
        // Downsample

        half4 FragDownsample(VaryingsDefault i) : SV_Target
        {
            return DownsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0);
        }

        // ----------------------------------------------------------------------------------------
        // Upsample

        half4 FragUpsample(VaryingsDefault i) : SV_Target
        {
			return UpsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0);
        }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // 0: Prefilter
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment FragPrefilter

            ENDHLSL
        }

        // 1: Downsample
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment FragDownsample

            ENDHLSL
        }

        // 2: Upsample
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment FragUpsample

            ENDHLSL
        }
    }
}
