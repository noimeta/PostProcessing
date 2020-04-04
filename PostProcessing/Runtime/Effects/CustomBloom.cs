using System;
using UnityEngine.Serialization;

namespace UnityEngine.Rendering.PostProcessing
{
    // For now and by popular request, this bloom effect is geared toward artists so they have full
    // control over how it looks at the expense of physical correctness.
    // Eventually we will need a "true" natural bloom effect with proper energy conservation.

    /// <summary>
    /// This class holds settings for the Bloom effect.
    /// </summary>
    [Serializable]
    [PostProcess(typeof(CustomBloomRenderer), "Unity/CustomBloom")]
    public sealed class CustomBloom : PostProcessEffectSettings
    {
        /// <summary>
        /// The strength of the bloom filter.
        /// </summary>
        [Min(0f), Tooltip("Strength of the bloom filter. Values higher than 1 will make bloom contribute more energy to the final render.")]
        public FloatParameter intensity = new FloatParameter { value = 0f };

        /// <summary>
        /// Filters out pixels under this level of brightness. This value is expressed in
        /// gamma-space.
        /// </summary>
        [Min(0f), Tooltip("Filters out pixels under this level of brightness. Value is in gamma-space.")]
        public FloatParameter threshold = new FloatParameter { value = 1f };

        /// <summary>
        /// Bluriness
        /// </summary>
        [Min(0f), Tooltip("bluriness")]
        public FloatParameter bluriness = new FloatParameter { value = 1f };

        /// <summary>
        /// Returns <c>true</c> if the effect is currently enabled and supported.
        /// </summary>
        /// <param name="context">The current post-processing render context</param>
        /// <returns><c>true</c> if the effect is currently enabled and supported</returns>
        public override bool IsEnabledAndSupported(PostProcessRenderContext context)
        {
            return enabled.value
                && intensity.value > 0f;
        }
    }

    [UnityEngine.Scripting.Preserve]
    internal sealed class CustomBloomRenderer : PostProcessEffectRenderer<CustomBloom>
    {
        enum Pass
        {
            Prefilter,
            Blur
        }
        int tmpFull;
        int tmpHalf;
        int bluriness;

        public override void Init()
        {
            tmpFull = Shader.PropertyToID("_tmpFull");
            tmpHalf = Shader.PropertyToID("_tmpHalf");
            bluriness = Shader.PropertyToID("_Bluriness");
        }

        public override void Render(PostProcessRenderContext context)
        {
            var cmd = context.command;
            cmd.BeginSample("CustomBloom");

            var sheet = context.propertySheets.Get(context.resources.shaders.bloom);

            // Apply auto exposure adjustment in the prefiltering pass
            sheet.properties.SetTexture(ShaderIDs.AutoExposureTex, context.autoExposureTexture);

            // Do bloom on a half-res buffer, full-res doesn't bring much and kills performances on
            // fillrate limited platforms
            int tw = Mathf.FloorToInt(context.screenWidth / 2f);
            int th = Mathf.FloorToInt(context.screenHeight / 2f);

            // Prefiltering parameters
            float lthresh = Mathf.GammaToLinearSpace(settings.threshold.value);
            float knee = lthresh * 0.5f;
            var threshold = new Vector4(lthresh, lthresh - knee, knee * 2f, 0.25f / knee);
            sheet.properties.SetVector(ShaderIDs.Threshold, threshold);
            float lclamp = Mathf.GammaToLinearSpace(65472);
            sheet.properties.SetVector(ShaderIDs.Params, new Vector4(lclamp, 0f, 0f, 0f));
            sheet.properties.SetFloat(bluriness, settings.bluriness.value);

            float intensity = RuntimeUtilities.Exp2(settings.intensity.value / 10f) - 1f;
            
            context.GetScreenSpaceTemporaryRT(cmd, tmpFull, 0, context.sourceFormat, RenderTextureReadWrite.Default, FilterMode.Bilinear, context.screenWidth, context.screenHeight);
            context.GetScreenSpaceTemporaryRT(cmd, tmpHalf, 0, context.sourceFormat, RenderTextureReadWrite.Default, FilterMode.Bilinear, tw, th);
            cmd.BlitFullscreenTriangle(context.source, tmpFull, sheet, (int)Pass.Prefilter);

            cmd.BlitFullscreenTriangle(tmpFull, tmpHalf, sheet, (int)Pass.Blur);
            cmd.BlitFullscreenTriangle(tmpHalf, tmpFull, sheet, (int)Pass.Blur);
            var shaderSettings = new Vector4(1, intensity, 0, 0);
            
            var screenRatio = (float)context.screenWidth / (float)context.screenHeight;

            // Shader properties
            var uberSheet = context.uberSheet;
            uberSheet.EnableKeyword("BLOOM_CUSTOM");
            uberSheet.properties.SetVector(ShaderIDs.Bloom_Settings, shaderSettings);
            cmd.SetGlobalTexture(ShaderIDs.BloomTex, tmpFull);

            // Cleanup
            cmd.ReleaseTemporaryRT(tmpHalf);

            cmd.EndSample("CustomBloom");
            
            context.bloomBufferNameID = tmpFull;
        }
    }
}
