#define TEST
using System;

namespace UnityEngine.Rendering.PostProcessing
{
    /// <summary>
    /// Convolution kernel size for the Depth of Field effect.
    /// </summary>
    public enum KernelSize
    {
        /// <summary>
        /// Small filter.
        /// </summary>
        Small,

        /// <summary>
        /// Medium filter.
        /// </summary>
        Medium,

        /// <summary>
        /// Large filter.
        /// </summary>
        Large,

        /// <summary>
        /// Very large filter.
        /// </summary>
        VeryLarge
    }

    /// <summary>
    /// A volume parameter holding a <see cref="KernelSize"/> value.
    /// </summary>
    [Serializable]
    public sealed class KernelSizeParameter : ParameterOverride<KernelSize> {}

    /// <summary>
    /// This class holds settings for the Depth of Field effect.
    /// </summary>
    [Serializable]
    [PostProcess(typeof(DepthOfFieldRenderer), "Unity/Depth of Field", false)]
    public sealed class DepthOfField : PostProcessEffectSettings
    {
        /// <summary>
        /// The distance to the point of focus.
        /// </summary>
        [Min(0.1f), Tooltip("Distance to the point of focus.")]
        public FloatParameter focusDistance = new FloatParameter { value = 20f };
#if TEST
        /// <summary>
        /// The distance from the focal region on the side nearer to the camera over which the scene transitions from focused to blurred
        /// </summary>
        [Range(0.05f, 1000f), Tooltip("The region of image in focus")]
        public FloatParameter focalRegion = new FloatParameter { value = 2.0f };

        /// <summary>
        /// The distance from the focal region on the side nearer to the camera over which the scene transitions from focused to blurred
        /// </summary>
        [Range(0.05f, 1000f), Tooltip("The distance from the focal region on the side nearer to the camera over which the scene transitions from focused to blurred")]
        public FloatParameter nearTransition = new FloatParameter { value = 50.0f };

        /// <summary>
        /// The distance from the focal region on the side nearer to the camera over which the scene transitions from focused to blurred
        /// </summary>
        [Range(0.05f, 1000f), Tooltip("The distance from the focal region on the side further to the camera over which the scene transitions from focused to blurred")]
        public FloatParameter farTransition = new FloatParameter { value = 50.0f };
#else
        /// <summary>
        /// The ratio of the aperture (known as f-stop or f-number). The smaller the value is, the
        /// shallower the depth of field is.
        /// </summary>
        [Range(0.05f, 32f), Tooltip("Ratio of aperture (known as f-stop or f-number). The smaller the value is, the shallower the depth of field is.")]
        public FloatParameter aperture = new FloatParameter { value = 5.6f };

        /// <summary>
        /// The distance between the lens and the film. The larger the value is, the shallower the
        /// depth of field is.
        /// </summary>
        [Range(1f, 300f), Tooltip("Distance between the lens and the film. The larger the value is, the shallower the depth of field is.")]
        public FloatParameter focalLength = new FloatParameter { value = 50f };

        /// <summary>
        /// The convolution kernel size of the bokeh filter, which determines the maximum radius of
        /// bokeh. It also affects the performance (the larger the kernel is, the longer the GPU
        /// time is required).
        /// </summary>
        [DisplayName("Max Blur Size"), Tooltip("Convolution kernel size of the bokeh filter, which determines the maximum radius of bokeh. It also affects performances (the larger the kernel is, the longer the GPU time is required).")]
        public KernelSizeParameter kernelSize = new KernelSizeParameter { value = KernelSize.Medium };
#endif
        /// <summary>
        /// Returns <c>true</c> if the effect is currently enabled and supported.
        /// </summary>
        /// <param name="context">The current post-processing render context</param>
        /// <returns><c>true</c> if the effect is currently enabled and supported</returns>
        public override bool IsEnabledAndSupported(PostProcessRenderContext context)
        {
            return enabled.value
                && SystemInfo.graphicsShaderLevel >= 35;
        }
    }

    [UnityEngine.Scripting.Preserve]
    // TODO: Doesn't play nice with alpha propagation, see if it can be fixed without killing performances
    internal sealed class DepthOfFieldRenderer : PostProcessEffectRenderer<DepthOfField>
    {
        enum Pass
        {
            DownSample,
            UpSample,
            DepthBlur,
            BlurHSmall,
            BlurVSmall,
            BlurHMedium,
            BlurVMedium,
            BlurHLarge,
            BlurVLarge,
            BlurHVeryLarge,
            BlurVVeryLarge,
            Composite
        }

        // Height of the 35mm full-frame format (36mm x 24mm)
        // TODO: Should be set by a physical camera
        const float k_FilmHeight = 0.024f;
        int dofDepthID;

        public override void Init()
        {
            dofDepthID = Shader.PropertyToID("_DofDepth");
        }

