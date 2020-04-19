Shader "Hidden/PostProcessing/Bloom"
{
    HLSLINCLUDE
        
        #include "../StdLib.hlsl"
        #include "../Colors.hlsl"
        #include "../Sampling.hlsl"

        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        TEXTURE2D_SAMPLER2D(_BloomTex, sampler_BloomTex);

        float4 _MainTex_TexelSize;
        float4 _Threshold; // x: threshold value (linear), y: threshold - knee, z: knee * 2, w: 0.25 / knee
		float  _SampleScale;

        // ----------------------------------------------------------------------------------------
        // Prefilter

        half4 Prefilter(half4 color)
        {
			//return color - _Threshold.xxxx;
			return QuadraticThreshold(color, _Threshold.x, _Threshold.yzw);
        }

        half4 FragPrefilter(VaryingsSimple i) : SV_Target
        {
            half4 color = DownsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0, _SampleScale);
            return Prefilter(SafeHDR(color));
        }

        // ----------------------------------------------------------------------------------------
        // Downsample

        half4 FragDownsample(VaryingsSimple i) : SV_Target
        {
            return DownsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0, _SampleScale);
        }

        // ----------------------------------------------------------------------------------------
        // Upsample

        half4 FragUpsample(VaryingsSimple i) : SV_Target
        {
			return UpsampleDual(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy / 2.0, _SampleScale);
        }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // 0: Prefilter
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertSimple
                #pragma fragment FragPrefilter

            ENDHLSL
        }

        // 1: Downsample
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertSimple
                #pragma fragment FragDownsample

            ENDHLSL
        }

        // 2: Upsample
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertSimple
                #pragma fragment FragUpsample

            ENDHLSL
        }
    }
}
