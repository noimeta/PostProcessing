Shader "Hidden/PostProcessing/CustomBloom"
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
		float  _Bluriness;
        float4 _Params; // x: clamp, yzw: unused

		struct VaryingsForBlur
		{
			float4 vertex : SV_POSITION;
			float2 texcoord : TEXCOORD0;
			float4 lower : TEXCOORD1;
			float4 upper : TEXCOORD2;
		};

		VaryingsDefault VertDefault(AttributesDefault v)
		{
			VaryingsDefault o;
			o.vertex = float4(v.vertex.xy, 0.0, 1.0);
			o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);
			o.texcoord = o.texcoord * float2(1.0, -1.0) + float2(0.0, 1.0);
			return o;
		}

		VaryingsForBlur VertForBlur(AttributesDefault v)
		{
			VaryingsDefault o;
			o.vertex = float4(v.vertex.xy, 0.0, 1.0);
			o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);
			o.texcoord = o.texcoord * float2(1.0, -1.0) + float2(0.0, 1.0);

			float4 offset = _MainTex_TexelSize.xyxy * float2(-_Bluriness, _Bluriness).xxyy;
			o.lower = o.texcoord.xyxy + offset.xyzy;
			o.upper = o.texcoord.xyxy + offset.xwzw;
			return o;
		}

		half4 FragPreFilter(VaryingsForBlur i) : SV_Target
		{
			half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.lower.xy);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.lower.zw);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.upper.xy);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.upper.zw);
			color = QuadraticThreshold(color, _Threshold.x, _Threshold.yzw);
			return color;
		}

		half4 FragBlur(VaryingsForBlur i) : SV_Target
		{
			half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.lower.xy);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.lower.zw);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.upper.xy);
			color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.upper.zw);
			return color * 0.2;
		}

        // ----------------------------------------------------------------------------------------
        // Prefilter

        half4 Prefilter(half4 color, float2 uv)
        {
            half autoExposure = SAMPLE_TEXTURE2D(_AutoExposureTex, sampler_AutoExposureTex, uv).r;
            color *= autoExposure;
            color = min(_Params.x, color); // clamp to max
            color = QuadraticThreshold(color, _Threshold.x, _Threshold.yzw);
            return color;
        }

		half4 FragPrefilter(VaryingsDefault i) : SV_Target
		{
			half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
			return Prefilter(SafeHDR(color), i.texcoord);
		}

        half4 FragPrefilter4(VaryingsDefault i) : SV_Target
        {
			half4 color = DownsampleBox4Tap(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, UnityStereoAdjustedTexelSize(_MainTex_TexelSize).xy);
            return Prefilter(SafeHDR(color), i.texcoord);
        }

		// ----------------------------------------------------------------------------------------
		// Blur
		half4 FragHorizontalBlur(VaryingsDefault i) : SV_Target
		{
			return HorizontalBlur(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy);
		}

		half4 FragVerticalBlur(VaryingsDefault i) : SV_Target
		{
			return VerticalBlur(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, _MainTex_TexelSize.xy);
		}

        // ----------------------------------------------------------------------------------------
        // Downsample

        half4 FragDownsample4(VaryingsDefault i) : SV_Target
        {
            half4 color = DownsampleBox4Tap(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, UnityStereoAdjustedTexelSize(_MainTex_TexelSize).xy);
            return color;
        }

        // ----------------------------------------------------------------------------------------
        // Upsample & combine

        half4 Combine(half4 bloom, float2 uv)
        {
            half4 color = SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, uv);
            return bloom + color;
        }

        half4 FragUpsampleBox(VaryingsDefault i) : SV_Target
        {
            half4 bloom = UpsampleBox(TEXTURE2D_PARAM(_MainTex, sampler_MainTex), i.texcoord, UnityStereoAdjustedTexelSize(_MainTex_TexelSize).xy, _SampleScale);
            return Combine(bloom, i.texcoordStereo);
        }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // 0: Prefilter with blur
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertForBlur
                #pragma fragment FragPrefilter

            ENDHLSL
        }

        // 1: Blur pass
        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertForBlur
                #pragma fragment FragBlur

            ENDHLSL
        }
    }
}