        public override DepthTextureMode GetCameraFlags()
        {
            return DepthTextureMode.Depth;
        }
#if !TEST
        float CalculateMaxCoCRadius(int screenHeight)
        {
            // Estimate the allowable maximum radius of CoC from the kernel
            // size (the equation below was empirically derived).
            float radiusInPixels = (float)settings.kernelSize.value * 4f + 6f;

            // Applying a 5% limit to the CoC radius to keep the size of
            // TileMax/NeighborMax small enough.
            return Mathf.Min(0.05f, radiusInPixels / screenHeight);
        }
#endif
        public override void Render(PostProcessRenderContext context)
        {
            // The coc is stored in alpha so we need a 4 channels target. Note that using ARGB32
            // will result in a very weak near-blur.
            var colorFormat = context.camera.allowHDR ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32;
            var cocFormat = RenderTextureFormat.R8;
#if TEST
            // Material setup
            var sheet = context.propertySheets.Get(context.resources.shaders.depthOfField);
            sheet.properties.Clear();
            float halfRegion = settings.focalRegion / 2.0f;
            float nearEnd = settings.focusDistance - halfRegion;
            float nearStart = nearEnd - settings.nearTransition;
            float farStart = settings.focalRegion + halfRegion;
            float farEnd = farStart + settings.farTransition;
            var dofDepth = new Vector4(nearStart, nearEnd, farStart, farEnd);
            sheet.properties.SetVector(dofDepthID, dofDepth);
#else
            // Material setup
            float scaledFilmHeight = k_FilmHeight * (context.height / 1080f);
            var f = settings.focalLength.value / 1000f;
            var s1 = Mathf.Max(settings.focusDistance.value, f);
            var aspect = (float)context.screenWidth / (float)context.screenHeight;
            var coeff = f * f / (settings.aperture.value * (s1 - f) * scaledFilmHeight * 2f);
            var maxCoC = CalculateMaxCoCRadius(context.screenHeight);

            var sheet = context.propertySheets.Get(context.resources.shaders.depthOfField);
            sheet.properties.Clear();
            sheet.properties.SetFloat(ShaderIDs.Distance, s1);
            sheet.properties.SetFloat(ShaderIDs.LensCoeff, coeff);
            sheet.properties.SetFloat(ShaderIDs.MaxCoC, maxCoC);
            sheet.properties.SetFloat(ShaderIDs.RcpMaxCoC, 1f / maxCoC);
            sheet.properties.SetFloat(ShaderIDs.RcpAspect, 1f / aspect);
#endif
            var cmd = context.command;
            cmd.BeginSample("DepthOfField");

            //// Generate blur amount and linearize depth
            //context.GetScreenSpaceTemporaryRT(cmd, ShaderIDs.CoCTex, 0, cocFormat, RenderTextureReadWrite.Linear);
            //cmd.BlitFullscreenTriangle(BuiltinRenderTextureType.None, ShaderIDs.CoCTex, sheet, (int)Pass.DepthBlur);

            cmd.BeginSample("Downsample1");
            // Downsample
            context.GetScreenSpaceTemporaryRT(cmd, ShaderIDs.DepthOfFieldTex, 0, colorFormat, RenderTextureReadWrite.Default, FilterMode.Bilinear, context.width / 2, context.height / 2);
            cmd.BlitFullscreenTriangle(context.source, ShaderIDs.DepthOfFieldTex, sheet, (int)Pass.DownSample);
            cmd.EndSample("Downsample1");

            cmd.BeginSample("Downsample2");
            // Downsample
            context.GetScreenSpaceTemporaryRT(cmd, ShaderIDs.DepthOfFieldTemp, 0, colorFormat, RenderTextureReadWrite.Default, FilterMode.Bilinear, context.width / 4, context.height / 4);
            cmd.BlitFullscreenTriangle(ShaderIDs.DepthOfFieldTex, ShaderIDs.DepthOfFieldTemp, sheet, (int)Pass.BlurHMedium);
            cmd.EndSample("Downsample2");

            cmd.BeginSample("Upsample");
            // Upsample
            cmd.BlitFullscreenTriangle(ShaderIDs.DepthOfFieldTemp, ShaderIDs.DepthOfFieldTex, sheet, (int)Pass.DownSample);
            cmd.EndSample("Upsample");

            cmd.ReleaseTemporaryRT(ShaderIDs.DepthOfFieldTemp);

            // Combine pass
            cmd.BeginSample("Combine");
            cmd.BlitFullscreenTriangle(context.source, context.destination, sheet, (int)Pass.Composite);
            cmd.EndSample("Combine");
            cmd.ReleaseTemporaryRT(ShaderIDs.DepthOfFieldTex);

            if (!context.IsTemporalAntialiasingActive())
                cmd.ReleaseTemporaryRT(ShaderIDs.CoCTex);

            cmd.EndSample("DepthOfField");

            m_ResetHistory = false;
        }

        public override void Release()
        {
            ResetHistory();
        }
    }
}
